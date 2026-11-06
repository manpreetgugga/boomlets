"""Composes World 23's orchard loop, "Seasons Grove", and writes it to
audio/music/world_23.wav (22.05 kHz mono, 16-bit). A gentle folk waltz in
G major: a fingerpicked acoustic guitar (plucked-string synthesis: a burst
of noise ringing round a tuned delay line), a breathy wooden recorder
carrying the tune, a soft bass string and a hand-drum thump on each bar.
Four bars of guitar, an eight-bar tune, a higher eight-bar answer, and
four bars that lead back to the top. Original music made from plain
synthesis, so there is nothing to license.

Run from the project folder:  python tools/make_music_w23.py
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
BAR = 3 * BEAT
BARS = 24
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.0 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(2323)
dry = [0.0] * N
wet = [0.0] * N


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def add(start_beat, buf, amp, send=0.4):
    s0 = int(round(start_beat * BEAT * SR))
    for i, v in enumerate(buf):
        j = s0 + i
        if j >= N:
            j -= LOOP_N
        v *= amp
        dry[j] += v * (1.0 - send)
        wet[j] += v * send


def render(start_beat, seconds, fn, amp, send=0.4):
    add(start_beat, [fn(i / SR) for i in range(int(seconds * SR))], amp, send)


# --- Instruments --------------------------------------------------------------

def pluck(f, seconds, bright=0.5, decay=0.996):
    """Karplus-Strong plucked string: a noise burst circulating in a delay
    line one period long, softened a little on every pass."""
    period = SR / f
    n = int(period)
    frac = period - n
    buf = [random.uniform(-1.0, 1.0) for _ in range(n + 2)]
    # Pre-soften the burst so the pluck sounds like a fingertip, not a pick.
    for _ in range(int(3 * (1.0 - bright)) + 1):
        buf = [0.5 * (buf[k] + buf[k - 1]) for k in range(len(buf))]
    out = []
    idx = 0
    length = len(buf) - 1
    total = int(seconds * SR)
    prev = 0.0
    for i in range(total):
        a = buf[idx % length]
        b = buf[(idx + 1) % length]
        v = a + (b - a) * frac
        new = decay * 0.5 * (v + prev)
        prev = v
        buf[idx % length] = new
        out.append(v)
        idx += 1
    # Fade the very end so long notes never click.
    fade = min(int(0.05 * SR), total)
    for k in range(fade):
        out[total - 1 - k] *= k / fade
    return out


def recorder(f, length):
    """A wooden recorder: soft attack, gentle vibrato that blooms in, a hint
    of the octave and a breathy chiff at the start."""
    def fn(t):
        att = min(t / 0.05, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.12)
        vib = 1.0 + 0.005 * min(max(t - 0.2, 0.0) / 0.3, 1.0) * math.sin(TAU * 5.2 * t)
        ph = TAU * f * vib * t
        tone = math.sin(ph) + 0.12 * math.sin(2.0 * ph) + 0.05 * math.sin(3.0 * ph)
        chiff = random.uniform(-1.0, 1.0) * 0.25 * math.exp(-t * 40.0)
        breath = random.uniform(-1.0, 1.0) * 0.025
        return (tone + chiff + breath) * att * rel
    return fn


def drum(t):
    f = 90.0 + 50.0 * math.exp(-t * 30.0)
    return math.sin(TAU * f * t) * math.exp(-t * 9.0) + random.uniform(-1, 1) * 0.08 * math.exp(-t * 50.0)


# --- The tune -------------------------------------------------------------------

# (bass, chord tones for the strum) per bar, G major.
G = (43, [55, 59, 62, 67])
C = (48, [55, 60, 64, 67])
D = (50, [54, 57, 62, 66])
D7 = (50, [54, 57, 60, 66])
Em = (40, [55, 59, 64, 67])
Am = (45, [57, 60, 64, 69])
CHORDS = [G, C, D, G,
          G, C, D, G, Em, C, D, D7,
          C, G, Am, D, G, Em, Am, D,
          G, C, D7, G]

MELODY = [
    # The tune.
    (12, 2, 83), (14, 1, 81),
    (15, 1, 79), (16, 1, 81), (17, 1, 84),
    (18, 2, 86), (20, 1, 81),
    (21, 3, 83),
    (24, 1, 83), (25, 1, 86), (26, 1, 88),
    (27, 2, 84), (29, 1, 83),
    (30, 1, 81), (31, 1, 79), (32, 1, 78),
    (33, 3, 81),
    # The answer, a little higher.
    (36, 1, 88), (37, 1, 86), (38, 1, 84),
    (39, 2, 86), (41, 1, 83),
    (42, 1, 84), (43, 1, 83), (44, 1, 81),
    (45, 2, 78), (47, 1, 81),
    (48, 1, 83), (49, 1, 86), (50, 1, 88),
    (51, 2, 86), (53, 1, 83),
    (54, 1, 84), (55, 1, 83), (56, 1, 81),
    (57, 2, 78), (59, 1, 81),
    # Leading home.
    (60, 3, 79),
    (66, 1, 78), (67, 1, 81), (68, 1, 86),
    (69, 3, 83),
]

for bar, (bass, tones) in enumerate(CHORDS):
    b0 = bar * 3
    # Bass string on the downbeat, the fifth on beat 3 in busier bars.
    add(b0, pluck(mtof(bass), 2.2, 0.3, 0.997), 0.34, send=0.25)
    # Fingerpicking: a gentle rolled pattern on the off-beats.
    pattern = [(1.0, 1), (1.5, 2), (2.0, 3), (2.5, 2)]
    for beat, k in pattern:
        add(b0 + beat, pluck(mtof(tones[k]), 1.4, 0.55, 0.995), 0.16, send=0.4)
    add(b0 + 0.5, pluck(mtof(tones[0]), 1.2, 0.5, 0.995), 0.12, send=0.4)
    # A hand drum from bar 5, with a soft second tap.
    if 4 <= bar < 22:
        render(b0, 0.5, drum, 0.28, send=0.15)
        render(b0 + 2, 0.4, drum, 0.12, send=0.15)

for beat, length, note in MELODY:
    render(beat, length * BEAT + 0.2, recorder(mtof(note), length * BEAT * 0.94), 0.17, send=0.45)
    # The guitar doubles the answer an octave down, softly.
    if 36 <= beat < 60:
        add(beat, pluck(mtof(note - 12), 1.0, 0.6, 0.994), 0.07, send=0.45)


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
for d in (1087, 1163, 1249, 1319):
    c = comb(wet, d, 0.82, 0.35)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.55 + rev[i] * 0.55 for i in range(N)]

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

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_23.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
