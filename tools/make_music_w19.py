"""Composes World 19's playful lab loop, "Slime Lab", and writes it to
audio/music/world_19.wav (22.05 kHz mono, 16-bit). A bouncy, quirky tune
in F major at an easy pace: a bright marimba-like synth pluck bouncing
through broken chords, a soft round bass, bubbly "bloop" blips that rise in
pitch, a gentle square-ish lead that enters in bar 5 with little chromatic
slides, and a light kit (soft kick, ticking hats, a tiny finger snap).
Calm and loopable; original music made from plain sine-based instruments,
so there is nothing to license.

Run from the project folder:  python tools/make_music_w19.py
Pure Python (no numpy); takes about a minute.
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
BARS = 20
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.0 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(1919)
dry = [0.0] * N
wet = [0.0] * N


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def render(start_beat, seconds, fn, amp, send=0.4):
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


# --- Instruments --------------------------------------------------------------

def pluck(f):
    """A soft marimba-like synth pluck: a woody fundamental, a bright
    fourth-harmonic tick that dies at once, and a short round tail."""
    def fn(t):
        att = min(t / 0.002, 1.0)
        v = math.sin(TAU * f * t) * math.exp(-t * 5.5)
        v += 0.35 * math.sin(TAU * f * 4.0 * t) * math.exp(-t * 28.0)
        v += 0.18 * math.sin(TAU * f * 2.0 * t) * math.exp(-t * 9.0)
        return v * att
    return fn


def bloop(f):
    """A bubble: a sine that swoops up an octave and pops."""
    def fn(t):
        att = min(t / 0.004, 1.0)
        ph = TAU * f * (t + 1.6 * t * t / 0.12) if t < 0.12 else TAU * f * (0.12 + 1.6 * 0.12) + TAU * f * 2.6 * (t - 0.12)
        return math.sin(ph) * att * math.exp(-t * 16.0)
    return fn


def bass(f, length):
    def fn(t):
        att = min(t / 0.015, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.1)
        v = math.sin(TAU * f * t) + 0.25 * math.sin(TAU * 2.0 * f * t) * math.exp(-t * 6.0)
        return v * att * rel * math.exp(-t * 1.2)
    return fn


def lead(f, length, slide_from=None):
    """A gentle square-ish lead: odd harmonics kept low, slow vibrato and an
    optional little slide up into the note."""
    def fn(t):
        att = min(t / 0.02, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.12)
        g = f
        if slide_from is not None:
            k = min(t / 0.08, 1.0)
            g = slide_from + (f - slide_from) * k
        vib = 1.0 + 0.005 * min(max(t - 0.15, 0.0) / 0.3, 1.0) * math.sin(TAU * 5.5 * t)
        ph = TAU * g * vib * t
        v = math.sin(ph) + 0.22 * math.sin(3.0 * ph) + 0.08 * math.sin(5.0 * ph)
        return v * att * rel
    return fn


def kick(t):
    f = 55.0 + 70.0 * math.exp(-t * 30.0)
    return math.sin(TAU * f * t) * math.exp(-t * 9.0)


def make_hat():
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]
        prev[0] = x
        return hp * math.exp(-t * 90.0) * min(t / 0.001, 1.0)
    return fn


def make_snap():
    def fn(t):
        n = random.uniform(-1.0, 1.0) * math.exp(-t * 45.0)
        tone = math.sin(TAU * 1800.0 * t) * math.exp(-t * 60.0) * 0.4
        return (n * 0.7 + tone) * min(t / 0.001, 1.0)
    return fn


# --- The tune -------------------------------------------------------------------

# (bass root, pluck chord) per bar, F major with a couple of colour chords.
F = (41, [65, 69, 72, 77])
DM = (38, [62, 65, 69, 74])
BB = (46, [62, 65, 70, 74])
C = (36, [60, 64, 67, 72])
AM = (45, [60, 64, 69, 72])
GM = (43, [62, 67, 70, 74])
D7 = (38, [60, 62, 66, 69])
CHORDS = [F, DM, BB, C,
          F, DM, BB, C,
          F, AM, BB, C,
          GM, D7, GM, C,
          BB, C, F, C]

# (beat, beats long, MIDI note, slide from note or None) for the lead.
MELODY = [
    (16, 0.5, 72, None), (16.5, 0.5, 74, None), (17, 1, 77, None), (18, 0.5, 76, None), (18.5, 1.5, 72, None),
    (20, 0.5, 74, None), (20.5, 0.5, 72, None), (21, 1, 69, None), (22, 2, 65, None),
    (24, 0.5, 70, None), (24.5, 0.5, 69, None), (25, 1, 70, None), (26, 0.5, 74, None), (26.5, 1.5, 77, 76),
    (28, 1, 76, None), (29, 1, 72, None), (30, 2, 67, None),
    (32, 0.5, 72, None), (32.5, 0.5, 74, None), (33, 1, 77, None), (34, 0.5, 79, None), (34.5, 1.5, 81, 80),
    (36, 1, 79, None), (37, 1, 76, None), (38, 2, 72, None),
    (40, 1, 74, None), (41, 0.5, 77, None), (41.5, 0.5, 74, None), (42, 2, 70, None),
    (44, 1, 72, None), (45, 1, 76, None), (46, 2, 79, None),
    (48, 1.5, 79, None), (49.5, 0.5, 77, None), (50, 2, 74, None),
    (52, 1, 72, None), (53, 1, 74, None), (54, 2, 78, 77),
    (56, 1.5, 79, None), (57.5, 0.5, 77, None), (58, 1, 74, None), (59, 1, 70, None),
    (60, 3, 72, None),
    (64, 1, 74, None), (65, 1, 72, None), (66, 2, 70, None),
    (68, 1, 72, None), (69, 1, 74, None), (70, 2, 76, None),
    (72, 0.5, 77, None), (72.5, 0.5, 76, None), (73, 1, 72, None), (74, 2, 69, None),
    (76, 1, 72, None), (77, 1, 67, None), (78, 2, 72, None),
]
# Pluck pattern: chord tone index per eighth, None for a rest.
PATTERN = [0, 2, 1, 3, None, 2, 1, 2]

for bar, (root, chord) in enumerate(CHORDS):
    b0 = bar * 4
    lvl = 0.7 if bar < 4 else 1.0
    for k, idx in enumerate(PATTERN):
        if idx is None:
            continue
        accent = 1.0 if k in (0, 3, 6) else 0.7
        render(b0 + k * 0.5, 0.9, pluck(mtof(chord[idx])), 0.11 * accent * lvl, send=0.35)
    # Soft round bass from bar 3: root, a bounce up the fifth, root again.
    if bar >= 2:
        render(b0, BEAT * 1.4, bass(mtof(root), BEAT * 1.1), 0.24, send=0.08)
        render(b0 + 1.5, BEAT * 0.6, bass(mtof(root + 7), BEAT * 0.4), 0.14, send=0.08)
        render(b0 + 2.5, BEAT * 1.4, bass(mtof(root + 12 if root < 40 else root), BEAT * 1.1), 0.18, send=0.08)
    # Light kit from bar 5.
    if bar >= 4:
        render(b0, 0.4, kick, 0.3, send=0.05)
        render(b0 + 2.5, 0.4, kick, 0.18, send=0.05)
        for e in range(8):
            render(b0 + e * 0.5, 0.06, make_hat(), 0.05 if e % 2 else 0.035, send=0.15)
        render(b0 + 1, 0.15, make_snap(), 0.09, send=0.3)
        render(b0 + 3, 0.15, make_snap(), 0.09, send=0.3)
    # Bubbles: a couple of rising bloops each bar on off-beats.
    for _ in range(2 if bar >= 4 else 1):
        beat = b0 + random.choice([0.75, 1.75, 2.25, 3.25, 3.75])
        render(beat, 0.25, bloop(mtof(random.choice(chord) + 12)), 0.06, send=0.6)

for beat, length, note, slide in MELODY:
    render(beat, length * BEAT + 0.3, lead(mtof(note), length * BEAT, mtof(slide) if slide else None), 0.1, send=0.4)
    # The pluck doubles the tune an octave up near the end, sparkly.
    if beat >= 64:
        render(beat, 0.8, pluck(mtof(note + 12)), 0.05, send=0.5)


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
    c = comb(wet, d, 0.82, 0.35)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.55 + rev[i] * 0.55 for i in range(N)]

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

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_19.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
