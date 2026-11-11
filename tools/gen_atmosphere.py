"""Original, reproducible Off Frequency sound design. No sampled/copyrighted recordings.

Requires Python, numpy, scipy and ffmpeg. Long beds are stereo Vorbis streams;
short textures remain in the original audio folder. Seeded and click-free at wrap.
"""
from pathlib import Path
import subprocess
import tempfile
import numpy as np
from scipy.signal import butter, sosfilt
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


def score():
    # 64 seconds, slow D-minor/add9 to Bb/F/C voicings, no stingers or risers.
    x = np.zeros((64*SR, 2))
    for bar, chord in enumerate([[50,57,60,64], [46,53,57,60], [48,55,60,62], [45,52,57,62]]):
        for j, pitch in enumerate(chord):
            a = note(pitch, 22)
            add(x, a, bar*16, .15 if j else .18, (j-1.5)*.30)
            add(x, a, bar*16+.31, .04, -(j-1.5)*.30)
    for when, pitch in [(2,74),(7,69),(13,76),(20,72),(26,69),(35,74),(42,67),(50,69),(57,76)]:
        a=note(pitch,7,False)
        add(x,a,when,.13, .35*np.sin(when))
        for delay, gain in [(.41,.045),(.83,.025),(1.37,.012)]:
            add(x,a,when+delay,gain,-.45*np.sin(when))
    save('night_score', x)


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
    save('people_murmur',x,.5)
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
    score()
    beds()
