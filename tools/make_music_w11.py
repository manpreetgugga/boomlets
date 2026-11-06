"""Composes World 11's loop, "Lantern Waltz", and writes it to
audio/music/world_11.wav (22.05 kHz mono, 16-bit). A playful, light spooky
waltz in D minor and 3/4: pizzicato strings (oom-pah-pah), a twinkly celesta
tune, a wobbly theremin-like voice in the middle section and a soft wood
block. Original music from plain synthesised instruments (plucked strings
are Karplus-Strong), so there is nothing to license.

Run from the project folder:  python tools/make_music_w11.py
Pure Python (no numpy); takes about half a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BEAT = 0.43              # one crotchet; a bar is three of them (3/4)
BAR = 3 * BEAT
BARS = 32
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(1111)
dry = [0.0] * N
wet = [0.0] * N


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def add(start_sec, samples, amp, send=0.4):
    s0 = int(round(start_sec * SR))
    for i, v in enumerate(samples):
        j = s0 + i
        if j >= N:
            break
        v *= amp
        dry[j] += v * (1.0 - send)
        wet[j] += v * send


def render(start_beat, seconds, fn, amp, send=0.4):
    n = int(seconds * SR)
    add(start_beat * BEAT, [fn(i / SR) for i in range(n)], amp, send)


# --- Instruments --------------------------------------------------------------

def pluck(f, seconds, bright=0.5, decay=0.99):
    """Karplus-Strong plucked string; a short decay makes it pizzicato."""
    period = max(2, int(round(SR / f)))
    buf = [random.uniform(-1.0, 1.0) for _ in range(period)]
    buf = [(buf[k] + buf[k - 1]) * 0.5 for k in range(period)]
    out = []
    n = int(seconds * SR)
    k = 0
    for i in range(n):
        a = buf[k]
        b = buf[(k + 1) % period]
        buf[k] = (a * bright + b * (1.0 - bright)) * decay
        out.append(a * min(i / 40.0, 1.0))
        k = (k + 1) % period
    fade = min(int(0.04 * SR), n)
    for i in range(fade):
        out[n - fade + i] *= 1.0 - i / fade
    return out


def celesta(f):
    """A little bell-like celesta: bright partials that fade fast."""
    def fn(t):
        env = min(t / 0.003, 1.0) * math.exp(-t * 3.2)
        v = math.sin(TAU * f * t)
        v += 0.3 * math.sin(TAU * 2.0 * f * t) * math.exp(-t * 7.0)
        v += 0.14 * math.sin(TAU * 4.0 * f * t) * math.exp(-t * 14.0)
        return v * env
    return fn


def theremin(f, length):
    """A wobbly, friendly theremin voice with a slow vibrato and a slide in."""
    def fn(t):
        att = min(t / 0.18, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.3)
        slide = 1.0 - 0.03 * math.exp(-t * 9.0)
        vib = 1.0 + 0.012 * math.sin(TAU * 5.5 * t) * min(t / 0.4, 1.0)
        ph = TAU * f * slide * vib * t
        return (math.sin(ph) + 0.08 * math.sin(2.0 * ph)) * att * rel
    return fn


def woodblock(f):
    def fn(t):
        return math.sin(TAU * f * t) * math.exp(-t * 45.0) + random.uniform(-1, 1) * math.exp(-t * 200.0) * 0.3
    return fn


# --- The tune -------------------------------------------------------------------

DM = (38, [57, 62, 65])
A7 = (45, [55, 61, 64])
GM = (43, [58, 62, 67])
BB = (46, [58, 62, 65])
F = (41, [57, 60, 65])
C = (48, [55, 60, 64])
A = (45, [57, 61, 64])
A_PART = [DM, A7, DM, GM, DM, BB, A7, DM]
B_PART = [F, C, DM, A, BB, GM, A7, A7]
CHORDS = A_PART + A_PART + B_PART + A_PART

# (start beat, length in beats, MIDI note) for each 8-bar section.
A_MEL = [
    (0, 1, 74), (1, 1, 77), (2, 1, 81),
    (3, 2, 76), (5, 1, 73),
    (6, 1, 74), (7, 1, 77), (8, 1, 81),
    (9, 2, 82), (11, 1, 79),
    (12, 1, 81), (13, 0.5, 79), (13.5, 0.5, 77), (14, 1, 76),
    (15, 1, 77), (16, 1, 74), (17, 1, 70),
    (18, 1, 73), (19, 1, 76), (20, 1, 79),
    (21, 2, 74),
]
A2_MEL = A_MEL[:-4] + [(18, 0.5, 81), (18.5, 0.5, 79), (19, 0.5, 76), (19.5, 0.5, 73), (20, 1, 69), (21, 2, 74), (23, 1, 86)]
B_MEL = [
    (0, 1, 72), (1, 1, 77), (2, 1, 81),
    (3, 2, 79), (5, 1, 76),
    (6, 1, 77), (7, 1, 74), (8, 1, 77),
    (9, 3, 76),
    (12, 1, 74), (13, 1, 77), (14, 1, 82),
    (15, 2, 79), (17, 1, 82),
    (18, 1, 81), (19, 1, 79), (20, 1, 76),
    (21, 1, 73), (22, 1, 76), (23, 1, 79),
]
MELODY = A_MEL + [(s + 24, l, m) for s, l, m in A2_MEL] + [(s + 48, l, m) for s, l, m in B_MEL] + [(s + 72, l, m) for s, l, m in A2_MEL[:-1]]
# The theremin hums long notes through the middle section (bar, bars, note).
HUM = [(16, 1, 69), (17, 1, 67), (18, 1, 69), (19, 1, 73), (20, 1, 74), (21, 1, 70), (22, 2, 73)]

for bar, (bass, chord) in enumerate(CHORDS):
    b0 = bar * 3
    add(b0 * BEAT, pluck(mtof(bass), 0.9, 0.45, 0.992), 0.42, send=0.15)
    for beat in (1, 2):
        for k, m in enumerate(chord):
            add((b0 + beat) * BEAT + k * 0.006, pluck(mtof(m), 0.32, 0.55, 0.985), 0.13, send=0.3)
    render(b0, 0.15, woodblock(820.0), 0.06, send=0.2)
    render(b0 + 1, 0.15, woodblock(1150.0), 0.035, send=0.2)
    render(b0 + 2, 0.15, woodblock(1150.0), 0.035, send=0.2)

for start, length, note in MELODY:
    render(start, length * BEAT + 0.9, celesta(mtof(note)), 0.2, send=0.45)
    # A soft octave-up shimmer on the long notes.
    if length >= 2:
        render(start + 0.02, 1.2, celesta(mtof(note + 12)), 0.05, send=0.6)

for bar, bars, note in HUM:
    render(bar * 3, bars * BAR + 0.35, theremin(mtof(note), bars * BAR * 0.95), 0.085, send=0.5)


# --- Reverb (Schroeder: four combs into two all-passes) -------------------------

def comb(x, delay_n, fb, damp):
    y = [0.0] * len(x)
    buf = [0.0] * delay_n
    lpv = 0.0
    k = 0
    for i, v in enumerate(x):
        out = buf[k]
        lpv = out * (1.0 - damp) + lpv * damp
        buf[k] = v + lpv * fb
        y[i] = out
        k += 1
        if k == delay_n:
            k = 0
    return y


def allpass(x, delay_n, g):
    y = [0.0] * len(x)
    buf = [0.0] * delay_n
    k = 0
    for i, v in enumerate(x):
        b = buf[k]
        out = -v + b
        buf[k] = v + b * g
        y[i] = out
        k += 1
        if k == delay_n:
            k = 0
    return y


rev = [0.0] * N
for d in (1116, 1188, 1277, 1356):
    c = comb(wet, d, 0.85, 0.4)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.5 + rev[i] * 0.6 for i in range(N)]

# Fold the tail back onto the start so the loop is seamless.
for i in range(TAIL_N):
    mix[i] += mix[LOOP_N + i]
mix = mix[:LOOP_N]

lp = 0.0
for i in range(LOOP_N):
    lp = lp * 0.25 + mix[i] * 0.75
    mix[i] = lp

peak = max(abs(v) for v in mix) or 1.0
gain = 0.89 / peak

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_11.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
