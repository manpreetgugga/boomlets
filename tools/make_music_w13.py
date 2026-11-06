"""Composes World 13's loop, "Cloud Groove" (Rhythm Cloudway), and writes it
to audio/music/world_13.wav (22.05 kHz mono, 16-bit). An upbeat but calm
marimba and soft-synth groove at exactly 100 BPM with a clear four-on-the-
floor pulse, 16 bars long, so the world's beat tiles (driven by their own
clock at the same tempo) line up with it. Original music made from plain
sine-based instruments.

Run from the project folder:  python tools/make_music_w13.py
Pure Python (no numpy); takes about half a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 100
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(13)
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

def marimba(f):
    def fn(t):
        att = min(t / 0.003, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 5.5)
                      + 0.14 * math.sin(TAU * 4.0 * f * t) * math.exp(-t * 20.0)
                      + 0.05 * math.sin(TAU * 9.9 * f * t) * math.exp(-t * 45.0))
    return fn


def synth_lead(f, length):
    """A soft square-ish lead: a few odd harmonics, gentle vibrato."""
    def fn(t):
        att = min(t / 0.03, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.15)
        vib = 1.0 + 0.004 * math.sin(TAU * 5.0 * t) * min(t / 0.3, 1.0)
        ph = TAU * f * vib * t
        v = math.sin(ph) + 0.22 * math.sin(3 * ph) + 0.08 * math.sin(5 * ph)
        return v * att * rel * (0.75 + 0.25 * math.exp(-t * 3.0))
    return fn


def pad(f, length):
    def fn(t):
        att = min(t / 0.6, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.5)
        v = (math.sin(TAU * f * 1.003 * t) + math.sin(TAU * f * 0.997 * t)) * 0.5
        v += 0.15 * math.sin(TAU * 2.0 * f * t)
        return v * att * rel
    return fn


def bass(f, length):
    def fn(t):
        att = min(t / 0.008, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.08)
        return (math.sin(TAU * f * t) + 0.3 * math.sin(TAU * 2.0 * f * t)) * att * rel * math.exp(-t * 2.2)
    return fn


def kick(t):
    f = 48.0 + 75.0 * math.exp(-t * 32.0)
    return math.sin(TAU * f * t) * math.exp(-t * 10.0)


def make_noise(decay, hp=True):
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        y = x - prev[0] if hp else x
        prev[0] = x
        return y * math.exp(-t * decay)
    return fn


def clap(t):
    # Three quick bursts then a short tail.
    env = 0.0
    for k in range(3):
        u = t - k * 0.011
        if u >= 0.0:
            env = max(env, math.exp(-u * 160.0))
    env = max(env, 0.5 * math.exp(-max(t - 0.022, 0.0) * 28.0) if t > 0.022 else 0.0)
    return random.uniform(-1.0, 1.0) * env


# --- The tune -------------------------------------------------------------------

# D major, a looping I - vi - IV - V feel with a lift in the second half.
PROG = [
    (38, [62, 66, 69, 73]),  # Dmaj7
    (35, [62, 66, 69, 71]),  # Bm7
    (43, [62, 67, 71, 74]),  # Gmaj7 (add9 colour)
    (45, [61, 64, 69, 73]),  # A6
    (38, [62, 66, 69, 73]),  # Dmaj7
    (42, [61, 66, 69, 73]),  # F#m7
    (43, [62, 67, 71, 74]),  # Gmaj7
    (45, [61, 64, 67, 69]),  # A7
]
CHORDS = PROG + PROG[:6] + [(40, [64, 67, 71, 74]), (45, [61, 64, 67, 69])]  # ... Em7, A7

# (beat, length in beats, MIDI note) for the marimba hook (first half) and
# the soft synth answer (second half).
MELODY = [
    (0, 0.5, 78), (0.5, 0.5, 81), (1.5, 0.5, 78), (2, 1, 76), (3, 1, 74),
    (4, 0.5, 74), (4.5, 0.5, 76), (5.5, 0.5, 78), (6, 2, 74),
    (8, 0.5, 79), (8.5, 0.5, 78), (9, 0.5, 76), (10, 1, 74), (11, 1, 76),
    (12, 1.5, 76), (13.5, 0.5, 73), (14, 2, 69),
    (16, 0.5, 78), (16.5, 0.5, 81), (17.5, 0.5, 78), (18, 1, 76), (19, 1, 78),
    (20, 0.5, 81), (20.5, 0.5, 78), (21.5, 0.5, 76), (22, 2, 73),
    (24, 0.5, 74), (24.5, 0.5, 76), (25, 1, 79), (26, 1, 78), (27, 1, 76),
    (28, 1.5, 76), (29.5, 0.5, 78), (30, 2, 76),
    (32, 1.5, 81), (33.5, 0.5, 79), (34, 1, 78), (35, 1, 74),
    (36, 2, 76), (38, 1, 78), (39, 1, 81),
    (40, 1.5, 83), (41.5, 0.5, 81), (42, 1, 78), (43, 1, 76),
    (44, 3, 78),
    (48, 1.5, 81), (49.5, 0.5, 79), (50, 1, 78), (51, 1, 81),
    (52, 1.5, 83), (53.5, 0.5, 81), (54, 2, 78),
    (56, 1, 79), (57, 1, 78), (58, 1, 76), (59, 1, 74),
    (60, 2, 73), (62, 1, 76), (63, 1, 73),
]

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 4
    for m in voicing:
        render(b0, BAR + 0.5, pad(mtof(m - 12), BAR * 0.95), 0.04, send=0.7)
    # Bass: root on 1, a pickup octave on the "and" of 2, fifth on 3.
    render(b0, 0.9 * BEAT, bass(mtof(root), 0.8 * BEAT), 0.30, send=0.1)
    render(b0 + 1.5, 0.45 * BEAT, bass(mtof(root + 12), 0.4 * BEAT), 0.16, send=0.1)
    render(b0 + 2, 0.9 * BEAT, bass(mtof(root + 7), 0.8 * BEAT), 0.24, send=0.1)
    render(b0 + 3.5, 0.45 * BEAT, bass(mtof(root + 12), 0.4 * BEAT), 0.14, send=0.1)
    # Marimba comping on the off-beats.
    for k in range(4):
        render(b0 + k + 0.5, 0.6, marimba(mtof(voicing[(k + 1) % 4])), 0.07, send=0.45)
    # Drums: a soft four-on-the-floor kick (the pulse), clap on 2 and 4,
    # shaker eighths.
    for k in range(4):
        render(b0 + k, 0.4, kick, 0.34 if k % 2 == 0 else 0.28, send=0.03)
        render(b0 + k + 0.5, 0.12, make_noise(45.0), 0.06, send=0.25)
        render(b0 + k, 0.08, make_noise(70.0), 0.025, send=0.2)
    for k in (1, 3):
        render(b0 + k, 0.25, clap, 0.09, send=0.35)

for beat, length, note in MELODY:
    if beat < 32:
        render(beat, min(length * BEAT + 1.0, 2.2), marimba(mtof(note)), 0.30, send=0.4)
        render(beat, min(length * BEAT + 0.8, 1.6), marimba(mtof(note - 12)), 0.08, send=0.4)
    else:
        render(beat, length * BEAT + 0.2, synth_lead(mtof(note), length * BEAT * 0.9), 0.11, send=0.5)
        render(beat, min(length * BEAT + 0.9, 1.8), marimba(mtof(note)), 0.14, send=0.45)


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

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_13.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
