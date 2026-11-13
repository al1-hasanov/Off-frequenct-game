#!/usr/bin/env python3
"""Sounds added in v0.6 (Act 3): Dad's whistle, the whistle the wrong way up,
and chalk on a blackboard. Standard library only, deterministic (own seed), so
the older generator's output is untouched.

    python3 tools/gen_audio_v06.py
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")
rng = random.Random(2009)
TAU = 2 * math.pi


def write(name, x, peak=0.8):
    m = max(1e-9, max(abs(s) for s in x))
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s / m * peak)) * 32767)) for s in x))
    print("wrote", name)


def note(f0, f1, dur, vib=5.5):
    """A whistled note gliding from f0 to f1: a breathy sine with a little vibrato."""
    n = int(dur * SR)
    out = []
    ph = 0.0
    for i in range(n):
        u = i / n
        f = f0 + (f1 - f0) * (u * u * (3 - 2 * u))
        f *= 1 + 0.006 * math.sin(TAU * vib * i / SR)
        ph += TAU * f / SR
        env = min(1.0, i / (0.04 * SR)) * min(1.0, (n - i) / (0.08 * SR))
        out.append(env * (0.9 * math.sin(ph) + 0.06 * math.sin(2 * ph) + 0.05 * rng.uniform(-1, 1)))
    return out


def gap(dur):
    return [0.0] * int(dur * SR)


def whistle(first, second):
    return gap(0.05) + note(*first, 0.42) + gap(0.12) + note(*second, 0.55) + gap(0.2)


def chalk():
    """Chalk on slate: short scratchy strokes."""
    out = []
    for stroke in range(4):
        n = int(rng.uniform(0.18, 0.32) * SR)
        lp = 0.0
        for i in range(n):
            u = i / n
            s = rng.uniform(-1, 1)
            lp += 0.35 * (s - lp)
            hp = s - lp
            squeak = 0.25 * math.sin(TAU * (2400 + 300 * stroke) * i / SR) * (rng.random() < 0.3)
            env = math.sin(math.pi * u) ** 0.6
            out.append(env * (0.8 * hp + squeak))
        out += gap(rng.uniform(0.05, 0.12))
    return out


if __name__ == "__main__":
    # Dad's: down, then up.
    write("whistle", whistle((1180, 980), (980, 1420)), 0.6)
    # Mara's (Blue's): up, then down. Close isn't the same.
    write("whistle_rev", whistle((1000, 1380), (1380, 960)), 0.6)
    write("chalk", chalk(), 0.5)
