"""Composes World 21's calm loop, "Echo Grotto", and writes it to
audio/music/world_21.wav (22.05 kHz mono, 16-bit). A dreamy cave piece in
D major at 72 BPM: slow airy pads (soft detuned sine stacks that swell in
and out), a round sine bass, and a kalimba melody (a plucked sine with the
bright, slightly out-of-tune overtone a metal tine has) sent through a
dotted-eighth feedback delay so every note answers itself, like an echo in
a sea cave. Little water-drop blips fall now and then, and a hushed shaker
joins in the second half. The tail is folded back onto the start so it
loops without a seam. Original music, nothing to license.

Run from the project folder:  python tools/make_music_w21.py
Pure Python (no numpy); takes about a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 72
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(4.0 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(2121)
dry = [0.0] * N
wet = [0.0] * N
kal = [0.0] * N   # kalimba bus, goes through the echo delay


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def render(start_beat, seconds, fn, amp, send=0.3, bus=None):
    s0 = int(round(start_beat * BEAT * SR))
    n = int(seconds * SR)
    for i in range(n):
        j = s0 + i
        if j >= N:
            j -= LOOP_N
        v = fn(i / SR) * amp
        if bus is not None:
            bus[j] += v
        else:
            dry[j] += v * (1.0 - send)
            wet[j] += v * send


# --- Voices ------------------------------------------------------------------------

def pad(f, length, att=1.6, rel=1.8):
    """Two slightly detuned sine stacks with a slow swell and a gentle
    shimmer."""
    det = 1.0035
    ph0 = random.random() * TAU

    def fn(t):
        if t < att:
            a = 0.5 - 0.5 * math.cos(math.pi * t / att)
        else:
            a = 1.0
        if t > length:
            a *= max(0.0, 1.0 - (t - length) / rel)
        if a <= 0.0:
            return 0.0
        sh = 1.0 + 0.12 * math.sin(TAU * 0.35 * t + ph0)
        v = 0.0
        for d in (1.0, det):
            w = TAU * f * d * t
            v += math.sin(w) + 0.32 * math.sin(2 * w + 0.4) + 0.12 * math.sin(3 * w + 1.1)
        return v * 0.5 * a * sh
    return fn


def kalimba(f):
    """A plucked tine: the fundamental rings, a bright overtone near 5.4x
    dies fast, and a tiny click starts it."""
    def fn(t):
        a = min(t / 0.003, 1.0)
        v = math.sin(TAU * f * t) * math.exp(-t * 2.6)
        v += 0.35 * math.sin(TAU * f * 5.43 * t) * math.exp(-t * 14.0)
        v += 0.12 * math.sin(TAU * f * 2.0 * t) * math.exp(-t * 6.0)
        return v * a
    return fn


def bass(f, length):
    def fn(t):
        a = min(t / 0.04, 1.0)
        r = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.4)
        return (math.sin(TAU * f * t) + 0.18 * math.sin(TAU * 2 * f * t)) * a * r * math.exp(-t * 0.35)
    return fn


def drop(f):
    """A water drop: a quick upward sine chirp."""
    def fn(t):
        ff = f * (1.0 + 1.4 * (1.0 - math.exp(-t * 40.0)))
        return math.sin(TAU * ff * t) * math.exp(-t * 28.0) * min(t / 0.002, 1.0)
    return fn


def shaker(t):
    return random.uniform(-1.0, 1.0) * math.exp(-t * 45.0) * min(t / 0.008, 1.0)


# --- The tune ------------------------------------------------------------------------

# (bass root, pad notes) for each two-bar chord, D major.
PROG = [
    (38, [62, 66, 69, 73, 76]),   # Dmaj9
    (35, [62, 66, 69, 71, 74]),   # Bm7add11-ish
    (43, [62, 66, 67, 71, 74]),   # Gmaj7
    (45, [62, 64, 69, 71, 76]),   # A sus
    (42, [61, 66, 69, 73, 76]),   # F#m7
    (35, [62, 66, 69, 71, 73]),   # Bm9
    (43, [62, 67, 71, 74, 78]),   # Gmaj7
    (45, [61, 64, 69, 73, 76]),   # A
]

for k, (root, notes) in enumerate(PROG):
    b0 = k * 8
    for n in notes:
        render(b0, 2 * BAR + 2.0, pad(mtof(n), 2 * BAR - 0.4), 0.034, send=0.55)
    render(b0, 2 * BAR, bass(mtof(root), 2 * BAR - 0.6), 0.2, send=0.15)
    render(b0 + 6, BAR, bass(mtof(root + 7), BAR * 0.5), 0.1, send=0.15)

# Kalimba: (beat, midi). A gentle pentatonic line; the delay answers it.
MOTIF_A = [(0, 81), (0.5, 78), (1, 74), (2, 76), (2.5, 78), (3.5, 81),
           (4, 83), (5, 81), (6, 78), (7, 76)]
MOTIF_B = [(0, 78), (0.5, 76), (1, 74), (2, 71), (3, 74), (3.5, 76),
           (4, 78), (5, 81), (5.5, 83), (6, 86), (7.5, 83)]
MOTIF_C = [(0, 86), (1, 83), (1.5, 81), (2, 78), (3, 81), (4, 83),
           (4.5, 81), (5, 78), (6, 76), (6.5, 74), (7, 76)]
MOTIF_D = [(0, 74), (1, 76), (1.5, 78), (2, 81), (3.5, 78), (4, 76),
           (5, 73), (6, 74)]
LINE = [(8, MOTIF_A), (16, MOTIF_B), (24, MOTIF_A), (32, MOTIF_C),
        (40, MOTIF_B), (48, MOTIF_C), (56, MOTIF_D)]
# Bars 1-2: just a few high notes over the pad.
INTRO = [(0, 81), (2, 78), (3.5, 86), (5, 83), (6.5, 78)]
for beat, note in INTRO:
    render(beat, 2.2, kalimba(mtof(note)), 0.12, bus=kal)
for start, motif in LINE:
    for beat, note in motif:
        vel = 0.15 if beat % 1.0 == 0 else 0.11
        render(start + beat, 2.2, kalimba(mtof(note)), vel, bus=kal)
        # A soft lower octave doubling on the bar's first note.
        if beat in (0, 4):
            render(start + beat, 2.2, kalimba(mtof(note - 12)), 0.06, bus=kal)

# Water drops here and there.
for beat in (3.25, 13.75, 22.5, 29.25, 37.75, 45.5, 52.25, 61.75):
    render(beat, 0.2, drop(random.choice([1400.0, 1700.0, 2000.0])), 0.05, send=0.7)

# Shaker in the second half: soft offbeat eighths.
for bar in range(8, 16):
    for k in range(8):
        lvl = 0.03 if k % 2 == 1 else 0.016
        render(bar * 4 + k * 0.5, 0.12, shaker, lvl, send=0.3)


# --- Echo delay on the kalimba --------------------------------------------------------

def feedback_delay(x, delay_s, fb, damp, mix):
    d = int(delay_s * SR)
    buf = [0.0] * d
    y = [0.0] * len(x)
    lp = 0.0
    k = 0
    for i, v in enumerate(x):
        out = buf[k]
        lp = out * (1.0 - damp) + lp * damp
        buf[k] = v + lp * fb
        y[i] = v + out * mix
        k += 1
        if k == d:
            k = 0
    return y


kal_out = feedback_delay(kal, BEAT * 0.75, 0.45, 0.45, 0.7)
for i in range(N):
    dry[i] += kal_out[i] * 0.65
    wet[i] += kal_out[i] * 0.35


# --- A soft cave reverb ---------------------------------------------------------------

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
for d in (1311, 1433, 1557, 1617):
    c = comb(wet, d, 0.86, 0.4)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.4 + rev[i] * 0.6 for i in range(N)]

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
peak = max(abs(v) for v in mix)

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_21.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR), "peak %.2f" % peak)
