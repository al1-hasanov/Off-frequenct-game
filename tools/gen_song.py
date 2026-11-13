#!/usr/bin/env python3
""""Their song" for Off Frequency (v0.5.1): the music Tomas's radio finds in the
clearing on October 14, 1980, and the few notes Mara hears again down the
observatory corridor in 1983 (and on frequency 12, back at the snowfield).

An original late-'70s soft instrumental in D major, 76 bpm: electric piano,
bass, brushed drums, a string pad and a soft synth lead. Original synthesis,
no samples; seeded, so the same files come out on every machine.

    python3 tools/gen_song.py

Writes two Vorbis files into audio/, the same length and sample-aligned, so the
game can start both together and crossfade between them in time:

    song_clear   the song as heard through Tomas's headphones (stereo)
    song_radio   the same song out of a small transistor speaker: narrow band,
                 overdriven, fading, with static and crackle (mono)

Requires numpy, scipy and ffmpeg.
"""
from pathlib import Path
import subprocess
import tempfile

import numpy as np
from scipy.io.wavfile import write
from scipy.signal import butter, fftconvolve, sosfilt

SR = 32000
BPM = 76.0
BEAT = 60.0 / BPM
ROOT = Path(__file__).resolve().parents[1] / "audio"
RNG = np.random.default_rng(14101980)

BARS = 18
LENGTH = BARS * 4 * BEAT + 2.4  # the last chord rings out


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def at(beat):
    return int(round(beat * BEAT * SR))


# ------------------------------------------------------------------ the music

# (Rhodes voicing, bass root) by chord. The voicings leave out any note a
# semitone under the tune (no seventh under a melody root), so nothing rubs.
CHORDS = {
    "D":    ([54, 57, 59, 64], 38),   # D6/9, rootless: F# A B E
    "F#m":  ([57, 61, 64, 68], 42),   # F#m9: A C# E G#
    "G":    ([59, 62, 67, 69], 43),   # Gadd9: B D G A
    "Gm":   ([58, 62, 64, 67], 43),   # Gm6: Bb D E G (the turn)
    "D/A":  ([57, 62, 64, 66], 45),   # Dadd9 over A
    "Bm":   ([57, 59, 62], 35),       # Bm7: A B D
    "Em7":  ([55, 59, 62, 64], 40),   # Em7: G B D E
    "A7s":  ([55, 62, 64, 69], 45),   # A7sus4
    "A7":   ([55, 61, 64, 66], 45),   # A13: G C# E F#
    "Dend": ([54, 57, 62, 64, 69], 38),
    "G/D":  ([55, 59, 62, 66], 38),
}
# Two chords in a bar are split at beat 3.
PROGRESSION = [
    ["D"], ["F#m"], ["G"], ["Gm"], ["D/A"], ["Bm"], ["Em7"], ["A7s", "A7"],
    ["D"], ["F#m"], ["G"], ["Gm"], ["D/A"], ["Bm"], ["Em7", "A7"], ["Dend"],
    ["G/D"], ["Dend"],
]

# The tune: (midi, start beat, length in beats). The opening four notes are
# the ones anyone who heard them in the clearing would know again.
A4, B4, Cs5, D5, E5, Fs5, G5, A5, B5 = 69, 71, 73, 74, 76, 78, 79, 81, 83
MELODY = [
    # A
    (A4, 0, 1), (D5, 1, 1), (Fs5, 2, 2),
    (E5, 4, 1.5), (D5, 5.5, 0.5), (Cs5, 6, 2),
    (B4, 8, 1), (D5, 9, 1), (G5, 10, 1.5), (Fs5, 11.5, 0.5),
    (E5, 12, 3), (D5, 15, 1),
    (A4, 16, 1), (D5, 17, 1), (Fs5, 18, 1), (A5, 19, 1),
    (G5, 20, 1.5), (Fs5, 21.5, 0.5), (D5, 22, 2),
    (E5, 24, 1), (G5, 25, 1), (Fs5, 26, 1), (E5, 27, 1),
    (E5, 28, 1), (D5, 29, 1), (Cs5, 30, 2),
    # A'
    (A4, 32, 1), (D5, 33, 1), (Fs5, 34, 1.5), (A5, 35.5, 0.5),
    (Fs5, 36, 1.5), (E5, 37.5, 0.5), (Cs5, 38, 2),
    (B4, 40, 1), (D5, 41, 1), (G5, 42, 1), (B5, 43, 1),
    (A5, 44, 3), (G5, 47, 1),
    (Fs5, 48, 2), (E5, 50, 1), (D5, 51, 1),
    (Fs5, 52, 1.5), (E5, 53.5, 0.5), (D5, 54, 1), (B4, 55, 1),
    (G5, 56, 1), (Fs5, 57, 1), (E5, 58, 1), (Cs5, 59, 1),
    (D5, 60, 4),
]


# ------------------------------------------------------------------ instruments

def env_adsr(n, attack, decay_tau, release, gate):
    """Exponential decay from a short attack; released at `gate` samples."""
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / max(attack, 1e-4)) * np.exp(-t / decay_tau)
    if gate < n:
        rel = np.exp(-(t[gate:] - t[gate]) / release)
        e[gate:] = e[gate] * rel
    return e


def rhodes(midi, length, vel=1.0):
    """Two-operator FM electric piano: a 1:1 body with a bright, fast-fading
    bark, and the tine's high ping."""
    f = hz(midi)
    n = int((length + 1.2) * SR)
    t = np.arange(n) / SR
    index = 1.5 * vel * np.exp(-t / 0.45) + 0.35
    body = np.sin(2 * np.pi * f * t + index * np.sin(2 * np.pi * f * t))
    tine = np.sin(2 * np.pi * f * 14.0 * t) * np.exp(-t / 0.025) * 0.18
    tau = 2.6 * (220.0 / f) ** 0.35
    e = env_adsr(n, 0.003, tau, 0.22, int(length * SR))
    return (body + tine) * e * vel


def bass(midi, length, vel=1.0):
    f = hz(midi)
    n = int((length + 0.5) * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * 2 * f * t) + 0.08 * np.sin(2 * np.pi * 3 * f * t)
    thump = np.sin(2 * np.pi * f * t) * np.exp(-t / 0.05) * 0.4
    e = env_adsr(n, 0.008, 1.6, 0.12, int(length * SR * 0.92))
    return (x + thump) * e * vel


def lead(midi, length, vel=1.0):
    """A soft synth lead: warm harmonics, a breath of attack, vibrato that
    blooms after the note has settled."""
    f = hz(midi)
    n = int((length + 0.35) * SR)
    t = np.arange(n) / SR
    vib = 0.0045 * np.clip((t - 0.28) / 0.35, 0.0, 1.0) * np.sin(2 * np.pi * 5.1 * t)
    phase = 2 * np.pi * f * np.cumsum(1.0 + vib) / SR
    x = np.sin(phase) + 0.32 * np.sin(2 * phase) + 0.12 * np.sin(3 * phase) + 0.05 * np.sin(4 * phase)
    breath = RNG.normal(0, 1, n) * np.exp(-t / 0.04) * 0.05
    a = np.minimum(1.0, t / 0.035)
    e = a * (0.82 + 0.18 * np.exp(-t / 0.3))
    gate = int(length * SR)
    if gate < n:
        e[gate:] *= np.exp(-(t[gate:] - t[gate]) / 0.09)
    y = (x + breath) * e * vel
    return sosfilt(butter(2, 3400, fs=SR, output="sos"), y)


def pad(midis, length, vel=1.0):
    """A string-machine pad: detuned saws, filtered, slow in and out."""
    n = int((length + 1.5) * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    for m in midis:
        for det in (-0.08, 0.0, 0.09):
            f = hz(m) * 2 ** (det / 12)
            ph = (f * t + RNG.random()) % 1.0
            y += (2 * ph - 1) * 0.33
    y = sosfilt(butter(2, 1500, fs=SR, output="sos"), y)
    e = np.minimum(1.0, t / 0.9) * np.where(t < length, 1.0, np.exp(-(t - length) / 0.6))
    return y * e * vel / len(midis)


def kick(vel=1.0):
    n = int(0.4 * SR)
    t = np.arange(n) / SR
    f = 52 + 60 * np.exp(-t / 0.035)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.16) * vel


def brush(vel=1.0, length=0.32):
    n = int(length * SR)
    t = np.arange(n) / SR
    x = sosfilt(butter(2, [900, 7000], btype="bandpass", fs=SR, output="sos"), RNG.normal(0, 1, n))
    # A brush is a sweep: a soft swell, not a crack.
    e = np.minimum(1.0, t / 0.012) * np.exp(-t / 0.11)
    return x * e * vel * 0.5


def hat(vel=1.0):
    n = int(0.09 * SR)
    t = np.arange(n) / SR
    x = sosfilt(butter(2, 7000, btype="highpass", fs=SR, output="sos"), RNG.normal(0, 1, n))
    return x * np.exp(-t / 0.018) * vel * 0.35


# ------------------------------------------------------------------ arranging

def place(dst, x, start, gain=1.0, pan=0.0):
    i0 = int(start)
    if i0 >= len(dst):
        return
    x = x[: len(dst) - i0]
    dst[i0:i0 + len(x), 0] += x * gain * np.sqrt((1 - pan) * 0.5)
    dst[i0:i0 + len(x), 1] += x * gain * np.sqrt((1 + pan) * 0.5)


def chords_by_beat():
    """[(start beat, length in beats, name)] for the whole song."""
    out = []
    for bar, names in enumerate(PROGRESSION):
        if len(names) == 1:
            out.append((bar * 4, 4, names[0]))
        else:
            out.append((bar * 4, 2, names[0]))
            out.append((bar * 4 + 2, 2, names[1]))
    return out


def arrange():
    n = int(LENGTH * SR)
    keys = np.zeros((n, 2))
    low = np.zeros((n, 2))
    tune = np.zeros((n, 2))
    strings = np.zeros((n, 2))
    drums = np.zeros((n, 2))
    last_bar = len(PROGRESSION) - 1
    for start, length, name in chords_by_beat():
        voicing, root = CHORDS[name]
        bar = start // 4
        ending = bar >= 15
        # Electric piano: on the beat, an anticipation on the "and" of 2, and
        # a light touch on 4. The last bars just ring.
        hits = [(0.0, length if ending else 1.4, 0.9)]
        if not ending and length == 4:
            hits += [(1.5, 1.0, 0.55), (3.0, 0.9, 0.42)]
        elif not ending:
            hits += [(1.0, 0.9, 0.5)]
        for off, dur, vel in hits:
            for k, m in enumerate(voicing):
                # A slight roll, low to high, like a hand on the keys.
                place(keys, rhodes(m, dur * BEAT, vel), at(start + off) + k * int(0.012 * SR), 0.16, -0.25 + k * 0.17)
        # Bass: the root, then a walk into the next bar.
        if bar <= last_bar:
            place(low, bass(root, (length - 0.5 if not ending else length) * BEAT), at(start), 0.32)
            if length == 4 and not ending:
                place(low, bass(root + 7, 0.45 * BEAT, 0.7), at(start + 3.5), 0.32)
        # Strings from the fifth bar, a little more in the second half.
        if 4 <= bar:
            sv = 0.5 if bar < 8 else 0.8
            place(strings, pad(list(voicing[1:3]) + [root + 12], length * BEAT, sv), at(start), 0.2, 0.0)
    # Brushed drums from bar 1, quiet; out for the last two bars.
    for bar in range(16):
        b = bar * 4
        place(drums, kick(0.9), at(b), 0.30)
        place(drums, kick(0.5), at(b + 2.5), 0.30)
        for beat in (1, 3):
            place(drums, brush(0.9), at(b + beat), 0.24, 0.15)
        for e in range(8):
            if e % 2 == 1 or bar >= 8:
                place(drums, hat(0.7 if e % 2 else 0.4), at(b + e * 0.5), 0.12, 0.35)
    for midi, start, length in MELODY:
        place(tune, lead(midi, length * BEAT * 0.97, 1.0), at(start), 0.25, -0.05)
        # A quiet octave double in the second half.
        if start >= 32:
            place(tune, lead(midi - 12, length * BEAT * 0.97, 0.5), at(start), 0.06, 0.2)
    return keys, low, tune, strings, drums


def tremolo(x, rate=4.6, depth=0.22):
    """The suitcase piano's stereo tremolo."""
    t = np.arange(len(x)) / SR
    m = depth * np.sin(2 * np.pi * rate * t)
    y = x.copy()
    y[:, 0] *= 1.0 - m
    y[:, 1] *= 1.0 + m
    return y


def reverb(x, rt60=1.9, mix=0.22):
    """Convolution with a decaying, decorrelated noise tail, darker as it fades."""
    n = int(rt60 * 1.3 * SR)
    t = np.arange(n) / SR
    out = np.zeros_like(x)
    for ch in range(2):
        ir = RNG.normal(0, 1, n) * np.exp(-6.9 * t / rt60)
        ir = sosfilt(butter(1, 2600, fs=SR, output="sos"), ir)
        ir[: int(0.012 * SR)] = 0.0
        ir /= np.sqrt(np.sum(ir ** 2))
        out[:, ch] = fftconvolve(x[:, ch], ir)[: len(x)]
    return x * (1.0 - mix) + out * mix * 1.6


def soft_clip(x, drive=1.4):
    return np.tanh(drive * x) / np.tanh(drive)


def mix_clear():
    keys, low, tune, strings, drums = arrange()
    keys = tremolo(keys)
    dry = keys + low + tune + strings + drums
    wet = reverb(dry)
    x = soft_clip(wet / np.max(np.abs(wet)) * 0.9, 1.2)
    # A gentle tape-warm tilt: a little less top.
    for ch in range(2):
        x[:, ch] = 0.85 * x[:, ch] + 0.15 * sosfilt(butter(1, 5000, fs=SR, output="sos"), x[:, ch])
    fade = int(1.8 * SR)
    x[-fade:] *= np.linspace(1, 0, fade)[:, None] ** 2
    return x


def radio_version(clear):
    """The same mix through a pocket transistor radio on a weak, drifting
    station: band-limited, overdriven, fading in and out, under static."""
    mono = clear.mean(axis=1)
    n = len(mono)
    t = np.arange(n) / SR
    x = sosfilt(butter(4, [320, 3100], btype="bandpass", fs=SR, output="sos"), mono)
    x = soft_clip(x / np.max(np.abs(x)) * 1.6, 2.2)
    # The little speaker's honk around 1 kHz.
    honk = sosfilt(butter(2, [800, 1500], btype="bandpass", fs=SR, output="sos"), x)
    x = x + 0.6 * honk
    # Fading: slow swells with an occasional deeper dip.
    fade = 0.78 + 0.16 * np.sin(2 * np.pi * 0.11 * t + 0.7) + 0.06 * np.sin(2 * np.pi * 0.37 * t)
    for centre in (11.5, 29.0, 43.5):
        fade -= 0.35 * np.exp(-((t - centre) / 0.9) ** 2)
    x *= np.clip(fade, 0.2, 1.0)
    # Static: hiss shaped like an AM band, plus crackle.
    hiss = sosfilt(butter(2, [400, 4200], btype="bandpass", fs=SR, output="sos"), RNG.normal(0, 1, n))
    x += hiss * 0.07 * (1.25 - np.clip(fade, 0.2, 1.0))
    crackle = np.zeros(n)
    for i in RNG.integers(0, n - 200, 260):
        crackle[i:i + 60] += RNG.normal(0, 1, 60) * np.exp(-np.arange(60) / 9.0) * RNG.uniform(0.2, 0.9)
    x += sosfilt(butter(2, 2500, btype="highpass", fs=SR, output="sos"), crackle) * 0.35
    # A faint heterodyne whistle from the next station over, drifting.
    whistle = np.sin(2 * np.pi * np.cumsum(1180 + 40 * np.sin(2 * np.pi * 0.05 * t)) / SR)
    x += whistle * 0.012
    x /= np.max(np.abs(x))
    return np.column_stack([x, x])


def save(name, x, peak):
    x = x - x.mean(axis=0)
    edge = int(0.01 * SR)
    x[:edge] *= np.linspace(0, 1, edge)[:, None]
    x *= peak / max(np.max(np.abs(x)), 1e-4)
    with tempfile.TemporaryDirectory() as d:
        p = Path(d) / "mix.wav"
        data = np.clip(x, -1, 1)
        if name == "song_radio":
            data = data[:, :1]
        write(p, SR, (data * 32767).astype(np.int16))
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(p), "-c:a", "libvorbis", "-q:a", "4",
                        str(ROOT / (name + ".ogg"))], check=True)
    rms = np.sqrt(np.mean(x ** 2))
    print(f"{name}: {len(x) / SR:.2f} s, peak {np.max(np.abs(x)):.2f}, rms {rms:.3f}")


if __name__ == "__main__":
    clear = mix_clear()
    radio = radio_version(clear)
    save("song_clear", clear, 0.8)
    save("song_radio", radio, 0.7)
