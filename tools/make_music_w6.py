"""Composes World 6's gentle clocktower loop, "Clockwork Keep", and writes it
to audio/music/world_6.wav (22.05 kHz mono, 16-bit). A ticking music-box
waltz in F major, 3/4: a comb music box melody, an oom-pah-pah of soft
plucked bass and little chord stabs, a tick-tock woodblock that keeps the
clock time and a warm reed pad. Original music made from plain sine-based
instruments, so there is nothing to license.

Run from the project folder:  python tools/make_music_w6.py
Pure Python (no numpy); takes about a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 104
BEAT = 60.0 / BPM
BAR = 3 * BEAT
BARS = 32
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.0 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(66)
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


# --- Instruments --------------------------------------------------------------

def musicbox(f):
    """A comb music box tine: a bright, slightly inharmonic ping."""
    def fn(t):
        att = min(t / 0.002, 1.0)
        v = math.sin(TAU * f * t) * math.exp(-t * 2.6)
        v += 0.45 * math.sin(TAU * f * 3.01 * t) * math.exp(-t * 7.0)
        v += 0.18 * math.sin(TAU * f * 5.43 * t) * math.exp(-t * 14.0)
        return v * att
    return fn


def pluck_bass(f):
    """Round plucked bass, like a soft upright."""
    def fn(t):
        att = min(t / 0.004, 1.0)
        v = math.sin(TAU * f * t) + 0.35 * math.sin(TAU * 2 * f * t) * math.exp(-t * 6.0)
        return v * att * math.exp(-t * 3.2)
    return fn


def stab(f):
    """Short warm keyboard chord note for the "pah-pah"."""
    def fn(t):
        att = min(t / 0.006, 1.0)
        v = math.sin(TAU * f * t) + 0.25 * math.sin(TAU * 2 * f * t)
        return v * att * math.exp(-t * 7.0)
    return fn


def reed(f, length):
    """A soft accordion-ish reed pad with a slow wobble."""
    def fn(t):
        att = min(t / 0.5, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.5)
        vib = 1.0 + 0.003 * math.sin(TAU * 5.0 * t)
        v = 0.0
        for d in (0.997, 1.003):
            ph = TAU * f * d * vib * t
            v += math.sin(ph) + 0.35 * math.sin(2 * ph) + 0.15 * math.sin(3 * ph)
        return v * 0.5 * att * rel
    return fn


def woodblock(f):
    """The clock's tick (high) or tock (low)."""
    def fn(t):
        return (math.sin(TAU * f * t) + 0.5 * math.sin(TAU * f * 1.48 * t)) * math.exp(-t * 55.0)
    return fn


def shaker(t):
    return random.uniform(-1.0, 1.0) * math.exp(-t * 60.0)


# --- The tune -------------------------------------------------------------------

F, Bb, C, Dm, Gm, A7, Am = (
    (41, [65, 69, 72]), (46, [65, 70, 74]), (36, [64, 67, 70]),
    (38, [62, 65, 69]), (43, [62, 67, 70]), (45, [61, 64, 67]), (45, [60, 64, 69]),
)
# 16 bars, played twice (the second time with a counter-melody).
PROG = [F, F, Bb, F, Gm, C, F, C,
        Dm, Am, Bb, F, Gm, C, F, F]
CHORDS = PROG + PROG

# (beat, length in beats, MIDI note), beats counted from the loop start.
A_PART = [
    (0, 2, 72), (2, 1, 69), (3, 2, 77), (5, 1, 76), (6, 2, 74), (8, 1, 70),
    (9, 3, 72), (12, 1, 70), (13, 1, 72), (14, 1, 74), (15, 2, 76), (17, 1, 72),
    (18, 2, 77), (20, 1, 76), (21, 2, 74), (23, 1, 76),
]
B_PART = [
    (24, 2, 77), (26, 1, 74), (27, 2, 76), (29, 1, 72), (30, 1, 74), (31, 1, 77),
    (32, 1, 82), (33, 3, 81), (36, 1, 79), (37, 1, 77), (38, 1, 74), (39, 2, 76),
    (41, 1, 79), (42, 3, 77), (45, 2, 72), (47, 1, 74),
]
MELODY = A_PART + B_PART
for beat, length, note in A_PART + B_PART:
    MELODY.append((beat + 48, length, note))
# A few twinkles high up in the second pass.
COUNTER = [(48 + 1.5 + k * 6, 0.5, 84 if k % 2 == 0 else 81) for k in range(8)]

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 3
    # Oom-pah-pah: bass on 1 (fifth below every other bar), chord stabs on 2 and 3.
    bass = root if bar % 2 == 0 else root + 7
    while bass > 48:
        bass -= 12
    render(b0, BAR, pluck_bass(mtof(bass)), 0.34, send=0.15)
    for k in (1, 2):
        for m in voicing:
            render(b0 + k, 0.4, stab(mtof(m - 12)), 0.035, send=0.3)
    # Reed pad under the chord, quieter in the first pass.
    lvl = 0.6 if bar < 16 else 1.0
    for m in voicing:
        render(b0, BAR + 0.5, reed(mtof(m - 12), BAR), 0.022 * lvl, send=0.6)
    # The clock: tick on 1, tock on 2 and 3, and a soft shaker on the off-beats.
    render(b0, 0.15, woodblock(1650.0), 0.16, send=0.2)
    render(b0 + 1, 0.15, woodblock(1180.0), 0.11, send=0.2)
    render(b0 + 2, 0.15, woodblock(1180.0), 0.11, send=0.2)
    if bar >= 2:
        for k in range(3):
            render(b0 + k + 0.5, 0.06, shaker, 0.03, send=0.3)

for beat, length, note in MELODY:
    render(beat, min(length * BEAT + 1.6, 3.0), musicbox(mtof(note + 12)), 0.2, send=0.45)
    # A quiet octave-down double so the box sounds full.
    render(beat, min(length * BEAT + 1.0, 2.4), musicbox(mtof(note)), 0.08, send=0.45)
for beat, length, note in COUNTER:
    render(beat, 1.6, musicbox(mtof(note + 12)), 0.07, send=0.7)


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
    c = comb(wet, d, 0.8, 0.35)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.55 + rev[i] * 0.55 for i in range(N)]

# Fold the tail back onto the start so the loop is seamless.
for i in range(TAIL_N):
    mix[i] += mix[LOOP_N + i]
mix = mix[:LOOP_N]

# Gentle soft-clip so the music-box pings do not set the level on their own.
peak = max(abs(v) for v in mix) or 1.0
mix = [math.tanh(1.1 * v / peak) for v in mix]
peak = max(abs(v) for v in mix) or 1.0
gain = 0.89 / peak

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_6.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
