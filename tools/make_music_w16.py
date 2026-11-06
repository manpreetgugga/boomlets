"""Composes World 16's cosy loop, "Inkwell Library", and writes it to
audio/music/world_16.wav (22.05 kHz mono, 16-bit). A gentle library waltz in
F major, 3/4: a harpsichord keeps the oom-pah-pah (a pizzicato bass note on
the downbeat, two light chords after it), a celesta sings the tune, soft
strings hum underneath from the second phrase and a tiny clock-tick keeps
time. The last phrase brings the harpsichord up to double the tune before
the loop settles back to the start. Original music made from plain
sine-based instruments, so there is nothing to license.

Run from the project folder:  python tools/make_music_w16.py
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
TAIL_N = int(3.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(1616)
dry = [0.0] * N      # instruments that stay dry-ish
wet = [0.0] * N      # sent to the reverb


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def render(start_beat, seconds, fn, amp, send=0.5):
    """Adds fn(t) for `seconds` from `start_beat` into the dry and wet buses.
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

def harpsichord(f):
    """A plucked quill-on-string: lots of bright harmonics that fade fast (the
    top ones first), two strings a hair apart and a tiny click on the pluck."""
    def fn(t):
        att = min(t / 0.0015, 1.0)
        v = 0.0
        for k in range(1, 10):
            amp = 1.0 / (k ** 0.75)
            dec = 2.4 + 1.1 * k
            v += amp * math.exp(-t * dec) * (math.sin(TAU * f * k * t) + 0.6 * math.sin(TAU * f * 1.0015 * k * t))
        click = random.uniform(-1.0, 1.0) * math.exp(-t * 260.0) * 0.5
        return (v * 0.4 + click) * att
    return fn


def celesta(f):
    """A soft bell-piano: a round fundamental, a quick metallic shimmer on the
    attack and a long gentle fade."""
    def fn(t):
        att = min(t / 0.003, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 2.0)
                      + 0.3 * math.sin(TAU * 2.0 * f * t) * math.exp(-t * 4.0)
                      + 0.16 * math.sin(TAU * 4.0 * f * t) * math.exp(-t * 9.0)
                      + 0.05 * math.sin(TAU * 7.1 * f * t) * math.exp(-t * 22.0))
    return fn


def pizz(f):
    """A plucked cello note for the downbeats."""
    def fn(t):
        att = min(t / 0.004, 1.0)
        return att * (math.sin(TAU * f * t) + 0.35 * math.sin(TAU * 2.0 * f * t) * math.exp(-t * 6.0)
                      + 0.12 * math.sin(TAU * 3.0 * f * t) * math.exp(-t * 9.0)) * math.exp(-t * 3.6)
    return fn


def strings(f, length):
    """Warm, slowly swelling strings."""
    def fn(t):
        att = min(t / 0.6, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.6)
        vib = 1.0 + 0.003 * math.sin(TAU * 5.2 * t)
        v = 0.0
        for d in (0.997, 1.0, 1.003):
            ph = TAU * f * d * vib * t
            v += math.sin(ph) + 0.3 * math.sin(2.0 * ph) + 0.12 * math.sin(3.0 * ph)
        return v / 3.0 * att * rel
    return fn


def tick(t):
    """A small wooden clock tick."""
    return (math.sin(TAU * 2100.0 * t) * 0.6 + random.uniform(-1.0, 1.0) * 0.4) * math.exp(-t * 90.0)


# --- The tune -------------------------------------------------------------------

# (bass note, harpsichord voicing) per bar, F major.
F, Dm, Gm, C7, Bb, C, Am, G7 = (
    (41, [57, 60, 65]), (50, [57, 62, 65]), (43, [58, 62, 67]), (48, [58, 60, 64]),
    (46, [58, 62, 65]), (48, [55, 60, 64]), (45, [57, 60, 64]), (43, [55, 59, 65]),
)
A_PART = [F, Dm, Gm, C7, F, Dm, Gm, F]
B_PART = [Bb, F, Gm, C, Am, Dm, G7, C7]
CHORDS = A_PART + B_PART + A_PART + B_PART[:7] + [C7]

A_TUNE = [
    [(0, 1, 72), (1, 1, 77), (2, 1, 81)],
    [(0, 2, 81), (2, 1, 79)],
    [(0, 1, 79), (1, 1, 77), (2, 1, 74)],
    [(0, 3, 76)],
    [(0, 1, 72), (1, 1, 77), (2, 1, 81)],
    [(0, 2, 84), (2, 1, 81)],
    [(0, 1, 82), (1, 1, 79), (2, 1, 76)],
    [(0, 3, 77)],
]
B_TUNE = [
    [(0, 1, 74), (1, 1, 77), (2, 1, 82)],
    [(0, 2, 81), (2, 1, 77)],
    [(0, 1, 79), (1, 1, 82), (2, 1, 79)],
    [(0, 3, 76)],
    [(0, 1, 76), (1, 1, 79), (2, 1, 84)],
    [(0, 2, 81), (2, 1, 77)],
    [(0, 1, 79), (1, 1, 77), (2, 1, 74)],
    [(0, 2, 76), (2, 1, 79)],
]
TUNE = A_TUNE + B_TUNE + A_TUNE + B_TUNE

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 3
    # Oom: a pizzicato bass note and a low harpsichord root.
    render(b0, 2.0, pizz(mtof(root)), 0.26, send=0.2)
    render(b0, 1.2, harpsichord(mtof(root + 12)), 0.05, send=0.3)
    # Pah-pah: light chords on beats two and three.
    lvl = 0.75 if bar < 8 else 1.0
    for beat in (1, 2):
        for k, m in enumerate(voicing):
            render(b0 + beat + k * 0.012, 0.9, harpsichord(mtof(m)), 0.032 * lvl * (1.0 if beat == 1 else 0.85), send=0.35)
    # Strings from the second phrase.
    if bar >= 8:
        for m in voicing:
            render(b0, BAR + 0.7, strings(mtof(m - 12), BAR), 0.03, send=0.8)
    # Clock ticks on every beat from bar 9, softer off the downbeat.
    if bar >= 8:
        for beat in range(3):
            render(b0 + beat, 0.06, tick, 0.03 if beat == 0 else 0.018, send=0.2)
    # Celesta sparkles: a little broken chord on the last two phrases.
    if bar >= 16:
        for k, beat in enumerate((0.5, 1.5, 2.5)):
            render(b0 + beat, 1.2, celesta(mtof(voicing[k] + 24)), 0.035, send=0.7)

for bar, notes in enumerate(TUNE):
    b0 = bar * 3
    for beat, length, note in notes:
        render(b0 + beat, length * BEAT + 1.2, celesta(mtof(note)), 0.19, send=0.5)
        # The harpsichord doubles the tune an octave down in the last phrases.
        if bar >= 16:
            render(b0 + beat, 1.2, harpsichord(mtof(note - 12)), 0.06, send=0.4)


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
    c = comb(wet, d, 0.84, 0.35)
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

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_16.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
