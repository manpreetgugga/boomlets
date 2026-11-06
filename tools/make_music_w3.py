"""Composes World 3's loop, "Canyon Cocoa Trot", and writes it to
audio/music/world_3.wav (22.05 kHz mono, 16-bit). A calm, warm, slightly
western tune in D minor: a plucked boom-chick guitar on an Andalusian
progression, a breathy whistle lead with a canyon echo, a soft clip-clop
woodblock and a shaker. Original music from plain synthesised instruments
(plucked strings are Karplus-Strong), so there is nothing to license.

Run from the project folder:  python tools/make_music_w3.py
Pure Python (no numpy); takes under a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 76
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(33)
dry = [0.0] * N      # instruments that stay dry-ish
wet = [0.0] * N      # sent to the reverb
echo_bus = [0.0] * N  # the whistle's canyon echo


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def add(start_sec, samples, amp, send=0.4, echo=0.0):
    s0 = int(round(start_sec * SR))
    for i, v in enumerate(samples):
        j = s0 + i
        if j >= N:
            break
        v *= amp
        dry[j] += v * (1.0 - send)
        wet[j] += v * send
        if echo:
            echo_bus[j] += v * echo


def render(start_beat, seconds, fn, amp, send=0.4, echo=0.0):
    n = int(seconds * SR)
    add(start_beat * BEAT, [fn(i / SR) for i in range(n)], amp, send, echo)


# --- Instruments --------------------------------------------------------------

def pluck(f, seconds, bright=0.5, decay=0.996):
    """Karplus-Strong plucked string: a warm nylon-ish guitar."""
    period = max(2, int(round(SR / f)))
    buf = [random.uniform(-1.0, 1.0) for _ in range(period)]
    # Soften the initial burst so it sounds like a thumb, not a pick.
    for _ in range(2 if bright < 0.5 else 1):
        buf = [(buf[k] + buf[k - 1]) * 0.5 for k in range(period)]
    out = []
    n = int(seconds * SR)
    k = 0
    for i in range(n):
        a = buf[k]
        b = buf[(k + 1) % period]
        buf[k] = (a * bright + b * (1.0 - bright)) * decay
        out.append(a)
        k = (k + 1) % period
    # Fade the very end so notes never click off.
    fade = min(int(0.05 * SR), n)
    for i in range(fade):
        out[n - fade + i] *= 1.0 - i / fade
    return out


def whistle(f, length):
    """A breathy whistle/ocarina with a vibrato that blooms on long notes."""
    def fn(t):
        att = min(t / 0.06, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.18)
        vib_depth = 0.006 * min(max(t - 0.25, 0.0) / 0.4, 1.0)
        ph = TAU * f * t + vib_depth * f / 5.2 * math.sin(TAU * 5.2 * t)
        v = math.sin(ph) + 0.12 * math.sin(2.0 * ph) + 0.04 * math.sin(3.0 * ph)
        breath = random.uniform(-1.0, 1.0) * 0.035 * att
        return (v + breath) * att * rel
    return fn


def pad(f, length):
    def fn(t):
        att = min(t / 0.9, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.7)
        trem = 0.88 + 0.12 * math.sin(TAU * 0.2 * t)
        v = (math.sin(TAU * f * 1.002 * t) + math.sin(TAU * f * 0.998 * t)) * 0.5
        return v * att * rel * trem
    return fn


def woodblock(f):
    def fn(t):
        return (math.sin(TAU * f * t) + 0.4 * math.sin(TAU * f * 2.7 * t)) * math.exp(-t * 55.0)
    return fn


def soft_kick(t):
    f = 50.0 + 55.0 * math.exp(-t * 28.0)
    return math.sin(TAU * f * t) * math.exp(-t * 9.0)


def make_shaker():
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]
        prev[0] = x
        env = min(t / 0.01, 1.0) * math.exp(-t * 30.0)
        return hp * env
    return fn


# --- The tune -------------------------------------------------------------------

DM = (38, 45, [57, 62, 65, 69])   # root, fifth, strum voicing
C = (36, 43, [55, 60, 64, 67])
BB = (34, 41, [53, 58, 62, 65])
A = (33, 40, [52, 57, 61, 64])
GM = (31, 38, [55, 58, 62, 67])
CHORDS = [DM, C, BB, A, DM, C, BB, A, GM, DM, BB, A, DM, C, BB, A]

# (beat, length in beats, MIDI note)
MELODY = [
    (0, 1.5, 69), (1.5, 0.5, 67), (2, 1, 65), (3, 1, 62),
    (4, 2, 64), (6, 1, 67), (7, 1, 64),
    (8, 1.5, 62), (9.5, 0.5, 65), (10, 1, 70), (11, 1, 69),
    (12, 1, 67), (13, 2.5, 69),
    (16, 1.5, 74), (17.5, 0.5, 72), (18, 1, 69), (19, 1, 65),
    (20, 1.5, 67), (21.5, 0.5, 69), (22, 1, 72), (23, 1, 67),
    (24, 1.5, 65), (25.5, 0.5, 67), (26, 1, 65), (27, 1, 62),
    (28, 1, 61), (29, 2.5, 64),
    # Middle: up the canyon wall and back.
    (32, 2, 67), (34, 1, 70), (35, 1, 74),
    (36, 2, 69), (38, 1, 74), (39, 1, 77),
    (40, 2, 74), (42, 1, 72), (43, 1, 70),
    (44, 1.5, 69), (45.5, 0.5, 70), (46, 2, 73),
    (48, 1.5, 74), (49.5, 0.5, 72), (50, 1, 69), (51, 1, 65),
    (52, 1, 67), (53, 1, 64), (54, 2, 67),
    (56, 1.5, 65), (57.5, 0.5, 64), (58, 1, 62), (59, 1, 65),
    (60, 3, 64),
]

for bar, (root, fifth, voicing) in enumerate(CHORDS):
    b0 = bar * 4
    t0 = b0 * BEAT
    for m in voicing[1:]:
        render(b0, BAR + 0.8, pad(mtof(m), BAR), 0.03, send=0.75)
    # Boom-chick: bass on 1 and 3 (root then fifth), a gentle strum on 2 and 4.
    add(t0, pluck(mtof(root), 1.6, 0.35, 0.997), 0.42, send=0.15)
    add(t0 + 2 * BEAT, pluck(mtof(fifth), 1.4, 0.35, 0.997), 0.34, send=0.15)
    for beat in (1, 3):
        for k, m in enumerate(voicing):
            add(t0 + beat * BEAT + k * 0.014, pluck(mtof(m), 0.9, 0.5, 0.993), 0.11, send=0.35)
    # A soft pickup strum on the "and" of 4 every other bar.
    if bar % 2 == 1:
        for k, m in enumerate(reversed(voicing)):
            add(t0 + 3.5 * BEAT + k * 0.012, pluck(mtof(m), 0.5, 0.5, 0.99), 0.06, send=0.35)
    render(b0, 0.6, soft_kick, 0.22, send=0.05)
    render(b0 + 2, 0.6, soft_kick, 0.12, send=0.05)
    # Clip-clop.
    for k in range(4):
        render(b0 + k + 0.5, 0.12, woodblock(1250.0 if k % 2 == 0 else 980.0), 0.045, send=0.25)
    for k in range(8):
        render(b0 + k * 0.5, 0.12, make_shaker(), 0.035 if k % 2 else 0.018, send=0.3)

for beat, length, note in MELODY:
    render(beat, length * BEAT + 0.25, whistle(mtof(note), length * BEAT * 0.92), 0.17, send=0.35, echo=0.5)


# --- Canyon echo (a dotted-eighth delay with a little feedback) ----------------

delay = int(round(0.75 * BEAT * SR))
echo = [0.0] * N
for i in range(N):
    back = echo[i - delay] if i >= delay else 0.0
    echo[i] = echo_bus[i - delay] * 0.55 + back * 0.4 if i >= delay else 0.0
# Soften the echo with a gentle low-pass.
lp = 0.0
for i in range(N):
    lp = lp * 0.55 + echo[i] * 0.45
    echo[i] = lp
for i in range(N):
    wet[i] += echo[i] * 0.4
    dry[i] += echo[i] * 0.45


# --- Reverb (Schroeder: four combs into two all-passes) -------------------------

def comb(x, delay_n, fb, damp):
    y = [0.0] * len(x)
    buf = [0.0] * delay_n
    lpv = 0.0
    k = 0
    for i, v in enumerate(x):
        out = buf[k]
        lpv = out * (1.0 - damp) + lpv * damp
        buf[k] = v + lpv * fb
        y[i] = out
        k += 1
        if k == delay_n:
            k = 0
    return y


def allpass(x, delay_n, g):
    y = [0.0] * len(x)
    buf = [0.0] * delay_n
    k = 0
    for i, v in enumerate(x):
        b = buf[k]
        out = -v + b
        buf[k] = v + b * g
        y[i] = out
        k += 1
        if k == delay_n:
            k = 0
    return y


rev = [0.0] * N
for d in (1116, 1188, 1277, 1356):
    c = comb(wet, d, 0.86, 0.35)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.5 + rev[i] * 0.6 for i in range(N)]

# Fold the tail back onto the start so the loop is seamless.
for i in range(TAIL_N):
    mix[i] += mix[LOOP_N + i]
mix = mix[:LOOP_N]

# A touch of warmth: one-pole low-pass to take the edge off the plucks.
lp = 0.0
for i in range(LOOP_N):
    lp = lp * 0.25 + mix[i] * 0.75
    mix[i] = lp

peak = max(abs(v) for v in mix) or 1.0
gain = 0.89 / peak

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_3.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
