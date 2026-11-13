#!/usr/bin/env python3
"""Vehicle sounds for Off Frequency (v0.5): Sollen's snowcat, Ma's pickup and
the county plow. Original synthesis, no recordings; seeded, so the same files
come out on every machine. Loops are built circularly (periodic firing,
FFT-domain filtering), so they wrap without a click.

    python3 tools/gen_vehicles.py

Writes 22.05 kHz mono WAVs into audio/, like tools/gen_audio.py:

    engine        the snowcat's diesel pulling down the mountain (loop)
    tracks        its tracks: grousers on the sprocket, snow, bogies (loop)
    engine_start  the snowcat cranked and catching (garage, the underpass)
    engine_stop   the diesel dying under the bridge
    starter       the starter turning a diesel with no fuel in it
    truck_idle    Ma's V8 idling in the snow, heater on (loop)
    truck_start   Ma's truck starting behind the diner
    plow          the county plow, far down the road (loop)

Requires numpy and scipy.
"""
from pathlib import Path
import wave

import numpy as np
from scipy.signal import freqz, lfilter

SR = 22050
OUT = Path(__file__).resolve().parents[1] / "audio"
TAU = 2 * np.pi


# --------------------------------------------------------------- filters

def biquad(kind, f0, q=0.707):
    """RBJ cookbook biquad coefficients."""
    w0 = TAU * f0 / SR
    c, s = np.cos(w0), np.sin(w0)
    alpha = s / (2 * q)
    if kind == "lp":
        b = [(1 - c) / 2, 1 - c, (1 - c) / 2]
    elif kind == "hp":
        b = [(1 + c) / 2, -(1 + c), (1 + c) / 2]
    elif kind == "bp":
        b = [alpha, 0.0, -alpha]
    else:
        raise ValueError(kind)
    a = [1 + alpha, -2 * c, 1 - alpha]
    return np.array(b) / a[0], np.array(a) / a[0]


def filt(x, kind, f0, q=0.707, loop=False):
    """One biquad. With loop=True it's applied circularly (the periodic steady
    state), so a looping signal stays seamless."""
    b, a = biquad(kind, f0, q)
    if not loop:
        return lfilter(b, a, x)
    n = len(x)
    f = np.fft.rfftfreq(n, 1 / SR)
    _, h = freqz(b, a, worN=f, fs=SR)
    return np.fft.irfft(np.fft.rfft(x) * h, n)


def chain(x, stages, loop=False):
    for st in stages:
        x = filt(x, *st, loop=loop)
    return x


def band(x, lo, hi, loop=False, order=2):
    for _ in range(order):
        x = filt(filt(x, "hp", lo, loop=loop), "lp", hi, loop=loop)
    return x


def place(dst, sig, i, gain=1.0, loop=False):
    """Add sig into dst at sample i (wrapping round when it's a loop)."""
    if loop:
        ix = (i + np.arange(len(sig))) % len(dst)
        np.add.at(dst, ix, sig * gain)
    else:
        j = min(len(dst), i + len(sig))
        if i < len(dst):
            dst[i:j] += sig[: j - i] * gain


def reverb(x, seconds, mix, rng, loop=False):
    """A plain exponential-noise tail: distance and the snowbanks."""
    n = int(seconds * SR)
    ir = rng.normal(0, 1, n) * np.exp(-np.arange(n) / (seconds * SR / 6.5))
    ir = band(ir, 200, 3500)
    ir /= np.sqrt(np.sum(ir ** 2))
    if loop:
        wet = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(ir, len(x)), len(x))
    else:
        wet = np.convolve(x, ir)[: len(x)]
    return x * (1 - mix) + wet * mix * 1.6


def fade(x, a=0.01, b=0.05):
    x = x.copy()
    na, nb = int(a * SR), int(b * SR)
    if na:
        x[:na] *= np.linspace(0, 1, na)
    if nb:
        x[-nb:] *= np.linspace(1, 0, nb)
    return x


def a_weighted_level(x):
    """Loudness as the ear hears it (A-weighted RMS, dB), so a rumble and a
    rattle can be set to sit at the same level in the mix."""
    f = np.maximum(np.fft.rfftfreq(len(x), 1 / SR), 1e-3)
    f2 = f * f
    ra = (12194 ** 2 * f2 * f2) / ((f2 + 20.6 ** 2) * np.sqrt((f2 + 107.7 ** 2) * (f2 + 737.9 ** 2)) * (f2 + 12194 ** 2))
    power = np.abs(np.fft.rfft(x)) ** 2 * (ra ** 2) * 10 ** 0.2
    return 10 * np.log10(power.sum() / len(x) ** 2 * 2 + 1e-20)


def write(name, x, level):
    """Write at a given A-weighted level (dB), keeping peaks under 0.95."""
    x = np.asarray(x, dtype=np.float64)
    x = x - np.mean(x)
    x *= 10 ** ((level - a_weighted_level(x)) / 20)
    peak = np.max(np.abs(x))
    if peak > 0.95:
        x *= 0.95 / peak
        print(f"  {name}: held to peak 0.95 ({level - 20 * np.log10(peak / 0.95):.1f} dB(A) instead of {level})")
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"{name:14s} {len(x) / SR:5.2f}s")


# --------------------------------------------------------------- engines

def firing_times(rate, n, loop=False):
    """Sample indices of the firings for a firing rate (Hz) given per sample.
    For a loop the phase is scaled to a whole number of firings."""
    phase = np.cumsum(rate) / SR
    if loop:
        phase *= round(phase[-1]) / phase[-1]
    k = np.floor(phase).astype(int)
    return np.nonzero(np.diff(k, prepend=0) > 0)[0]


def pulse_kernel(tau_ms=1.0, rebound=0.35):
    """One exhaust pressure pulse: a fast rise, a fall, a small suck-back."""
    t = np.arange(int(0.012 * SR)) / SR
    tau = tau_ms / 1000
    p = (t / tau) * np.exp(1 - t / tau)
    t2 = np.maximum(0.0, t - 2 * tau)
    p -= rebound * (t2 / (2.5 * tau)) * np.exp(1 - t2 / (2.5 * tau))
    return p


def knock_kernels(rng, count=8, lo=1600, hi=4800, decay_ms=2.4):
    """Diesel knock: the clatter of each combustion, a little different every time."""
    out = []
    n = int(0.016 * SR)
    env = np.exp(-np.arange(n) / (decay_ms / 1000 * SR))
    for _ in range(count):
        k = band(rng.normal(0, 1, n), lo, hi) * env
        out.append(k / np.max(np.abs(k)))
    return out


def engine_body(n, rate, amps, rng, loop=False, exhaust=((85, 1.2, 1.0), (210, 2.0, 0.6), (480, 3.0, 0.3)),
                tau_ms=1.0, knock=0.25, knock_band=(1600, 4800), lowpass=1500, banks=None, rasp=0.0):
    """The heart of every engine here: firing events through an exhaust.

    rate: firing rate per sample (Hz); amps: per-event amplitude multiplier
    (a function of event index and sample index); banks: optional list of
    exhaust tunings, one per bank, picked by banks_pattern on the event index.
    rasp: how much of the exhaust's mid-range bark to keep (a phone speaker
    hears little below 200 Hz, so every engine needs some).
    """
    fires = firing_times(rate, n, loop)
    kern = pulse_kernel(tau_ms)
    knocks = knock_kernels(rng, lo=knock_band[0], hi=knock_band[1])
    if banks is None:
        trains = [np.zeros(n)]
        pick = lambda j: 0
        tunings = [exhaust]
    else:
        trains = [np.zeros(n) for _ in banks[0]]
        pattern = banks[1]
        pick = lambda j: pattern[j % len(pattern)]
        tunings = banks[0]
    clatter = np.zeros(n)
    for j, i in enumerate(fires):
        a = amps(j, i) * (1 + 0.06 * rng.standard_normal())
        place(trains[pick(j)], kern, int(i), a, loop)
        place(clatter, knocks[j % len(knocks)], int(i) + int(0.0006 * SR), a * knock, loop)
    out = np.zeros(n)
    for train, tuning in zip(trains, tunings):
        x = filt(train, "hp", 28, loop=loop)
        tone = sum(filt(x, "bp", f0, q, loop=loop) * g for f0, q, g in tuning)
        out += tone + 0.35 * filt(x, "lp", 300, loop=loop)
        if rasp:
            out += rasp * band(x, 300, 1800, loop=loop, order=1)
    out = filt(filt(out, "lp", lowpass, loop=loop), "lp", lowpass * 1.3, loop=loop)
    return out, clatter, fires


# --------------------------------------------------------------- the snowcat

CAT_EXHAUST = ((85, 1.2, 1.0), (210, 2.0, 0.6), (480, 3.0, 0.4), (760, 3.0, 0.3))

def snowcat_engine(rng):
    """A four-cylinder diesel at about 1500 rpm, pulling: 50 firings a second."""
    L = 4.0
    n = int(L * SR)
    t = np.arange(n) / SR
    rate = 50.0 * (1 + 0.012 * np.sin(TAU * t / L) + 0.006 * np.sin(TAU * 3 * t / L))
    cyl = [1.0, 0.82, 0.94, 0.88]
    load = 1 + 0.08 * np.sin(TAU * 2 * t / L + 0.4)
    body, clatter, fires = engine_body(n, rate, lambda j, i: cyl[j % 4] * load[i], rng, loop=True,
                                       exhaust=CAT_EXHAUST, rasp=0.9, lowpass=2000)
    # Gear train whine and the fan, riding on the firing.
    whir = band(rng.normal(0, 1, n), 520, 760, loop=True) * (0.6 + 0.4 * np.sin(TAU * 25 * t) ** 2)
    fan = band(rng.normal(0, 1, n), 300, 2400, loop=True)
    rumble = filt(rng.normal(0, 1, n), "lp", 90, loop=True)
    x = body + clatter * 0.9 + whir * 0.05 + fan * 0.035 + rumble * 0.25
    return reverb(x, 0.25, 0.12, rng, loop=True)


def snowcat_tracks(rng):
    """Grousers slapping onto the sprocket, the belt in the snow, the bogies."""
    L = 4.0
    n = int(L * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    hits = 88  # 22 a second
    clank_t = np.arange(int(0.05 * SR)) / SR
    for k in range(hits):
        i = int(k * n / hits + rng.integers(-60, 60))
        a = 0.6 + 0.4 * rng.random()
        f1, f2, f3 = (900 + 120 * rng.standard_normal(), 1460 + 160 * rng.standard_normal(), 2320 + 200 * rng.standard_normal())
        clank = (np.sin(TAU * f1 * clank_t) * np.exp(-clank_t / 0.012) + 0.6 * np.sin(TAU * f2 * clank_t) * np.exp(-clank_t / 0.008)
                 + 0.35 * np.sin(TAU * f3 * clank_t) * np.exp(-clank_t / 0.006))
        thud = np.sin(TAU * 78 * clank_t) * np.exp(-clank_t / 0.03)
        place(x, clank * 0.22 + thud * 0.55, i, a, loop=True)
    # The belt pressing into snow: a crunch that swells with each grouser.
    crunch = band(rng.normal(0, 1, n), 350, 2200, loop=True) * (0.55 + 0.45 * np.sin(TAU * 22 * t) ** 2)
    grains = np.zeros(n)
    for _ in range(1400):
        i = int(rng.integers(0, n))
        g = rng.normal(0, 1, 40) * np.exp(-np.arange(40) / 8)
        place(grains, g, i, rng.random(), loop=True)
    grains = band(grains, 2200, 6500, loop=True)
    bogies = filt(filt(rng.normal(0, 1, n), "lp", 140, loop=True), "lp", 140, loop=True)
    # One dry bogie wheel squeaking through the loop.
    sq = np.zeros(n)
    st = np.arange(int(0.42 * SR)) / SR
    squeak = np.sin(TAU * (1150 * st - 260 * st * st)) * np.sin(np.pi * st / st[-1]) ** 2
    place(sq, squeak, int(1.3 * SR), 1.0, loop=True)
    out = x + crunch * 0.32 + grains * 0.4 + bogies * 0.55 + sq * 0.05
    return reverb(out, 0.3, 0.15, rng, loop=True)


def starter_motor(n, start, end, rng, cranks_per_s=3.3, comps_per_rev=2.0, whine=900.0):
    """A starter turning an engine over: the motor's whine sagging at every
    compression stroke, the chug of each one."""
    t = np.arange(n) / SR
    on = (t >= start) & (t < end)
    comp_rate = cranks_per_s * comps_per_rev
    cphase = np.cumsum(np.where(on, comp_rate, 0.0)) / SR
    squeeze = np.exp(-((cphase % 1.0) - 0.75) ** 2 / 0.02)  # the speed dips near each compression
    spin_up = np.clip((t - start) / 0.12, 0, 1)
    spin_down = np.clip((end + 0.18 - t) / 0.18, 0, 1)
    speed = np.where(t < end, spin_up, spin_down) * (1 - 0.3 * squeeze) * (t >= start)
    ph = np.cumsum(55.0 * speed) / SR
    motor = sum(np.sin(TAU * h * ph) / h ** 0.8 for h in range(1, 14))
    gear = np.sin(TAU * whine * np.cumsum(speed) / SR)
    brushes = band(rng.normal(0, 1, n), 2000, 5200)
    x = (motor * 0.35 + gear * 0.08 + brushes * 0.06) * speed
    # The chug: air squeezed and released in each cylinder.
    chug = np.zeros(n)
    edges = np.nonzero(np.diff(np.floor(cphase)) > 0)[0]
    ct = np.arange(int(0.09 * SR)) / SR
    thump = np.sin(TAU * 62 * ct) * np.exp(-ct / 0.03) + 0.4 * band(rng.normal(0, 1, len(ct)), 150, 900) * np.exp(-ct / 0.02)
    for i in edges:
        place(chug, thump, int(i), 0.8 + 0.2 * rng.random())
    return x + chug * 0.55


def solenoid(rng):
    ct = np.arange(int(0.05 * SR)) / SR
    return (band(rng.normal(0, 1, len(ct)), 1500, 6000) * np.exp(-ct / 0.003)
            + 0.5 * np.sin(TAU * 1250 * ct) * np.exp(-ct / 0.015))


def snowcat_starter(rng):
    """Garage, frequency H: the key turns, the starter cranks a dry engine,
    nothing catches, and she lets go."""
    L = 2.4
    n = int(L * SR)
    x = starter_motor(n, 0.06, 1.95, rng)
    place(x, solenoid(rng), int(0.02 * SR), 0.9)
    place(x, solenoid(rng), int(1.96 * SR), 0.5)
    return fade(reverb(x, 0.35, 0.18, rng), 0.005, 0.12)


def snowcat_start(rng):
    """The snowcat cranked over and catching: a ragged first few firings, a
    flare of revs, settling to a lumpy idle."""
    L = 3.6
    n = int(L * SR)
    t = np.arange(n) / SR
    catch = 0.78
    x = starter_motor(n, 0.06, catch + 0.05, rng)
    place(x, solenoid(rng), int(0.02 * SR), 0.9)
    rpm = np.interp(t, [0, catch, catch + 0.1, catch + 0.55, catch + 1.5, L], [0, 0, 900, 2050, 780, 760])
    rate = rpm / 60 * 2
    cyl = [1.0, 0.8, 0.95, 0.86]
    env = np.clip((t - catch) / 0.08, 0, 1)

    def amps(j, i):
        a = cyl[j % 4] * env[i]
        if j < 6 and rng.random() < 0.35:  # it doesn't catch on every cylinder at first
            a *= 0.2
        return a * (1.25 if t[i] < catch + 0.6 else 1.0)

    body, clatter, _ = engine_body(n, rate, amps, rng, knock=0.32, exhaust=CAT_EXHAUST, rasp=0.9, lowpass=2000)
    out = x + body + clatter * 0.9
    return fade(reverb(out, 0.3, 0.15, rng), 0.005, 0.5)


def snowcat_stop(rng):
    """Under the bridge: the diesel sags, misses, and dies; the whole machine
    rocks back on its mounts."""
    L = 2.2
    n = int(L * SR)
    t = np.arange(n) / SR
    die = 1.15
    rate = 50.0 * np.clip(1 - t / die, 0, 1) ** 1.4
    env = np.clip(1 - t / (die + 0.1), 0, 1) ** 0.6

    def amps(j, i):
        a = env[i]
        if t[i] > 0.55 and rng.random() < 0.3:  # misfiring as it goes
            a *= 0.15
        return a

    body, clatter, _ = engine_body(n, np.maximum(rate, 0.0), amps, rng, exhaust=CAT_EXHAUST, rasp=0.9, lowpass=2000)
    x = body + clatter * 0.8
    ct = np.arange(int(0.45 * SR)) / SR
    rock = np.sin(TAU * 34 * ct) * np.exp(-ct / 0.12)
    rattle = band(rng.normal(0, 1, len(ct)), 900, 3200) * np.exp(-ct / 0.07)
    place(x, rock * 0.9 + rattle * 0.25, int(die * SR), 1.0)
    for k, when in enumerate((1.55, 1.9)):
        tick = band(rng.normal(0, 1, 200), 3000, 7000) * np.exp(-np.arange(200) / 25)
        place(x, tick, int(when * SR), 0.12 - 0.04 * k)
    return fade(reverb(x, 0.4, 0.2, rng), 0.005, 0.2)


# --------------------------------------------------------------- Ma's pickup

V8_BANKS = (((62, 1.1, 1.0), (128, 1.6, 0.6), (250, 2.2, 0.3), (520, 2.5, 0.22), (900, 3.0, 0.1)),
            ((70, 1.1, 1.0), (140, 1.6, 0.55), (275, 2.2, 0.27), (560, 2.5, 0.2), (960, 3.0, 0.09)))
V8_ORDER = (0, 1, 0, 0, 1, 0, 1, 1)  # left/right banks in firing order: the lope


def truck_idle(rng):
    """A '70s/'80s V8 at about 660 rpm, the heater fan going, idling in the snow."""
    L = 4.0
    n = int(L * SR)
    t = np.arange(n) / SR
    rate = 44.0 * (1 + 0.02 * np.sin(TAU * 2 * t / L) + 0.008 * np.sin(TAU * 5 * t / L))
    cyl = [1.0, 0.78, 0.92, 0.7, 0.96, 0.82, 0.88, 0.74]
    body, clatter, _ = engine_body(n, rate, lambda j, i: cyl[j % 8], rng, loop=True, banks=(V8_BANKS, V8_ORDER),
                                   tau_ms=1.4, knock=0.04, knock_band=(2500, 6000), lowpass=1400, rasp=0.7)
    lifters = np.zeros(n)
    tick = band(rng.normal(0, 1, 120), 3500, 7000) * np.exp(-np.arange(120) / 14)
    for k in range(int(22 * L)):
        place(lifters, tick, int(k * n / (22 * L)), 0.5 + 0.5 * rng.random(), loop=True)
    blower = band(rng.normal(0, 1, n), 250, 1400, loop=True)
    belt = np.sin(TAU * 1180 * t) * (0.5 + 0.5 * np.sin(TAU * 0.5 * t))
    x = body + clatter + lifters * 0.035 + blower * 0.05 + belt * 0.004
    return reverb(x, 0.6, 0.2, rng, loop=True)


def truck_start(rng):
    """Ma's truck behind the diner: a quick crank, a blip of revs, the idle."""
    L = 3.0
    n = int(L * SR)
    t = np.arange(n) / SR
    catch = 0.6
    x = starter_motor(n, 0.05, catch + 0.03, rng, cranks_per_s=4.2, comps_per_rev=4.0, whine=1100.0) * 0.9
    place(x, solenoid(rng), int(0.02 * SR), 0.8)
    rpm = np.interp(t, [0, catch, catch + 0.08, catch + 0.32, catch + 1.1, L], [0, 0, 700, 1650, 700, 660])
    rate = rpm / 60 * 4
    cyl = [1.0, 0.78, 0.92, 0.7, 0.96, 0.82, 0.88, 0.74]
    env = np.clip((t - catch) / 0.05, 0, 1)
    body, clatter, _ = engine_body(n, rate, lambda j, i: cyl[j % 8] * env[i], rng, banks=(V8_BANKS, V8_ORDER),
                                   tau_ms=1.4, knock=0.04, knock_band=(2500, 6000), lowpass=1500, rasp=0.7)
    out = x + body + clatter
    return fade(reverb(out, 0.5, 0.2, rng), 0.005, 0.6)


# --------------------------------------------------------------- the plow

def plow(rng):
    """The county plow a long way down the road: a big diesel working hard,
    the blade scraping and chattering, chains on the tyres, all of it softened
    by distance and thrown back by the banks."""
    L = 6.0
    n = int(L * SR)
    t = np.arange(n) / SR
    rate = 95.0 * (1 + 0.025 * np.sin(TAU * t / L) + 0.01 * np.sin(TAU * 4 * t / L))
    cyl = [1.0, 0.86, 0.93, 0.9, 0.84, 0.95]
    body, clatter, _ = engine_body(n, rate, lambda j, i: cyl[j % 6], rng, loop=True,
                                   exhaust=((95, 1.0, 1.0), (190, 1.6, 0.6), (380, 2.4, 0.3)), lowpass=1200)
    # The blade: steel on packed snow and asphalt, chattering over the seams.
    chatter = np.zeros(n)
    for k in range(int(L * 3)):
        i = int(k * n / (L * 3) + rng.integers(-800, 800))
        w = int(0.22 * SR)
        e = np.sin(np.pi * np.arange(w) / w) ** 2 * (0.6 + 0.4 * rng.random())
        place(chatter, e, i, 1.0, loop=True)
    scrape = band(rng.normal(0, 1, n), 900, 3200, loop=True) * (0.45 + 0.55 * chatter)
    hiss = band(rng.normal(0, 1, n), 400, 1400, loop=True)
    # Tyre chains: a jingle every turn of the wheels.
    chains = np.zeros(n)
    for k in range(int(L * 3.4)):
        i = int(k * n / (L * 3.4))
        for _ in range(3):
            j = int(rng.integers(0, int(0.08 * SR)))
            ct = np.arange(int(0.03 * SR)) / SR
            ring = np.sin(TAU * (3200 + 900 * rng.random()) * ct) * np.exp(-ct / 0.006)
            place(chains, ring, i + j, 0.5 + 0.5 * rng.random(), loop=True)
    # Once a loop the blade hits a frost heave: a heavy clank.
    ct = np.arange(int(0.4 * SR)) / SR
    clank = (np.sin(TAU * 160 * ct) * np.exp(-ct / 0.08) + 0.6 * np.sin(TAU * 610 * ct) * np.exp(-ct / 0.05)
             + 0.3 * np.sin(TAU * 1730 * ct) * np.exp(-ct / 0.03))
    bang = np.zeros(n)
    place(bang, clank, int(3.7 * SR), 1.0, loop=True)
    near = body + clatter * 0.5 + scrape * 0.5 + hiss * 0.25 + chains * 0.06 + bang * 0.35
    # Distance: the highs go first, and the banks answer.
    far = filt(filt(near, "lp", 1800, loop=True), "lp", 2400, loop=True)
    far = filt(far, "hp", 70, loop=True)
    return reverb(far, 0.9, 0.38, rng, loop=True)


if __name__ == "__main__":
    # Levels are A-weighted dB, matched by ear against the v0.4 sounds they
    # replace (engine -32.6, plow -25.6) so the room volumes still hold.
    write("engine", snowcat_engine(np.random.default_rng(503)), -30.0)
    write("tracks", snowcat_tracks(np.random.default_rng(504)), -31.0)
    write("engine_start", snowcat_start(np.random.default_rng(505)), -27.0)
    write("engine_stop", snowcat_stop(np.random.default_rng(506)), -31.0)
    write("starter", snowcat_starter(np.random.default_rng(507)), -27.0)
    write("truck_idle", truck_idle(np.random.default_rng(508)), -28.0)
    write("truck_start", truck_start(np.random.default_rng(509)), -27.0)
    write("plow", plow(np.random.default_rng(510)), -25.0)
