"""Composes World 7's shimmering cave loop, "Prism Caverns", and writes it
to audio/music/world_7.wav (22.05 kHz mono, 16-bit). Slow and glassy in
E major with a bright Lydian A#: crystal-glass chimes with long echoes, a
sparkling arpeggio, a soft shimmer pad, a round sine bass and a light
"tink" on the backbeat, all washed in a dotted-eighth echo and a big cave
reverb. Original music made from plain sine-based instruments, so there is
nothing to license.

Run from the project folder:  python tools/make_music_w7.py
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

random.seed(77)
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

def glass(f):
    """A crystal-glass chime: a sine with a fading FM shimmer and a glassy
    inharmonic partial."""
    def fn(t):
        att = min(t / 0.004, 1.0)
        mod = 1.6 * math.exp(-t * 5.0) * math.sin(TAU * f * 3.5 * t)
        v = math.sin(TAU * f * t + mod) * math.exp(-t * 1.6)
        v += 0.3 * math.sin(TAU * f * 2.76 * t) * math.exp(-t * 4.5)
        v += 0.12 * math.sin(TAU * f * 5.4 * t) * math.exp(-t * 9.0)
        return v * att
    return fn


def sparkle(f):
    """A tiny high bell for the arpeggio."""
    def fn(t):
        return (math.sin(TAU * f * t) + 0.3 * math.sin(TAU * f * 4.2 * t) * math.exp(-t * 12.0)) * math.exp(-t * 4.0) * min(t / 0.002, 1.0)
    return fn


def pad(f, length):
    """A soft shimmer pad: detuned sines with a slow swell and a gentle
    tremolo, plus a quiet octave above."""
    def fn(t):
        att = min(t / 1.2, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 1.2)
        trem = 0.85 + 0.15 * math.sin(TAU * 3.2 * t)
        v = 0.0
        for d in (0.996, 1.0, 1.004):
            v += math.sin(TAU * f * d * t)
        v += 0.35 * math.sin(TAU * 2.0 * f * 1.002 * t)
        return v * 0.33 * att * rel * trem
    return fn


def bass(f, length):
    """A round sine bass with a soft attack."""
    def fn(t):
        att = min(t / 0.03, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.3)
        return (math.sin(TAU * f * t) + 0.2 * math.sin(TAU * 2 * f * t)) * att * rel * math.exp(-t * 0.5)
    return fn


def tink(t):
    """A light glassy tick for the backbeat."""
    return (math.sin(TAU * 4200.0 * t) + 0.6 * math.sin(TAU * 6900.0 * t)) * math.exp(-t * 70.0)


def drop(t):
    """A soft low "thum", like a drip in a big cave."""
    f = 70.0 + 60.0 * math.exp(-t * 25.0)
    return math.sin(TAU * f * t) * math.exp(-t * 9.0)


def shaker(t):
    return random.uniform(-1.0, 1.0) * math.exp(-t * 80.0)


# --- The tune -------------------------------------------------------------------

E, Fs, Csm, A, Bsus, B = (
    (40, [64, 68, 71, 75]), (42, [66, 70, 73, 76]), (37, [61, 64, 68, 71]),
    (45, [61, 64, 68, 69]), (47, [64, 66, 71, 73]), (47, [63, 66, 71, 75]),
)
PROG = [E, Fs, Csm, A, E, Fs, Bsus, B]
CHORDS = PROG + PROG

# (beat, length in beats, MIDI note), beats counted from the loop start.
PHRASE = [
    (0, 1.5, 80), (1.5, 0.5, 83), (2, 2, 87),
    (4, 1, 85), (5, 1, 82), (6, 2, 78),
    (8, 1.5, 80), (9.5, 0.5, 76), (10, 1, 73), (11, 1, 76),
    (12, 3, 80), (15, 1, 78),
    (16, 1, 76), (17, 1, 80), (18, 1, 83), (19, 1, 88),
    (20, 2, 87), (22, 1, 85), (23, 1, 82),
    (24, 2, 83), (26, 2, 78),
    (28, 3, 75), (31, 1, 78),
]
MELODY = PHRASE + [(b + 32, l, m) for b, l, m in PHRASE]

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 4
    second = bar >= 8
    render(b0, BAR, bass(mtof(root), BAR - 0.2), 0.3, send=0.15)
    for m in voicing:
        render(b0, BAR + 1.2, pad(mtof(m - 12), BAR), 0.03 if second else 0.022, send=0.7)
    # The sparkling arpeggio: chord tones up two octaves on the eighths,
    # quiet in the first pass and brighter in the second.
    order = [0, 1, 2, 3, 2, 1, 2, 3]
    for k in range(8):
        m = voicing[order[k]] + 12
        render(b0 + k * 0.5, 1.0, sparkle(mtof(m)), 0.05 if second else 0.03, send=0.75)
    # A drip on 1, a glass tink on 2 and 4, and a whisper of shaker.
    render(b0, 0.4, drop, 0.22, send=0.4)
    if bar >= 1:
        render(b0 + 1, 0.12, tink, 0.05, send=0.5)
        render(b0 + 3, 0.12, tink, 0.05, send=0.5)
    if bar >= 4:
        for k in range(4):
            render(b0 + k + 0.5, 0.05, shaker, 0.018, send=0.4)

for beat, length, note in MELODY:
    render(beat, min(length * BEAT + 1.8, 3.4), glass(mtof(note)), 0.16, send=0.55)

# --- Echo (dotted eighth) then reverb (Schroeder: four combs, two all-passes) ---

d = int(round(0.75 * BEAT * SR))
for i in range(d, N):
    wet[i] += wet[i - d] * 0.45


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
for dl in (1310, 1422, 1527, 1617):
    c = comb(wet, dl, 0.84, 0.3)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.45 + rev[i] * 0.6 for i in range(N)]

# Fold the tail back onto the start so the loop is seamless.
for i in range(TAIL_N):
    mix[i] += mix[LOOP_N + i]
mix = mix[:LOOP_N]

# Gentle soft-clip so the chimes do not set the level on their own.
peak = max(abs(v) for v in mix) or 1.0
mix = [math.tanh(1.2 * v / peak) for v in mix]
peak = max(abs(v) for v in mix) or 1.0
# Level it with the other worlds (RMS about 5300 of 32767), never past 0.89.
rms = math.sqrt(sum(v * v for v in mix) / len(mix)) or 1.0
gain = min(0.89 / peak, 0.162 / rms)

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_7.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * gain)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
