"""Composes World 10's loop, "Bramblewood Jig", and writes it to
audio/music/world_10.wav (22.05 kHz mono, 16-bit). A soft woodland folk tune
in G major and a lilting 6/8: a plucked harp-guitar rolling arpeggios, a
breathy wooden flute lead, a mellow clarinet answering in the second half, a
padded frame drum and a light shaker. Original music from plain synthesised
instruments (plucked strings are Karplus-Strong), so there is nothing to
license.

Run from the project folder:  python tools/make_music_w10.py
Pure Python (no numpy); takes about a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
EIGHTH = 0.23            # one eighth note; a bar is six of them (6/8)
BAR = 6 * EIGHTH
BARS = 32
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(1010)
dry = [0.0] * N
wet = [0.0] * N


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def add(start_sec, samples, amp, send=0.4):
    s0 = int(round(start_sec * SR))
    for i, v in enumerate(samples):
        j = s0 + i
        if j >= N:
            break
        v *= amp
        dry[j] += v * (1.0 - send)
        wet[j] += v * send


def render(start_eighth, seconds, fn, amp, send=0.4):
    n = int(seconds * SR)
    add(start_eighth * EIGHTH, [fn(i / SR) for i in range(n)], amp, send)


# --- Instruments --------------------------------------------------------------

def pluck(f, seconds, bright=0.5, decay=0.996):
    """Karplus-Strong plucked string: a soft harp-guitar."""
    period = max(2, int(round(SR / f)))
    buf = [random.uniform(-1.0, 1.0) for _ in range(period)]
    for _ in range(2):
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
    fade = min(int(0.05 * SR), n)
    for i in range(fade):
        out[n - fade + i] *= 1.0 - i / fade
    return out


def flute(f, length):
    """A breathy wooden flute: mostly sine, a little second harmonic, a
    chiff of breath at the start and a gentle vibrato on long notes."""
    def fn(t):
        att = min(t / 0.05, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.15)
        vib = 0.005 * min(max(t - 0.2, 0.0) / 0.3, 1.0)
        ph = TAU * f * t + vib * f / 5.0 * math.sin(TAU * 5.0 * t)
        v = math.sin(ph) + 0.18 * math.sin(2.0 * ph) + 0.05 * math.sin(3.0 * ph)
        chiff = random.uniform(-1.0, 1.0) * 0.25 * math.exp(-t * 40.0)
        breath = random.uniform(-1.0, 1.0) * 0.03
        return (v + chiff + breath) * att * rel
    return fn


def clarinet(f, length):
    """A mellow clarinet: odd harmonics, slow swell."""
    def fn(t):
        att = min(t / 0.12, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.25)
        ph = TAU * f * t + 0.003 * f / 4.5 * math.sin(TAU * 4.5 * t)
        v = math.sin(ph) + 0.32 * math.sin(3.0 * ph) + 0.12 * math.sin(5.0 * ph)
        return v * att * rel
    return fn


def frame_drum(t):
    f = 85.0 + 40.0 * math.exp(-t * 30.0)
    body = math.sin(TAU * f * t) * math.exp(-t * 11.0)
    skin = random.uniform(-1.0, 1.0) * math.exp(-t * 60.0) * 0.25
    return body + skin


def make_shaker():
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]
        prev[0] = x
        return hp * min(t / 0.008, 1.0) * math.exp(-t * 35.0)
    return fn


# --- The tune -------------------------------------------------------------------

G = [43, 50, 55, 59]      # root, fifth, octave, tenth (an arpeggio voicing)
C = [36, 43, 48, 52]
D = [38, 45, 50, 54]
EM = [40, 47, 52, 55]
AM = [45, 52, 57, 60]
A_PART = [G, C, G, D, EM, C, D, G]
B_PART = [EM, C, G, D, EM, AM, D, D]
B_END = [EM, C, G, D, EM, AM, D, G]
CHORDS = A_PART + B_PART + A_PART + B_END

# (start eighth, length in eighths, MIDI note) for one A + B half (16 bars).
A_MEL = [
    (0, 3, 71), (3, 1, 69), (4, 2, 67),
    (6, 3, 76), (9, 1, 74), (10, 2, 72),
    (12, 2, 71), (14, 1, 74), (15, 2, 79), (17, 1, 78),
    (18, 2, 76), (20, 1, 74), (21, 3, 69),
    (24, 2, 67), (26, 1, 71), (27, 3, 76),
    (30, 1, 76), (31, 1, 74), (32, 1, 72), (33, 3, 67),
    (36, 2, 69), (38, 1, 71), (39, 2, 72), (41, 1, 69),
    (42, 5, 67),
]
B_MEL = [
    (48, 3, 71), (51, 3, 76),
    (54, 2, 79), (56, 1, 76), (57, 3, 72),
    (60, 2, 74), (62, 1, 71), (63, 3, 67),
    (66, 2, 69), (68, 1, 66), (69, 1, 69), (70, 2, 74),
    (72, 3, 76), (75, 1, 78), (76, 2, 79),
    (78, 2, 81), (80, 1, 79), (81, 3, 76),
    (84, 2, 74), (86, 1, 76), (87, 2, 78), (89, 1, 81),
    (90, 3, 78), (93, 3, 74),
]
B_END_MEL = B_MEL[:-4] + [(84, 3, 69), (87, 1, 72), (88, 1, 71), (89, 1, 69), (90, 5, 67)]
MELODY = A_MEL + B_MEL + [(s + 96, l, m) for s, l, m in A_MEL] + [(s + 96, l, m) for s, l, m in B_END_MEL]

# The clarinet's long answering notes in the second half (start bar, bars, note).
COUNTER = [(16, 2, 59), (18, 2, 60), (20, 2, 59), (22, 2, 62),
           (24, 2, 64), (26, 1, 60), (27, 1, 62), (28, 2, 64), (30, 1, 62), (31, 1, 59)]

ARP = [0, 1, 2, 3, 2, 1]
for bar, voicing in enumerate(CHORDS):
    e0 = bar * 6
    for k, idx in enumerate(ARP):
        m = voicing[idx] + (12 if idx > 0 else 0)
        amp = 0.32 if k == 0 else 0.15
        add((e0 + k) * EIGHTH, pluck(mtof(m), 1.1 if k == 0 else 0.7, 0.45, 0.996), amp, send=0.3)
    # Low bass pluck on the downbeat.
    add(e0 * EIGHTH, pluck(mtof(voicing[0]), 1.6, 0.3, 0.997), 0.3, send=0.12)
    render(e0, 0.5, frame_drum, 0.22, send=0.1)
    render(e0 + 3, 0.5, frame_drum, 0.12, send=0.1)
    for k in range(6):
        render(e0 + k, 0.1, make_shaker(), 0.03 if k % 3 else 0.016, send=0.3)

for start, length, note in MELODY:
    render(start, length * EIGHTH + 0.2, flute(mtof(note), length * EIGHTH * 0.92), 0.16, send=0.4)

for bar, bars, note in COUNTER:
    render(bar * 6, bars * BAR + 0.3, clarinet(mtof(note), bars * BAR * 0.95), 0.075, send=0.5)


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
    c = comb(wet, d, 0.85, 0.4)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.5 + rev[i] * 0.6 for i in range(N)]

# Fold the tail back onto the start so the loop is seamless.
for i in range(TAIL_N):
    mix[i] += mix[LOOP_N + i]
mix = mix[:LOOP_N]

lp = 0.0
for i in range(LOOP_N):
    lp = lp * 0.25 + mix[i] * 0.75
    mix[i] = lp

peak = max(abs(v) for v in mix) or 1.0
gain = 0.89 / peak

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_10.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
