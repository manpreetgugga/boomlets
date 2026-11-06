"""Composes World 18's lazy desert loop, "Domino Dunes", and writes it to
audio/music/world_18.wav (22.05 kHz mono, 16-bit). A warm lilt in D
Phrygian dominant at an easy walking pace: a plucked oud (a round, woody
pluck with a little slide into each note) rolling gentle broken chords, a
breathy ney-like reed melody that enters in bar 5, a low drone, a soft
bass, frame-drum "doum" and "tek" hand drums with a light swing, and tiny
finger-cymbal chimes over the last bars. Calm and loopable; original music
made from plain sine-based instruments, so there is nothing to license.

Run from the project folder:  python tools/make_music_w18.py
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
SWING = 0.07   # beats the off-beat eighths lean late

random.seed(1818)
dry = [0.0] * N
wet = [0.0] * N


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def render(start_beat, seconds, fn, amp, send=0.5):
    """Adds fn(t) for `seconds` from `start_beat` into the dry and wet buses,
    wrapping past the loop end so ringing notes still loop."""
    s0 = int(round(start_beat * BEAT * SR))
    n = int(seconds * SR)
    for i in range(n):
        j = s0 + i
        if j >= N:
            j -= LOOP_N
        v = fn(i / SR) * amp
        dry[j] += v * (1.0 - send)
        wet[j] += v * send


def swing(beat):
    """Pushes off-beat eighths a little late for a lazy lilt."""
    frac = beat - math.floor(beat)
    return beat + (SWING if abs(frac - 0.5) < 1e-6 else 0.0)


# --- Instruments --------------------------------------------------------------

def oud(f):
    """A fretless plucked lute: round low harmonics, a quick slide up into the
    note and a woody body knock at the attack."""
    def fn(t):
        att = min(t / 0.003, 1.0)
        slide = 1.0 - 0.018 * math.exp(-t * 30.0)
        v = 0.0
        for k, w in ((1, 1.0), (2, 0.55), (3, 0.32), (4, 0.18), (5, 0.08)):
            v += w * math.sin(TAU * f * k * slide * t) * math.exp(-t * (2.6 + 1.6 * k))
        body = math.sin(TAU * 210.0 * t) * math.exp(-t * 45.0) * 0.25
        return (v + body) * att
    return fn


def ney(f, length):
    """A breathy reed flute: slow attack, gentle vibrato, airy noise."""
    def fn(t):
        att = min(t / 0.12, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.3)
        vib = 1.0 + 0.007 * min(max(t - 0.2, 0.0) / 0.5, 1.0) * math.sin(TAU * 4.6 * t)
        ph = TAU * f * vib * t
        tone = math.sin(ph) + 0.3 * math.sin(2.0 * ph) + 0.1 * math.sin(3.0 * ph)
        breath = random.uniform(-1.0, 1.0) * 0.09 * (0.5 + 0.5 * math.exp(-t * 5.0))
        return (tone + breath) * att * rel
    return fn


def drone(f, length):
    def fn(t):
        att = min(t / 1.5, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 1.2)
        trem = 0.85 + 0.15 * math.sin(TAU * 0.2 * t)
        v = 0.0
        for d in (0.997, 1.0, 1.003):
            v += math.sin(TAU * f * d * t) + 0.3 * math.sin(TAU * 2.0 * f * d * t) + 0.12 * math.sin(TAU * 3.0 * f * d * t)
        return v / 3.0 * att * rel * trem
    return fn


def bass(f, length):
    def fn(t):
        att = min(t / 0.02, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.15)
        return (math.sin(TAU * f * t) + 0.2 * math.sin(TAU * 2.0 * f * t)) * att * rel * math.exp(-t * 1.5)
    return fn


def doum(t):
    """The deep centre hit of a frame drum."""
    f = 70.0 + 45.0 * math.exp(-t * 25.0)
    return math.sin(TAU * f * t) * math.exp(-t * 7.0) + random.uniform(-1, 1) * 0.08 * math.exp(-t * 50.0)


def make_tek():
    """The bright rim tap of a frame drum."""
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]
        prev[0] = x
        ring = math.sin(TAU * 820.0 * t) * math.exp(-t * 60.0) * 0.5
        return (hp * 0.6 * math.exp(-t * 70.0) + ring) * min(t / 0.002, 1.0)
    return fn


def zill(f):
    """A tiny finger cymbal chime."""
    def fn(t):
        att = min(t / 0.002, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 3.0) + 0.5 * math.sin(TAU * f * 2.41 * t) * math.exp(-t * 5.0)
                      + 0.3 * math.sin(TAU * f * 3.87 * t) * math.exp(-t * 7.0))
    return fn


# --- The tune -------------------------------------------------------------------

# D Phrygian dominant: D Eb F# G A Bb C. (bass root, oud chord) per bar.
PROG = [
    (50, [62, 66, 69, 74]),  # D
    (50, [62, 66, 69, 74]),  # D
    (51, [63, 67, 70, 75]),  # Eb
    (50, [62, 66, 69, 74]),  # D
    (43, [62, 67, 70, 74]),  # Gm
    (48, [60, 63, 67, 72]),  # Cm
    (51, [63, 67, 70, 75]),  # Eb
    (50, [62, 66, 69, 74]),  # D, home
]
CHORDS = PROG + PROG

# (beat, length in beats, MIDI note) for the reed; it enters in bar 5 and
# sings a little higher in the last four bars.
MELODY = [
    (16, 1.5, 74), (17.5, 0.5, 75), (18, 1, 74), (19, 1, 72),
    (20, 2, 70), (22, 1, 72), (23, 1, 70),
    (24, 1.5, 67), (25.5, 0.5, 70), (26, 1, 69), (27, 1, 67),
    (28, 3, 66),
    (32, 1, 69), (33, 1, 70), (34, 2, 74),
    (36, 1, 75), (37, 1, 74), (38, 2, 72),
    (40, 1.5, 70), (41.5, 0.5, 72), (42, 1, 70), (43, 1, 67),
    (44, 3, 69),
    (48, 1, 74), (49, 1, 78), (50, 2, 79),
    (52, 1, 78), (53, 1, 75), (54, 2, 74),
    (56, 1.5, 72), (57.5, 0.5, 70), (58, 1, 67), (59, 1, 66),
    (60, 3, 62),
]
# Oud broken chord: chord indexes, one per eighth.
ARP = [0, 2, 1, 3, 2, 1, 2, 3]

for bar, (root, chord) in enumerate(CHORDS):
    b0 = bar * 4
    # A low drone on D and A under everything.
    if bar % 2 == 0:
        render(b0, BAR * 2 + 1.5, drone(mtof(38), BAR * 2), 0.05, send=0.7)
        render(b0, BAR * 2 + 1.5, drone(mtof(45), BAR * 2), 0.03, send=0.7)
    # Oud: softer at first, a fuller pick pattern from bar 5.
    lvl = 0.7 if bar < 4 else 1.0
    for k in range(8):
        if bar < 4 and k in (3, 7):
            continue
        note = chord[ARP[k]]
        accent = 1.0 if k in (0, 3, 6) else 0.7
        render(swing(b0 + k * 0.5), 1.4, oud(mtof(note)), 0.085 * accent * lvl, send=0.45)
    render(b0, 2.2, oud(mtof(root + 12)), 0.09, send=0.35)
    if bar >= 4:
        render(b0, BAR * 0.9, bass(mtof(root), BAR * 0.6), 0.2, send=0.1)
        render(b0 + 2.5, BEAT, bass(mtof(root + 7 if root + 7 <= 55 else root - 5), BEAT * 0.7), 0.12, send=0.1)
    # Hand drums: doum on 1 and the "and" of 3, teks around them, from bar 3.
    if bar >= 2:
        render(b0, 0.6, doum, 0.32, send=0.15)
        render(swing(b0 + 2.5), 0.6, doum, 0.22, send=0.15)
        for beat, a in ((1.0, 0.12), (1.5, 0.08), (3.0, 0.12), (3.5, 0.08)):
            render(swing(b0 + beat), 0.12, make_tek(), a, send=0.25)
        if bar % 4 == 3:
            render(swing(b0 + 3.5), 0.4, doum, 0.16, send=0.15)
    # Finger cymbals over the last bars.
    if bar >= 12:
        render(b0 + 1.0, 1.5, zill(2350.0), 0.03, send=0.7)
        render(b0 + 3.0, 1.5, zill(2350.0 * 1.06), 0.025, send=0.7)

for beat, length, note in MELODY:
    render(beat, length * BEAT + 0.5, ney(mtof(note), length * BEAT), 0.15, send=0.5)
    # The oud doubles the melody an octave down in the finale.
    if beat >= 48:
        render(beat, 1.4, oud(mtof(note - 12)), 0.06, send=0.45)


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

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_18.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
