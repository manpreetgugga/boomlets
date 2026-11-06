"""Composes World 9's (Ember Forge) calm background loop, "Anvil Lullaby",
and writes it to audio/music/world_9.wav (22.05 kHz mono, 16-bit). A warm,
low, steady groove in D Dorian: soft anvil taps keep time over a round
marimba bass, a mellow reed melody and a glowing pad. Original music made
from plain sine-based instruments, so there is nothing to license.

Run from the project folder:  python tools/make_music_w9.py
Pure Python (no numpy); takes about half a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 84
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.0 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(9)
dry = [0.0] * N
wet = [0.0] * N


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def render(start_beat, seconds, fn, amp, send=0.4):
    s0 = int(round(start_beat * BEAT * SR))
    n = int(seconds * SR)
    for i in range(n):
        j = s0 + i
        if j >= N:
            break
        v = fn(i / SR) * amp
        dry[j] += v * (1.0 - send)
        wet[j] += v * send


# --- Instruments --------------------------------------------------------------

def anvil(f):
    """A small, soft anvil tap: a few inharmonic partials that ring briefly."""
    parts = ((1.0, 1.0, 9.0), (2.76, 0.45, 14.0), (5.4, 0.2, 22.0), (8.93, 0.08, 30.0))

    def fn(t):
        att = min(t / 0.002, 1.0)
        v = 0.0
        for mul, amp, dec in parts:
            v += math.sin(TAU * f * mul * t) * amp * math.exp(-t * dec)
        return v * att
    return fn


def marimba(f):
    def fn(t):
        att = min(t / 0.004, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 2.6)
                      + 0.35 * math.sin(TAU * 4.0 * f * t) * math.exp(-t * 9.0)
                      + 0.1 * math.sin(TAU * 10.0 * f * t) * math.exp(-t * 20.0))
    return fn


def reed(f, length):
    """A mellow, clarinet-like reed: odd harmonics and a gentle vibrato."""
    def fn(t):
        att = min(t / 0.09, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.25)
        vib = 1.0 + 0.003 * min(max(t - 0.3, 0.0) / 0.5, 1.0) * math.sin(TAU * 4.6 * t)
        ph = TAU * f * vib * t
        v = math.sin(ph) + 0.28 * math.sin(3.0 * ph) + 0.1 * math.sin(5.0 * ph)
        return v * att * rel
    return fn


def pad(f, length):
    def fn(t):
        att = min(t / 1.2, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 1.0)
        swell = 0.8 + 0.2 * math.sin(TAU * 0.15 * t)
        v = 0.0
        for d in (0.997, 1.003):
            p = TAU * f * d * t
            v += math.sin(p) + 0.25 * math.sin(2.0 * p)
        return v * 0.5 * att * rel * swell
    return fn


def thump():
    def fn(t):
        f = 48.0 + 60.0 * math.exp(-t * 28.0)
        return math.sin(TAU * f * t) * math.exp(-t * 11.0) * min(t / 0.003, 1.0)
    return fn


def make_shaker():
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]
        prev[0] = x
        return hp * math.exp(-t * 30.0)
    return fn


# --- The tune -------------------------------------------------------------------

DM = (38, [50, 53, 57, 60])    # Dm7
G = (43, [50, 55, 59, 62])     # G (the Dorian colour)
AM = (45, [52, 55, 60, 64])    # Am7
F = (41, [48, 53, 57, 60])     # Fmaj
C = (36, [52, 55, 60, 64])     # C
SECTION = [DM, G, DM, G, F, C, AM, AM]
CHORDS = SECTION + SECTION

# (beat, length in beats, MIDI note); four beats a bar.
MELODY = [
    (0, 1.5, 62), (1.5, 0.5, 64), (2, 2, 65),
    (4, 1, 67), (5, 1, 65), (6, 2, 64),
    (8, 1.5, 62), (9.5, 0.5, 60), (10, 2, 62),
    (12, 1, 59), (13, 1, 60), (14, 2, 62),
    (16, 2, 65), (18, 1, 64), (19, 1, 62),
    (20, 2, 64), (22, 2, 60),
    (24, 1, 64), (25, 1, 67), (26, 1, 65), (27, 1, 64),
    (28, 4, 62),
    (32, 1.5, 69), (33.5, 0.5, 67), (34, 2, 65),
    (36, 1, 67), (37, 1, 65), (38, 2, 64),
    (40, 1.5, 62), (41.5, 0.5, 64), (42, 2, 65),
    (44, 1, 67), (45, 1, 69), (46, 2, 71),
    (48, 2, 69), (50, 1, 67), (51, 1, 65),
    (52, 2, 64), (54, 2, 67),
    (56, 1, 65), (57, 1, 64), (58, 1, 62), (59, 1, 60),
    (60, 4, 62),
]
# Bass pattern per bar: (beat offset, interval from root).
BASS = [(0, 0), (1.5, 12), (2, 7), (3, 12), (3.5, 7)]

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 4
    for m in voicing:
        render(b0, BAR + 1.0, pad(mtof(m), BAR), 0.04, send=0.7)
    for off, iv in BASS:
        amp = 0.3 if off == 0 else 0.18
        render(b0 + off, 1.6, marimba(mtof(root + 12 + iv)), amp, send=0.25)
    # Anvil taps: a steady, quiet tick on every beat, a brighter tap on 2 and 4.
    for k in range(8):
        beat = b0 + k * 0.5
        if k in (2, 6):
            render(beat, 0.8, anvil(1320.0), 0.09, send=0.45)
        elif k % 2 == 0:
            render(beat, 0.4, anvil(1760.0), 0.035, send=0.3)
        else:
            render(beat, 0.15, make_shaker(), 0.02, send=0.2)
    for k in (0, 2):
        render(b0 + k, 0.5, thump(), 0.32, send=0.1)
    if bar % 4 == 3:
        render(b0 + 3.5, 0.8, anvil(990.0), 0.07, send=0.5)

for beat, length, note in MELODY:
    render(beat, length * BEAT + 0.3, reed(mtof(note), length * BEAT * 0.92), 0.13, send=0.45)


# --- Reverb (Schroeder: four combs into two all-passes) -------------------------

def comb(x, delay, fb, damp):
    y = [0.0] * len(x)
    buf = [0.0] * delay
    lp = 0.0
    k = 0
    for i, v in enumerate(x):
        out = buf[k]
        lp = out * (1.0 - damp) + lp * damp
        buf[k] = v + lp * fb
        y[i] = out
        k += 1
        if k == delay:
            k = 0
    return y


def allpass(x, delay, g):
    y = [0.0] * len(x)
    buf = [0.0] * delay
    k = 0
    for i, v in enumerate(x):
        b = buf[k]
        out = -v + b
        buf[k] = v + b * g
        y[i] = out
        k += 1
        if k == delay:
            k = 0
    return y


rev = [0.0] * N
for d in (1116, 1188, 1277, 1356):
    c = comb(wet, d, 0.84, 0.45)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.5 + rev[i] * 0.55 for i in range(N)]

for i in range(TAIL_N):
    mix[i] += mix[LOOP_N + i]
mix = mix[:LOOP_N]

# A gentle low-pass keeps the whole thing warm.
# (Start from the filter's settled value at the loop's end, so the seam is clean.)
lp = 0.0
for i in range(LOOP_N - 2000, LOOP_N):
    lp += (mix[i] - lp) * 0.55
for i in range(LOOP_N):
    lp += (mix[i] - lp) * 0.55
    mix[i] = lp

peak = max(abs(v) for v in mix) or 1.0
gain = 0.89 / peak

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_9.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
