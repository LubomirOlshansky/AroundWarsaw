"""Generate the in-game radio: original vaporwave loops, synthesised from scratch.

Usage: python3 -I tools/make_music.py game/audio/radio shots

Every sound is made here (no samples): slow jazzy seventh chords on detuned saw
pads, a round bass, an FM electric piano, soft drums, a lot of reverb, tape
wobble and a little vinyl hiss. Each track is a seamless loop: every voice is
written into a circular buffer, and the reverb, wobble and filters run over the
loop twice so their state at the end matches the start.

Writes <name>.wav (16-bit stereo). WAV stays gapless (MP3 adds padding at the loop
point and this ffmpeg has no libvorbis); in Godot, import it with loop mode Forward
and QOA compression, which shrinks it about 5x.
Also writes <plots>/music_<name>.png (outside the game, so Godot doesn't ship it): three band-energy lines (bass, mids, highs) over time,
so the arrangement can be checked by eye.
"""
import array
import math
import os
import random
import struct
import sys
import wave
import zlib

RATE = 22050

NOTE = {"C": 0, "Db": 1, "D": 2, "Eb": 3, "E": 4, "F": 5, "Gb": 6, "G": 7, "Ab": 8, "A": 9, "Bb": 10, "B": 11}
SHAPES = {"maj7": [0, 4, 7, 11], "m7": [0, 3, 7, 10], "m9": [0, 3, 7, 10, 14], "maj9": [0, 4, 7, 11, 14],
          "7sus4": [0, 5, 7, 10], "7": [0, 4, 7, 10], "add9": [0, 4, 7, 14], "m11": [0, 3, 7, 10, 17]}

# name, title, bpm, bars per chord, chords (root, shape, octave of the root for the pad)
TRACKS = [
    ("palma_de_gaulle", "Palma de Gaulle'a", 72, 2,
     [("F", "maj7", 3), ("E", "m7", 3), ("D", "m9", 3), ("C", "maj9", 3)]),
    ("rondo_3am", "Rondo Dmowskiego 3 A.M.", 80, 2,
     [("A", "m9", 3), ("F", "maj7", 3), ("D", "m11", 3), ("E", "7sus4", 3)]),
    ("mordor_mall", "Mordor Mall Muzak", 92, 2,
     [("Db", "maj7", 3), ("C", "m7", 3), ("Bb", "m9", 3), ("Eb", "add9", 3)]),
]


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def midi_of(root, octave):
    return 12 * (octave + 1) + NOTE[root]


class Loop:
    """A stereo circular buffer: anything written past the end wraps to the start."""

    def __init__(self, seconds):
        self.n = int(seconds * RATE)
        self.l = array.array("f", [0.0]) * self.n
        self.r = array.array("f", [0.0]) * self.n

    def add(self, i, left, right):
        k = i % self.n
        self.l[k] += left
        self.r[k] += right


def poly_saw(phase, dt):
    """Band-limited saw (polyBLEP), phase in [0, 1)."""
    v = 2.0 * phase - 1.0
    if phase < dt:
        t = phase / dt
        v -= t + t - t * t - 1.0
    elif phase > 1.0 - dt:
        t = (phase - 1.0) / dt
        v -= t * t + t + t + 1.0
    return v


def envelope(t, length, attack, release):
    if t < attack:
        return t / attack
    if t > length:
        return max(0.0, 1.0 - (t - length) / release)
    return 1.0


def pad(loop, start, length, freqs, gain, cutoff, rnd):
    """Detuned saw pair per note through a gentle one-pole low-pass."""
    attack, release = 0.5, 1.2
    total = int((length + release) * RATE)
    a = 1.0 - math.exp(-2 * math.pi * cutoff / RATE)
    for f in freqs:
        for detune, pan in ((-0.0045, 0.25), (0.0045, 0.75)):
            fr = f * (1 + detune)
            dt = fr / RATE
            ph = rnd.random()
            lp = 0.0
            g = gain / len(freqs)
            gl, gr = g * (1 - pan) * 1.4, g * pan * 1.4
            for k in range(total):
                ph += dt
                if ph >= 1.0:
                    ph -= 1.0
                lp += a * (poly_saw(ph, dt) - lp)
                e = envelope(k / RATE, length, attack, release)
                s = lp * e
                loop.add(start + k, s * gl, s * gr)


def bass(loop, start, length, f, gain):
    total = int(length * RATE)
    ph = 0.0
    for k in range(total):
        t = k / RATE
        ph += f / RATE
        e = min(1.0, t / 0.01) * math.exp(-t * 1.6) * (1.0 if t < length - 0.05 else max(0.0, (length - t) / 0.05))
        s = (math.sin(2 * math.pi * ph) + 0.25 * math.sin(4 * math.pi * ph)) * e * gain
        loop.add(start + k, s, s)


def epiano(loop, start, f, gain, pan):
    """Two-operator FM 'electric piano' note with a bell-like attack."""
    total = int(1.6 * RATE)
    for k in range(total):
        t = k / RATE
        index = 1.8 * math.exp(-t * 6.0)
        mod = math.sin(2 * math.pi * f * t) * index
        s = math.sin(2 * math.pi * f * t + mod) * math.exp(-t * 2.2) * min(1.0, t / 0.004) * gain
        loop.add(start + k, s * (1 - pan) * 1.4, s * pan * 1.4)


def kick(loop, start, gain):
    ph = 0.0
    for k in range(int(0.35 * RATE)):
        t = k / RATE
        f = 45 + 80 * math.exp(-t * 28)
        ph += f / RATE
        s = math.sin(2 * math.pi * ph) * math.exp(-t * 9) * gain
        loop.add(start + k, s, s)


def snare(loop, send, start, gain, rnd):
    lp = 0.0
    for k in range(int(0.25 * RATE)):
        t = k / RATE
        noise = rnd.uniform(-1, 1)
        lp += 0.35 * (noise - lp)
        s = ((noise - lp) * 0.8 + 0.4 * math.sin(2 * math.pi * 185 * t)) * math.exp(-t * 18) * gain
        loop.add(start + k, s, s)
        send.add(start + k, s * 1.6, s * 1.6)


def hat(loop, start, gain, rnd, pan):
    prev = 0.0
    for k in range(int(0.06 * RATE)):
        t = k / RATE
        noise = rnd.uniform(-1, 1)
        s = (noise - prev) * math.exp(-t * 70) * gain
        prev = noise
        loop.add(start + k, s * (1 - pan), s * pan)


def reverb(buf, n, room):
    """Schroeder reverb (four combs, two all-passes) run over the loop twice."""
    combs = [int(RATE * d * room) for d in (0.0297, 0.0371, 0.0411, 0.0437)]
    allp = [int(RATE * d) for d in (0.005, 0.0017)]
    cb = [array.array("f", [0.0]) * c for c in combs]
    ci = [0] * 4
    ab = [array.array("f", [0.0]) * a for a in allp]
    ai = [0] * 2
    out = array.array("f", [0.0]) * n
    for rep in range(2):
        for i in range(n):
            x = buf[i]
            y = 0.0
            for c in range(4):
                d = cb[c][ci[c]]
                cb[c][ci[c]] = x + d * 0.84
                ci[c] = (ci[c] + 1) % combs[c]
                y += d
            y *= 0.25
            for a in range(2):
                d = ab[a][ai[a]]
                ab[a][ai[a]] = y + d * 0.5
                ai[a] = (ai[a] + 1) % allp[a]
                y = d - 0.5 * y
            if rep == 1:
                out[i] = y
    return out


def tape(chan, n, seed):
    """Wow and flutter: read the loop through a slowly wandering delay."""
    out = array.array("f", [0.0]) * n
    base = 0.012 * RATE
    for i in range(n):
        t = i / RATE
        # Wobble frequencies are whole cycles per loop so it stays seamless.
        cycles_wow = max(1, round(0.45 * n / RATE))
        cycles_fl = max(1, round(5.3 * n / RATE))
        d = base + 0.0035 * RATE * math.sin(2 * math.pi * cycles_wow * i / n + seed) \
            + 0.0004 * RATE * math.sin(2 * math.pi * cycles_fl * i / n)
        p = i - d
        k = math.floor(p)
        f = p - k
        out[i] = chan[k % n] * (1 - f) + chan[(k + 1) % n] * f
    return out


def lowpass_loop(chan, n, cutoff):
    a = 1.0 - math.exp(-2 * math.pi * cutoff / RATE)
    out = array.array("f", [0.0]) * n
    y = 0.0
    for rep in range(2):
        for i in range(n):
            y += a * (chan[i] - y)
            if rep == 1:
                out[i] = y
    return out


def render(name, bpm, bars_per_chord, chords, seed):
    rnd = random.Random(seed)
    beat = 60.0 / bpm
    bar = 4 * beat
    progression = chords * 2  # two passes of the progression make the loop
    seconds = len(progression) * bars_per_chord * bar
    dry = Loop(seconds)
    send = Loop(seconds)

    for ci, (root, shape, octave) in enumerate(progression):
        t0 = ci * bars_per_chord * bar
        start = int(t0 * RATE)
        notes = [midi_of(root, octave) + iv for iv in SHAPES[shape]]
        span = bars_per_chord * bar
        pad(dry, start, span - 0.2, [hz(m) for m in notes], 0.30, 1400 + 400 * (ci % 2), rnd)
        pad(send, start, span - 0.2, [hz(m + 12) for m in notes[:3]], 0.10, 2200, rnd)
        broot = midi_of(root, 1) + (12 if NOTE[root] < 4 else 0)
        for b in range(bars_per_chord * 2):
            hop = 7 if b % 2 else 0
            bass(dry, int((t0 + b * 2 * beat) * RATE), 2 * beat - 0.05, hz(broot + hop), 0.32)
        # Electric piano: a lazy, seeded arpeggio of the chord tones an octave up.
        for step in range(bars_per_chord * 8):
            if rnd.random() < 0.42:
                m = rnd.choice(notes) + 12
                t = t0 + step * beat / 2 + rnd.uniform(0, 0.02)
                epiano(dry, int(t * RATE), hz(m), 0.09, rnd.uniform(0.3, 0.7))
                epiano(send, int(t * RATE), hz(m), 0.05, 0.5)

    beats = int(round(seconds / beat))
    for b in range(beats):
        t = b * beat
        if b % 4 in (0,) or (b % 8 == 6 and rnd.random() < 0.7):
            kick(dry, int(t * RATE), 0.55)
        if b % 4 in (1, 3):
            snare(dry, send, int((t + 0.012) * RATE), 0.22, rnd)
        for half in (0, 1):
            if rnd.random() < 0.85:
                hat(dry, int((t + half * beat / 2 + 0.006) * RATE), 0.05 if half else 0.08, rnd, rnd.uniform(0.35, 0.65))

    n = dry.n
    wet_l = reverb(send.l, n, 1.0)
    wet_r = reverb(send.r, n, 1.07)
    mix_l = array.array("f", (dry.l[i] + wet_l[i] * 0.9 + dry.l[i] * 0.0 for i in range(n)))
    mix_r = array.array("f", (dry.r[i] + wet_r[i] * 0.9 for i in range(n)))
    # A little room on everything too.
    room_l = reverb(mix_l, n, 0.6)
    room_r = reverb(mix_r, n, 0.63)
    for i in range(n):
        mix_l[i] += room_l[i] * 0.25
        mix_r[i] += room_r[i] * 0.25
    mix_l = lowpass_loop(tape(mix_l, n, seed * 0.7), n, 5200)
    mix_r = lowpass_loop(tape(mix_r, n, seed * 0.7 + 0.4), n, 5200)

    # Vinyl: soft hiss and the odd crackle.
    for i in range(n):
        h = rnd.uniform(-1, 1) * 0.004
        if rnd.random() < 0.00012:
            h += rnd.uniform(-0.25, 0.25)
        mix_l[i] += h
        mix_r[i] += h * 0.9

    peak = max(max(abs(v) for v in mix_l), max(abs(v) for v in mix_r))
    gain = 0.82 / peak
    out_l = [math.tanh(v * gain * 1.1) / math.tanh(1.1) for v in mix_l]
    out_r = [math.tanh(v * gain * 1.1) / math.tanh(1.1) for v in mix_r]
    return seconds, out_l, out_r


def write_wav(path, left, right):
    data = array.array("h")
    for a, b in zip(left, right):
        data.append(int(max(-1.0, min(1.0, a)) * 32767))
        data.append(int(max(-1.0, min(1.0, b)) * 32767))
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def band_plot(path, left, right):
    """PNG of bass / mid / high energy over time (orange, green, cyan)."""
    mono = [(a + b) * 0.5 for a, b in zip(left, right)]
    width, height = 800, 240
    hop = max(1, len(mono) // width)
    lo = mid_lp = 0.0
    a_lo = 1.0 - math.exp(-2 * math.pi * 200 / RATE)
    a_mid = 1.0 - math.exp(-2 * math.pi * 2000 / RATE)
    bands = [[0.0] * width for _ in range(3)]
    for i, x in enumerate(mono):
        lo += a_lo * (x - lo)
        mid_lp += a_mid * (x - mid_lp)
        col = min(width - 1, i // hop)
        bands[0][col] += lo * lo
        bands[1][col] += (mid_lp - lo) ** 2
        bands[2][col] += (x - mid_lp) ** 2
    pixels = bytearray([16, 12, 28] * width * height)
    colours = [(255, 150, 60), (90, 220, 130), (80, 210, 240)]
    for b in range(3):
        vals = [math.sqrt(v / hop) for v in bands[b]]
        top = max(vals) or 1.0
        for x in range(width):
            y = height - 1 - int(vals[x] / top * (height / 3 - 4)) - b * height // 3
            for yy in range(max(0, y - 1), min(height, y + 1)):
                k = (yy * width + x) * 3
                pixels[k:k + 3] = bytes(colours[b])
    raw = b"".join(b"\x00" + bytes(pixels[y * width * 3:(y + 1) * width * 3]) for y in range(height))

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)) \
        + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


# --- loop MW-5: PÓŁNOC FM, 86,0 (docs/design/vision.md 4.6) ---------------------------
#
# Seven slow boom-bap / lo-fi instrumentals for the late-night station, one per brief:
# BPM, key and parts as the table says. Same rules as the loops above: every voice is
# synthesised here (no samples), written into a circular buffer, and every filter, the
# reverb and the tape wobble run round the loop twice, so the end flows into the start.
# Each is a whole number of bars (90-120 s) with an arrangement inside the loop: four
# bars of keys before the drums come in, the groove, a four-bar breakdown, the groove
# again with the lead on top; the loop point is the downbeat of bar 1.

# number, file stem, title (exactly as the brief), BPM, key (as the brief says it), tonic,
# scale, bars, chords per 8 bars (root, shape, bars).
POLNOC = [
    (1, "sod", "Sód", 78, "D minor", "D", "minor", 32,
     [("D", "m9", 2), ("Bb", "maj9", 2), ("G", "m9", 2), ("A", "7sus4", 1), ("A", "7b9", 1)]),
    (2, "wiadukt", "Wiadukt", 84, "A minor", "A", "minor", 32,
     [("A", "m9", 2), ("D", "m9", 2), ("G", "6", 2), ("F", "maj7", 1), ("E", "7", 1)]),
    (3, "nocna_przesiadka", "Nocna przesiadka", 80, "F minor", "F", "minor", 32,
     [("F", "m9", 2), ("Eb", "6", 2), ("Db", "maj7", 2), ("C", "7sus4", 1), ("C", "7b9", 1)]),
    (4, "szklo_na_woli", "Szkło na Woli", 88, "E minor", "E", "minor", 40,
     [("E", "m9", 2), ("C", "maj9", 2), ("G", "maj7", 2), ("D", "6", 2)]),
    (5, "bulwar_2340", "Bulwar, 23:40", 74, "C major 7", "C", "major", 32,
     [("C", "maj7", 2), ("A", "m7", 1), ("F", "maj7", 1), ("C", "maj7", 2), ("A", "m7", 1), ("F", "maj7", 1)]),
    (6, "mgla_nad_palacem", "Mgła nad Pałacem", 70, "B♭ minor", "Bb", "minor", 32,
     [("Bb", "m9", 2), ("Gb", "maj7", 2), ("Eb", "m9", 2), ("F", "7sus4", 1), ("F", "7b9", 1)]),
    (7, "swit_na_smolnej", "Świt na Smolnej", 90, "G major", "G", "major", 40,
     [("G", "maj7", 2), ("E", "m9", 2), ("C", "maj9", 2), ("D", "sus4", 1), ("D", "6", 1)]),
]
SHAPES.update({"7b9": [0, 4, 7, 10, 13], "6": [0, 4, 7, 9], "sus4": [0, 5, 7], "m6": [0, 3, 7, 9]})
SCALES = {"minor": [0, 2, 3, 5, 7, 8, 10], "major": [0, 2, 4, 5, 7, 9, 11]}
TAU = 2.0 * math.pi


def zeros(n):
    return array.array("d", bytes(8 * n))


def put(loop, sig, start, gain=1.0, pan=0.5):
    """Adds a mono signal into a Loop from sample `start`, equal-power panned (0 left, 1 right)."""
    if gain == 0.0:
        return
    n = loop.n
    gl = gain * math.cos(pan * math.pi / 2) * 1.4142
    gr = gain * math.sin(pan * math.pi / 2) * 1.4142
    L, R = loop.l, loop.r
    k = start % n
    for v in sig:
        L[k] += v * gl
        R[k] += v * gr
        k += 1
        if k == n:
            k = 0


def put2(loop, left, right, start, gain=1.0):
    n = loop.n
    L, R = loop.l, loop.r
    k = start % n
    for a, b in zip(left, right):
        L[k] += a * gain
        R[k] += b * gain
        k += 1
        if k == n:
            k = 0


def onepole_lp(x, f):
    a = 1.0 - math.exp(-TAU * f / RATE)
    y = 0.0
    out = zeros(len(x))
    for i, v in enumerate(x):
        y += a * (v - y)
        out[i] = y
    return out


def biquad_bp(x, f, q):
    """RBJ band-pass (0 dB peak), one pass (for notes, not loops)."""
    w = TAU * f / RATE
    alpha = math.sin(w) / (2 * q)
    a0 = 1 + alpha
    b0, b2 = alpha / a0, -alpha / a0
    a1, a2 = -2 * math.cos(w) / a0, (1 - alpha) / a0
    x1 = x2 = y1 = y2 = 0.0
    out = zeros(len(x))
    for i, v in enumerate(x):
        y = b0 * v + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, v, y1, y
        out[i] = y
    return out


def loop_filter(chan, kind, f, q=0.707):
    """RBJ low/high/band-pass round a loop (two passes, the second kept): seamless."""
    w = TAU * min(f, RATE * 0.45) / RATE
    cw = math.cos(w)
    alpha = math.sin(w) / (2 * q)
    if kind == "lp":
        b0, b1, b2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
    elif kind == "hp":
        b0, b1, b2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
    else:
        b0, b1, b2 = alpha, 0.0, -alpha
    a0 = 1 + alpha
    b0, b1, b2, a1, a2 = b0 / a0, b1 / a0, b2 / a0, -2 * cw / a0, (1 - alpha) / a0
    n = len(chan)
    out = array.array("f", [0.0]) * n
    x1 = x2 = y1 = y2 = 0.0
    for rep in range(2):
        for i in range(n):
            v = chan[i]
            y = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            x2, x1, y2, y1 = x1, v, y1, y
            out[i] = y
    return out


# --- instruments (each returns a mono note; the caller places it) ----------------------

def rhodes(f, length, rnd, bright=1.0):
    """An FM electric piano: a 1:1 pair with a decaying index, a soft tine at 14x, held
    `length` s then released."""
    total = int((length + 0.5) * RATE)
    out = zeros(total)
    w = TAU * f / RATE
    wt = TAU * f * 14.0 / RATE
    if f * 14.0 > RATE * 0.45:
        wt = 0.0
    ph = rnd.random() * TAU
    for k in range(total):
        t = k / RATE
        idx = (0.4 + 1.6 * math.exp(-t * 5.0)) * bright
        env = math.exp(-t * 0.9) * min(1.0, t / 0.003)
        if t > length:
            env *= max(0.0, 1.0 - (t - length) / 0.5)
        s = math.sin(w * k + ph + idx * math.sin(w * k))
        if wt:
            s += 0.18 * bright * math.sin(wt * k) * math.exp(-t * 18.0)
        out[k] = s * env
    return out


def piano(f, length, rnd, muted=False):
    """A plucked-string piano: slightly stretched partials, the high ones dying first, a
    felt-hammer knock; `muted` damps it to a short stab."""
    total = int((min(length, 0.35 if muted else length) + (0.12 if muted else 0.6)) * RATE)
    out = zeros(total)
    for h in range(1, 9):
        fh = f * h * math.sqrt(1 + 0.0004 * h * h)
        if fh > RATE * 0.45:
            break
        amp = 1.0 / h ** 1.25
        dec = (0.9 if muted else 2.6) / (1 + 0.45 * (h - 1))
        w = TAU * fh / RATE
        ph = rnd.random() * TAU
        k_dec = math.exp(-1.0 / (dec * RATE))
        e = amp
        for k in range(total):
            out[k] += e * math.sin(w * k + ph)
            e *= k_dec
    hold = int((0.3 if muted else length) * RATE)
    for k in range(total):
        a = min(1.0, k / (0.002 * RATE))
        if k > hold:
            a *= max(0.0, 1.0 - (k - hold) / (total - hold + 1))
        out[k] *= a
    knock = int(0.01 * RATE)
    for k in range(knock):
        out[k] += rnd.uniform(-1, 1) * 0.08 * (1 - k / knock)
    return onepole_lp(out, 2200 if muted else 4200)


def vibes(f, length, rnd):
    """A vibraphone bar: the fundamental, the 4x and 10x modes, the motor's tremolo."""
    total = int((length + 1.2) * RATE)
    out = zeros(total)
    for ratio, amp, dec in ((1.0, 1.0, 2.4), (3.93, 0.28, 0.45), (9.9, 0.08, 0.12)):
        w = TAU * f * ratio / RATE
        if f * ratio > RATE * 0.45:
            continue
        kd = math.exp(-1.0 / (dec * RATE))
        e = amp
        for k in range(total):
            out[k] += e * math.sin(w * k)
            e *= kd
    tw = TAU * 5.2 / RATE
    for k in range(total):
        out[k] *= (0.78 + 0.22 * math.sin(tw * k)) * min(1.0, k / 40.0)
    return out


def glass(f, rnd):
    """A glassy pluck: FM at 3.5:1 with a fast-falling index, a short bright decay."""
    total = int(0.9 * RATE)
    out = zeros(total)
    w = TAU * f / RATE
    for k in range(total):
        t = k / RATE
        idx = 2.2 * math.exp(-t * 14.0)
        out[k] = math.sin(w * k + idx * math.sin(3.5 * w * k)) * math.exp(-t * 4.2) * min(1.0, k / 30.0)
    return out


def nylon(f, length, rnd):
    """A nylon string (Karplus-Strong): a burst of soft noise in a delay line that averages
    itself away; warm, short."""
    period = RATE / f
    d = int(period)
    frac = period - d
    total = int((length + 0.3) * RATE)
    buf = [rnd.uniform(-1, 1) for _ in range(d + 2)]
    lp = 0.0
    for i in range(len(buf)):
        lp += 0.5 * (buf[i] - lp)
        buf[i] = lp
    out = zeros(total)
    m = len(buf)
    p = 0
    decay = 0.9965
    hold = int(length * RATE)
    for k in range(total):
        a = buf[p % m]
        b = buf[(p + 1) % m]
        v = (a * (1 - frac) + b * frac)
        nv = decay * 0.5 * (a + b)
        buf[p % m] = nv
        p += 1
        if p >= d:
            p = 0
        e = 1.0 if k < hold else max(0.0, 1.0 - (k - hold) / (0.3 * RATE))
        out[k] = v * e
    return onepole_lp(out, 2600)


def saw_voice(f, length, attack, release, cutoff0, cutoff1, rnd, vibrato=0.0, detune=0.004):
    """Two detuned band-limited saws through a one-pole low-pass that moves from cutoff0 to
    cutoff1 over the note: a pad voice. Returns (left, right)."""
    total = int((length + release) * RATE)
    left, right = zeros(total), zeros(total)
    for dt_, pan in ((-detune, 0.2), (detune, 0.8)):
        fr = f * (1 + dt_)
        dt = fr / RATE
        ph = rnd.random()
        lp = 0.0
        vp = rnd.random() * TAU
        vw = TAU * 4.8 / RATE
        for k in range(total):
            t = k / RATE
            inc = dt * (1.0 + vibrato * math.sin(vp + vw * k)) if vibrato else dt
            ph += inc
            if ph >= 1.0:
                ph -= 1.0
            c = cutoff0 + (cutoff1 - cutoff0) * min(1.0, t / max(length, 0.01))
            a = 1.0 - math.exp(-TAU * c / RATE)
            lp += a * (poly_saw(ph, inc) - lp)
            env = min(1.0, t / attack) if t < length else max(0.0, 1.0 - (t - length) / release)
            s = lp * env
            left[k] += s * (1 - pan)
            right[k] += s * pan
    return left, right


def sub_bass(f0, length, f1=None, glide=0.0, drive=1.2):
    """A round sine bass with a touch of second harmonic; with f1, it glides there over
    the last `glide` seconds."""
    total = int((length + 0.08) * RATE)
    out = zeros(total)
    ph = 0.0
    g0 = length - glide
    for k in range(total):
        t = k / RATE
        f = f0
        if f1 is not None and glide > 0 and t > g0:
            u = min(1.0, (t - g0) / glide)
            u = u * u * (3 - 2 * u)
            f = f0 * (f1 / f0) ** u
        ph += f / RATE
        e = min(1.0, t / 0.012)
        if t > length:
            e *= max(0.0, 1.0 - (t - length) / 0.08)
        s = math.sin(TAU * ph) + 0.22 * math.sin(2 * TAU * ph)
        out[k] = math.tanh(drive * s) / math.tanh(drive) * e
    return out


def chirp(f0, f1, length, rnd):
    total = int(length * RATE)
    out = zeros(total)
    ph = 0.0
    for k in range(total):
        u = k / total
        f = f0 + (f1 - f0) * (u * u if f1 > f0 else u)
        ph += f / RATE
        e = math.sin(math.pi * u) ** 1.5
        out[k] = (math.sin(TAU * ph) + 0.15 * math.sin(2 * TAU * ph)) * e
    return out


# --- drums (rendered once per track, a few variants each) -------------------------------

def d_kick(rnd, punch=1.0, tone=48.0, decay=7.0):
    total = int(0.45 * RATE)
    out = zeros(total)
    ph = 0.0
    for k in range(total):
        t = k / RATE
        f = tone + 95 * punch * math.exp(-t * 32)
        ph += f / RATE
        out[k] = math.tanh(1.6 * math.sin(TAU * ph)) * math.exp(-t * decay)
    for k in range(int(0.004 * RATE)):
        out[k] += rnd.uniform(-1, 1) * 0.25 * punch
    return onepole_lp(out, 1800)


def d_snare(rnd, crisp=0.0, tone=190.0, dark=4200.0, decay=16.0):
    total = int(0.32 * RATE)
    nz = zeros(total)
    for k in range(total):
        nz[k] = rnd.uniform(-1, 1)
    body = biquad_bp(nz, 1700 + 2200 * crisp, 0.8)
    out = zeros(total)
    for k in range(total):
        t = k / RATE
        out[k] = (body[k] * 1.6 + 0.55 * math.sin(TAU * tone * t) * math.exp(-t * 30)) * math.exp(-t * decay)
    return onepole_lp(out, dark + 5000 * crisp)


def d_clap(rnd, soft=1.0):
    total = int(0.4 * RATE)
    nz = zeros(total)
    for k in range(total):
        nz[k] = rnd.uniform(-1, 1)
    body = biquad_bp(nz, 1150, 1.1)
    out = zeros(total)
    for k in range(total):
        t = k / RATE
        e = 0.0
        for at in (0.0, 0.009, 0.019):
            if t >= at:
                e = max(e, math.exp(-(t - at) * 140))
        e = max(e, 0.35 * math.exp(-t * 11) if t > 0.024 else 0.0)
        out[k] = body[k] * e
    return onepole_lp(out, 3600 * soft)


def d_hat(rnd, length=0.07, bright=1.0, decay=60.0):
    total = int(length * RATE)
    out = zeros(total)
    prev = 0.0
    for k in range(total):
        v = rnd.uniform(-1, 1)
        out[k] = (v - prev) * math.exp(-k / RATE * decay)
        prev = v
    return onepole_lp(out, 5200 + 4000 * bright) if bright < 1.5 else out


def d_rim(rnd):
    total = int(0.08 * RATE)
    out = zeros(total)
    for k in range(total):
        t = k / RATE
        out[k] = (math.sin(TAU * 820 * t) * 0.7 + math.sin(TAU * 1620 * t) * 0.3) * math.exp(-t * 60) \
            + rnd.uniform(-1, 1) * 0.2 * math.exp(-t * 200)
    return out


def d_brush(rnd, length=0.22):
    """A brush swish: band-passed noise that swells and fades."""
    total = int(length * RATE)
    nz = zeros(total)
    for k in range(total):
        nz[k] = rnd.uniform(-1, 1)
    body = biquad_bp(nz, 4200, 0.6)
    out = zeros(total)
    for k in range(total):
        u = k / total
        out[k] = body[k] * (math.sin(math.pi * u) ** 0.8)
    return out


def d_brush_tap(rnd):
    total = int(0.18 * RATE)
    nz = zeros(total)
    for k in range(total):
        nz[k] = rnd.uniform(-1, 1)
    body = biquad_bp(nz, 2600, 0.7)
    out = zeros(total)
    for k in range(total):
        t = k / RATE
        out[k] = body[k] * math.exp(-t * 24) * 1.4
    return out


# --- beds: periodic over the loop -------------------------------------------------------

def vinyl(n, rnd, crackle=1.0, hiss=1.0):
    """Hiss, a low rumble and crackle (sparse clicks of two sizes), stereo."""
    chans = []
    for c in range(2):
        x = array.array("f", [0.0]) * n
        for i in range(n):
            x[i] = rnd.uniform(-1, 1) * 0.0035 * hiss
        hiss_f = loop_filter(x, "lp", 6000)
        for _ in range(int(n / RATE * 9 * crackle)):
            at = rnd.randrange(n)
            amp = rnd.uniform(0.02, 0.07) if rnd.random() < 0.9 else rnd.uniform(0.1, 0.2)
            for k in range(int(0.0015 * RATE)):
                hiss_f[(at + k) % n] += amp * rnd.uniform(-1, 1) * (1 - k / (0.0015 * RATE))
        chans.append(hiss_f)
    return chans


def river(n, rnd):
    """The Vistula at the steps: low wash with slow swells, a lap now and then, stereo."""
    chans = []
    swell_c = max(1, round(n / RATE / 7.5))
    lap_c = max(1, round(n / RATE / 2.6))
    for c in range(2):
        x = array.array("f", [0.0]) * n
        for i in range(n):
            x[i] = rnd.uniform(-1, 1)
        low = loop_filter(loop_filter(x, "lp", 480, 0.6), "hp", 90)
        lap = loop_filter(x, "bp", 900 + 140 * c, 1.4)
        out = array.array("f", [0.0]) * n
        for i in range(n):
            u = i / n
            sw = 0.6 + 0.4 * math.sin(TAU * (swell_c * u + 0.3 * c))
            lp_ = max(0.0, math.sin(TAU * (lap_c * u + 0.17 * c))) ** 6
            out[i] = low[i] * 0.3 * sw + lap[i] * 0.45 * lp_
        chans.append(out)
    return chans


# --- the arrangement ----------------------------------------------------------------------

def voicing(root, shape, centre=62, drop_root=True):
    """The chord's tones as MIDI notes in a close cluster round `centre` (the root left out
    of 5-note shapes: the bass has it)."""
    ivs = SHAPES[shape]
    if drop_root and len(ivs) >= 5:
        ivs = ivs[1:]
    pcs = [(NOTE[root] + iv) % 12 for iv in ivs]
    notes = []
    for pc in pcs:
        m = pc + 12 * round((centre - pc) / 12)
        while m < centre - 6:
            m += 12
        while m > centre + 6:
            m -= 12
        notes.append(m)
    return sorted(set(notes))


def scale_notes(tonic, scale, lo, hi):
    pcs = {(NOTE[tonic] + iv) % 12 for iv in SCALES[scale]}
    return [m for m in range(lo, hi + 1) if m % 12 in pcs]


def melody(rnd, bars, tonic, scale, chords_at, lo, hi, density=0.45, steps_per_bar=8):
    """A seeded lead: a two-bar phrase on the 8th-note grid, chord tones on the strong
    steps, stepwise in between, repeated with small changes. -> [(bar, step, midi, steps long)]."""
    notes = scale_notes(tonic, scale, lo, hi)
    out = []
    phrase = None
    for b0 in range(0, bars, 2):
        if phrase is None or rnd.random() < 0.4:
            rhythm = [s for s in range(2 * steps_per_bar) if (rnd.random() < density) or s == 0]
            phrase = rhythm
        cur = notes[len(notes) // 2]
        for idx, s in enumerate(phrase):
            bar = b0 + s // steps_per_bar
            step = s % steps_per_bar
            if bar >= bars:
                break
            tones = chords_at(bar)
            if step % 4 == 0:
                cands = [m for m in notes if m % 12 in tones]
            else:
                cands = [m for m in notes if abs(m - cur) <= 3]
            if not cands:
                cands = notes
            cands.sort(key=lambda m: abs(m - cur) + rnd.random() * 2.5)
            cur = cands[0]
            nxt = phrase[idx + 1] if idx + 1 < len(phrase) else 2 * steps_per_bar
            out.append((bar, step, cur, max(1, nxt - s)))
    return out


class Track:
    """The bars, the chords and the buses for one PÓŁNOC FM render."""

    def __init__(self, spec):
        (self.number, self.stem, self.title, self.bpm, self.key, self.tonic, self.scale,
         self.bars, self.cycle) = spec
        self.rnd = random.Random(500 + self.number)
        self.beat = 60.0 / self.bpm
        self.bar = 4 * self.beat
        self.seconds = self.bars * self.bar
        self.dry = Loop(self.seconds)
        self.send = Loop(self.seconds)
        self.n = self.dry.n
        # the chord under each bar
        per = []
        for root, shape, nb in self.cycle:
            per += [(root, shape)] * nb
        self.chord = [per[b % len(per)] for b in range(self.bars)]
        self.cycle_bars = len(per)

    def t(self, bar, beat=0.0):
        return int((bar * self.bar + beat * self.beat) * RATE)

    def tones(self, bar):
        root, shape = self.chord[bar % self.bars]
        return {(NOTE[root] + iv) % 12 for iv in SHAPES[shape]}

    def section(self, bar):
        """'intro' (4 bars), 'a', 'break' (4 bars mid-way), 'b'."""
        half = self.bars // 2
        if bar < 4:
            return "intro"
        if half <= bar < half + 4:
            return "break"
        return "a" if bar < half else "b"

    def chord_runs(self):
        """(start bar, bars, root, shape) for each held chord."""
        runs = []
        b = 0
        while b < self.bars:
            root, shape = self.chord[b]
            k = 1
            while b + k < self.bars and self.chord[b + k] == (root, shape) and (b + k) % self.cycle_bars != 0 \
                    and not self._cycle_start(b + k):
                k += 1
            runs.append((b, k, root, shape))
            b += k
        return runs

    def _cycle_start(self, bar):
        pos = bar % self.cycle_bars
        acc = 0
        for _, _, nb in self.cycle:
            if acc == pos:
                return True
            acc += nb
        return False

    def drums(self, pattern, kit, swing=0.0, sections=("a", "b"), fill=True, jitter=0.006):
        """pattern: {voice: 16-char string per bar ('x' hit, 'o' soft, '.' rest)}; kit: {voice:
        ([variants], gain, pan, send)}."""
        rnd = self.rnd
        for bar in range(self.bars):
            sec = self.section(bar)
            if sec not in sections:
                continue
            last = fill and bar % 4 == 3
            for voice, steps in pattern.items():
                if voice not in kit:
                    continue
                variants, gain, pan, send = kit[voice]
                if isinstance(steps, (list, tuple)):
                    steps = steps[1] if last and len(steps) > 1 else steps[0]
                for s, ch in enumerate(steps):
                    if ch == ".":
                        continue
                    v = 1.0 if ch == "x" else 0.45
                    delay = 0.0
                    if s % 4 == 2:
                        delay += swing * self.beat / 6
                    elif s % 2 == 1:
                        delay += swing * self.beat / 10
                    at = self.t(bar, s / 4) + int((delay + rnd.uniform(-jitter, jitter)) * RATE)
                    g = gain * v * rnd.uniform(0.85, 1.0)
                    sig = rnd.choice(variants)
                    put(self.dry, sig, at, g, pan + rnd.uniform(-0.04, 0.04))
                    if send:
                        put(self.send, sig, at, g * send, 0.5)

    def bassline(self, pattern, gain, octave=1, glide=0.0, sections=("intro", "a", "break", "b"), drive=1.2):
        """pattern: [(beat in the bar, beats long, interval)] per bar; the root of the bar's chord."""
        cache = {}
        for bar in range(self.bars):
            if self.section(bar) not in sections:
                continue
            root, _ = self.chord[bar]
            base = midi_of(root, octave)
            if base < 31:
                base += 12
            nxt_root, _ = self.chord[(bar + 1) % self.bars]
            nb = midi_of(nxt_root, octave)
            if nb < 31:
                nb += 12
            for beat, length, iv in pattern:
                f0 = hz(base + iv)
                last = beat + length >= 4.0 - 1e-6
                f1 = hz(nb) if glide and last and nxt_root != root else None
                key = (round(f0, 2), length, f1 and round(f1, 2))
                if key not in cache:
                    cache[key] = sub_bass(f0, length * self.beat - 0.04, f1, glide * self.beat if f1 else 0.0, drive)
                put(self.dry, cache[key], self.t(bar, beat), gain, 0.5)

    def finish(self, lead_room=1.0, wet=0.9, cutoff=5200, wobble=1.0, crackle=1.0, hiss=1.0, extra=None, drive_cap=3.0):
        """Reverb on the send, a little room on everything, the tape, the vinyl; one soft
        saturation stage set so the loop's crest (peak over RMS) is about 12 dB."""
        n = self.n
        wl = reverb(self.send.l, n, 1.0 * lead_room)
        wr = reverb(self.send.r, n, 1.07 * lead_room)
        ml = array.array("f", (self.dry.l[i] + wl[i] * wet for i in range(n)))
        mr = array.array("f", (self.dry.r[i] + wr[i] * wet for i in range(n)))
        rl = reverb(ml, n, 0.6)
        rr = reverb(mr, n, 0.63)
        for i in range(n):
            ml[i] += rl[i] * 0.2
            mr[i] += rr[i] * 0.2
        if extra is not None:
            for chans, g in extra:
                for i in range(n):
                    ml[i] += chans[0][i] * g
                    mr[i] += chans[1][i] * g
        seed = self.number * 0.9
        ml = tape_amount(ml, n, seed, wobble)
        mr = tape_amount(mr, n, seed + 0.4, wobble)
        ml = loop_filter(loop_filter(ml, "lp", cutoff, 0.6), "hp", 28)
        mr = loop_filter(loop_filter(mr, "lp", cutoff, 0.6), "hp", 28)
        vl, vr = vinyl(n, self.rnd, crackle, hiss)
        for i in range(n):
            ml[i] += vl[i]
            mr[i] += vr[i]
        peak = max(max(abs(v) for v in ml), max(abs(v) for v in mr))
        g = 1.0 / peak
        drive = 1.0
        while True:
            th = math.tanh(drive)
            sq = 0.0
            pk = 0.0
            for i in range(0, n, 3):
                a = math.tanh(ml[i] * g * drive) / th
                b = math.tanh(mr[i] * g * drive) / th
                sq += a * a + b * b
            rms = math.sqrt(sq / (2 * len(range(0, n, 3))))
            crest = -20 * math.log10(max(rms, 1e-9))
            if crest <= 12.0 or drive >= drive_cap:
                break
            drive += 0.15
        th = math.tanh(drive)
        out_l = [0.89 * math.tanh(v * g * drive) / th for v in ml]
        out_r = [0.89 * math.tanh(v * g * drive) / th for v in mr]
        self.drive, self.crest = drive, crest
        return out_l, out_r


def tape_amount(chan, n, seed, amount):
    """tape() with the wow and flutter scaled by `amount` (whole cycles per loop)."""
    out = array.array("f", [0.0]) * n
    base = 0.014 * RATE
    cw = max(1, round(0.45 * n / RATE))
    cf = max(1, round(5.3 * n / RATE))
    dw = 0.0035 * RATE * amount
    dfl = 0.0004 * RATE * amount
    for i in range(n):
        d = base + dw * math.sin(TAU * cw * i / n + seed) + dfl * math.sin(TAU * cf * i / n)
        p = i - d
        k = math.floor(p)
        f = p - k
        out[i] = chan[k % n] * (1 - f) + chan[(k + 1) % n] * f
    return out


def comp_keys(tr, instrument, hits, gain, centre=62, send=0.4, sections=("intro", "a", "break", "b"), spread=0.25):
    """Chord stabs/holds: hits = [(beat in the run, beats long, velocity)] per 2-bar run (a
    1-bar run takes those in its first bar)."""
    cache = {}
    rnd = tr.rnd
    for b0, nb, root, shape in tr.chord_runs():
        notes = voicing(root, shape, centre)
        for beat, length, vel in hits:
            if beat >= nb * 4:
                continue
            bar = b0 + int(beat // 4)
            if tr.section(bar) not in sections:
                continue
            for j, m in enumerate(notes):
                key = (m, length)
                if key not in cache:
                    cache[key] = instrument(hz(m), length * tr.beat, rnd)
                at = tr.t(b0, beat) + int((j * 0.008 + rnd.uniform(0, 0.006)) * RATE)
                pan = 0.5 + spread * ((j / max(1, len(notes) - 1)) - 0.5) * 2
                g = gain * vel / len(notes) ** 0.5
                put(tr.dry, cache[key], at, g, pan)
                put(tr.send, cache[key], at, g * send, 0.5)


def pads(tr, gain, centre=55, attack=0.8, release=1.4, cut0=900, cut1=None, vibrato=0.0, send=0.5,
         sections=("intro", "a", "break", "b"), rising=False, choir=False):
    cache = {}
    for b0, nb, root, shape in tr.chord_runs():
        if tr.section(b0) not in sections:
            continue
        notes = voicing(root, shape, centre, drop_root=False)
        length = nb * tr.bar - 0.15
        c0, c1 = cut0, cut1 if cut1 is not None else cut0
        if rising:
            # the pad opens over each 8-bar phrase (a rise that starts again with the phrase)
            ph0 = (b0 % 8) / 8.0
            ph1 = ((b0 % 8) + nb) / 8.0
            c0 = cut0 + (cut1 - cut0) * ph0
            c1 = cut0 + (cut1 - cut0) * ph1
        key = (root, shape, nb, round(c0), round(c1))
        if key not in cache:
            L = R = None
            for m in notes:
                l_, r_ = saw_voice(hz(m), length, attack, release, c0, c1, tr.rnd, vibrato)
                if L is None:
                    L, R = l_, r_
                else:
                    for i in range(len(L)):
                        L[i] += l_[i]
                        R[i] += r_[i]
            if choir:
                # an "ah": two formants over the saws, a little of the dry body kept
                fl = biquad_bp(L, 720, 2.2)
                fr = biquad_bp(R, 720, 2.2)
                gl = biquad_bp(L, 1150, 3.0)
                gr = biquad_bp(R, 1150, 3.0)
                L = array.array("d", (fl[i] * 1.6 + gl[i] * 0.9 + L[i] * 0.25 for i in range(len(L))))
                R = array.array("d", (fr[i] * 1.6 + gr[i] * 0.9 + R[i] * 0.25 for i in range(len(R))))
            cache[key] = (L, R)
        L, R = cache[key]
        g = gain / len(notes) ** 0.5
        put2(tr.dry, L, R, tr.t(b0), g)
        put2(tr.send, L, R, tr.t(b0), g * send)


def lead(tr, instrument, lo, hi, gain, density=0.45, sections=("b",), send=0.6, pan=0.55, motif=None, steps=8):
    cache = {}
    rnd = random.Random(900 + tr.number)
    line = motif if motif is not None else melody(rnd, tr.bars, tr.tonic, tr.scale, tr.tones, lo, hi, density, steps)
    step_beats = 4.0 / steps
    for bar, step, m, ln in line:
        if tr.section(bar) not in sections:
            continue
        length = ln * step_beats * tr.beat * 0.9
        key = (m, round(length, 2))
        if key not in cache:
            cache[key] = instrument(hz(m), length, tr.rnd)
        at = tr.t(bar, step * step_beats) + int(tr.rnd.uniform(0, 0.012) * RATE)
        g = gain * tr.rnd.uniform(0.8, 1.0)
        put(tr.dry, cache[key], at, g, pan)
        put(tr.send, cache[key], at, g * send, 0.5)


# --- the seven tracks -----------------------------------------------------------------

BOOM = {"kick": ["x.........x.....", "x.........x..x.."], "snare": ["....x.......x...", "....x.......x..o"]}


def kit_dusty(rnd, k=0.75, s=0.46, h=0.11, bright=0.8):
    return {
        "kick": ([d_kick(rnd, 0.9) for _ in range(2)], k, 0.5, 0.0),
        "snare": ([d_snare(rnd, 0.0, dark=3600) for _ in range(3)], s, 0.52, 0.35),
        "hat": ([d_hat(rnd, 0.07, bright) for _ in range(4)], h, 0.62, 0.0),
        "ohat": ([d_hat(rnd, 0.22, bright, 14.0) for _ in range(2)], h * 0.8, 0.62, 0.1),
        "rim": ([d_rim(rnd)], 0.12, 0.42, 0.2),
        "clap": ([d_clap(rnd, 0.8) for _ in range(2)], s * 0.9, 0.5, 0.45),
    }


def track_sod(tr):
    """1 Sód: dusty kick and snare, Rhodes 9th chords, sub bass, vinyl crackle."""
    kit = kit_dusty(tr.rnd)
    tr.drums(dict(BOOM, hat=["x.x.x.x.x.x.x.x.", "x.x.x.x.x.x.xox."]), kit, swing=0.55)
    tr.drums({"hat": "x...x...x...x..."}, kit, swing=0.55, sections=("break",), fill=False)
    comp_keys(tr, rhodes, [(0, 3.5, 1.0), (3.5, 2.5, 0.55), (6.5, 1.5, 0.4)], 0.62, centre=63, send=0.45)
    tr.bassline([(0, 2.5, 0), (2.75, 1.0, 0), (3.5, 0.5, 7)], 0.22, sections=("a", "break", "b"), drive=1.8)
    tr.bassline([(0, 4.0, 0)], 0.13, sections=("intro",), drive=1.8)
    lead(tr, lambda f, ln, r: rhodes(f, ln, r, 1.3), 69, 81, 0.22, density=0.3, sections=("b",), send=0.7)
    return tr.finish(crackle=1.8, hiss=1.3, cutoff=5200, wobble=0.8)


def track_wiadukt(tr):
    """2 Wiadukt: swung hats, muted piano stabs, a low string pad."""
    kit = kit_dusty(tr.rnd, k=0.6, s=0.0, h=0.09, bright=0.9)
    tr.drums({"hat": ["x.xox.x.x.xox.x.", "x.xox.x.x.xoxxx."], "ohat": "......x.......x.", "kick": "x.......x.o.....",
              "rim": "....x.......x..."}, kit, swing=0.85)
    tr.drums({"hat": "x.x.x.x.x.x.x.x."}, kit, swing=0.85, sections=("break",), fill=False)
    comp_keys(tr, lambda f, ln, r: piano(f, ln, r, True), [(0.5, 0.5, 0.9), (1.5, 0.5, 0.6), (2.75, 0.5, 0.8),
              (4.5, 0.5, 0.9), (5.75, 0.5, 0.6), (7.0, 0.5, 0.7)], 0.75, centre=64, send=0.3,
              sections=("a", "break", "b"))
    pads(tr, 0.13, centre=50, attack=1.4, release=1.6, cut0=700, cut1=900, vibrato=0.0015, send=0.6)
    tr.bassline([(0, 3.0, 0), (3.0, 1.0, 7)], 0.2, sections=("a", "b"), drive=1.8)
    lead(tr, lambda f, ln, r: piano(f, ln, r, False), 64, 76, 0.26, density=0.32, sections=("b",), send=0.5)
    return tr.finish(crackle=0.8, cutoff=5000, wobble=0.6)


def track_przesiadka(tr):
    """3 Nocna przesiadka: soft clap, a tram-bell motif on the vibraphone, tape wobble."""
    kit = kit_dusty(tr.rnd, k=0.75, s=0.34, h=0.06)
    tr.drums({"kick": ["x......x..x.....", "x......x..x...x."], "clap": ["....x.......x...", "....x.......x.o."],
              "hat": "x.x.x.x.x.x.x.x."}, kit, swing=0.5)
    pads(tr, 0.10, centre=56, attack=0.9, release=1.4, cut0=1100, cut1=1100, send=0.5)
    comp_keys(tr, rhodes, [(0, 7.5, 0.7)], 0.4, centre=62, send=0.4)
    tr.bassline([(0, 1.5, 0), (1.75, 1.0, 0), (3.0, 1.0, 12)], 0.22, drive=1.8, sections=("a", "break", "b"))
    # the motif: the tram's two-tone bell (a third down), answered a step lower, every 2 bars
    t0, sc = NOTE["F"], scale_notes("F", "minor", 70, 86)
    hi = [m for m in sc if m % 12 == (t0 + 7) % 12][0]  # C6
    lo = hi - 4  # Ab5: the bell's major third
    motif = []
    for b in range(0, tr.bars, 2):
        motif += [(b, 0, hi, 2), (b, 2, lo, 4)]
        if b % 8 == 6:
            motif += [(b + 1, 0, lo - 1, 2), (b + 1, 2, lo - 3, 6)]  # G, F: home
        else:
            motif += [(b + 1, 0, hi - 2, 2), (b + 1, 2, lo, 6)]
    lead(tr, vibes, 0, 0, 0.32, sections=("intro", "a", "break", "b"), send=0.7, pan=0.6, motif=motif)
    return tr.finish(wobble=2.2, crackle=1.0, cutoff=4800)


def track_szklo(tr):
    """4 Szkło na Woli: a crisp kit, glassy plucks, a rising pad."""
    kit = {
        "kick": ([d_kick(tr.rnd, 1.1, 52, 9.0) for _ in range(2)], 0.68, 0.5, 0.0),
        "snare": ([d_snare(tr.rnd, 0.8, 210, 5200, 20.0) for _ in range(3)], 0.4, 0.5, 0.3),
        "hat": ([d_hat(tr.rnd, 0.05, 2.0, 90.0) for _ in range(4)], 0.08, 0.66, 0.0),
        "ohat": ([d_hat(tr.rnd, 0.2, 2.0, 18.0) for _ in range(2)], 0.06, 0.66, 0.1),
    }
    tr.drums({"kick": ["x.....x...x.....", "x.....x...x..x.."], "snare": ["....x.......x...", "....x.......x.x."],
              "hat": ["x.xxx.x.x.xxx.x.", "x.xxx.x.x.xxxxxx"], "ohat": "..............x."}, kit, swing=0.2)
    pads(tr, 0.16, centre=57, attack=1.2, release=1.2, cut0=500, cut1=3200, rising=True, send=0.6)
    tr.bassline([(0, 1.5, 0), (1.5, 1.0, 0), (3.0, 0.75, 7)], 0.22, drive=1.8, sections=("a", "break", "b"))
    # plucks: a 16th arpeggio of the chord, two octaves up, in the A and B sections
    arp = []
    for bar in range(tr.bars):
        tones = sorted(voicing(*tr.chord[bar], centre=76))
        pattern = [0, 2, 1, 3, 2, 0, 3, 1]
        for s in range(8):
            if (s + bar) % 3 == 2:
                continue
            arp.append((bar, s, tones[pattern[s] % len(tones)], 1))
    lead(tr, lambda f, ln, r: glass(f, r), 0, 0, 0.15, sections=("intro", "a", "break", "b"), send=0.8, pan=0.4, motif=arp)
    lead(tr, lambda f, ln, r: glass(f * 0.5, r), 64, 79, 0.16, density=0.35, sections=("b",), send=0.7, pan=0.62)
    return tr.finish(crackle=0.5, hiss=0.7, cutoff=6200, wobble=0.4)


def track_bulwar(tr):
    """5 Bulwar, 23:40: brushes, nylon-guitar chords (the "three chords"), river noise."""
    kit = {"brush": ([d_brush(tr.rnd) for _ in range(3)], 0.12, 0.45, 0.2),
           "tap": ([d_brush_tap(tr.rnd) for _ in range(3)], 0.2, 0.55, 0.3),
           "kick": ([d_kick(tr.rnd, 0.5, 46, 6.0) for _ in range(2)], 0.5, 0.5, 0.0)}
    tr.drums({"brush": "x...x...x...x...", "tap": ["....x.......x...", "....x.......x.o."],
              "kick": "x.......x......."}, kit, swing=0.7)
    # the strum: down on 1, up on 2-and, down on 3, up on 4 (each string 18 ms apart)
    cache = {}
    for bar in range(tr.bars):
        root, shape = tr.chord[bar]
        notes = voicing(root, shape, 57, drop_root=False)
        notes = [midi_of(root, 2) + (12 if NOTE[root] < 4 else 0)] + notes
        for beat, down, vel in ((0, True, 1.0), (1.5, False, 0.5), (2, True, 0.8), (3.0, False, 0.45), (3.5, True, 0.6)):
            if tr.section(bar) == "intro" and beat > 0:
                continue
            order = notes if down else list(reversed(notes[1:]))
            for j, m in enumerate(order):
                key = (m, beat)
                if key not in cache:
                    cache[key] = nylon(hz(m), (2.0 if beat == 0 else 0.6) * tr.beat, tr.rnd)
                at = tr.t(bar, beat) + int(j * 0.018 * RATE)
                put(tr.dry, cache[key], at, 0.24 * vel, 0.35 + 0.3 * j / len(order))
                put(tr.send, cache[key], at, 0.07 * vel, 0.5)
    tr.bassline([(0, 2.0, 0), (2.0, 2.0, 7)], 0.18, sections=("a", "break", "b"), drive=1.5)
    lead(tr, lambda f, ln, r: nylon(f, ln, r), 64, 79, 0.2, density=0.3, sections=("b",), send=0.5, pan=0.62)
    rv = river(tr.n, tr.rnd)
    return tr.finish(crackle=0.6, cutoff=5400, wobble=0.5, extra=[(rv, 0.22)])


def track_mgla(tr):
    """6 Mgła nad Pałacem: half-time drums, a wide choir pad, a slow bass glide."""
    kit = kit_dusty(tr.rnd, k=0.9, s=0.5, h=0.05, bright=0.4)
    tr.drums({"kick": ["x.......x.......", "x.......x.....x."], "snare": ["........x.......", "........x.....o."],
              "hat": "x...x...x...x..."}, kit, swing=0.4)
    pads(tr, 0.2, centre=58, attack=1.6, release=2.0, cut0=1600, cut1=1600, vibrato=0.003, send=0.9, choir=True)
    tr.bassline([(0, 4.0, 0)], 0.26, glide=1.5, drive=1.8)
    comp_keys(tr, lambda f, ln, r: rhodes(f, ln, r, 0.6), [(0, 7.0, 0.6)], 0.25, centre=65, send=0.7,
              sections=("break", "b"))
    lead(tr, lambda f, ln, r: piano(f, ln, r, False), 65, 77, 0.2, density=0.2, sections=("b",), send=0.9)
    return tr.finish(lead_room=1.15, wet=1.1, crackle=0.9, cutoff=4200, wobble=0.9)


def track_swit(tr):
    """7 Świt na Smolnej: a brighter kit, birds, a hopeful piano line."""
    kit = {
        "kick": ([d_kick(tr.rnd, 1.0, 50, 8.0) for _ in range(2)], 0.8, 0.5, 0.0),
        "snare": ([d_snare(tr.rnd, 0.5, 200, 4800, 18.0) for _ in range(3)], 0.36, 0.5, 0.3),
        "hat": ([d_hat(tr.rnd, 0.06, 1.2, 70.0) for _ in range(4)], 0.08, 0.64, 0.0),
        "ohat": ([d_hat(tr.rnd, 0.2, 1.2, 16.0) for _ in range(2)], 0.06, 0.64, 0.1),
    }
    tr.drums({"kick": ["x.......x.x.....", "x.......x.x...x."], "snare": ["....x.......x...", "....x.......x..o"],
              "hat": "x.x.x.x.x.x.x.x.", "ohat": "......x.......x."}, kit, swing=0.35)
    comp_keys(tr, rhodes, [(0, 3.0, 0.9), (3.0, 1.0, 0.5), (4.0, 3.5, 0.7)], 0.4, centre=64, send=0.4)
    pads(tr, 0.07, centre=60, attack=1.0, release=1.4, cut0=1800, cut1=1800, send=0.5)
    tr.bassline([(0, 2.0, 0), (2.5, 1.0, 7), (3.5, 0.5, 12)], 0.2, drive=1.8, sections=("a", "break", "b"))
    lead(tr, lambda f, ln, r: piano(f, ln, r, False), 67, 83, 0.3, density=0.5, sections=("a", "b"), send=0.5)
    # birds: short phrases of two to four chirps, now and then, wider in the breakdown
    birds = Loop(tr.seconds)
    rnd = random.Random(77)
    t = 1.0
    while t < tr.seconds - 1.0:
        f0 = rnd.uniform(2600, 4200)
        for c in range(rnd.randint(2, 4)):
            ln = rnd.uniform(0.05, 0.12)
            sig = chirp(f0, f0 * rnd.uniform(1.1, 1.5), ln, rnd)
            put(birds, sig, int((t + c * rnd.uniform(0.09, 0.16)) * RATE), rnd.uniform(0.03, 0.06), rnd.uniform(0.15, 0.85))
        t += rnd.uniform(1.8, 5.5)
    return tr.finish(crackle=0.6, cutoff=6400, wobble=0.5, extra=[((birds.l, birds.r), 1.0)])


POLNOC_RENDER = {1: track_sod, 2: track_wiadukt, 3: track_przesiadka, 4: track_szklo, 5: track_bulwar,
                 6: track_mgla, 7: track_swit}


def bands(left, right):
    """Share of energy below 200 Hz, 200 Hz-2 kHz and above 2 kHz (the spectrum's sanity)."""
    lo = mid = 0.0
    a_lo = 1.0 - math.exp(-TAU * 200 / RATE)
    a_mid = 1.0 - math.exp(-TAU * 2000 / RATE)
    e = [0.0, 0.0, 0.0]
    for a, b in zip(left, right):
        x = (a + b) * 0.5
        lo += a_lo * (x - lo)
        mid += a_mid * (x - mid)
        e[0] += lo * lo
        e[1] += (mid - lo) ** 2
        e[2] += (x - mid) ** 2
    s = sum(e) or 1.0
    return [v / s for v in e]


def render_polnoc(spec, out_dir, plot_dir):
    tr = Track(spec)
    left, right = POLNOC_RENDER[tr.number](tr)
    name = "%02d_%s" % (tr.number, tr.stem)
    wav = os.path.join(out_dir, name + ".wav")
    write_wav(wav, left, right)
    with open(os.path.join(out_dir, name + ".txt"), "w", encoding="utf-8") as f:
        f.write("licence: own: synthesised by tools/make_music.py (MIT)\ntitle: %s\nartist: Around Warsaw\n" % tr.title)
    band_plot(os.path.join(plot_dir, "music_polnoc_" + name + ".png"), left, right)
    seam = max(abs(left[0] - left[-1]), abs(right[0] - right[-1]))
    steps = sorted(abs(left[i] - left[i - 1]) for i in range(1, len(left), 7))
    p999 = steps[int(len(steps) * 0.999)]
    b = bands(left, right)
    return ("%d %s: %d bars, %.1f s, %d BPM, %s; crest %.1f dB (drive %.2f); seam step %.4f vs p99.9 %.4f; "
            "energy <200 Hz %.0f%%, 200 Hz-2 kHz %.0f%%, >2 kHz %.0f%%" % (
                tr.number, tr.title, tr.bars, tr.seconds, tr.bpm, tr.key, tr.crest, tr.drive, seam, p999,
                b[0] * 100, b[1] * 100, b[2] * 100))


def _polnoc_job(args):
    return render_polnoc(*args)


def main(out_dir, plot_dir, which="vapor", only=None):
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(plot_dir, exist_ok=True)
    if which == "polnoc":
        specs = [s for s in POLNOC if only is None or s[0] in only]
        jobs = [(s, out_dir, plot_dir) for s in specs]
        try:
            import multiprocessing
            with multiprocessing.Pool(min(len(jobs), os.cpu_count() or 1)) as pool:
                lines = pool.map(_polnoc_job, jobs)
        except (ImportError, OSError):
            lines = [_polnoc_job(j) for j in jobs]
        for line in lines:
            print(line)
        return
    for seed, (name, title, bpm, bpc, chords) in enumerate(TRACKS, 1):
        seconds, left, right = render(name, bpm, bpc, chords, seed)
        wav = os.path.join(out_dir, name + ".wav")
        write_wav(wav, left, right)
        band_plot(os.path.join(plot_dir, "music_" + name + ".png"), left, right)
        seam = max(abs(left[0] - left[-1]), abs(right[0] - right[-1]))
        rms = math.sqrt(sum(v * v for v in left) / len(left))
        line = f"{title}: {seconds:.1f} s loop, {bpm} BPM, rms {20 * math.log10(rms):.1f} dBFS, seam jump {seam:.3f}, {os.path.getsize(wav) // 1024} KB"
        print(line)


if __name__ == "__main__":
    opts = [a for a in sys.argv[1:] if a.startswith("--")]
    pos = [a for a in sys.argv[1:] if not a.startswith("--")]
    which = "vapor"
    only = None
    for o in opts:
        if o.startswith("--set="):
            which = o[len("--set="):]
        elif o.startswith("--only="):
            only = {int(v) for v in o[len("--only="):].split(",")}
    main(pos[0], pos[1], which, only)
