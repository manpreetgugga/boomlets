"""Composes World 17's sunny loop, "Paint Plaza", and writes it to
audio/music/world_17.wav (22.05 kHz mono, 16-bit). A bouncy café tune in
G major, 4/4 at 118 BPM: a musette accordion (three reeds a hair apart)
plays the tune, a marimba bounces off-beat chords (and rolls arpeggios in
the middle section), a plucked upright bass walks root-and-fifth and a soft
brushed shaker swings along. The last section brings the marimba up to
double the tune before the loop drops back to the start. Original music
made from plain sine-based instruments, so there is nothing to license.

Run from the project folder:  python tools/make_music_w17.py
Pure Python (no numpy); takes about a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 118
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 24
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.0 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi
SWING = 0.08     # off-beat eighths land a little late

random.seed(1717)
dry = [0.0] * N
wet = [0.0] * N


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def swing(b):
    """Pushes off-beat eighths later for a lilting café swing."""
    frac = b - math.floor(b)
    if abs(frac - 0.5) < 1e-6:
        return b + SWING
    return b


def render(start_beat, seconds, fn, amp, send=0.4):
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

def accordion(f, length):
    """A musette accordion: three reeds tuned slightly apart (the warm
    wobble), a reedy odd-heavy tone and a bellows swell on each note."""
    harm = [(1, 1.0), (2, 0.42), (3, 0.5), (4, 0.18), (5, 0.24), (6, 0.08), (7, 0.1)]
    reeds = (0.994, 1.0, 1.0065)

    def fn(t):
        att = min(t / 0.025, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.07)
        swell = 0.85 + 0.15 * math.sin(min(t / max(length, 0.01), 1.0) * math.pi)
        v = 0.0
        for d in reeds:
            ph = TAU * f * d * t
            for k, a in harm:
                v += a * math.sin(k * ph)
        return v / 3.0 * att * rel * swell
    return fn


def marimba(f):
    """A wooden bar: a round fundamental, the bright fourth partial that
    fades fast and a soft mallet knock."""
    def fn(t):
        att = min(t / 0.002, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 5.5)
                      + 0.35 * math.sin(TAU * 3.93 * f * t) * math.exp(-t * 22.0)
                      + 0.12 * math.sin(TAU * 9.2 * f * t) * math.exp(-t * 60.0))
    return fn


def upright(f):
    """A plucked upright bass."""
    def fn(t):
        att = min(t / 0.005, 1.0)
        return att * (math.sin(TAU * f * t) + 0.4 * math.sin(TAU * 2.0 * f * t) * math.exp(-t * 7.0)
                      + 0.15 * math.sin(TAU * 3.0 * f * t) * math.exp(-t * 12.0)) * math.exp(-t * 4.2)
    return fn


def shaker(t):
    return random.uniform(-1.0, 1.0) * (min(t / 0.008, 1.0)) * math.exp(-t * 45.0)


def kick(t):
    return math.sin(TAU * (55.0 + 70.0 * math.exp(-t * 35.0)) * t) * math.exp(-t * 14.0)


# --- The tune -------------------------------------------------------------------

CH = {
    "G": (43, [67, 71, 74]), "D7": (38, [66, 69, 72]), "C": (48, [64, 67, 72]),
    "Em": (40, [64, 67, 71]), "Am": (45, [64, 69, 72]),
}
# Chords per bar as (beat, name) changes.
A_CH = [[(0, "G")], [(0, "D7")], [(0, "G")], [(0, "C")], [(0, "G")], [(0, "Em")], [(0, "Am"), (2, "D7")], [(0, "G")]]
B_CH = [[(0, "C")], [(0, "G")], [(0, "D7")], [(0, "G")], [(0, "C")], [(0, "Em")], [(0, "Am"), (2, "D7")], [(0, "G")]]
CHORDS = A_CH + B_CH + A_CH

A_TUNE = [
    [(0, 1, 71), (1, 0.5, 74), (1.5, 0.5, 71), (2, 1, 67), (3, 1, 71)],
    [(0, 1.5, 72), (1.5, 0.5, 71), (2, 1, 69), (3, 1, 66)],
    [(0, 1, 67), (1, 0.5, 71), (1.5, 0.5, 74), (2, 1, 79), (3, 1, 78)],
    [(0, 2, 76), (2, 1, 72), (3, 1, 76)],
    [(0, 1, 74), (1, 0.5, 79), (1.5, 0.5, 74), (2, 1, 71), (3, 1, 74)],
    [(0, 1.5, 76), (1.5, 0.5, 74), (2, 1, 71), (3, 1, 67)],
    [(0, 1, 69), (1, 1, 72), (2, 1, 76), (3, 1, 78)],
    [(0, 2.5, 79), (3, 0.5, 74), (3.5, 0.5, 71)],
]
B_TUNE = [
    [(0, 1, 76), (1, 0.5, 79), (1.5, 0.5, 76), (2, 1, 72), (3, 1, 76)],
    [(0, 1.5, 74), (1.5, 0.5, 71), (2, 2, 67)],
    [(0, 1, 69), (1, 0.5, 72), (1.5, 0.5, 74), (2, 1, 78), (3, 1, 81)],
    [(0, 2, 79), (2, 1, 74), (3, 1, 71)],
    [(0, 1, 72), (1, 1, 76), (2, 1, 79), (3, 1, 84)],
    [(0, 1.5, 83), (1.5, 0.5, 81), (2, 1, 79), (3, 1, 76)],
    [(0, 1, 74), (1, 1, 72), (2, 1, 69), (3, 1, 66)],
    [(0, 3, 67), (3, 0.5, 71), (3.5, 0.5, 74)],
]
TUNE = A_TUNE + B_TUNE + A_TUNE


def chord_at(bar, beat):
    name = CHORDS[bar][0][1]
    for b, nm in CHORDS[bar]:
        if beat >= b:
            name = nm
    return CH[name]


for bar in range(BARS):
    b0 = bar * 4
    section = bar // 8
    for beat in range(4):
        root, voicing = chord_at(bar, beat)
        # Bass: root on 1, fifth on 3, a walking step on 4 into the next bar.
        if beat in (0, 2):
            note = root if beat == 0 else root + 7
            render(b0 + beat, 0.9, upright(mtof(note)), 0.3, send=0.15)
            render(b0 + beat, 0.25, kick, 0.1 if beat == 0 else 0.06, send=0.05)
        # Marimba off-beat chords on 2 and 4.
        if beat in (1, 3):
            for k, m in enumerate(voicing):
                render(b0 + beat + k * 0.01, 0.9, marimba(mtof(m)), 0.055, send=0.35)
        # Shaker on every eighth, swung.
        for half in (0.0, 0.5):
            render(swing(b0 + beat + half), 0.08, shaker, 0.035 if half == 0.0 else 0.05, send=0.1)
    # Middle section: rolling marimba arpeggios an octave up.
    if section == 1:
        for e in range(8):
            root, voicing = chord_at(bar, e * 0.5)
            m = voicing[[0, 1, 2, 1][e % 4]] + 12
            render(swing(b0 + e * 0.5), 0.7, marimba(mtof(m)), 0.04, send=0.4)

for bar, notes in enumerate(TUNE):
    b0 = bar * 4
    for beat, length, note in notes:
        start = swing(b0 + beat)
        dur = length * BEAT * 0.92
        render(start, dur + 0.1, accordion(mtof(note), dur), 0.085, send=0.35)
        # The marimba doubles the tune in the last section.
        if bar >= 16:
            render(start, 0.9, marimba(mtof(note)), 0.08, send=0.35)


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
    c = comb(wet, d, 0.78, 0.4)
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

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_17.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
