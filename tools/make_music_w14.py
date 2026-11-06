"""Composes World 14's calm mining loop, "Magnet Mines", and writes it to
audio/music/world_14.wav (22.05 kHz mono, 16-bit). A chugging but easy-going
tune in G major: a plucked banjo rolling eighth-notes, a steel-drum lead, a
walking "boom-chick" bass and a soft mine-cart shuffle on brushes. Original
music made from plain sine-based instruments, so there is nothing to license.

Run from the project folder:  python tools/make_music_w14.py
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

random.seed(1414)
dry = [0.0] * N
wet = [0.0] * N


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def render(start_beat, seconds, fn, amp, send=0.5):
    """Adds fn(t) for `seconds` from `start_beat`; wraps past the loop end."""
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

def banjo(f):
    """A bright, short pluck: many harmonics that die fast, a little twang."""
    def fn(t):
        att = min(t / 0.002, 1.0)
        bend = 1.0 + 0.004 * math.exp(-t * 30.0)
        v = 0.0
        for k in range(1, 7):
            v += math.sin(TAU * f * bend * k * t) * math.exp(-t * (6.0 + 5.0 * k)) / (k ** 0.8)
        return v * att * 0.7
    return fn


def steeldrum(f):
    """A steel pan: fundamental, octave and a soft twelfth, round and ringing."""
    def fn(t):
        att = min(t / 0.004, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 2.4)
                      + 0.45 * math.sin(TAU * 2.0 * f * t) * math.exp(-t * 3.5)
                      + 0.18 * math.sin(TAU * 3.0 * f * t + 0.4) * math.exp(-t * 6.0)
                      + 0.08 * math.sin(TAU * 4.1 * f * t) * math.exp(-t * 14.0))
    return fn


def pad(f, length):
    def fn(t):
        att = min(t / 0.9, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.7)
        v = (math.sin(TAU * f * 1.003 * t) + math.sin(TAU * f * 0.997 * t)) * 0.5
        v += 0.15 * math.sin(TAU * 2.0 * f * t)
        return v * att * rel
    return fn


def bass(f, length):
    """A plucked upright-ish bass."""
    def fn(t):
        att = min(t / 0.008, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.1)
        return (math.sin(TAU * f * t) + 0.3 * math.sin(TAU * 2.0 * f * t) * math.exp(-t * 6.0)) * att * rel * math.exp(-t * 2.2)
    return fn


def kick(t):
    f = 48.0 + 55.0 * math.exp(-t * 30.0)
    return math.sin(TAU * f * t) * math.exp(-t * 12.0)


def make_noise(decay, tone=0.0):
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]
        prev[0] = x
        return (hp * 0.6 + x * 0.4 + tone * math.sin(TAU * 230.0 * t)) * math.exp(-t * decay)
    return fn


# --- The tune -------------------------------------------------------------------

# (bass root, chord tones) per bar, G major.
PROG = [
    (43, [55, 59, 62, 67]),  # G
    (40, [55, 59, 64, 67]),  # Em
    (36, [55, 60, 64, 67]),  # C
    (38, [54, 57, 62, 66]),  # D
    (43, [55, 59, 62, 67]),  # G
    (47, [54, 59, 62, 66]),  # Bm
    (36, [55, 60, 64, 67]),  # C
    (38, [54, 57, 60, 62]),  # D7
]
CHORDS = PROG + [
    (40, [55, 59, 64, 67]),  # Em
    (36, [55, 60, 64, 67]),  # C
    (43, [55, 59, 62, 67]),  # G
    (38, [54, 57, 62, 66]),  # D
    (36, [55, 60, 64, 67]),  # C
    (38, [54, 57, 62, 66]),  # D
    (43, [55, 59, 62, 67]),  # G
    (38, [54, 57, 60, 62]),  # D7 -> top
]

# (beat, length in beats, MIDI note): a sunny steel-drum line.
MELODY = [
    (0, 1, 74), (1, 0.5, 71), (1.5, 0.5, 74), (2, 2, 79),
    (4, 1, 76), (5, 1, 74), (6, 2, 71),
    (8, 1, 72), (9, 0.5, 74), (9.5, 0.5, 76), (10, 2, 79),
    (12, 1.5, 78), (13.5, 0.5, 76), (14, 2, 74),
    (16, 1, 74), (17, 0.5, 71), (17.5, 0.5, 74), (18, 2, 79),
    (20, 1, 78), (21, 1, 74), (22, 2, 71),
    (24, 1, 72), (25, 1, 76), (26, 1, 79), (27, 1, 76),
    (28, 3, 74),
    # Second half.
    (32, 1.5, 76), (33.5, 0.5, 74), (34, 2, 71),
    (36, 1, 72), (37, 1, 76), (38, 2, 79),
    (40, 1, 81), (41, 1, 79), (42, 1, 74), (43, 1, 71),
    (44, 3, 74),
    (48, 1, 76), (49, 1, 79), (50, 2, 84),
    (52, 1, 81), (53, 1, 78), (54, 2, 74),
    (56, 1.5, 79), (57.5, 0.5, 78), (58, 1, 76), (59, 1, 74),
    (60, 2, 71), (62, 2, 69),
]
ROLL = [0, 2, 3, 1, 2, 3, 0, 3]

for bar, (root, tones) in enumerate(CHORDS):
    b0 = bar * 4
    for m in tones[:3]:
        render(b0, BAR + 0.8, pad(mtof(m), BAR), 0.035, send=0.75)
    # Boom-chick bass: root on 1, fifth on 3, a walking note on the "and" of 4.
    render(b0, BEAT * 1.2, bass(mtof(root), BEAT * 0.9), 0.3, send=0.1)
    render(b0 + 2, BEAT * 1.2, bass(mtof(root + 7 if root < 42 else root - 5), BEAT * 0.9), 0.25, send=0.1)
    render(b0 + 3.5, BEAT * 0.6, bass(mtof(root + 2), BEAT * 0.4), 0.16, send=0.1)
    # The banjo roll on every eighth, quieter in the opening bars.
    lvl = 0.55 if bar < 2 else 1.0
    for k in range(8):
        accent = 1.0 if k % 2 == 0 else 0.7
        render(b0 + k * 0.5, 0.6, banjo(mtof(tones[ROLL[k]] + 12)), 0.07 * accent * lvl, send=0.35)
    # A soft mine-cart shuffle: kick on 1 and 3, brushed chugs on the eighths.
    if bar >= 1:
        render(b0, 0.4, kick, 0.3, send=0.05)
        render(b0 + 2, 0.4, kick, 0.2, send=0.05)
        for b in (1, 3):
            render(b0 + b, 0.2, make_noise(22.0, 0.2), 0.05, send=0.4)
    for k in range(8):
        swing = 0.0 if k % 2 == 0 else 0.06
        render(b0 + k * 0.5 + swing, 0.1, make_noise(48.0), 0.035 if k % 2 == 0 else 0.022, send=0.2)

for beat, length, note in MELODY:
    render(beat, min(length * BEAT + 1.4, 3.0), steeldrum(mtof(note)), 0.2, send=0.45)


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

# Level: aim for the same loudness as the other worlds' loops (RMS ~0.155),
# with a soft knee so the few loudest peaks round off instead of clipping.
rms = math.sqrt(sum(v * v for v in mix) / len(mix)) or 1.0
gain = 0.155 / rms


def soft(x):
    a = abs(x)
    if a < 0.8:
        return x
    return math.copysign(0.8 + 0.19 * math.tanh((a - 0.8) / 0.19), x)


mix = [soft(v * gain) for v in mix]
gain = 1.0

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_14.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
