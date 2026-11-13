"""Original, reproducible Off Frequency sound design. No sampled/copyrighted recordings.

Requires Python, numpy, scipy and ffmpeg. Long beds are stereo Vorbis streams;
short textures remain in the original audio folder. Seeded and click-free at wrap.
"""
from pathlib import Path
import subprocess
import tempfile
import numpy as np
from scipy.signal import butter, sosfilt, lfilter
from scipy.io.wavfile import write

SR = 32000
ROOT = Path(__file__).resolve().parents[1] / 'audio'
RNG = np.random.default_rng(2141983)


def noise(n, low=80, high=1800):
    x = RNG.normal(0, 1, n)
    x = sosfilt(butter(2, [low, high], fs=SR, btype='bandpass', output='sos'), x)
    return x / max(np.std(x), .01)


def add(dst, mono, when, gain=1, pan=0):
    # Circular placement lets sustained notes and reverb cross the loop boundary.
    ix = (int(when * SR) + np.arange(len(mono))) % len(dst)
    dst[ix, 0] += mono * gain * np.sqrt((1 - pan) * .5)
    dst[ix, 1] += mono * gain * np.sqrt((1 + pan) * .5)


def note(midi, duration, soft=True):
    t = np.arange(int(duration * SR)) / SR
    f = 440 * 2 ** ((midi - 69) / 12)
    attack = 1 - np.exp(-t / (.65 if soft else .025))
    env = attack * np.exp(-t / (duration * .32)) * np.minimum(1, (duration - t) / .5)
    x = np.sin(2*np.pi*f*t) + .18*np.sin(2*np.pi*f*2*t) + .045*np.sin(2*np.pi*f*3*t)
    return x * env


def save(name, x, peak=.72):
    x -= x.mean(axis=0)
    # The tiny edge taper only removes a discontinuity; the arrangement stays circular.
    n = int(SR * .015)
    x[:n] *= np.linspace(0, 1, n)[:, None]
    x[-n:] *= np.linspace(1, 0, n)[:, None]
    x *= peak / max(np.max(np.abs(x)), .001)
    with tempfile.TemporaryDirectory() as d:
        p = Path(d) / 'mix.wav'
        write(p, SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(p), '-c:a', 'libvorbis', '-q:a', '4', str(ROOT / (name + '.ogg'))], check=True)
    print(name, len(x) / SR, 'seconds', flush=True)


def dystopia():
    """v0.5 background score: dark dystopian ambient, for focus and calm.

    Three minutes, circular so it loops without a seam: a sub drone, slowly
    breathing detuned pads over a dark minor progression (Dm9 - Bbmaj7#11 -
    Gm9 - Eb/D), distant metal resonances, filtered wind, a few far-off bell
    notes and the ghost of a radio carrier, all in a long, dark reverb.
    Uses its own random generator, so the beds below are unchanged.
    """
    rng = np.random.default_rng(1983214)
    dur = 180
    n = dur * SR
    t = np.arange(n) / SR
    x = np.zeros((n, 2))

    def hz(m):
        return 440.0 * 2 ** ((m - 69) / 12)

    def whole(f):
        # A whole number of cycles in the loop, so a held tone has no seam.
        return round(f * dur) / dur

    def circular_band(sig, low, high):
        # Band-pass by FFT: circular, so filtered noise wraps cleanly too.
        spec = np.fft.rfft(sig)
        f = np.fft.rfftfreq(len(sig), 1 / SR)
        mask = 1 / (1 + (low / np.maximum(f, 1e-3)) ** 4) / (1 + (f / high) ** 4) if high else 1 / (1 + (low / np.maximum(f, 1e-3)) ** 4)
        return np.fft.irfft(spec * mask, len(sig))

    def place(mono, start, gain, pan):
        ix = (int(start * SR) + np.arange(len(mono))) % n
        x[ix, 0] += mono * gain * np.sqrt((1 - pan) * .5)
        x[ix, 1] += mono * gain * np.sqrt((1 + pan) * .5)

    # Sub drone on D, with its fifth, breathing very slowly.
    breath = .75 + .25 * np.sin(2 * np.pi * t / 45.0)
    sub = (np.sin(2 * np.pi * whole(hz(26)) * t) + .55 * np.sin(2 * np.pi * whole(hz(33)) * t + .7)
           + .25 * np.sin(2 * np.pi * whole(hz(26) * 1.003) * t)) * breath
    place(sub, 0, .16, 0)

    # Pads: four chords of 45 s that overlap, detuned voices, a slow filter sweep.
    chords = [[38, 45, 53, 64, 69], [34, 41, 50, 57, 64], [31, 38, 46, 57, 60], [39, 46, 55, 62, 67]]
    seg = 45.0
    span = seg + 14.0
    m = int(span * SR)
    tt = np.arange(m) / SR
    env = np.minimum(1, tt / 12.0) * np.minimum(1, (span - tt) / 14.0)
    env = env ** 1.5
    for ci, chord in enumerate(chords):
        start = ci * seg - 7.0
        bright = 280 + 420 * (.5 + .5 * np.sin(2 * np.pi * (tt + start) / 63.0 + ci))
        for j, midi in enumerate(chord):
            f0 = hz(midi)
            voice = np.zeros(m)
            for det in (-0.006, 0.0, 0.0055):
                ph = rng.uniform(0, 2 * np.pi)
                for k in range(1, 7):
                    fk = f0 * k * (1 + det)
                    gain = (1.0 / k) / (1 + (fk / bright) ** 4)
                    voice += np.sin(2 * np.pi * fk * tt + ph * k) * gain
            voice *= env * (.85 + .15 * np.sin(2 * np.pi * tt / (9 + 2 * j) + j))
            place(voice, start, .05 if j else .065, (j - 2) * .32)

    # Wind: two bands of noise, drifting in and out.
    for ch in range(2):
        w1 = circular_band(rng.normal(0, 1, n), 120, 520)
        w2 = circular_band(rng.normal(0, 1, n), 420, 1300)
        g1 = .5 + .5 * np.sin(2 * np.pi * t / 36.0 + ch)
        g2 = .5 + .5 * np.sin(2 * np.pi * t / 60.0 + 2 + ch)
        x[:, ch] += (w1 / np.std(w1) * g1 * .022 + w2 / np.std(w2) * g2 ** 2 * .009)

    # Distant metal: a struck girder far off, ringing in a few inharmonic modes.
    modes = [173.0, 241.0, 389.0, 467.0, 613.0, 829.0]
    for when in [8, 31, 57, 79, 103, 128, 151, 172]:
        hit = np.zeros(int(7 * SR))
        burst = rng.normal(0, 1, int(.04 * SR)) * np.linspace(1, 0, int(.04 * SR))
        hit[:len(burst)] = burst
        out = np.zeros_like(hit)
        for f in rng.choice(modes, 3, replace=False):
            f = f * rng.uniform(.97, 1.03)
            r = np.exp(-1.0 / (SR * rng.uniform(1.2, 2.4)))
            w = 2 * np.pi * f / SR
            out += lfilter([1 - r], [1, -2 * r * np.cos(w), r * r], hit)
        out = sosfilt(butter(2, 1600, fs=SR, output='sos'), out)
        place(out / max(np.max(np.abs(out)), 1e-6), when + rng.uniform(-1, 1), .05, rng.uniform(-.8, .8))

    # Far-off bell notes, a few, with long tails.
    for when, midi in [(14, 74), (29, 77), (47, 69), (66, 72), (88, 74), (112, 76), (133, 69), (158, 72)]:
        f = hz(midi)
        bl = int(9 * SR)
        bt = np.arange(bl) / SR
        bell = np.zeros(bl)
        for mult, amp, dec in [(1, 1, 3.5), (2.0, .45, 2.2), (2.76, .3, 1.6), (5.4, .12, .8), (.5, .2, 4.5)]:
            bell += np.sin(2 * np.pi * f * mult * bt) * amp * np.exp(-bt / dec)
        bell *= np.minimum(1, bt / .008)
        place(bell, when, .028, rng.uniform(-.6, .6))

    # The ghost of a radio carrier, twice.
    for when in [96, 166]:
        gl = int(4 * SR)
        gt = np.arange(gl) / SR
        carrier = np.sin(2 * np.pi * (1180 * gt + 30 * np.sin(2 * np.pi * .6 * gt)))
        hiss = sosfilt(butter(2, [900, 3200], fs=SR, btype='bandpass', output='sos'), rng.normal(0, 1, gl))
        ghost = (carrier * .5 + hiss / np.std(hiss) * .5) * np.sin(np.pi * gt / 4.0) ** 2
        place(ghost, when, .012, rng.uniform(-.5, .5))

    # A long, dark reverb, applied circularly so the tail wraps into the start.
    il = int(5.0 * SR)
    it = np.arange(il) / SR
    for ch in range(2):
        ir = rng.normal(0, 1, il) * np.exp(-it / 1.4)
        ir = sosfilt(butter(2, 2400, fs=SR, output='sos'), ir)
        ir /= np.sqrt(np.sum(ir ** 2))
        wet = np.real(np.fft.ifft(np.fft.fft(x[:, ch]) * np.fft.fft(ir, n)))
        x[:, ch] = x[:, ch] * .62 + wet * .9
    x = np.column_stack([circular_band(x[:, 0], 28, None), circular_band(x[:, 1], 28, None)])
    x -= x.mean(axis=0)
    x *= .7 / max(np.max(np.abs(x)), .001)
    with tempfile.TemporaryDirectory() as d:
        p = Path(d) / 'mix.wav'
        write(p, SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(p), '-c:a', 'libvorbis', '-q:a', '4',
                        str(ROOT / 'night_score.ogg')], check=True)
    print('night_score (dark dystopian ambient)', dur, 'seconds', flush=True)


def beds():
    dur = 32
    n = dur*SR
    t = np.arange(n)/SR
    x=np.zeros((n,2))
    for ch in range(2):
        x[:,ch]=noise(n,70,1250)*.025*(.7+.3*np.sin(2*np.pi*t/16+ch))
    for when in [3,20]:
        sec=9; tt=np.arange(sec*SR)/SR
        env=np.sin(np.pi*tt/sec)**2
        car=(noise(len(tt),100,1600)*.10 + np.sin(2*np.pi*(48*tt+3*np.sin(tt)))*.04)*env
        start=int(when*SR)
        pan=np.linspace(-.9,.9,len(tt))
        ix=(start+np.arange(len(tt)))%n
        x[ix,0]+=car*np.sqrt((1-pan)/2);x[ix,1]+=car*np.sqrt((1+pan)/2)
    save('street_air',x,.65)
    # Low, indistinct, nonverbal crowd texture. No fake spoken lines or jump scares.
    x=np.zeros((n,2))
    for person in range(5):
        f=RNG.uniform(95,180)
        signal=np.zeros(n)
        for h in range(1,14):
            amp=np.exp(-((h*f-650)/360)**2)+.35*np.exp(-((h*f-1250)/260)**2)
            signal+=np.sin(2*np.pi*h*f*t + .6*np.sin(t*2+person))*amp/h
        env=np.maximum(0,np.sin(t*(.74+person*.13)+person))**3
        signal*=env*(.7+.3*np.sin(t*7+person))
        add(x,signal,0,.05,(person-2)*.36)
    x+=np.column_stack([noise(n,300,1800),noise(n,300,1800)])*.004
    # v0.5: the murmur layer is no longer used (fake voices; see README). It is still
    # generated here so the shared random sequence, and every bed after it, is unchanged.
    _ = x
    x=np.zeros((n,2))
    for ch in range(2):
        x[:,ch]=noise(n,60,700)*.018 + np.sin(2*np.pi*60*t)*.014+np.sin(2*np.pi*120*t)*.004
    save('room_air',x,.4)
    x=np.column_stack([noise(n,75,950),noise(n,75,950)])*.03
    for when in [2.2,9.3,21.8,27.0]:
        a=note(88, .4,False)+note(93,.4,False)*.4
        add(x,a,when,.02,RNG.uniform(-.7,.7))
    save('diner_room',x,.45)
    # Narrow-band original radio melody: warm late-night receiver, no broadcasts.
    x=np.zeros((n,2))
    for i,p in enumerate([62,65,69,72,69,65,64,67,71,74,71,67,60,64,67,69]):
        a=note(p,2.7,False)
        add(x,a,i*2,.16,0)
        add(x,a,i*2+.18,.025,-.2)
    x+=np.column_stack([noise(n,400,2800),noise(n,400,2800)])*.006
    save('radio_music',x,.65)


if __name__ == '__main__':
    import sys
    # v0.5 replaced the 64-second score with dystopia(). `python tools/gen_atmosphere.py score`
    # rebuilds only the score; with no argument, the beds are rebuilt too.
    dystopia()
    if 'score' not in sys.argv[1:]:
        beds()
