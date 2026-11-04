"""Generates the chiptune sound effects in assets/sfx/ (no external deps).

Run from the repo root:  python3 tool/make_sfx.py
Every sound is synthesised from square/triangle waves and noise so the app
ships no third-party audio.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sfx')
random.seed(7)


def square(f, t, duty=0.5):
    return 1.0 if (t * f) % 1.0 < duty else -1.0


def tri(f, t):
    p = (t * f) % 1.0
    return 4 * p - 1 if p < 0.5 else 3 - 4 * p


def env(i, n, attack=0.004, release=0.6):
    t = i / RATE
    a = min(1.0, t / attack) if attack else 1.0
    r = 1.0 - (i / n) ** (1 / max(release, 1e-3)) if release else 1.0
    return a * max(0.0, r)


def tone(freqs, dur, wave_fn=square, vol=0.35, slide=None, duty=0.5, release=0.6):
    """Plays each freq in sequence for dur seconds each."""
    out = []
    for k, f in enumerate(freqs):
        n = int(RATE * dur)
        for i in range(n):
            t = i / RATE
            ff = f if slide is None else f + (slide[k] - f) * (i / n)
            s = square(ff, t, duty) if wave_fn is square else wave_fn(ff, t)
            out.append(s * vol * env(i, n, release=release))
    return out


def noise(dur, vol=0.4, lp=0.5, release=0.8):
    n = int(RATE * dur)
    out, last = [], 0.0
    for i in range(n):
        last = last + lp * (random.uniform(-1, 1) - last)
        out.append(last * vol * env(i, n, release=release))
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


def save(name, samples):
    path = os.path.join(OUT, name + '.wav')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1, min(1, s)) * 32000)) for s in samples))


C5, E5, G5, C6, A4, F4, D5, B4 = 523.25, 659.25, 783.99, 1046.5, 440.0, 349.23, 587.33, 493.88

os.makedirs(OUT, exist_ok=True)
save('tap', tone([880], 0.035, duty=0.25, vol=0.25))
save('select', tone([660, 990], 0.03, duty=0.25, vol=0.22))
save('open', tone([440], 0.09, slide=[880], duty=0.25, vol=0.18, release=1.0))
save('close', tone([700], 0.08, slide=[350], duty=0.25, vol=0.16, release=1.0))
save('flip', mix(noise(0.09, vol=0.35, lp=0.9), tone([300], 0.06, slide=[900], vol=0.1)))
save('correct', tone([C5, E5, G5, C6], 0.055, duty=0.25, vol=0.28))
save('pass', tone([G5, D5], 0.08, wave_fn=tri, vol=0.4))
save('tick', tone([1200], 0.02, duty=0.125, vol=0.2, release=0.3))
save('alarm', tone([A4, F4] * 3, 0.11, vol=0.3, release=1.5))
save('win', tone([C5, E5, G5, C6, G5, C6], 0.09, duty=0.25, vol=0.28, release=1.2))
save('lose', tone([G5, E5, C5, 261.63], 0.12, wave_fn=tri, vol=0.45, release=1.0))
save('boom', mix(noise(0.7, vol=0.8, lp=0.25, release=0.35), tone([120], 0.5, slide=[40], wave_fn=tri, vol=0.5)))
save('coin', tone([B4 * 2, 1318.5], 0.06, duty=0.5, vol=0.22, release=1.0))
save('spin', tone([1500], 0.012, duty=0.5, vol=0.15, release=0.2))
save('start', tone([C5, G5, C6], 0.07, duty=0.5, vol=0.25, release=1.0))
print('wrote', sorted(os.listdir(OUT)))
