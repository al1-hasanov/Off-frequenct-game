#!/usr/bin/env python3
"""Generate the placeholder sound effects and ambience for Off Frequency.

Standard library only and fully deterministic (fixed random seed), so the
same files come out on every machine. Replace any of these WAVs with real
recordings later; the game loads them by file name.

    python3 tools/gen_audio.py
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")
rng = random.Random(1983)
TAU = 2 * math.pi


# ---------------------------------------------------------------- helpers

def secs(s):
    return int(s * SR)


def noise(n):
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def lowpass(x, cutoff):
    a = 1.0 - math.exp(-TAU * cutoff / SR)
    y = 0.0
    out = []
    for s in x:
        y += a * (s - y)
        out.append(y)
    return out


def highpass(x, cutoff):
    lp = lowpass(x, cutoff)
    return [s - l for s, l in zip(x, lp)]


def bandpass(x, f0, q):
    """RBJ biquad band-pass with a fixed center frequency."""
    w0 = TAU * f0 / SR
    alpha = math.sin(w0) / (2 * q)
    cw = math.cos(w0)
    a0 = 1 + alpha
    b0, b2 = alpha / a0, -alpha / a0
    a1, a2 = -2 * cw / a0, (1 - alpha) / a0
    x1 = x2 = y1 = y2 = 0.0
    out = []
    for s in x:
        y = b0 * s + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1 = x1, s
        y2, y1 = y1, y
        out.append(y)
    return out


def bandpass_tv(x, freq_at, q, block=64):
    """Band-pass whose center frequency follows freq_at(sample_index)."""
    x1 = x2 = y1 = y2 = 0.0
    out = []
    b0 = b2 = a1 = a2 = 0.0
    for i, s in enumerate(x):
        if i % block == 0:
            w0 = TAU * max(60.0, freq_at(i)) / SR
            alpha = math.sin(w0) / (2 * q)
            a0 = 1 + alpha
            b0, b2 = alpha / a0, -alpha / a0
            a1, a2 = -2 * math.cos(w0) / a0, (1 - alpha) / a0
        y = b0 * s + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1 = x1, s
        y2, y1 = y1, y
        out.append(y)
    return out


def radio(x):
    """Band-limit to an AM-radio / telephone feel."""
    return lowpass(highpass(x, 320), 3000)


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    return out


def gain(x, g):
    return [s * g for s in x]


def env_exp(n, decay, attack=0.002):
    a = max(1, secs(attack))
    return [min(1.0, i / a) * math.exp(-i / (decay * SR)) for i in range(n)]


def apply(x, env):
    return [s * e for s, e in zip(x, env)]


def sine(n, freq, phase=0.0):
    return [math.sin(TAU * freq * i / SR + phase) for i in range(n)]


def make_loop(x, length, fade):
    """Crossfade the tail into the head so the file loops without a click."""
    n, f = secs(length), secs(fade)
    assert len(x) >= n + f
    out = x[:n]
    for i in range(f):
        k = i / f
        out[i] = x[i] * k + x[n + i] * (1 - k)
    return out


def fade_edges(x, ms=8):
    f = min(len(x) // 2, int(SR * ms / 1000))
    for i in range(f):
        k = i / f
        x[i] *= k
        x[-1 - i] *= k
    return x


def write(name, x, peak=0.85, edges=True):
    m = max(1e-9, max(abs(s) for s in x))
    x = [s * peak / m for s in x]
    if edges:
        x = fade_edges(x)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in x))
    print(f"{name:14s} {len(x) / SR:5.2f}s")


# ---------------------------------------------------------------- sounds

def hum():
    n = secs(3.0)
    # 60 Hz mains hum: 180 whole cycles in 3 s, so the loop is seamless.
    tones = mix(sine(n, 60), gain(sine(n, 120, 0.3), 0.45), gain(sine(n, 180), 0.2), gain(sine(n, 240), 0.08))
    return tones


def static_loop():
    n = secs(3.5)
    x = lowpass(highpass(noise(n), 400), 5200)
    for i in range(n):
        x[i] *= 1 + 0.18 * math.sin(TAU * 7 * i / SR)
    pops = [0.0] * n
    i = 0
    while i < n:
        if rng.random() < 0.0009:
            amp = rng.uniform(0.6, 1.4)
            for k in range(secs(0.006)):
                if i + k < n:
                    pops[i + k] += amp * rng.uniform(-1, 1) * math.exp(-k / (SR * 0.0015))
            i += secs(0.01)
        i += 1
    return make_loop(mix(x, gain(pops, 0.35)), 3.0, 0.4)


def wind():
    n = secs(8.6)
    y, b = 0.0, []
    for s in noise(n):
        y = y * 0.997 + s * 0.04
        b.append(y)
    b = lowpass(b, 700)
    out = []
    for i, s in enumerate(b):
        t = i / SR
        amp = 0.55 + 0.3 * math.sin(TAU * t / 8.0) ** 2 + 0.15 * math.sin(TAU * t / 4.0 + 1.0)
        out.append(s * amp)
    hiss = gain(lowpass(highpass(noise(n), 2500), 6000), 0.05)
    return make_loop(mix(out, hiss), 8.0, 0.6)


def knock():
    n = secs(0.45)
    body = apply(sine(n, 82), env_exp(n, 0.07))
    mid = apply(sine(n, 165, 1.0), env_exp(n, 0.035))
    hit = apply(lowpass(noise(n), 900), env_exp(n, 0.018, 0.001))
    return mix(body, gain(mid, 0.5), gain(hit, 0.9))


def crack():
    n = secs(1.1)
    snap = apply(noise(n), env_exp(n, 0.045, 0.0005))
    thump = apply(sine(n, 55), env_exp(n, 0.12))
    tail = apply(radio(noise(n)), [0.12 * min(1, i / secs(0.05)) * math.exp(-i / (SR * 0.6)) for i in range(n)])
    return mix(snap, gain(thump, 0.6), tail)


def click():
    n = secs(0.07)
    return mix(apply(noise(n), env_exp(n, 0.004, 0.0003)), gain(apply(sine(n, 2100), env_exp(n, 0.012)), 0.4))


def breaker():
    n = secs(0.9)
    t1 = apply(noise(n), env_exp(n, 0.012, 0.0005))
    low = apply(sine(n, 68), env_exp(n, 0.16))
    ring = apply(mix(sine(n, 950), gain(sine(n, 1430), 0.7)), env_exp(n, 0.28))
    second = [0.0] * secs(0.09) + apply(noise(n - secs(0.09)), env_exp(n - secs(0.09), 0.01))
    return mix(t1, gain(low, 0.9), gain(ring, 0.12), gain(second, 0.5))


def door():
    n = secs(0.9)
    latch = apply(noise(n), env_exp(n, 0.008, 0.0005))
    creak = []
    f = 180.0
    for i in range(n):
        t = i / SR
        f = 160 + 60 * math.sin(TAU * 1.3 * t) + 20 * math.sin(TAU * 7 * t)
        creak.append(math.sin(TAU * f * t) * (1 if (i // 40) % 3 else 0.3))
    creak = apply(bandpass(creak, 900, 3), [min(1, t / 0.15) * max(0, 1 - t / 0.85) for t in (i / SR for i in range(n))])
    thud = [0.0] * secs(0.6) + apply(lowpass(noise(secs(0.3)), 500), env_exp(secs(0.3), 0.05))
    return mix(latch, gain(creak, 0.25), gain(thud, 0.7))


def scratch():
    n = secs(2.4)
    hp = lowpass(highpass(noise(n), 2200), 7000)
    env = [0.0] * n
    i = 0
    while i < n:
        length = secs(rng.uniform(0.04, 0.09))
        amp = rng.uniform(0.35, 1.0)
        for k in range(length):
            if i + k < n:
                env[i + k] = amp * math.sin(math.pi * k / length)
        i += length + secs(rng.uniform(0.01, 0.06))
    return make_loop(apply(hp, env), 2.0, 0.3)


def ring():
    n = secs(1.3)
    out = [0.0] * n
    strike = secs(0.05)
    for s0 in range(0, secs(1.0), strike):
        m = n - s0
        partials = mix(sine(m, 1150), gain(sine(m, 1720), 0.6), gain(sine(m, 2410), 0.3))
        e = env_exp(m, 0.14)
        for k in range(m):
            out[s0 + k] += partials[k] * e[k] * 0.4
    return lowpass(out, 5000)


def ringback():
    n = secs(2.2)
    tone_n = secs(1.6)
    tone = mix(sine(tone_n, 440), sine(tone_n, 480))
    tone = fade_edges(tone, 15) + [0.0] * (n - tone_n)
    return radio(mix(tone, gain(noise(n), 0.03)))


def dial():
    out = []
    for group in (3, 5, 2):
        for _ in range(group):
            c = click()
            out += c + [0.0] * (secs(0.1) - len(c))
        out += [0.0] * secs(0.22)
    return radio(out)


def step():
    n = secs(0.16)
    return mix(apply(lowpass(noise(n), 900), env_exp(n, 0.03, 0.002)), gain(apply(sine(n, 110), env_exp(n, 0.02)), 0.6))


def step_snow():
    n = secs(0.3)
    out = [0.0] * n
    for _ in range(70):
        pos = int(abs(rng.gauss(0.08, 0.05)) * SR)
        amp = rng.uniform(0.3, 1.0)
        for k in range(secs(0.004)):
            if pos + k < n:
                out[pos + k] += amp * rng.uniform(-1, 1) * math.exp(-k / (SR * 0.001))
    return lowpass(highpass(out, 1200), 6500)


def lock():
    n = secs(1.0)
    out = [0.0] * n
    for _ in range(11):
        pos = secs(rng.uniform(0.0, 0.6))
        f = rng.uniform(2300, 4200)
        m = n - pos
        p = apply(sine(m, f), env_exp(m, 0.02, 0.0005))
        for k in range(m):
            out[pos + k] += p[k] * rng.uniform(0.4, 0.8)
    pos = secs(0.78)
    m = n - pos
    snap = mix(apply(sine(m, 1800), env_exp(m, 0.03)), apply(noise(m), env_exp(m, 0.006, 0.0003)))
    for k in range(m):
        out[pos + k] += snap[k]
    return out


def powerup():
    n = secs(0.9)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = 100 + 40 * t
        phase += f / SR
        saw = 2 * (phase % 1.0) - 1
        out.append(saw * min(1.0, t / 0.5))
    out = lowpass(out, 1400)
    return mix(click() + [0.0] * (n - len(click())), gain(out, 0.5))


def radio_music():
    """Sixteen bars of a soft, distant late-night station: Am F C G."""
    total = secs(16.6)
    out = [0.0] * total
    notes = {"A2": 110.0, "C3": 130.81, "D3": 146.83, "E3": 164.81, "F2": 87.31, "F3": 174.61,
             "G2": 98.0, "G3": 196.0, "A3": 220.0, "B3": 246.94, "C4": 261.63, "D4": 293.66,
             "E4": 329.63, "G4": 392.0, "A4": 440.0, "C5": 523.25, "D5": 587.33, "E5": 659.25}
    chords = [("A2", "A3", "C4", "E4"), ("F2", "F3", "A3", "C4"), ("C3", "G3", "C4", "E4"), ("G2", "G3", "B3", "D4")]
    melody = ["E5", "C5", "A4", "C5", "A4", "C5", "E5", "D5", "C5", "E5", "G4", "C5", "D5", "B3", "G4", "D5"]

    def add_tone(start, dur, freq, amp, attack, release):
        n = secs(dur + release)
        for k in range(n):
            i = start + k
            if i >= total:
                break
            t = k / SR
            e = min(1.0, t / attack) * (1.0 if t < dur else max(0.0, 1 - (t - dur) / release))
            s = math.sin(TAU * freq * t) + 0.25 * math.sin(TAU * 2 * freq * t) + 0.08 * math.sin(TAU * 3 * freq * t)
            out[i] += s * e * amp

    for bar in range(5):  # one extra bar feeds the loop crossfade
        root, *rest = chords[bar % 4]
        start = secs(bar * 4.0)
        add_tone(start, 3.6, notes[root], 0.3, 0.05, 0.6)
        for nm in rest:
            add_tone(start, 3.7, notes[nm], 0.12, 0.5, 0.8)
    for beat, nm in enumerate(melody + melody[:1]):
        start = secs(beat * 1.0 + 0.5)
        n = secs(0.9)
        f = notes[nm]
        for k in range(n):
            i = start + k
            if i >= total:
                break
            t = k / SR
            out[i] += math.sin(TAU * f * t) * math.exp(-t / 0.35) * 0.22 * min(1, t / 0.005)
    for i in range(total):
        out[i] *= 1 + 0.06 * math.sin(TAU * 0.5 * i / SR)
    out = radio(out)
    out = mix(out, gain(lowpass(highpass(noise(total), 600), 4000), 0.025))
    return make_loop(out, 16.0, 0.5)


def drone():
    n = secs(10.6)
    out = []
    for i in range(n):
        t = i / SR
        s = (math.sin(TAU * 55.0 * t) + math.sin(TAU * 55.3 * t)
             + 0.6 * math.sin(TAU * 82.41 * t) * (0.6 + 0.4 * math.sin(TAU * t / 10))
             + 0.35 * math.sin(TAU * 110.0 * t) * (0.5 + 0.5 * math.sin(TAU * t / 5 + 1))
             + 0.15 * math.sin(TAU * 164.81 * t))
        out.append(s)
    out = mix(out, gain(lowpass(noise(n), 300), 0.6))
    return make_loop(out, 10.0, 0.6)


def voice(length, seed):
    """Unintelligible, speech-shaped murmur through radio static."""
    local = random.Random(seed)
    n = secs(length)
    # syllable plan: (start, end, F1, F2)
    syl = []
    t = 0.05
    while t < length - 0.15:
        d = local.uniform(0.11, 0.24)
        syl.append((t, t + d, local.uniform(350, 800), local.uniform(900, 2300)))
        t += d + local.uniform(0.02, 0.09)
        if local.random() < 0.12:
            t += 0.18
    env = [0.0] * n
    f1 = [500.0] * n
    f2 = [1500.0] * n
    for a, b, v1, v2 in syl:
        for i in range(secs(a), min(n, secs(b))):
            p = (i - secs(a)) / max(1, secs(b) - secs(a))
            env[i] = math.sin(math.pi * p) ** 0.6
            f1[i], f2[i] = v1, v2
    f1 = lowpass(f1, 25)
    f2 = lowpass(f2, 25)
    src = []
    phase = 0.0
    for i in range(n):
        tt = i / SR
        f0 = 195 + 30 * math.sin(TAU * 0.9 * tt) - 25 * tt / length + local.uniform(-3, 3)
        phase += f0 / SR
        src.append((2 * (phase % 1.0) - 1) * env[i])
    v = mix(bandpass_tv(src, lambda i: f1[i], 5), gain(bandpass_tv(src, lambda i: f2[i], 7), 0.7))
    v = radio(v)
    hiss = gain(lowpass(highpass(noise(n), 500), 4500), 0.18)
    return mix(v, hiss)


def sting():
    n = secs(3.6)
    out = []
    for i in range(n):
        t = i / SR
        e = (t / 3.2) ** 2 if t < 3.2 else max(0.0, 1 - (t - 3.2) / 0.05)
        s = (math.sin(TAU * 49 * t) + math.sin(TAU * 52 * t) + 0.5 * math.sin(TAU * 98 * t)
             + 0.25 * math.sin(TAU * 880 * t) + 0.25 * math.sin(TAU * 932.3 * t))
        out.append(s * e)
    return out


def breath():
    n = secs(2.4)
    x = bandpass(noise(n), 1100, 1.2)
    env = []
    for i in range(n):
        t = i / SR
        env.append(max(0.0, math.sin(math.pi * t / 1.0)) if t < 1.0 else max(0.0, math.sin(math.pi * (t - 1.2) / 1.1)) * 0.8 if t > 1.2 else 0.0)
    return radio(mix(apply(x, env), gain(noise(n), 0.04)))


def hangup():
    n = secs(0.5)
    return radio(mix(apply(noise(n), env_exp(n, 0.01, 0.0005)), gain(apply(sine(n, 300), env_exp(n, 0.06)), 0.6)))



# ---------------------------------------------------------------- v0.2 sounds

def crossing():
    """Walking through the dark into another frequency: a rising hiss, a burst, a drop."""
    n = secs(1.7)
    rise = [((i / n) ** 2.6) for i in range(n)]
    swell = apply(bandpass_tv(noise(n), lambda i: 180 + 3200 * (i / n) ** 2, 2.0), rise)
    b0 = secs(1.2)
    m = n - b0
    burst = [0.0] * b0 + apply(radio(noise(m)), env_exp(m, 0.08, 0.002))
    sub = [0.0] * b0 + apply(sine(m, 42), env_exp(m, 0.4))
    ring_ = [0.0] * b0 + apply(mix(sine(m, 1320), gain(sine(m, 1990), 0.5)), env_exp(m, 0.3))
    return mix(gain(swell, 0.55), burst, gain(sub, 0.9), gain(ring_, 0.08))


def carrier():
    """A dead station: a flat tone and nothing else (frequency 00)."""
    n = secs(2.6)
    tone = mix(sine(n, 800), gain(sine(n, 1600), 0.12))
    return make_loop(radio(mix(tone, gain(noise(n), 0.05))), 2.0, 0.4)


def snore():
    n = secs(4.5)
    base = lowpass(noise(n), 800)
    out = []
    for i in range(n):
        t = (i / SR) % 4.0
        if t < 1.4:
            e = math.sin(math.pi * t / 1.4) * (0.55 + 0.45 * math.sin(TAU * 31 * t))
        elif 1.9 < t < 3.3:
            e = 0.3 * math.sin(math.pi * (t - 1.9) / 1.4)
        else:
            e = 0.0
        out.append(base[i] * max(0.0, e))
    return make_loop(radio(out), 4.0, 0.4)


def rain():
    n = secs(3.5)
    bed = lowpass(highpass(noise(n), 900), 6000)
    drops = [0.0] * n
    for _ in range(900):
        p = rng.randrange(0, n - 200)
        a = rng.uniform(0.2, 1.0)
        for k in range(120):
            drops[p + k] += a * rng.uniform(-1, 1) * math.exp(-k / 18.0)
    return make_loop(radio(mix(gain(bed, 0.6), gain(highpass(drops, 1500), 0.5))), 3.0, 0.4)


def plow():
    """A plow truck clearing the road (frequency 03)."""
    n = secs(4.6)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = 46 + 4 * math.sin(TAU * 0.3 * t)
        ph += f / SR
        saw = 2 * (ph % 1.0) - 1
        out.append(saw * (0.7 + 0.3 * math.sin(TAU * 11 * t)))
    eng = lowpass(out, 500)
    scrape = apply(bandpass(noise(n), 2400, 1.5), [0.5 + 0.5 * math.sin(TAU * 0.25 * i / SR) ** 2 for i in range(n)])
    return make_loop(radio(mix(eng, gain(scrape, 0.35))), 4.0, 0.5)


def siren():
    n = secs(6.6)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = 850 + 300 * math.sin(TAU * t / 3.0)
        ph += f / SR
        out.append(math.sin(TAU * ph))
    far = lowpass(out, 2500)
    return make_loop(radio(mix(gain(far, 0.5), gain(noise(n), 0.06))), 6.0, 0.5)


def engine():
    """The snowcat's diesel, idling and pulling."""
    n = secs(3.6)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = 36 + 1.5 * math.sin(TAU * 0.5 * t)
        ph += f / SR
        p = ph % 1.0
        pulse = math.exp(-p * 9.0)
        out.append(pulse + 0.4 * (2 * p - 1))
    body = lowpass(out, 420)
    clatter = apply(bandpass(noise(n), 1800, 2.0), [0.25 + 0.2 * math.sin(TAU * 36 * i / SR) for i in range(n)])
    tracks = apply(bandpass(noise(n), 300, 1.2), [0.5 + 0.5 * math.sin(TAU * 6 * i / SR) for i in range(n)])
    return make_loop(mix(body, gain(clatter, 0.12), gain(tracks, 0.25)), 3.0, 0.5)


def engine_stop():
    n = secs(1.6)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = max(6.0, 36 * (1 - t / 1.3))
        ph += f / SR
        p = ph % 1.0
        out.append((math.exp(-p * 9.0) + 0.4 * (2 * p - 1)) * max(0.0, 1 - t / 1.4))
    return lowpass(out, 400)


def tape_hiss():
    n = secs(3.5)
    x = lowpass(highpass(noise(n), 2000), 9000)
    wow = [1 + 0.08 * math.sin(TAU * 0.7 * i / SR) for i in range(n)]
    return make_loop(apply(x, wow), 3.0, 0.4)


def tape_rip():
    n = secs(0.7)
    out = [0.0] * n
    i = 0
    while i < n:
        a = rng.uniform(0.3, 1.0) * (0.4 + 0.6 * (i / n))
        for k in range(60):
            if i + k < n:
                out[i + k] += a * rng.uniform(-1, 1) * math.exp(-k / 10.0)
        i += int(rng.uniform(30, 160) * (1.2 - i / n))
    return bandpass(out, 2500, 1.0)


def keys():
    n = secs(0.8)
    out = [0.0] * n
    for _ in range(9):
        p = secs(rng.uniform(0.0, 0.45))
        m = n - p
        f = rng.uniform(2600, 5200)
        clink = apply(mix(sine(m, f), gain(sine(m, f * 1.51), 0.6), gain(sine(m, f * 2.3), 0.3)), env_exp(m, 0.05, 0.0005))
        a = rng.uniform(0.3, 0.8)
        for k in range(m):
            out[p + k] += clink[k] * a
    return out


def squeak():
    """A hot bulb turning in its socket."""
    n = secs(0.8)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = 1700 + 500 * (t / 0.8) + 90 * math.sin(TAU * 23 * t)
        ph += f / SR
        g = 1.0 if (i // 300) % 4 != 3 else 0.2
        out.append(math.sin(TAU * ph) * g * math.sin(math.pi * t / 0.8))
    grit = apply(bandpass(noise(n), 3000, 2.0), [0.3] * n)
    return mix(gain(out, 0.5), grit)


def thunk():
    n = secs(0.7)
    low = apply(lowpass(noise(n), 300), env_exp(n, 0.08, 0.001))
    body = apply(sine(n, 70), env_exp(n, 0.12))
    latch = [0.0] * secs(0.05) + apply(highpass(noise(n - secs(0.05)), 2000), env_exp(n - secs(0.05), 0.01, 0.0005))
    return mix(low, gain(body, 0.8), gain(latch, 0.5))


# ---------------------------------------------------------------- v0.3 (Act 2)
def _scanner_v03():
    """v0.3's scanner (garbled talk). Replaced in v0.3.1; see __main__."""
    n = secs(5.5)
    out = [0.0] * n
    hiss = gain(highpass(noise(n), 1200), 0.08)
    t = 0.2
    while t < 5.0:
        length = rng.uniform(0.6, 1.4)
        v = voice(length, rng.randrange(1000))
        p = secs(t)
        for k, sm in enumerate(v):
            if p + k < n:
                out[p + k] += sm * 0.8
        t += length + rng.uniform(0.4, 0.9)
    return make_loop(radio(mix(out, hiss)), 5.0, 0.4)


def kettle():
    n = secs(3.4)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = 2100 + 60 * math.sin(TAU * 5.5 * t) + 30 * math.sin(TAU * 0.7 * t)
        ph += f / SR
        out.append(math.sin(TAU * ph) * (0.8 + 0.2 * math.sin(TAU * 9 * t)))
    breathy = gain(bandpass(noise(n), 2100, 6), 0.4)
    return make_loop(radio(mix(gain(out, 0.5), breathy)), 3.0, 0.4)


def bell():
    """Church bells, slow, far away."""
    n = secs(6.4)
    out = [0.0] * n
    for k, start in enumerate([0.0, 1.5, 3.0, 4.5]):
        p = secs(start)
        f0 = [392.0, 330.0, 392.0, 294.0][k]
        for h, (mult, amp) in enumerate([(1.0, 1.0), (2.0, 0.5), (2.76, 0.35), (5.4, 0.2)]):
            for i in range(secs(2.5)):
                if p + i < n:
                    out[p + i] += amp * math.sin(TAU * f0 * mult * i / SR) * math.exp(-i / (SR * (1.2 - h * 0.2)))
    return make_loop(radio(lowpass(out, 3000)), 6.0, 0.4)


def bark():
    """One dog bark: a short barked tone with a noisy edge."""
    n = secs(0.32)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = 520 * (1 - t * 1.6)
        ph += max(90.0, f) / SR
        out.append((2 * (ph % 1.0) - 1) * math.exp(-t * 9) * min(1, t / 0.01))
    edge = apply(bandpass(noise(n), 1400, 2), env_exp(n, 0.05))
    return lowpass(mix(out, gain(edge, 0.5)), 3200)


def barking():
    """A dog barking far off, as a station loop."""
    n = secs(4.6)
    out = [0.0] * n
    for start in [0.3, 0.7, 2.2, 2.55, 2.9, 3.9]:
        b = bark()
        p = secs(start)
        for k, sm in enumerate(b):
            if p + k < n:
                out[p + k] += sm
    return make_loop(radio(mix(out, gain(noise(n), 0.02))), 4.2, 0.3)


def _crowd_v03():
    """v0.3's street (a murmur). Replaced in v0.3.1; see __main__."""
    n = secs(5.6)
    out = [0.0] * n
    for k in range(9):
        v = voice(5.4, 300 + k)
        off = rng.randrange(0, secs(0.2))
        g = rng.uniform(0.3, 0.7)
        for i, sm in enumerate(v):
            if off + i < n:
                out[off + i] += sm * g
    return make_loop(lowpass(mix(out, gain(noise(n), 0.03)), 2200), 5.0, 0.5)


def typewriter():
    n = secs(4.4)
    out = [0.0] * n
    t = 0.1
    while t < 4.1:
        p = secs(t)
        a = rng.uniform(0.5, 1.0)
        for k in range(400):
            if p + k < n:
                out[p + k] += a * rng.uniform(-1, 1) * math.exp(-k / 40.0)
        t += rng.choice([0.09, 0.12, 0.14, 0.2, 0.45])
    return make_loop(radio(highpass(out, 600)), 4.0, 0.3)


def match_strike():
    n = secs(1.3)
    scratch_ = apply(bandpass(noise(n), 3000, 1.5), [math.exp(-i / (SR * 0.06)) for i in range(n)])
    flare = apply(lowpass(noise(n), 1400), [min(1, max(0, (i / SR - 0.05) / 0.08)) * math.exp(-max(0, i / SR - 0.13) / 0.35) for i in range(n)])
    return mix(scratch_, gain(flare, 0.6))


def shopbell():
    """The bell over a shop door."""
    n = secs(1.6)
    out = [0.0] * n
    for start, f0 in [(0.0, 1760.0), (0.07, 2093.0), (0.16, 1760.0)]:
        p = secs(start)
        for i in range(n - p):
            out[p + i] += math.sin(TAU * f0 * i / SR) * math.exp(-i / (SR * 0.35)) * 0.5
            out[p + i] += math.sin(TAU * f0 * 2.7 * i / SR) * math.exp(-i / (SR * 0.12)) * 0.2
    return out


def scrape():
    """A steel filing cabinet dragged on a bare floor."""
    n = secs(1.1)
    grind = bandpass(noise(n), 700, 3)
    out = []
    for i in range(n):
        t = i / SR
        out.append(grind[i] * (0.6 + 0.4 * math.sin(TAU * 23 * t)) * math.sin(math.pi * t / 1.1))
    return out


def hush():
    """The same cabinet sliding on a doormat: almost nothing."""
    n = secs(1.0)
    return apply(lowpass(noise(n), 500), [0.25 * math.sin(math.pi * i / n) for i in range(n)])


def plug():
    n = secs(0.25)
    pop = apply(noise(n), env_exp(n, 0.01))
    thud = apply(sine(n, 120), env_exp(n, 0.05))
    return mix(gain(highpass(pop, 1500), 0.6), thud)


def boards():
    """Old planks levered off with a creak and a crack."""
    n = secs(1.5)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = 180 + 120 * math.sin(TAU * 1.3 * t) + rng.uniform(-30, 30)
        ph += f / SR
        out.append((2 * (ph % 1.0) - 1) * 0.4 * min(1, t / 0.1) * max(0, 1 - t / 1.0))
    creak = bandpass(out, 600, 2)
    crack_ = apply(highpass(noise(n), 800), [math.exp(-max(0, i / SR - 1.0) / 0.03) if i / SR >= 1.0 else 0.0 for i in range(n)])
    return mix(creak, gain(crack_, 0.9))


def dish_motor():
    """The dish turning on its own: a deep groan with a ratchet."""
    n = secs(4.4)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = 55 + 8 * math.sin(TAU * 0.25 * t)
        ph += f / SR
        out.append(math.sin(TAU * ph) + 0.3 * math.sin(TAU * ph * 2.02))
    ratchet = apply(bandpass(noise(n), 900, 4), [0.4 if (i // secs(0.18)) % 2 == 0 else 0.05 for i in range(n)])
    return make_loop(lowpass(mix(gain(out, 0.6), gain(ratchet, 0.3)), 1500), 4.0, 0.4)


def drip():
    """Water dripping in a tunnel, with a long echo."""
    n = secs(5.6)
    out = [0.0] * n
    for start in [0.4, 1.9, 2.6, 4.1]:
        p = secs(start)
        for i in range(secs(0.9)):
            if p + i < n:
                t = i / SR
                out[p + i] += math.sin(TAU * (1200 - 500 * t) * t) * math.exp(-t * 14)
        for echo in [0.21, 0.43]:
            q = p + secs(echo)
            for i in range(secs(0.4)):
                if q + i < n:
                    t = i / SR
                    out[q + i] += 0.3 * math.sin(TAU * (1200 - 500 * t) * t) * math.exp(-t * 14)
    return make_loop(mix(lowpass(out, 3000), gain(lowpass(noise(n), 200), 0.05)), 5.0, 0.4)


def silence_hit():
    """The moment every sound is sucked out: a short inhale of air."""
    n = secs(0.6)
    return apply(highpass(noise(n), 2500), [(i / n) ** 3 * (1 - (i / n) ** 8) for i in range(n)])


# ---------------------------------------------------------------- v0.3.1
# No fake speech anywhere: the street is people doing things (steps, doors,
# a shovel, a cough, a car, a whistle), and radios are radio (squelch,
# carriers, Morse, tuning whistles). Each of these sounds draws from its own
# seeded random generator, so it never shifts the shared sequence the older
# sounds use.

class seeded:
    """`with seeded(n):` swaps the shared generator for a private one."""

    def __init__(self, seed):
        self.seed = seed

    def __enter__(self):
        global rng
        self.saved = rng
        rng = random.Random(self.seed)

    def __exit__(self, *exc):
        global rng
        rng = self.saved


def place(out, sig, t, g=1.0):
    p = secs(t)
    for k, sm in enumerate(sig):
        if 0 <= p + k < len(out):
            out[p + k] += sm * g


def far(x, cutoff):
    """Distance: the highs go first."""
    return lowpass(lowpass(x, cutoff), cutoff * 1.4)


def comb(x, delay, fb, damp):
    out = list(x)
    lp = 0.0
    for i in range(delay, len(out)):
        lp = out[i - delay] * (1 - damp) + lp * damp
        out[i] += lp * fb
    return out


def allpass(x, delay, g=0.5):
    out = [0.0] * len(x)
    for i in range(len(x)):
        d = out[i - delay] if i >= delay else 0.0
        xd = x[i - delay] if i >= delay else 0.0
        out[i] = -g * x[i] + xd + g * d
    return out


def street_verb(x, wet=0.25):
    """Small Schroeder reverb: sound bouncing between house fronts in the snow."""
    combs = [comb(x, d, 0.72, 0.45) for d in (617, 683, 739, 811)]
    w = [sum(c[i] for c in combs) * 0.25 for i in range(len(x))]
    w = allpass(allpass(w, 241), 83)
    return [a * (1 - wet) + b * wet for a, b in zip(x, w)]


def cough():
    """One person coughing into a scarf: two breathy bursts with a little voice."""
    n = secs(0.6)
    out = [0.0] * n
    for start, amp, dur in [(0.0, 1.0, 0.17), (0.24, 0.6, 0.13)]:
        m = secs(dur + 0.08)
        env = [min(1.0, i / secs(0.006)) * math.exp(-i / (SR * dur * 0.3)) for i in range(m)]
        air = apply(noise(m), env)
        air = mix(bandpass(air, 550, 2.5), gain(bandpass(air, 1250, 3.5), 0.7), gain(bandpass(air, 2400, 5), 0.35))
        buzz = []
        ph = 0.0
        for i in range(m):
            ph += (150 - 40 * i / m) / SR
            buzz.append((2 * (ph % 1.0) - 1) * env[i] * 0.25)
        place(out, mix(air, lowpass(buzz, 900)), start, amp)
    return lowpass(out, 3500)


def stomp():
    """Boots knocked together to shake off the snow."""
    n = secs(0.25)
    return lowpass(mix(apply(noise(n), env_exp(n, 0.025, 0.001)), gain(apply(sine(n, 95), env_exp(n, 0.05)), 0.8)), 700)


def shovel_stroke():
    """A snow shovel pushed along a sidewalk, then the snow thrown off it."""
    n = secs(1.15)
    grit = bandpass(noise(n), 1700, 1.2)
    mod = lowpass([rng.uniform(0.2, 1.0) for _ in range(n)], 45)
    push = []
    for i in range(n):
        t = i / SR
        e = min(1.0, t / 0.08) * (1.0 if t < 0.62 else max(0.0, 1 - (t - 0.62) / 0.05))
        push.append(grit[i] * mod[i] * e)
    toss = [0.0] * secs(0.78) + apply(lowpass(noise(secs(0.37)), 900), [math.sin(math.pi * i / secs(0.37)) * 0.6 for i in range(secs(0.37))])
    return mix(push, toss)


def passing_car(length=5.5):
    """A car crawling past on packed snow: tyres and a low engine, swelling and fading."""
    n = secs(length)
    tyres = noise(n)
    tyres = bandpass_tv(tyres, lambda i: 300 + 900 * math.sin(math.pi * i / n) ** 2, 0.8)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        x = i / n
        swell = math.sin(math.pi * x) ** 2.2
        f = 38 + 6 * (1 - x)  # a touch of Doppler
        ph += f / SR
        eng = math.sin(TAU * ph) + 0.6 * math.sin(TAU * 2 * ph) + 0.35 * math.sin(TAU * 3 * ph + 0.4)
        out.append((tyres[i] * 0.9 + eng * 0.22 * (0.8 + 0.2 * math.sin(TAU * 11 * t))) * swell)
    return lowpass(out, 1800)


def whistle():
    """Somebody whistling a few notes to themselves, out in the cold."""
    notes = [(784, 0.32), (880, 0.22), (988, 0.5), (880, 0.24), (784, 0.24), (659, 0.7)]
    n = secs(sum(d for _, d in notes) + 0.3)
    track = []
    for f, d in notes:
        track += [f] * secs(d)
    track += [track[-1]] * (n - len(track))
    track = lowpass(track, 18)  # glide between notes
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        ph += track[i] * (1 + 0.012 * math.sin(TAU * 5.2 * t)) / SR
        e = min(1.0, t / 0.05) * min(1.0, (n - i) / secs(0.25))
        out.append(math.sin(TAU * ph) * e)
    breath = apply(bandpass(noise(n), 1600, 2), [0.18] * n)
    return mix(out, breath)


def street():
    """Main Street at 2:14 AM: the whole town outside, not talking."""
    length = 16.0
    n = secs(length + 1.0)
    out = [0.0] * n
    # Walkers crunching past at different distances.
    for start, steps, pace, g, cut in [(0.4, 9, 0.52, 0.55, 2600), (3.1, 12, 0.47, 0.35, 1500),
                                       (7.6, 8, 0.56, 0.7, 3600), (10.8, 10, 0.5, 0.3, 1300),
                                       (13.2, 6, 0.6, 0.45, 2200)]:
        for k in range(steps):
            near = math.sin(math.pi * (k + 0.5) / steps)
            place(out, far(step_snow(), cut), start + k * pace + rng.uniform(-0.03, 0.03), g * (0.4 + 0.6 * near))
    place(out, far(cough(), 2200), 2.3, 0.55)
    place(out, far(cough(), 1500), 11.9, 0.35)
    for k in range(3):
        place(out, far(shovel_stroke(), 2000), 4.6 + k * 1.5, 0.32)
    place(out, far(door(), 1400), 1.6, 0.5)
    place(out, far(door(), 1100), 14.4, 0.4)
    place(out, far(thunk(), 900), 9.3, 0.55)          # a car door
    place(out, far(keys(), 3000), 8.6, 0.18)
    for k, t in enumerate([6.2, 6.5, 6.8]):
        place(out, stomp(), t, 0.45 - k * 0.05)
    place(out, far(passing_car(), 1600), 8.9, 0.42)
    place(out, far(whistle(), 2600), 12.1, 0.08)
    for t in [5.3, 5.7]:
        place(out, far(bark(), 900), t, 0.22)          # a dog, blocks away
    bed = gain(lowpass(noise(n), 160), 0.6)            # the low air of a town at night
    out = street_verb(mix(out, bed), 0.28)
    return make_loop(highpass(out, 40), length, 1.0)


def squelch_tail():
    n = secs(0.16)
    return apply(highpass(noise(n), 900), [min(1.0, i / secs(0.004)) * math.exp(-i / (SR * 0.05)) for i in range(n)])


def roger_beep():
    n = secs(0.14)
    tone = [math.sin(TAU * (1200 if i < secs(0.07) else 1600) * i / SR) for i in range(n)]
    return fade_edges(gain(tone, 0.5), 4)


def flutter(n, rate, lo, hi):
    """A smooth random envelope: a new target `rate` times a second, eased between."""
    step = max(1, secs(1.0 / rate))
    pts = [rng.uniform(lo, hi) for _ in range(n // step + 2)]
    out = []
    for i in range(n):
        k, f = divmod(i, step)
        e = 0.5 - 0.5 * math.cos(math.pi * f / step)
        out.append(pts[k] * (1 - e) + pts[k + 1] * e)
    return out


def keyed_carrier(length, wobble):
    """A weak keyed transmitter with nobody speaking: hiss that flutters and fades."""
    n = secs(length)
    fade = flutter(n, wobble, 0.08, 1.0)
    fast = flutter(n, 14.0, 0.55, 1.0)  # picket-fencing from a moving car
    hiss = lowpass(highpass(noise(n), 500), 3200)
    hum_ = [0.18 * math.sin(TAU * 120 * i / SR) for i in range(n)]
    env = [min(1.0, i / secs(0.01)) for i in range(n)]
    return [(hiss[i] * fade[i] * fast[i] * 0.8 + hum_[i]) * env[i] for i in range(n)]


def data_burst(length=0.45):
    """A digital ID burst: two tones flipping fast."""
    n = secs(length)
    out = []
    ph = 0.0
    bits = [rng.random() < 0.5 for _ in range(int(length / 0.012) + 2)]
    for i in range(n):
        f = 1200 if bits[int(i / secs(0.012))] else 1800
        ph += f / SR
        out.append(math.sin(TAU * ph) * 0.4)
    return fade_edges(out, 6)


def scanner():
    """A police scanner: squelch opening on weak carriers, roger beeps, a data burst. No talk."""
    length = 10.0
    n = secs(length + 0.5)
    out = [0.0] * n
    floor = gain(lowpass(highpass(noise(n), 1500), 5000), 0.015)
    t = 0.3
    k = 0
    while t < length - 0.8:
        d = rng.uniform(0.5, 1.3)
        place(out, gain(keyed_carrier(d, rng.uniform(5, 10)), 0.55), t)
        place(out, squelch_tail(), t + d, 0.9)
        if k % 2 == 0:
            place(out, roger_beep(), t + d - 0.16, 0.5)
        if k == 1:
            place(out, data_burst(), t + 0.05, 0.6)
        t += d + rng.uniform(0.7, 1.5)
        k += 1
    return make_loop(radio(mix(out, floor)), length, 0.4)


def transmission(length):
    """Under the 2:14 voice's words: the squelch opens on a fading, warbling carrier."""
    n = secs(length)
    out = [0.0] * n
    place(out, apply(noise(secs(0.05)), env_exp(secs(0.05), 0.012, 0.0005)), 0.0, 0.9)
    body_len = max(0.2, length - 0.22)
    body = keyed_carrier(body_len, 3.5)
    whistle_ = []
    ph = 0.0
    for i in range(secs(body_len)):
        tt = i / SR
        ph += (940 + 70 * math.sin(TAU * 0.6 * tt) + 25 * math.sin(TAU * 3.1 * tt)) / SR
        whistle_.append(math.sin(TAU * ph) * 0.12 * min(1.0, tt / 0.15))
    place(out, mix(body, whistle_), 0.04)
    place(out, squelch_tail(), length - 0.18, 1.0)
    return radio(out)


def morse(text, unit):
    code = {"C": "-.-.", "Q": "--.-", "M": "--", "A": ".-", "R": ".-.", "D": "-..", "E": "."}
    seq = []
    for w, word in enumerate(text.split()):
        for li, ch in enumerate(word):
            for si, sym in enumerate(code[ch]):
                seq.append((True, 1 if sym == "." else 3))
                seq.append((False, 1))
            seq[-1] = (False, 3)
        seq[-1] = (False, 7)
    out = []
    for on, units in seq:
        m = secs(units * unit)
        if on:
            out += [math.sin(TAU * 680 * i / SR) * min(1.0, i / 60, (m - i) / 60) for i in range(m)]
        else:
            out += [0.0] * m
    return out


def shortwave():
    """June's shop: every band crowded. Morse, tuning whistles, fading static."""
    length = 9.0
    n = secs(length + 0.6)
    out = [0.0] * n
    place(out, gain(morse("CQ CQ DE MARA", 0.065), 0.35), 0.3)
    sweep = []
    ph = 0.0
    for i in range(secs(1.6)):
        tt = i / SR
        ph += (2400 - 1500 * (tt / 1.6) ** 0.7) / SR
        sweep.append(math.sin(TAU * ph) * math.sin(math.pi * tt / 1.6) * 0.25)
    place(out, sweep, 6.4)
    place(out, gain(keyed_carrier(1.3, 5.0), 0.4), 4.9)
    fade = lowpass([rng.uniform(0.2, 1.0) for _ in range(n)], 2.0)
    static = [s * f for s, f in zip(lowpass(highpass(noise(n), 400), 4200), fade)]
    return make_loop(radio(mix(out, gain(static, 0.22))), length, 0.6)

if __name__ == "__main__":
    write("hum", hum(), 0.6, edges=False)
    write("static", static_loop(), 0.7, edges=False)
    write("wind", wind(), 0.8, edges=False)
    write("knock", knock(), 0.95)
    write("crack", crack(), 0.95)
    write("click", click(), 0.7)
    write("breaker", breaker(), 0.95)
    write("door", door(), 0.8)
    write("scratch", scratch(), 0.6, edges=False)
    write("ring", ring(), 0.8)
    write("ringback", ringback(), 0.6)
    write("dial", dial(), 0.7)
    write("step", step(), 0.6)
    write("step_snow", step_snow(), 0.6)
    write("lock", lock(), 0.8)
    write("powerup", powerup(), 0.7)
    write("radio_music", radio_music(), 0.7, edges=False)
    write("drone", drone(), 0.7, edges=False)
    # v0.3.1: the murmur is gone. It's still generated (and thrown away) so
    # the shared random sequence, and every sound after it, stays the same.
    voice(3.4, 7)
    voice(0.9, 11)
    with seeded(2141):
        write("voice", transmission(3.4), 0.8)
    with seeded(2142):
        write("voice_short", transmission(0.9), 0.8)
    write("sting", sting(), 0.8)
    write("breath", breath(), 0.6)
    write("hangup", hangup(), 0.8)
    # v0.2
    write("crossing", crossing(), 0.95)
    write("carrier", carrier(), 0.6, edges=False)
    write("snore", snore(), 0.7, edges=False)
    write("rain", rain(), 0.7, edges=False)
    # v0.5: the vehicle sounds (plow, engine, engine_stop) come from
    # tools/gen_vehicles.py. They're still generated here, and thrown away, so
    # the shared random sequence, and every sound after them, stays the same.
    plow()
    write("siren", siren(), 0.6, edges=False)
    engine()
    engine_stop()
    write("tape_hiss", tape_hiss(), 0.35, edges=False)
    write("tape_rip", tape_rip(), 0.8)
    write("keys", keys(), 0.7)
    write("squeak", squeak(), 0.6)
    write("thunk", thunk(), 0.9)
    # v0.3
    _scanner_v03()
    with seeded(2143):
        write("scanner", scanner(), 0.7, edges=False)
    write("kettle", kettle(), 0.5, edges=False)
    write("bell", bell(), 0.6, edges=False)
    write("bark", bark(), 0.8)
    write("barking", barking(), 0.6, edges=False)
    _crowd_v03()
    with seeded(2144):
        write("crowd", street(), 0.8, edges=False)
    write("typewriter", typewriter(), 0.6, edges=False)
    write("match", match_strike(), 0.7)
    write("shopbell", shopbell(), 0.6)
    write("scrape", scrape(), 0.8)
    write("hush", hush(), 0.4)
    write("plug", plug(), 0.7)
    write("boards", boards(), 0.85)
    write("dish_motor", dish_motor(), 0.6, edges=False)
    write("drip", drip(), 0.5, edges=False)
    write("silence_hit", silence_hit(), 0.4)
    # v0.3.1
    with seeded(2145):
        write("shortwave", shortwave(), 0.6, edges=False)
