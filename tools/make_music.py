"""Composes Boomlets' calm background loop, "Sorbet Skies", and writes it to
audio/music/sorbet_skies.wav (22.05 kHz mono, 16-bit). Original music made
from plain sine-based instruments, so there is nothing to license.

Run from the project folder:  python tools/make_music.py
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
TAIL_N = int(3.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(7)
dry = [0.0] * N      # instruments that stay dry-ish
wet = [0.0] * N      # sent to the reverb


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def render(start_beat, seconds, fn, amp, send=0.5):
    """Adds fn(t) for `seconds` from `start_beat` into dry and wet buses."""
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

def kalimba(f):
    def fn(t):
        att = min(t / 0.004, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 2.8)
                      + 0.22 * math.sin(TAU * 2.0 * f * t) * math.exp(-t * 5.0)
                      + 0.07 * math.sin(TAU * 5.4 * f * t) * math.exp(-t * 16.0))
    return fn


def marimba(f):
    def fn(t):
        att = min(t / 0.003, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 6.5)
                      + 0.12 * math.sin(TAU * 4.0 * f * t) * math.exp(-t * 22.0))
    return fn


def pad(f, length):
    def fn(t):
        att = min(t / 0.7, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.6)
        trem = 0.85 + 0.15 * math.sin(TAU * 0.25 * t)
        v = (math.sin(TAU * f * 1.003 * t) + math.sin(TAU * f * 0.997 * t)) * 0.5
        v += 0.18 * math.sin(TAU * 2.0 * f * t)
        return v * att * rel * trem
    return fn


def bass(f, length):
    def fn(t):
        att = min(t / 0.012, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.12)
        return (math.sin(TAU * f * t) + 0.25 * math.sin(TAU * 2.0 * f * t)) * att * rel * math.exp(-t * 1.1)
    return fn


def kick(t):
    f = 45.0 + 70.0 * math.exp(-t * 30.0)
    return math.sin(TAU * f * t) * math.exp(-t * 11.0)


def make_shaker():
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]          # a crude high-pass for a soft "tss"
        prev[0] = x
        return hp * math.exp(-t * 40.0)
    return fn


# --- The tune -------------------------------------------------------------------

# (bass note, pad voicing) per bar; the second eight bars repeat the first with
# a C7 at the end that leads back to the top.
PROG = [
    (41, [53, 57, 60, 64]),  # Fmaj7
    (45, [52, 55, 57, 60]),  # Am7
    (38, [53, 57, 60, 62]),  # Dm7
    (46, [53, 57, 58, 62]),  # Bbmaj7
    (41, [53, 57, 60, 64]),  # Fmaj7
    (45, [52, 55, 57, 60]),  # Am7
    (43, [53, 55, 58, 62]),  # Gm7
    (36, [53, 55, 58, 60]),  # Csus4
]
CHORDS = PROG + PROG[:7] + [(36, [52, 55, 58, 60])]  # ... C7

# (beat, length in beats, MIDI note)
MELODY = [
    (0, 1.5, 72), (1.5, 0.5, 69), (2, 1, 72), (3, 1, 74),
    (4, 2, 76), (6, 1, 72), (7, 1, 69),
    (8, 1.5, 74), (9.5, 0.5, 72), (10, 1, 69), (11, 1, 65),
    (12, 3, 67),
    (16, 1.5, 72), (17.5, 0.5, 69), (18, 1, 72), (19, 1, 77),
    (20, 2, 76), (22, 1, 74), (23, 1, 72),
    (24, 1.5, 74), (25.5, 0.5, 70), (26, 1, 69), (27, 1, 67),
    (28, 2, 67), (30, 1, 69), (31, 1, 67),
    # Second half: a little higher and airier.
    (32, 1, 77), (33, 0.5, 76), (33.5, 0.5, 72), (34, 2, 69),
    (36, 1, 67), (37, 1, 69), (38, 2, 72),
    (40, 1, 69), (41, 1, 72), (42, 1.5, 74), (43.5, 0.5, 72),
    (44, 3, 74),
    (48, 1.5, 72), (49.5, 0.5, 69), (50, 1, 67), (51, 1, 69),
    (52, 1.5, 76), (53.5, 0.5, 74), (54, 2, 72),
    (56, 1, 70), (57, 1, 69), (58, 1, 67), (59, 1, 70),
    (60, 2, 72), (62, 2, 67),
]
ARP = [0, 1, 2, 3, 2, 1, 2, 3]

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 4
    for m in voicing:
        render(b0, BAR + 0.7, pad(mtof(m), BAR), 0.055, send=0.7)
    render(b0, 1.6 * BEAT + 0.15, bass(mtof(root), 1.6 * BEAT), 0.30, send=0.15)
    render(b0 + 2.5, 1.4 * BEAT + 0.15, bass(mtof(root + 12 if root < 40 else root), 1.4 * BEAT), 0.22, send=0.15)
    for k, idx in enumerate(ARP):
        accent = 1.0 if k % 2 == 0 else 0.75
        render(b0 + k * 0.5, 0.8, marimba(mtof(voicing[idx] + 12)), 0.085 * accent, send=0.55)
    render(b0, 0.5, kick, 0.30, send=0.05)
    render(b0 + 2, 0.5, kick, 0.18, send=0.05)
    for k in range(8):
        render(b0 + k * 0.5, 0.15, make_shaker(), 0.05 if k % 2 else 0.03, send=0.3)

for beat, length, note in MELODY:
    render(beat, min(length * BEAT + 1.4, 3.0), kalimba(mtof(note)), 0.30, send=0.45)


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
    c = comb(wet, d, 0.86, 0.3)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.55 + rev[i] * 0.6 for i in range(N)]

# Fold the tail back onto the start so the loop is seamless.
for i in range(TAIL_N):
    mix[i] += mix[LOOP_N + i]
mix = mix[:LOOP_N]

peak = max(abs(v) for v in mix) or 1.0
gain = 0.89 / peak

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "sorbet_skies.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
