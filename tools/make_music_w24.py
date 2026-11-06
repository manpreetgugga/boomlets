"""Composes World 24's misty loop, "Mirror Marsh", and writes it to
audio/music/world_24.wav (22.05 kHz mono, 16-bit). A slow, calm tune in
E minor (Dorian colour): a soft harp plays rising arpeggios, then answers
each one with its mirror image falling back down; a breathy flute sings a
phrase and then its reflection (the same intervals turned upside down
round the same note). A hazy pad, a low harp bass and a faint wind-chime
shimmer keep it misty. Original music made from plain sine-based
instruments, so there is nothing to license.

Run from the project folder:  python tools/make_music_w24.py
Pure Python (no numpy); takes about a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 66
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(4.0 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(2424)
dry = [0.0] * N
wet = [0.0] * N


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def render(start_beat, seconds, fn, amp, send=0.5):
    """Adds fn(t) for `seconds` from `start_beat`; wraps past the loop end so
    ringing notes loop cleanly."""
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

def harp(f):
    """A soft harp pluck: a warm fundamental, gentle upper partials that fade
    first, and a slow ring."""
    def fn(t):
        att = min(t / 0.006, 1.0)
        v = math.sin(TAU * f * t) * math.exp(-t * 1.6)
        v += 0.35 * math.sin(TAU * 2.0 * f * t) * math.exp(-t * 3.2)
        v += 0.12 * math.sin(TAU * 3.0 * f * t) * math.exp(-t * 6.0)
        v += 0.05 * math.sin(TAU * 4.0 * f * t) * math.exp(-t * 10.0)
        return v * att
    return fn


def flute(f, length):
    """A soft, breathy flute with a slow vibrato."""
    def fn(t):
        att = min(t / 0.14, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.35)
        vib = 1.0 + 0.005 * min(max(t - 0.3, 0.0) / 0.5, 1.0) * math.sin(TAU * 4.6 * t)
        ph = TAU * f * vib * t
        tone = math.sin(ph) + 0.16 * math.sin(2.0 * ph) + 0.04 * math.sin(3.0 * ph)
        breath = random.uniform(-1.0, 1.0) * 0.06 * (0.35 + 0.65 * math.exp(-t * 5.0))
        return (tone + breath) * att * rel
    return fn


def pad(f, length):
    """A hazy pad that swells in and out like mist."""
    def fn(t):
        att = min(t / 1.8, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 1.4)
        trem = 0.8 + 0.2 * math.sin(TAU * 0.11 * t)
        v = 0.0
        for d in (0.995, 1.0, 1.005):
            v += math.sin(TAU * f * d * t) + 0.2 * math.sin(TAU * 2.0 * f * d * t)
        return v / 3.0 * att * rel * trem
    return fn


def chime(f):
    def fn(t):
        att = min(t / 0.002, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 2.5) + 0.3 * math.sin(TAU * f * 2.92 * t) * math.exp(-t * 5.0))
    return fn


# --- The tune -------------------------------------------------------------------

# (bass root, voicing) per bar: Em9, Cmaj7, G, D(add9)/F#, Em, Am7, Cmaj7, Bsus4.
PROG = [
    (40, [52, 55, 59, 62, 66]),
    (36, [48, 52, 55, 59, 64]),
    (43, [50, 55, 59, 62, 67]),
    (42, [50, 54, 57, 62, 64]),
    (40, [52, 55, 59, 62, 67]),
    (45, [52, 55, 57, 60, 64]),
    (36, [48, 55, 59, 60, 64]),
    (47, [52, 54, 59, 63, 66]),
]
CHORDS = PROG + PROG

# The flute's phrase, and its mirror: the same rhythm with every interval
# turned upside down round the axis note (E5 = 76), like a reflection in
# still water.
AXIS = 76
PHRASE = [(0, 1.5, 76), (1.5, 0.5, 79), (2, 2, 81), (4, 1, 83), (5, 1, 81), (6, 2, 79)]
PHRASE2 = [(0, 1.5, 78), (1.5, 0.5, 79), (2, 1, 81), (3, 1, 79), (4, 4, 76)]


def mirror(phrase):
    return [(b, l, 2 * AXIS - m) for (b, l, m) in phrase]


def snap(m):
    """Keeps a mirrored note in E minor (Dorian): nudges stray notes."""
    scale = {4, 6, 7, 9, 11, 1, 2}   # E F# G A B C# D
    pc = m % 12
    if pc in scale:
        return m
    return m + 1 if (pc + 1) % 12 in scale else m - 1


MELODY = []
for start, phrase in ((16, PHRASE), (24, mirror(PHRASE)), (32, PHRASE2), (40, mirror(PHRASE2)),
                      (48, PHRASE), (56, mirror(PHRASE2))):
    for b, l, m in phrase:
        MELODY.append((start + b, l, snap(m)))

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 4
    for m in voicing[:4]:
        render(b0, BAR + 1.5, pad(mtof(m), BAR), 0.03 if bar < 4 else 0.04, send=0.85)
    # Harp: up the chord in eighths for two beats, then the mirror image
    # back down.
    up = [voicing[k] + 12 for k in range(5)]
    seq = up[:4] + [up[4]] + up[3:0:-1]
    lvl = 0.7 if bar < 4 else 1.0
    for k, m in enumerate(seq[:8]):
        accent = 1.0 if k in (0, 4) else 0.72
        render(b0 + k * 0.5, 2.6, harp(mtof(m)), 0.07 * accent * lvl, send=0.6)
    # A low harp root on each downbeat and a soft fifth on beat three.
    render(b0, 3.0, harp(mtof(root + 12)), 0.1, send=0.45)
    if bar >= 4:
        render(b0 + 2, 2.4, harp(mtof(root + 19)), 0.06, send=0.45)
    # Wind chimes drift in now and then from bar 9.
    if bar >= 8 and bar % 2 == 0:
        for k, beat in enumerate((0.5, 2.25, 3.5)):
            render(b0 + beat, 2.4, chime(mtof(voicing[(bar + k) % 5] + 24)), 0.03, send=0.8)

for beat, length, note in MELODY:
    render(beat, length * BEAT + 0.6, flute(mtof(note), length * BEAT), 0.15, send=0.55)


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
for d in (1201, 1277, 1361, 1439):
    c = comb(wet, d, 0.88, 0.35)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.5 + rev[i] * 0.7 for i in range(N)]

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

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_24.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
