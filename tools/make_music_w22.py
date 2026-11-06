"""Composes World 22's dreamy space loop, "Comet Orbit", and writes it to
audio/music/world_22.wav (22.05 kHz mono, 16-bit). A slow lullaby in F major:
a tinkling music box (steel tines with slightly bell-like overtones) plays a
lazy arpeggio and later the tune, over a warm, slowly breathing synth pad and
a soft round bass. Little twinkles drift in and out like far stars, and from
the middle a soft heartbeat thump keeps time. Original music made from plain
sine-based instruments, so there is nothing to license.

Run from the project folder:  python tools/make_music_w22.py
Pure Python (no numpy); takes about a minute.
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 70
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
LOOP_N = int(round(BARS * BAR * SR))
TAIL_N = int(4.0 * SR)
N = LOOP_N + TAIL_N
TAU = 2.0 * math.pi

random.seed(2222)
dry = [0.0] * N
wet = [0.0] * N


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

def musicbox(f, ring=1.0):
    """A plucked steel tine: a pure tone that rings, a bright inharmonic
    'ting' on top that dies fast, and a tiny click at the start."""
    def fn(t):
        att = min(t / 0.0015, 1.0)
        v = math.sin(TAU * f * t) * math.exp(-t * 1.6 / ring)
        v += 0.32 * math.sin(TAU * f * 3.0 * t) * math.exp(-t * 7.0)
        v += 0.18 * math.sin(TAU * f * 5.4 * t) * math.exp(-t * 14.0)
        return v * att
    return fn


def pad(f, length):
    """A warm synth pad: three slightly detuned voices with a few soft
    harmonics, slow swell and a gentle breathing tremolo."""
    def fn(t):
        att = min(t / 1.6, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 1.4)
        trem = 0.82 + 0.18 * math.sin(TAU * 0.12 * t + f * 0.01)
        v = 0.0
        for d in (0.994, 1.0, 1.006):
            ph = TAU * f * d * t
            v += math.sin(ph) + 0.3 * math.sin(2.0 * ph) + 0.1 * math.sin(3.0 * ph)
        return v / 3.0 * att * rel * trem
    return fn


def bass(f, length):
    def fn(t):
        att = min(t / 0.05, 1.0)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 0.4)
        return (math.sin(TAU * f * t) + 0.12 * math.sin(TAU * 2.0 * f * t)) * att * rel * math.exp(-t * 0.5)
    return fn


def heartbeat(t):
    f = 55.0 + 30.0 * math.exp(-t * 25.0)
    return math.sin(TAU * f * t) * math.exp(-t * 8.0) * min(t / 0.004, 1.0)


def twinkle(f):
    def fn(t):
        att = min(t / 0.003, 1.0)
        shimmer = 1.0 + 0.004 * math.sin(TAU * 7.0 * t)
        return att * math.sin(TAU * f * shimmer * t) * math.exp(-t * 2.5)
    return fn


# --- The tune -------------------------------------------------------------------

# (bass root, pad voicing) per bar.
PROG = [
    (41, [57, 60, 64, 65]),  # Fmaj7
    (45, [55, 60, 64, 67]),  # Am7
    (46, [57, 58, 62, 65]),  # Bbmaj7
    (48, [55, 60, 62, 67]),  # Csus2
    (38, [57, 60, 64, 65]),  # Dm9 (no root)
    (43, [58, 62, 65, 69]),  # Gm9
    (46, [57, 60, 62, 65]),  # Bb6/9-ish
    (48, [55, 58, 64, 67]),  # C7
]
CHORDS = PROG + PROG

# The music-box tune (beat, MIDI note): enters in bar 5, rises for the
# second half and floats back down to rest on the last bar.
MELODY = [
    (16, 81), (17, 84), (18, 79), (19.5, 77),
    (20, 76), (21, 79), (22, 84), (23, 83),
    (24, 81), (25, 77), (26, 74), (27.5, 77),
    (28, 76), (29.5, 79), (30, 72),
    (32, 81), (33, 86), (34, 84), (35, 81),
    (36, 86), (37, 89), (38, 88), (39.5, 86),
    (40, 84), (41, 81), (42, 86), (43, 84),
    (44, 79), (45.5, 82), (46, 81), (47, 79),
    (48, 89), (49, 88), (50, 84), (51.5, 81),
    (52, 86), (53, 84), (54, 81), (55, 79),
    (56, 81), (57, 77), (58, 74), (59, 76),
    (60, 77), (62, 72),
]
# Arpeggio: indexes into the voicing (an octave up), one per eighth.
ARP = [0, 1, 2, 3, 2, 1, 3, 2]

for bar, (root, voicing) in enumerate(CHORDS):
    b0 = bar * 4
    for m in voicing:
        render(b0, BAR + 1.6, pad(mtof(m), BAR), 0.04 if bar < 4 else 0.05, send=0.85)
    # Music-box arpeggio: sparse (quarters) in the opening bars, eighths later.
    step = 1.0 if bar < 4 else 0.5
    lvl = 0.75 if bar < 4 else 0.6
    k = 0
    beat = 0.0
    while beat < 4.0 - 1e-6:
        note = voicing[ARP[k % 8]] + 12
        accent = 1.0 if k % 4 == 0 else 0.8
        render(b0 + beat, 2.2, musicbox(mtof(note), 0.9), 0.07 * accent * lvl, send=0.6)
        beat += step
        k += 1
    # Soft bass from bar 3 (a long note and a gentle push before the bar line).
    if bar >= 2:
        render(b0, BAR * 1.1, bass(mtof(root), BAR * 0.85), 0.2, send=0.15)
        render(b0 + 3, BEAT * 1.2, bass(mtof(root + 7 if root + 7 <= 50 else root - 5), BEAT * 0.8), 0.1, send=0.15)
    # Heartbeat from bar 9 (thump-thump on beat 1, a lone one on beat 3).
    if bar >= 8:
        render(b0, 0.5, heartbeat, 0.34, send=0.1)
        render(b0 + 0.4, 0.5, heartbeat, 0.22, send=0.1)
        render(b0 + 2, 0.5, heartbeat, 0.2, send=0.1)
    # Far-off twinkles: a couple of high notes per bar, scattered.
    for j in range(2 if bar >= 4 else 1):
        when = random.choice((0.5, 1.5, 2.5, 3.5, 1.0, 3.0))
        render(b0 + when, 2.0, twinkle(mtof(random.choice(voicing) + 24)), 0.03, send=0.85)

for beat, note in MELODY:
    render(beat, 2.6, musicbox(mtof(note), 1.4), 0.15, send=0.55)
    # A soft octave-down echo in the second half.
    if beat >= 32:
        render(beat + 0.02, 2.0, musicbox(mtof(note - 12), 1.2), 0.05, send=0.6)


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
for d in (1171, 1249, 1327, 1433):
    c = comb(wet, d, 0.88, 0.35)
    for i in range(N):
        rev[i] += c[i] * 0.25
rev = allpass(rev, 556, 0.5)
rev = allpass(rev, 225, 0.5)

mix = [dry[i] + wet[i] * 0.5 + rev[i] * 0.7 for i in range(N)]

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

out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "music", "world_22.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in mix))
print("wrote", out_path, "%.1f s" % (LOOP_N / SR))
