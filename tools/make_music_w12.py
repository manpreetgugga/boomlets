"""Composes World 12's loop, "Wind-Up Parade" (Toybox Town), and
writes it to audio/music/world_12.wav (22.05 kHz mono, 16-bit). A bouncy
toy piano and xylophone over a plucky bass, a tick-tock wood block and a
soft kick. Original music made from plain sine-based instruments.

Run from the project folder:  python tools/make_music_w12.py
Pure Python (no numpy); takes about half a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 112
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(12)
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

def toy_piano(f):
    """Tine-like: a bright, slightly inharmonic ping with a quick decay."""
    def fn(t):
        att = min(t / 0.002, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 4.5)
                      + 0.35 * math.sin(TAU * 3.0 * f * t + 0.3) * math.exp(-t * 9.0)
                      + 0.12 * math.sin(TAU * 6.27 * f * t) * math.exp(-t * 26.0))
    return fn


def xylophone(f):
    """Hard wooden bar: short, woody, with the 4x and 10x overtones."""
    def fn(t):
        att = min(t / 0.0015, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 11.0)
                      + 0.3 * math.sin(TAU * 3.93 * f * t) * math.exp(-t * 30.0)
                      + 0.08 * math.sin(TAU * 9.6 * f * t) * math.exp(-t * 60.0))
    return fn


def pluck_bass(f, length):
    def fn(t):
        att = min(t / 0.006, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.06)
        return (math.sin(TAU * f * t) + 0.3 * math.sin(TAU * 2.0 * f * t)) * att * rel * math.exp(-t * 4.0)
    return fn


def pad(f, length):
    def fn(t):
        att = min(t / 0.5, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.5)
        v = (math.sin(TAU * f * 1.002 * t) + math.sin(TAU * f * 0.998 * t)) * 0.5
        return v * att * rel
    return fn


def woodblock(f):
    def fn(t):
        return math.sin(TAU * f * t) * math.exp(-t * 55.0)
    return fn


def kick(t):
    f = 50.0 + 80.0 * math.exp(-t * 35.0)
    return math.sin(TAU * f * t) * math.exp(-t * 13.0)


# --- The tune -------------------------------------------------------------------

# Key of G. (bass root, chord tones) per bar.
PROG = [
    (43, [55, 59, 62]),  # G
    (40, [55, 59, 64]),  # Em
    (36, [55, 60, 64]),  # C
    (38, [54, 57, 62]),  # D
    (43, [55, 59, 62]),  # G
    (47, [54, 59, 62]),  # Bm
    (36, [55, 60, 64]),  # C
    (38, [54, 57, 60]),  # D7
]
CHORDS = PROG + PROG[:6] + [(45, [57, 60, 64]), (38, [54, 57, 60])]  # ... Am, D7

# (beat, length in beats, MIDI note): a skipping toy-piano tune.
MELODY = [
    (0, 0.5, 74), (0.5, 0.5, 79), (1, 1, 78), (2, 0.5, 76), (2.5, 0.5, 74), (3, 1, 71),
    (4, 0.5, 72), (4.5, 0.5, 74), (5, 1, 76), (6, 1.5, 79), (7.5, 0.5, 76),
    (8, 1, 76), (9, 0.5, 74), (9.5, 0.5, 72), (10, 1, 71), (11, 1, 72),
    (12, 1, 74), (13, 1, 78), (14, 2, 81),
    (16, 0.5, 74), (16.5, 0.5, 79), (17, 1, 78), (18, 0.5, 76), (18.5, 0.5, 74), (19, 1, 71),
    (20, 0.5, 74), (20.5, 0.5, 78), (21, 1, 81), (22, 1, 78), (23, 1, 74),
    (24, 1.5, 76), (25.5, 0.5, 79), (26, 1, 76), (27, 1, 72),
    (28, 1, 74), (29, 1, 72), (30, 2, 71),
    # Second half: the xylophone answers higher up.
    (32, 0.5, 83), (32.5, 0.5, 81), (33, 0.5, 79), (33.5, 0.5, 81), (34, 1, 83), (35, 1, 79),
    (36, 0.5, 76), (36.5, 0.5, 79), (37, 1, 83), (38, 2, 81),
    (40, 0.5, 79), (40.5, 0.5, 81), (41, 0.5, 79), (41.5, 0.5, 76), (42, 1, 74), (43, 1, 71),
    (44, 1, 74), (45, 1, 78), (46, 2, 81),
    (48, 0.5, 83), (48.5, 0.5, 81), (49, 1, 79), (50, 1, 76), (51, 1, 79),
    (52, 0.5, 78), (52.5, 0.5, 79), (53, 1, 81), (54, 2, 78),
    (56, 1, 76), (57, 0.5, 79), (57.5, 0.5, 76), (58, 1, 72), (59, 1, 76),
    (60, 1, 74), (61, 1, 78), (62, 1, 81), (63, 1, 78),
]

for bar, (root, tones) in enumerate(CHORDS):
    b0 = bar * 4
    for m in tones:
        render(b0, BAR + 0.5, pad(mtof(m), BAR * 0.9), 0.035, send=0.7)
    # Oom-pah: root on 1 and 3, chord stabs on the off-beats.
    render(b0, 0.9 * BEAT, pluck_bass(mtof(root), 0.8 * BEAT), 0.32, send=0.1)
    render(b0 + 2, 0.9 * BEAT, pluck_bass(mtof(root + 7), 0.8 * BEAT), 0.26, send=0.1)
    for k in (1, 3):
        for m in tones:
            render(b0 + k, 0.35, toy_piano(mtof(m + 12)), 0.045, send=0.35)
    # A little xylophone run on the "and" of each beat, quiet.
    for k in range(4):
        render(b0 + k + 0.5, 0.4, xylophone(mtof(tones[k % 3] + 24)), 0.05, send=0.4)
    render(b0, 0.4, kick, 0.30, send=0.03)
    render(b0 + 2, 0.4, kick, 0.22, send=0.03)
    for k in range(4):
        render(b0 + k, 0.1, woodblock(1400.0 if k % 2 == 0 else 1050.0), 0.07, send=0.2)

for beat, length, note in MELODY:
    voice = toy_piano if beat < 32 else xylophone
    render(beat, min(length * BEAT + 0.9, 2.0), voice(mtof(note)), 0.30 if beat < 32 else 0.34, send=0.35)
    if beat < 32:
        # Toy pianos sound with a faint octave doubling.
        render(beat, min(length * BEAT + 0.6, 1.4), xylophone(mtof(note + 12)), 0.05, send=0.4)


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
# The toy piano is peaky: a gentle soft-knee squash brings it up to the
# loudness of the other worlds' music.
mix = [math.tanh(1.1 * v / peak) for v in mix]
peak = max(abs(v) for v in mix) or 1.0
gain = 0.89 / peak

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_12.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
