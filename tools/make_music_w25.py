"""Composes World 25's finale loop, "Starlight Summit", and writes it to
audio/music/world_25.wav (22.05 kHz mono, 16-bit). The last world's tune: a
hopeful, slowly building piece in F major. It opens with a twinkling
glockenspiel ostinato over soft strings, a warm cello line joins, then a
singing violin melody climbs over a I-V-vi-IV-style progression to a bright,
satisfying high point with timpani rolls and celesta sparkles, before
settling back so the loop rejoins calmly. Original music made from plain
sine-based instruments, so there is nothing to license.

Run from the project folder:  python tools/make_music_w25.py
Pure Python (no numpy); takes about a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 80
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(2525)
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
            j -= LOOP_N
        v = fn(i / SR) * amp
        dry[j] += v * (1.0 - send)
        wet[j] += v * send


# --- Instruments --------------------------------------------------------------

def glock(f):
    """Glockenspiel: a bright struck bar with its high, inharmonic overtone."""
    def fn(t):
        att = min(t / 0.0015, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 2.4)
                      + 0.4 * math.sin(TAU * f * 2.756 * t) * math.exp(-t * 6.0)
                      + 0.12 * math.sin(TAU * f * 5.404 * t) * math.exp(-t * 14.0))
    return fn


def strings(f, length, bright=0.25):
    """A soft string section: detuned voices, slow bow attack and vibrato."""
    def fn(t):
        att = min(t / 0.5, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.7)
        vib = 1.0 + 0.003 * math.sin(TAU * 5.2 * t)
        v = 0.0
        for d in (0.994, 1.0, 1.006):
            ph = TAU * f * d * vib * t
            v += math.sin(ph) + bright * math.sin(2.0 * ph) + bright * 0.4 * math.sin(3.0 * ph)
        return v / 3.0 * att * rel
    return fn


def violin(f, length):
    """A singing lead: quicker bow, vibrato that blooms on long notes."""
    def fn(t):
        att = min(t / 0.08, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.3)
        vib = 1.0 + 0.006 * min(max(t - 0.2, 0.0) / 0.4, 1.0) * math.sin(TAU * 5.5 * t)
        ph = TAU * f * vib * t
        v = math.sin(ph) + 0.4 * math.sin(2.0 * ph) + 0.18 * math.sin(3.0 * ph) + 0.08 * math.sin(4.0 * ph)
        return v * att * rel
    return fn


def cello(f, length):
    def fn(t):
        att = min(t / 0.12, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.3)
        ph = TAU * f * t
        return (math.sin(ph) + 0.3 * math.sin(2.0 * ph) + 0.1 * math.sin(3.0 * ph)) * att * rel
    return fn


def timpani(t):
    f = 87.3 * (1.0 + 0.04 * math.exp(-t * 12.0))
    return (math.sin(TAU * f * t) + 0.3 * math.sin(TAU * f * 1.5 * t)) * math.exp(-t * 3.5) \
        + random.uniform(-1, 1) * 0.08 * math.exp(-t * 30.0)


def celesta(f):
    def fn(t):
        att = min(t / 0.002, 1.0)
        return att * (math.sin(TAU * f * t) + 0.2 * math.sin(TAU * 4.0 * f * t) * math.exp(-t * 8.0)) * math.exp(-t * 3.2)
    return fn


# --- The tune -------------------------------------------------------------------

# F major: F, C/E, Dm, Bb, F/A, Gm7, Bb, C(sus4 -> C).
PROG = [
    (41, [57, 60, 65, 69]),
    (40, [55, 60, 64, 67]),
    (38, [57, 62, 65, 69]),
    (46, [58, 62, 65, 70]),
    (45, [57, 60, 65, 69]),
    (43, [58, 62, 65, 67]),
    (46, [58, 62, 65, 70]),
    (48, [55, 60, 65, 67]),
]
CHORDS = PROG + PROG

# Violin melody: enters in bar 5, rises through the second half to a high
# point in bars 13-14, then eases down to lead home.
MELODY = [
    (16, 2, 72), (18, 1, 74), (19, 1, 76), (20, 3, 77), (23, 1, 76),
    (24, 2, 74), (26, 1, 72), (27, 1, 74), (28, 4, 72),
    (32, 2, 77), (34, 1, 79), (35, 1, 81), (36, 3, 82), (39, 1, 81),
    (40, 2, 79), (42, 1, 77), (43, 1, 79), (44, 4, 79),
    (48, 2, 81), (50, 1, 82), (51, 1, 84), (52, 3, 86), (55, 1, 84),
    (56, 2, 82), (58, 1, 81), (59, 1, 79), (60, 2, 77), (62, 2, 76),
]
# Glockenspiel ostinato: chord tones up and down, one per eighth.
OST = [3, 1, 2, 3, 0, 3, 2, 1]

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 4
    build = min(bar / 12.0, 1.0)
    # Strings: always there, a little fuller as the piece builds.
    for m in voicing:
        render(b0, BAR + 1.0, strings(mtof(m), BAR, 0.2 + 0.1 * build), 0.03 + 0.015 * build, send=0.75)
    # Glockenspiel twinkle: sparse at first (every quarter), then eighths.
    for k in range(8):
        if bar < 4 and k % 2 == 1:
            continue
        note = voicing[OST[k]] + 24
        accent = 1.0 if k % 4 == 0 else 0.7
        render(b0 + k * 0.5, 2.2, glock(mtof(note)), 0.05 * accent, send=0.55)
    # Cello from bar 5: root, then the fifth, walking gently.
    if bar >= 4:
        render(b0, BEAT * 2.2, cello(mtof(root), BEAT * 1.9), 0.12, send=0.25)
        render(b0 + 2, BEAT * 2.2, cello(mtof(root + 7), BEAT * 1.9), 0.09, send=0.25)
    else:
        render(b0, BAR + 0.5, cello(mtof(root), BAR * 0.9), 0.08, send=0.35)
    # Soft timpani on the downbeats from bar 9, with a roll into the peak
    # and into the loop's return.
    if bar >= 8:
        render(b0, 1.2, timpani, 0.22, send=0.2)
        if bar in (11, 15):
            for k in range(6):
                render(b0 + 3 + k / 6.0, 0.6, timpani, 0.08 + 0.025 * k, send=0.2)
    # Celesta sparkles over the high point.
    if bar >= 12:
        for k, beat in enumerate((0.25, 1.75, 2.75)):
            render(b0 + beat, 1.8, celesta(mtof(voicing[(bar + k) % 4] + 24)), 0.04, send=0.7)

for beat, length, note in MELODY:
    render(beat, length * BEAT + 0.5, violin(mtof(note), length * BEAT), 0.11, send=0.5)
    # The glockenspiel doubles the melody's first notes in the last part.
    if beat >= 48:
        render(beat, 1.8, glock(mtof(note + 12)), 0.035, send=0.6)


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

mix = [dry[i] + wet[i] * 0.55 + rev[i] * 0.6 for i in range(N)]

for i in range(TAIL_N):
    mix[i] += mix[LOOP_N + i]
mix = mix[:LOOP_N]

rms = math.sqrt(sum(v * v for v in mix) / len(mix)) or 1.0
gain = 0.155 / rms


def soft(x):
    a = abs(x)
    if a < 0.8:
        return x
    return math.copysign(0.8 + 0.19 * math.tanh((a - 0.8) / 0.19), x)


mix = [soft(v * gain) for v in mix]

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_25.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
