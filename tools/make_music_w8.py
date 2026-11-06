"""Composes World 8's (Gale Heights) calm background loop, "Kite Strings",
and writes it to audio/music/world_8.wav (22.05 kHz mono, 16-bit). An airy
waltz in G with a Lydian lift: breathy flute, soft strings, a little harp.
Original music made from plain sine-based instruments, so there is nothing
to license.

Run from the project folder:  python tools/make_music_w8.py
Pure Python (no numpy); takes about half a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 108
BEAT = 60.0 / BPM
BAR = 3 * BEAT
BARS = 24
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(8)
dry = [0.0] * N
wet = [0.0] * N


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def render(start_beat, seconds, fn, amp, send=0.5):
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

def flute(f, length):
    """A breathy flute: a near-sine with a touch of octave, a soft chiff and
    a vibrato that blooms after the attack."""
    state = [0.0]

    def fn(t):
        att = min(t / 0.07, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.18)
        vib = 1.0 + 0.004 * min(max(t - 0.25, 0.0) / 0.4, 1.0) * math.sin(TAU * 5.2 * t)
        ph = TAU * f * vib * t
        v = math.sin(ph) + 0.12 * math.sin(2.0 * ph) + 0.04 * math.sin(3.0 * ph)
        state[0] += (random.uniform(-1.0, 1.0) - state[0]) * 0.25
        breath = state[0] * (0.06 + 0.25 * math.exp(-t * 25.0))
        return (v * 0.9 + breath) * att * rel
    return fn


def strings(f, length):
    def fn(t):
        att = min(t / 0.9, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.8)
        swell = 0.85 + 0.15 * math.sin(TAU * 0.2 * t)
        v = 0.0
        for d in (0.996, 1.0, 1.004):
            p = TAU * f * d * t
            v += math.sin(p) + 0.3 * math.sin(2.0 * p) + 0.12 * math.sin(3.0 * p)
        return v / 3.0 * att * rel * swell
    return fn


def harp(f):
    def fn(t):
        att = min(t / 0.003, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 3.5)
                      + 0.3 * math.sin(TAU * 2.0 * f * t) * math.exp(-t * 7.0)
                      + 0.08 * math.sin(TAU * 3.0 * f * t) * math.exp(-t * 12.0))
    return fn


def bass(f, length):
    def fn(t):
        att = min(t / 0.02, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.2)
        return (math.sin(TAU * f * t) + 0.2 * math.sin(TAU * 2.0 * f * t)) * att * rel * math.exp(-t * 0.9)
    return fn


def make_brush():
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]
        prev[0] = x
        return hp * math.exp(-t * 18.0)
    return fn


# --- The tune -------------------------------------------------------------------

G = (43, [55, 59, 62, 66])     # Gmaj7
AG = (43, [57, 61, 64, 67])    # A/G (the Lydian lift)
EM = (40, [55, 59, 62, 64])    # Em7
C = (36, [55, 59, 60, 64])     # Cmaj7
D = (38, [54, 57, 62, 66])     # D
DS = (38, [55, 57, 62, 67])    # Dsus4
SECTION = [G, G, AG, AG, EM, EM, C, DS]
CHORDS = SECTION + SECTION[:7] + [D] + SECTION[:7] + [D]

# (beat, length in beats, MIDI note); three beats a bar.
MELODY = [
    (0, 2, 79), (2, 1, 78), (3, 3, 74),
    (6, 1, 76), (7, 1, 78), (8, 1, 81), (9, 3, 79),
    (12, 2, 76), (14, 1, 74), (15, 2, 71), (17, 1, 74),
    (18, 1, 72), (19, 1, 74), (20, 1, 76), (21, 3, 74),
    (24, 1, 83), (25, 1, 81), (26, 1, 79), (27, 3, 81),
    (30, 2, 85), (32, 1, 83), (33, 3, 81),
    (36, 1, 79), (37, 1, 76), (38, 1, 79), (39, 3, 78),
    (42, 1, 76), (43, 1, 74), (44, 1, 72), (45, 3, 74),
    (48, 2, 79), (50, 1, 78), (51, 3, 74),
    (54, 1, 76), (55, 1, 78), (56, 1, 81), (57, 3, 83),
    (60, 2, 81), (62, 1, 79), (63, 2, 76), (65, 1, 78),
    (66, 1, 79), (67, 1, 76), (68, 1, 74), (69, 3, 79),
]
ARP = [0, 1, 2, 3, 2, 1]

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 3
    for m in voicing:
        render(b0, BAR + 0.9, strings(mtof(m), BAR), 0.045, send=0.75)
    render(b0, 2.6 * BEAT + 0.25, bass(mtof(root), 2.6 * BEAT), 0.26, send=0.2)
    for k, idx in enumerate(ARP):
        accent = 1.0 if k % 2 == 0 else 0.7
        render(b0 + k * 0.5, 1.2, harp(mtof(voicing[idx] + 12)), 0.06 * accent, send=0.6)
    for k in (1, 2):
        render(b0 + k, 0.2, make_brush(), 0.035, send=0.35)

for beat, length, note in MELODY:
    render(beat, length * BEAT + 0.2, flute(mtof(note), length * BEAT * 0.92), 0.2, send=0.5)


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
    c = comb(wet, d, 0.87, 0.3)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.5 + rev[i] * 0.65 for i in range(N)]

for i in range(TAIL_N):
    mix[i] += mix[LOOP_N + i]
mix = mix[:LOOP_N]

peak = max(abs(v) for v in mix) or 1.0
gain = 0.89 / peak

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_8.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
