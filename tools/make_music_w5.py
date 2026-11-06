"""Composes World 5's calm night-city loop, "Neon Nightway", and writes it to
audio/music/world_5.wav (22.05 kHz mono, 16-bit). A gently pulsing synth
tune in A minor: warm detuned pads, a soft plucked 16th-note arpeggio, a
pulsing sub bass, an electric-piano lead and light drums. Original music made
from plain sine-based instruments, so there is nothing to license.

Run from the project folder:  python tools/make_music_w5.py
Pure Python (no numpy); takes about a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 92
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(55)
dry = [0.0] * N      # instruments that stay dry-ish
wet = [0.0] * N      # sent to the reverb


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def render(start_beat, seconds, fn, amp, send=0.5):
    """Adds fn(t) for `seconds` from `start_beat` into dry and wet buses.
    Wraps past the loop end so notes that ring over the top still loop."""
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
    """A soft synth pluck: a few harmonics whose top end dies away first, like
    a closing filter."""
    def fn(t):
        att = min(t / 0.003, 1.0)
        v = 0.0
        for k in range(1, 6):
            v += math.sin(TAU * f * k * t) * math.exp(-t * (5.0 + 7.0 * k)) / k
        return v * att
    return fn


def epiano(f):
    """A mellow electric piano: gentle FM that softens as the note rings."""
    def fn(t):
        att = min(t / 0.006, 1.0)
        idx = 1.1 * math.exp(-t * 4.0)
        mod = math.sin(TAU * f * t)
        return att * math.sin(TAU * f * t + idx * mod) * math.exp(-t * 1.6)
    return fn


def pad(f, length):
    """Warm detuned pad that breathes slowly."""
    def fn(t):
        att = min(t / 1.0, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.8)
        trem = 0.8 + 0.2 * math.sin(TAU * 0.18 * t)
        v = 0.0
        for d in (0.994, 1.0, 1.006):
            v += math.sin(TAU * f * d * t) + 0.3 * math.sin(TAU * 2.0 * f * d * t) + 0.12 * math.sin(TAU * 3.0 * f * d * t)
        return v / 3.0 * att * rel * trem
    return fn


def sub(f, length):
    """A round sub-bass pulse that ducks in on each eighth (a soft pump)."""
    def fn(t):
        att = min(t / 0.03, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.08)
        return (math.sin(TAU * f * t) + 0.2 * math.sin(TAU * 2.0 * f * t)) * att * rel * math.exp(-t * 2.5)
    return fn


def kick(t):
    f = 42.0 + 60.0 * math.exp(-t * 28.0)
    return math.sin(TAU * f * t) * math.exp(-t * 9.0)


def make_noise(decay, tone=0.0):
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]
        prev[0] = x
        return (hp + tone * math.sin(TAU * 190.0 * t)) * math.exp(-t * decay)
    return fn


# --- The tune -------------------------------------------------------------------

# (bass root, pad voicing) per bar.
PROG = [
    (45, [57, 60, 64, 67]),  # Am7
    (41, [57, 60, 64, 65]),  # Fmaj7
    (36, [55, 59, 60, 64]),  # Cmaj7
    (43, [55, 59, 62, 64]),  # G6
    (38, [57, 60, 62, 65]),  # Dm7
    (45, [55, 57, 60, 64]),  # Am7
    (41, [57, 60, 64, 65]),  # Fmaj7
    (40, [56, 59, 62, 64]),  # E7sus-ish (G#, B, D, E) -> back to Am
]
CHORDS = PROG + PROG

# (beat, length in beats, MIDI note): a slow, airy line.
MELODY = [
    (0, 1.5, 76), (1.5, 0.5, 74), (2, 2, 72),
    (4, 1, 72), (5, 1, 74), (6, 2, 76),
    (8, 1.5, 79), (9.5, 0.5, 76), (10, 2, 74),
    (12, 3, 71),
    (16, 1.5, 74), (17.5, 0.5, 72), (18, 2, 69),
    (20, 1, 72), (21, 1, 76), (22, 2, 74),
    (24, 1.5, 72), (25.5, 0.5, 69), (26, 2, 72),
    (28, 3, 71),
    # Second half: higher and a touch brighter.
    (32, 1, 81), (33, 1, 79), (34, 2, 76),
    (36, 1, 77), (37, 1, 76), (38, 2, 72),
    (40, 1.5, 76), (41.5, 0.5, 74), (42, 2, 72),
    (44, 3, 74),
    (48, 1.5, 77), (49.5, 0.5, 76), (50, 2, 72),
    (52, 1, 72), (53, 1, 74), (54, 2, 76),
    (56, 1.5, 74), (57.5, 0.5, 72), (58, 1.5, 71), (59.5, 0.5, 68),
    (60, 3, 69),
]
ARP = [0, 2, 1, 3, 2, 0, 3, 1]

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 4
    for m in voicing:
        render(b0, BAR + 0.9, pad(mtof(m), BAR), 0.05, send=0.75)
    # Pulsing eighth-note sub bass (root, with an octave hop on the "and" of 4).
    for k in range(8):
        note = root + (12 if k == 7 else 0)
        while note > 47:
            note -= 12
        render(b0 + k * 0.5, 0.5 * BEAT + 0.1, sub(mtof(note), 0.42 * BEAT), 0.26 if k % 2 == 0 else 0.19, send=0.1)
    # Sixteenth-note pluck arpeggio, quieter in the first two bars.
    lvl = 0.5 if bar < 2 else 1.0
    for k in range(16):
        idx = ARP[k % 8]
        octave = 12 if k < 8 else 24
        accent = 1.0 if k % 4 == 0 else (0.7 if k % 2 == 0 else 0.5)
        render(b0 + k * 0.25, 0.5, pluck(mtof(voicing[idx] + octave)), 0.05 * accent * lvl, send=0.6)
    # Soft drums: kick on 1 and 3, a light clap on 2 and 4, eighth hats.
    if bar >= 1:
        render(b0, 0.5, kick, 0.34, send=0.05)
        render(b0 + 2, 0.5, kick, 0.26, send=0.05)
        for b in (1, 3):
            render(b0 + b, 0.25, make_noise(26.0, 0.25), 0.05, send=0.5)
    for k in range(8):
        render(b0 + k * 0.5 + (0.0 if k % 2 == 0 else 0.03), 0.08, make_noise(70.0), 0.03 if k % 2 else 0.018, send=0.25)

for beat, length, note in MELODY:
    render(beat, min(length * BEAT + 1.5, 3.2), epiano(mtof(note)), 0.22, send=0.5)


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

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_5.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
