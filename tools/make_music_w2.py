"""Composes Candy Coast's (World 2) calm, sunny background loop, "Seashell
Sorbet", and writes it to audio/music/world_2.wav (22.05 kHz mono, 16-bit).
Original music from plain sine-based instruments (a soft steel pan, a plucked
ukulele, a calypso bass and hand drums), so there is nothing to license.

Run from the project folder:  python tools/make_music_w2.py
Pure Python (no numpy); takes about a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 96
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(22)
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

def steelpan(f):
    """A soft steel-pan note: a bright octave and a shimmery twelfth that fade
    faster than the fundamental, with a gentle mallet attack."""
    def fn(t):
        att = min(t / 0.006, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 2.2)
                      + 0.45 * math.sin(TAU * 2.0 * f * t + 0.3) * math.exp(-t * 3.4)
                      + 0.16 * math.sin(TAU * 3.01 * f * t) * math.exp(-t * 6.0)
                      + 0.05 * math.sin(TAU * 4.98 * f * t) * math.exp(-t * 14.0))
    return fn


def make_uke(f, seconds):
    """A plucked nylon string (Karplus-Strong), pre-rendered."""
    period = max(2, int(round(SR / f)))
    buf = [random.uniform(-1.0, 1.0) for _ in range(period)]
    # Soften the pluck.
    for k in range(2):
        buf = [(buf[i] + buf[i - 1]) * 0.5 for i in range(period)]
    n = int(seconds * SR)
    out = [0.0] * n
    for i in range(n):
        a = buf[i % period]
        b = buf[(i + 1) % period]
        out[i] = a
        buf[i % period] = (a + b) * 0.5 * 0.996
    def fn(t):
        i = int(t * SR)
        return out[i] if i < n else 0.0
    return fn


def pad(f, length):
    def fn(t):
        att = min(t / 0.9, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.6)
        trem = 0.85 + 0.15 * math.sin(TAU * 0.2 * t)
        v = (math.sin(TAU * f * 1.003 * t) + math.sin(TAU * f * 0.997 * t)) * 0.5
        return v * att * rel * trem
    return fn


def bass(f, length):
    def fn(t):
        att = min(t / 0.01, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.08)
        return (math.sin(TAU * f * t) + 0.3 * math.sin(TAU * 2.0 * f * t)) * att * rel * math.exp(-t * 2.0)
    return fn


def conga(f):
    def fn(t):
        g = f * (1.0 + 0.25 * math.exp(-t * 40.0))
        return math.sin(TAU * g * t) * math.exp(-t * 14.0)
    return fn


def kick(t):
    f = 50.0 + 60.0 * math.exp(-t * 32.0)
    return math.sin(TAU * f * t) * math.exp(-t * 12.0)


def make_shaker():
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]
        prev[0] = x
        env = min(t / 0.01, 1.0) * math.exp(-t * 32.0)
        return hp * env
    return fn


# --- The tune -------------------------------------------------------------------

# G major, a sunny I-vi-IV-V with a little detour; (bass root, pad voicing).
PROG = [
    (43, [59, 62, 66, 67]),  # Gmaj7
    (40, [59, 62, 64, 67]),  # Em7
    (36, [59, 60, 64, 67]),  # Cmaj7
    (38, [57, 60, 62, 66]),  # D7
    (43, [59, 62, 66, 67]),  # Gmaj7
    (47, [57, 59, 62, 66]),  # Bm7
    (36, [59, 60, 64, 67]),  # Cmaj7
    (45, [57, 60, 64, 67]),  # Am7
]
CHORDS = PROG + PROG[:7] + [(38, [57, 60, 62, 66])]  # ... D7 back to the top

# (beat, length in beats, MIDI note): a lazy, singable pan tune.
MELODY = [
    (0, 1, 74), (1, 0.5, 71), (1.5, 1, 74), (2.5, 1.5, 76),
    (4, 1, 74), (5, 0.5, 71), (5.5, 1.5, 67), (7, 1, 69),
    (8, 1.5, 72), (9.5, 0.5, 71), (10, 1, 69), (11, 1, 67),
    (12, 2, 69), (14, 1, 66), (15, 1, 69),
    (16, 1, 74), (17, 0.5, 71), (17.5, 1, 74), (18.5, 1.5, 79),
    (20, 1, 78), (21, 0.5, 74), (21.5, 1.5, 71), (23, 1, 74),
    (24, 1.5, 76), (25.5, 0.5, 74), (26, 1, 72), (27, 1, 71),
    (28, 3, 69), (31, 1, 71),
    # Second half: up a little, then home.
    (32, 1, 79), (33, 0.5, 78), (33.5, 1, 76), (34.5, 1.5, 74),
    (36, 1, 71), (37, 0.5, 74), (37.5, 1.5, 76), (39, 1, 74),
    (40, 1.5, 76), (41.5, 0.5, 79), (42, 1, 76), (43, 1, 72),
    (44, 2, 74), (46, 1, 78), (47, 1, 76),
    (48, 1, 74), (49, 0.5, 71), (49.5, 1, 74), (50.5, 1.5, 76),
    (52, 1, 74), (53, 0.5, 71), (53.5, 1.5, 69), (55, 1, 71),
    (56, 1.5, 72), (57.5, 0.5, 71), (58, 1, 69), (59, 1, 72),
    (60, 2, 69), (62, 2, 66),
]
# Ukulele strum: a calypso "down, down-up, up-down-up" on the voicing.
STRUM = [0, 1.5, 2, 3, 3.5]
CONGA = [(0.5, 0), (1.5, 1), (2.5, 0), (3, 1), (3.5, 1)]

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 4
    for m in voicing:
        render(b0, BAR + 0.7, pad(mtof(m), BAR), 0.035, send=0.75)
    # Calypso bass: root, a pushed fifth, root an octave up.
    render(b0, 1.2 * BEAT, bass(mtof(root), 1.0 * BEAT), 0.30, send=0.12)
    render(b0 + 1.5, 0.9 * BEAT, bass(mtof(root + 7), 0.7 * BEAT), 0.22, send=0.12)
    render(b0 + 2, 1.2 * BEAT, bass(mtof(root + 12), 1.0 * BEAT), 0.24, send=0.12)
    render(b0 + 3.5, 0.6 * BEAT, bass(mtof(root + 7), 0.4 * BEAT), 0.16, send=0.12)
    for k, sb in enumerate(STRUM):
        acc = 1.0 if k in (0, 2) else 0.7
        for s, m in enumerate(voicing):
            render(b0 + sb + s * 0.035, 0.9, make_uke(mtof(m), 0.9), 0.05 * acc, send=0.4)
    render(b0, 0.5, kick, 0.26, send=0.05)
    render(b0 + 2, 0.5, kick, 0.16, send=0.05)
    for sb, hi in CONGA:
        render(b0 + sb, 0.3, conga(330.0 if hi else 220.0), 0.07, send=0.3)
    for k in range(8):
        render(b0 + k * 0.5, 0.15, make_shaker(), 0.045 if k % 2 else 0.025, send=0.3)

for beat, length, note in MELODY:
    render(beat, min(length * BEAT + 1.4, 2.6), steelpan(mtof(note)), 0.26, send=0.5)
    # A soft echo an octave below on the long notes.
    if length >= 1.5:
        render(beat + 0.75, 1.6, steelpan(mtof(note - 12)), 0.06, send=0.8)


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

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_2.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
