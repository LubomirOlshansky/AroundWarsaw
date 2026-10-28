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


def main(out_dir, plot_dir):
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(plot_dir, exist_ok=True)
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
    main(sys.argv[1], sys.argv[2])
