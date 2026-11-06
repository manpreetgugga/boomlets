"""Composes World 20's calm loop, "Pixel Arcade", and writes it to
audio/music/world_20.wav (22.05 kHz mono, 16-bit). A gentle chiptune in
F major: a soft 12.5% pulse arpeggio, a round triangle-wave bass, a mellow
square-wave lead with a little delayed vibrato, a quiet echo voice an octave
up, a chip "kick" (a triangle pitch drop) and a hushed noise hat. It starts
with just arpeggio and bass, the lead joins in bar 5, the drums in bar 9,
and the last bars add a counter-line before it settles back to the start.
The oscillators are band-limited (a handful of harmonics), so the chip
tones stay soft instead of harsh. Original music, nothing to license.

Run from the project folder:  python tools/make_music_w20.py
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
TAIL_N = int(2.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(2020)
dry = [0.0] * N
wet = [0.0] * N


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def render(start_beat, seconds, fn, amp, send=0.3):
    s0 = int(round(start_beat * BEAT * SR))
    n = int(seconds * SR)
    for i in range(n):
        j = s0 + i
        if j >= N:
            j -= LOOP_N
        v = fn(i / SR) * amp
        dry[j] += v * (1.0 - send)
        wet[j] += v * send


# --- Oscillators -----------------------------------------------------------------

def pulse_table(duty, f):
    """(harmonic, amplitude, phase) for a band-limited pulse wave, rolled off
    a little so it sounds soft."""
    out = []
    k = 1
    while k * f < 5500.0 and k <= 9:
        a = 2.0 / (k * math.pi) * math.sin(k * math.pi * duty) / (k ** 0.35)
        out.append((k, a, -k * math.pi * duty))
        k += 1
    return out


def pulse(f, length, duty=0.5, vib=0.0, att=0.006, rel=0.06, decay=0.0):
    table = pulse_table(duty, f)

    def fn(t):
        a = min(t / att, 1.0)
        r = 1.0 if t < length else max(0.0, 1.0 - (t - length) / rel)
        if r <= 0.0:
            return 0.0
        v_amt = vib * min(max(t - 0.2, 0.0) / 0.3, 1.0)
        ph = TAU * f * t + v_amt * math.sin(TAU * 5.2 * t) / 5.2 * f * 0.01
        v = 0.0
        for k, amp, p0 in table:
            v += amp * math.cos(k * ph + p0)
        env = a * r * (math.exp(-t * decay) if decay > 0.0 else 1.0)
        return v * env
    return fn


def triangle(f, length, rel=0.05):
    def fn(t):
        a = min(t / 0.004, 1.0)
        r = 1.0 if t < length else max(0.0, 1.0 - (t - length) / rel)
        v = 0.0
        for idx, k in enumerate((1, 3, 5, 7)):
            v += (-1) ** idx * math.sin(TAU * f * k * t) / (k * k)
        return v * 0.81 * a * r
    return fn


def kick(t):
    f = 55.0 + 110.0 * math.exp(-t * 28.0)
    ph = TAU * (55.0 * t + 110.0 * (1.0 - math.exp(-t * 28.0)) / 28.0)
    v = 0.0
    for idx, k in enumerate((1, 3, 5)):
        v += (-1) ** idx * math.sin(k * ph) / (k * k)
    return v * math.exp(-t * 10.0)


def make_hat(decay):
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]
        prev[0] = x
        return hp * math.exp(-t * decay) * min(t / 0.002, 1.0)
    return fn


# --- The tune ------------------------------------------------------------------------

# (bass root, chord tones for the arpeggio) per bar, F major.
PROG = [
    (41, [65, 69, 72, 77]),  # F
    (38, [62, 65, 69, 74]),  # Dm
    (46, [65, 70, 74, 77]),  # Bb
    (48, [64, 67, 72, 76]),  # C
    (41, [65, 69, 72, 77]),  # F
    (45, [64, 69, 72, 76]),  # Am
    (46, [65, 70, 74, 77]),  # Bb
    (48, [65, 67, 72, 77]),  # Csus4
]
CHORDS = PROG + PROG

# (beat, beats, note) for the lead: enters in bar 5.
MELODY = [
    (16, 1, 72), (17, 0.5, 74), (17.5, 0.5, 76), (18, 2, 77),
    (20, 1, 76), (21, 1, 74), (22, 2, 72),
    (24, 1.5, 70), (25.5, 0.5, 72), (26, 1, 74), (27, 1, 72),
    (28, 3, 72),
    (32, 1, 77), (33, 0.5, 76), (33.5, 0.5, 74), (34, 2, 72),
    (36, 1, 76), (37, 1, 72), (38, 2, 69),
    (40, 1.5, 70), (41.5, 0.5, 74), (42, 1, 77), (43, 1, 74),
    (44, 3, 76),
    (48, 1, 72), (49, 0.5, 74), (49.5, 0.5, 76), (50, 2, 77),
    (52, 1, 79), (53, 1, 77), (54, 2, 76),
    (56, 1, 74), (57, 1, 76), (58, 1, 77), (59, 1, 79),
    (60, 3, 77),
]
# Counter-line in the last four bars (high, sparse).
COUNTER = [(48.5, 0.5, 84), (50.5, 0.5, 81), (52.5, 0.5, 86), (54.5, 0.5, 84),
           (56.5, 0.5, 82), (58.5, 0.5, 81), (60.5, 0.5, 84), (62, 1, 89)]
ARP = [0, 1, 2, 3, 2, 1, 2, 3]

for bar, (root, tones) in enumerate(CHORDS):
    b0 = bar * 4
    lvl = 0.75 if bar < 4 else 1.0
    for k in range(8):
        note = tones[ARP[k]]
        render(b0 + k * 0.5, BEAT * 0.5 + 0.1, pulse(mtof(note), BEAT * 0.38, duty=0.125, decay=3.0), 0.05 * lvl, send=0.35)
    # Triangle bass: root on 1, octave bounce on the "and" of 2, fifth on 3.
    render(b0, BEAT * 1.4, triangle(mtof(root), BEAT * 1.3), 0.3)
    render(b0 + 1.5, BEAT * 0.5, triangle(mtof(root + 12), BEAT * 0.4), 0.2)
    render(b0 + 2, BEAT * 1.4, triangle(mtof(root + 7), BEAT * 1.3), 0.26)
    render(b0 + 3.5, BEAT * 0.5, triangle(mtof(root + 12), BEAT * 0.4), 0.18)
    if bar >= 8:
        render(b0, 0.3, kick, 0.34, send=0.05)
        render(b0 + 2, 0.3, kick, 0.26, send=0.05)
        for k in range(4):
            render(b0 + k + 0.5, 0.06, make_hat(70.0), 0.03, send=0.2)
        if bar == 15:
            render(b0 + 3, 0.3, kick, 0.2, send=0.05)
            render(b0 + 3.5, 0.3, kick, 0.24, send=0.05)

for beat, length, note in MELODY:
    render(beat, length * BEAT + 0.1, pulse(mtof(note), length * BEAT * 0.92, duty=0.5, vib=1.0, att=0.01, rel=0.08), 0.085, send=0.4)
    # A quiet echo an octave up, an eighth late.
    render(beat + 0.75, length * BEAT * 0.6 + 0.1, pulse(mtof(note + 12), length * BEAT * 0.5, duty=0.25, att=0.01, rel=0.08, decay=2.0), 0.022, send=0.6)

for beat, length, note in COUNTER:
    render(beat, length * BEAT + 0.2, pulse(mtof(note), length * BEAT, duty=0.25, att=0.005, rel=0.1, decay=4.0), 0.04, send=0.6)


# --- A small room reverb --------------------------------------------------------------

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
    c = comb(wet, d, 0.8, 0.35)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.6 + rev[i] * 0.45 for i in range(N)]

# Fold the tail back onto the start so the loop is seamless.
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

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_20.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
