"""Composes World 4's calm, twinkly winter loop, "Twinkle Peaks", and writes
it to audio/music/world_4.wav (22.05 kHz mono, 16-bit). Original music made
from plain sine-based instruments (celesta, music box, glass bells, a soft
pad and sleigh bells), so there is nothing to license.

Run from the project folder:  python tools/make_music_w4.py
Pure Python (no numpy); takes about a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 72
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(4.0 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(44)
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

def celesta(f):
    """A soft struck-bar tone: a pure fundamental, a quick octave and a
    faint bell partial, with a gentle shimmer."""
    def fn(t):
        att = min(t / 0.003, 1.0)
        shimmer = 1.0 + 0.04 * math.sin(TAU * 5.5 * t)
        return att * shimmer * (math.sin(TAU * f * t) * math.exp(-t * 2.2)
                                + 0.35 * math.sin(TAU * 2.0 * f * t) * math.exp(-t * 4.5)
                                + 0.08 * math.sin(TAU * 4.07 * f * t) * math.exp(-t * 11.0))
    return fn


def music_box(f):
    def fn(t):
        att = min(t / 0.002, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 4.0)
                      + 0.25 * math.sin(TAU * 3.0 * f * t) * math.exp(-t * 9.0))
    return fn


def glass_bell(f):
    """Inharmonic partials, like a small glass bell, for the twinkles."""
    def fn(t):
        att = min(t / 0.002, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 1.8)
                      + 0.45 * math.sin(TAU * 2.76 * f * t) * math.exp(-t * 3.5)
                      + 0.2 * math.sin(TAU * 5.4 * f * t) * math.exp(-t * 7.0))
    return fn


def pad(f, length):
    def fn(t):
        att = min(t / 1.1, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.9)
        trem = 0.88 + 0.12 * math.sin(TAU * 0.2 * t)
        v = (math.sin(TAU * f * 1.002 * t) + math.sin(TAU * f * 0.998 * t)) * 0.5
        v += 0.12 * math.sin(TAU * 2.0 * f * t)
        return v * att * rel * trem
    return fn


def bass(f, length):
    def fn(t):
        att = min(t / 0.03, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.25)
        return (math.sin(TAU * f * t) + 0.15 * math.sin(TAU * 2.0 * f * t)) * att * rel * math.exp(-t * 0.6)
    return fn


def make_sleigh():
    """A tiny jingle: high-passed noise plus a few bright little rings."""
    prev = [0.0]
    rings = [random.uniform(4200.0, 6800.0) for _ in range(3)]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]
        prev[0] = x
        ring = sum(math.sin(TAU * r * t + k) for k, r in enumerate(rings)) / 3.0
        return (hp * 0.6 + ring * 0.5) * math.exp(-t * 28.0)
    return fn


# --- The tune -------------------------------------------------------------------

# (bass note, pad voicing) per bar, in D major.
CHORDS = [
    (38, [57, 61, 62, 66]),  # Dmaj7
    (35, [57, 59, 62, 66]),  # Bm7
    (43, [55, 59, 62, 66]),  # Gmaj7
    (45, [57, 61, 64, 66]),  # A6
    (38, [57, 61, 62, 66]),  # Dmaj7
    (42, [54, 57, 61, 64]),  # F#m7
    (40, [55, 59, 62, 64]),  # Em7
    (45, [57, 62, 64, 67]),  # A7sus
    (43, [55, 59, 62, 66]),  # Gmaj7
    (42, [54, 57, 61, 64]),  # F#m7
    (40, [55, 59, 62, 64]),  # Em7
    (42, [57, 62, 66, 69]),  # D/F#
    (43, [55, 59, 62, 66]),  # Gmaj7
    (43, [57, 61, 64, 67]),  # A/G
    (42, [54, 57, 61, 64]),  # F#m7
    (45, [57, 62, 64, 67]),  # A7sus, back to the top
]

# (beat, length in beats, MIDI note)
MELODY = [
    (0, 1, 78), (1, 1, 81), (2, 2, 86),
    (4, 1, 85), (5, 1, 83), (6, 2, 81),
    (8, 1, 83), (9, 1, 81), (10, 1, 78), (11, 1, 74),
    (12, 3, 76), (15, 1, 78),
    (16, 1.5, 81), (17.5, 0.5, 78), (18, 1, 81), (19, 1, 86),
    (20, 2, 85), (22, 1, 81), (23, 1, 78),
    (24, 1.5, 79), (25.5, 0.5, 78), (26, 1, 76), (27, 1, 74),
    (28, 3, 76), (31, 1, 73),
    # Second half: higher, a little brighter.
    (32, 1.5, 86), (33.5, 0.5, 83), (34, 2, 81),
    (36, 1, 85), (37, 1, 81), (38, 2, 78),
    (40, 1, 79), (41, 1, 81), (42, 1, 83), (43, 1, 86),
    (44, 2, 85), (46, 2, 81),
    (48, 1.5, 83), (49.5, 0.5, 81), (50, 1, 78), (51, 1, 81),
    (52, 2, 76), (54, 1, 78), (55, 1, 81),
    (56, 1, 78), (57, 1, 76), (58, 1, 74), (59, 1, 73),
    (60, 4, 76),
]
ARP = [0, 2, 1, 3, 2, 1, 3, 2]
TWINKLE = [86, 88, 90, 93, 95, 98]

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 4
    for m in voicing:
        render(b0, BAR + 1.0, pad(mtof(m), BAR), 0.05, send=0.75)
    render(b0, 2.2 * BEAT + 0.3, bass(mtof(root), 2.2 * BEAT), 0.26, send=0.2)
    render(b0 + 2.5, 1.4 * BEAT + 0.3, bass(mtof(root + 7), 1.4 * BEAT), 0.13, send=0.2)
    for k, idx in enumerate(ARP):
        accent = 1.0 if k % 2 == 0 else 0.7
        render(b0 + k * 0.5, 1.2, music_box(mtof(voicing[idx] + 12)), 0.06 * accent, send=0.6)
    # Sleigh bells: softly on 2 and 4, a light shimmer of eighths in the
    # second half.
    for k in range(8):
        if k in (2, 6):
            render(b0 + k * 0.5, 0.25, make_sleigh(), 0.07, send=0.35)
        elif bar >= 8 and k % 2 == 1:
            render(b0 + k * 0.5, 0.2, make_sleigh(), 0.025, send=0.35)
    # A twinkle or two high up, off the beat.
    for _ in range(1 if bar % 2 == 0 else 2):
        beat = b0 + random.choice([0.5, 1.5, 2.5, 3.5, 3.0])
        render(beat, 2.2, glass_bell(mtof(random.choice(TWINKLE))), 0.05, send=0.8)

for beat, length, note in MELODY:
    render(beat, min(length * BEAT + 1.6, 3.4), celesta(mtof(note)), 0.24, send=0.5)


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
    c = comb(wet, d, 0.88, 0.35)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.5 + rev[i] * 0.7 for i in range(N)]

# Fold the tail back onto the start so the loop is seamless.
for i in range(TAIL_N):
    mix[i] += mix[LOOP_N + i]
mix = mix[:LOOP_N]

peak = max(abs(v) for v in mix) or 1.0
gain = 0.85 / peak

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_4.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
