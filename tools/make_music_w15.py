"""Composes World 15's calm finale loop, "Origami Valley", and writes it to
audio/music/world_15.wav (22.05 kHz mono, 16-bit). A gentle tune in D major
pentatonic: a koto-like plucked arpeggio (bright strings with a little pitch
"press" on each pluck), a breathy bamboo-flute melody, a warm pad, soft
taiko thumps and a light shaker. It starts sparse and builds over the loop
to a hopeful, higher finale with bell sparkles, then settles back to the
start. Original music made from plain sine-based instruments, so there is
nothing to license.

Run from the project folder:  python tools/make_music_w15.py
Pure Python (no numpy); takes about a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 84
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(3.5 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(1515)
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

def koto(f):
    """A plucked silk string: bright harmonics that die away fast, the top
    ones first, and a tiny downward 'press' in pitch right after the pluck."""
    def fn(t):
        att = min(t / 0.002, 1.0)
        bend = 1.0 + 0.006 * math.exp(-t * 25.0)
        v = 0.0
        for k in range(1, 7):
            v += math.sin(TAU * f * k * bend * t) * math.exp(-t * (2.2 + 1.8 * k)) / (k ** 0.8)
        return v * att
    return fn


def flute(f, length):
    """A breathy bamboo flute: soft attack, slow vibrato that grows in, and a
    whisper of breath noise."""
    def fn(t):
        att = min(t / 0.09, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.25)
        vib = 1.0 + 0.006 * min(max(t - 0.25, 0.0) / 0.4, 1.0) * math.sin(TAU * 5.0 * t)
        ph = TAU * f * vib * t
        tone = math.sin(ph) + 0.22 * math.sin(2.0 * ph) + 0.06 * math.sin(3.0 * ph)
        breath = random.uniform(-1.0, 1.0) * 0.05 * (0.4 + 0.6 * math.exp(-t * 6.0))
        return (tone + breath) * att * rel
    return fn


def pad(f, length):
    """Warm, slowly breathing pad."""
    def fn(t):
        att = min(t / 1.2, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 1.0)
        trem = 0.85 + 0.15 * math.sin(TAU * 0.15 * t)
        v = 0.0
        for d in (0.996, 1.0, 1.004):
            v += math.sin(TAU * f * d * t) + 0.25 * math.sin(TAU * 2.0 * f * d * t)
        return v / 3.0 * att * rel * trem
    return fn


def bass(f, length):
    def fn(t):
        att = min(t / 0.02, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.15)
        return (math.sin(TAU * f * t) + 0.15 * math.sin(TAU * 2.0 * f * t)) * att * rel * math.exp(-t * 1.2)
    return fn


def taiko(t):
    f = 62.0 + 40.0 * math.exp(-t * 20.0)
    return math.sin(TAU * f * t) * math.exp(-t * 6.5) + random.uniform(-1, 1) * 0.15 * math.exp(-t * 40.0)


def bell(f):
    def fn(t):
        att = min(t / 0.002, 1.0)
        return att * (math.sin(TAU * f * t) * math.exp(-t * 2.2) + 0.35 * math.sin(TAU * f * 2.76 * t) * math.exp(-t * 4.5))
    return fn


def make_shaker(decay):
    prev = [0.0]

    def fn(t):
        x = random.uniform(-1.0, 1.0)
        hp = x - prev[0]
        prev[0] = x
        return hp * math.exp(-t * decay) * min(t / 0.006, 1.0)
    return fn


# --- The tune -------------------------------------------------------------------

# (bass root, pad voicing) per bar, D major.
PROG = [
    (50, [62, 66, 69, 74]),  # D
    (47, [59, 62, 66, 71]),  # Bm
    (43, [59, 62, 67, 71]),  # G
    (45, [57, 61, 64, 69]),  # A
    (50, [62, 66, 69, 74]),  # D
    (42, [61, 66, 69, 73]),  # F#m
    (43, [59, 62, 67, 71]),  # G
    (45, [57, 62, 64, 69]),  # Asus4, leading home
]
CHORDS = PROG + PROG

# (beat, length in beats, MIDI note) for the flute; it enters in bar 5 and
# climbs to a brighter finale in bars 13-16.
MELODY = [
    (16, 1.5, 74), (17.5, 0.5, 76), (18, 2, 78),
    (20, 1, 81), (21, 1, 78), (22, 2, 76),
    (24, 1.5, 74), (25.5, 0.5, 71), (26, 2, 74),
    (28, 3, 76),
    (32, 1, 78), (33, 1, 81), (34, 2, 83),
    (36, 1, 81), (37, 1, 78), (38, 2, 76),
    (40, 1.5, 78), (41.5, 0.5, 81), (42, 2, 78),
    (44, 3, 76),
    (48, 1, 81), (49, 1, 83), (50, 2, 86),
    (52, 1, 83), (53, 1, 81), (54, 2, 83),
    (56, 1.5, 81), (57.5, 0.5, 78), (58, 1.5, 76), (59.5, 0.5, 78),
    (60, 3, 76),
]
# Koto arpeggio: indexes into the voicing (an octave up), one per eighth.
ARP = [0, 2, 3, 1, 2, 3, 1, 2]

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 4
    for m in voicing:
        render(b0, BAR + 1.0, pad(mtof(m), BAR), 0.035 if bar < 4 else 0.045, send=0.8)
    # Koto: softer in the opening bars, fuller from bar 5.
    lvl = 0.6 if bar < 4 else 1.0
    for k in range(8):
        note = voicing[ARP[k]] + 12
        accent = 1.0 if k % 4 == 0 else 0.75
        render(b0 + k * 0.5, 1.6, koto(mtof(note)), 0.075 * accent * lvl, send=0.55)
    # A low koto root on each downbeat, and a soft bass from bar 5.
    render(b0, 2.0, koto(mtof(root + 12)), 0.08, send=0.4)
    if bar >= 4:
        render(b0, BAR * 0.9, bass(mtof(root), BAR * 0.8), 0.2, send=0.1)
        fifth = root + 7 if root + 7 <= 52 else root - 5
        render(b0 + 2.5, BEAT, bass(mtof(fifth), BEAT * 0.8), 0.12, send=0.1)
    # Soft taiko thumps from bar 9, with a little pick-up in the last bar.
    if bar >= 8:
        render(b0, 0.6, taiko, 0.3, send=0.15)
        render(b0 + 2, 0.6, taiko, 0.22, send=0.15)
        if bar == 15:
            render(b0 + 3, 0.5, taiko, 0.16, send=0.15)
            render(b0 + 3.5, 0.5, taiko, 0.2, send=0.15)
    # A light shaker on the eighths from bar 5.
    if bar >= 4:
        for k in range(8):
            render(b0 + k * 0.5 + (0.0 if k % 2 == 0 else 0.02), 0.09, make_shaker(55.0), 0.022 if k % 2 else 0.014, send=0.3)
    # Bell sparkles over the finale.
    if bar >= 12:
        for k, beat in enumerate((0, 1.5, 3)):
            render(b0 + beat, 1.6, bell(mtof(voicing[(bar + k) % 4] + 24)), 0.045, send=0.7)

for beat, length, note in MELODY:
    render(beat, length * BEAT + 0.4, flute(mtof(note), length * BEAT), 0.16, send=0.5)
    # The koto doubles the melody an octave down in the finale.
    if beat >= 48:
        render(beat, 1.5, koto(mtof(note - 12)), 0.06, send=0.5)


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

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_15.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
