"""Put your own songs on the game's radio: drop a file in, run this, done.

Usage:
    python3 -I tools/add_music.py                    convert every new file, all stations
    python3 -I tools/add_music.py --station=nocna_fm only that station's folder
    python3 -I tools/add_music.py --force            convert every file again, new or not
    python3 -I tools/add_music.py --dry-run          say what it would do, change nothing
    python3 -I tools/add_music.py --list             the stations, their tracks and the sizes
    python3 -I tools/add_music.py --licence="paid plan: owned"   licence for this run's files

Raw songs live in data/raw/music/<station_id>/ (git ignores data/raw: raw music is never
committed). The station ids are the "id" fields in game/data/radio.json. wav, mp3, flac, m4a
and aiff files that are not in radio.json yet (matched by file name, the track's "source")
are converted; the song's title comes from the file name (Night_on_Smolna.wav -> "Night on
Smolna"). An optional sidecar next to the song, <same name>.txt, says more:

    Night_on_Smolna.txt      licence: Suno Pro plan, owned      (one line alone = the licence)
                             title: Noc na Smolnej
                             artist: Lubomir

For each song, with ffmpeg and ffprobe:
  1. decode, resample to 44.1 kHz stereo, trim silence at both ends (below -50 dBFS, 0.2 s kept);
  2. measure the integrated loudness (EBU R128) and the true peak;
  3. apply ONE static gain so the song lands at the radio's level (TARGET_LUFS) and its true
     peak stays at -1 dBTP or lower. No limiter, compressor or loudnorm: they flatten music;
  4. encode Ogg Vorbis to game/audio/radio/<station_id>/<slug>.ogg (about 96 kbps; see below);
  5. add the track to radio.json (file, title, artist, seconds, gain_db, licence, source).
It prints each track's size, length and gain, and the radio's total size. A licence that is
not said stays "unknown": check those before a release (an AI tool's free plan may not allow
it); the radio check (tools/verify.sh, step radio) lists them as a WARN.

A folder in data/raw/music/ whose name is not a station in radio.json is not invented as one:
the tool prints the radio.json entry to add.

TARGET_LUFS is the mean integrated loudness of the three original loops from
tools/make_music.py (-14.6, -14.2 and -13.2 LUFS = -14.0), so new songs sit next to them.

The Ogg encoder, in this order: `oggenc` if it is on PATH (brew install vorbis-tools): ffmpeg
decodes, trims and applies the gain to a temporary 44.1 kHz stereo 16-bit WAV, `oggenc -b 96`
encodes it, the WAV is deleted; else ffmpeg's `libvorbis` if `ffmpeg -encoders` lists it; else
ffmpeg's own "vorbis" encoder (-strict -2), which ignores the bitrate and writes about 185 kb/s
(1.4 MB a minute; Homebrew's stripped ffmpeg has no libvorbis). The tool says which it uses
when it falls back. Nothing else changes with the encoder.

Loop MW-5: a station in radio.json may carry "encode": {"rate": 22050, "kbps": 40}: its files
are encoded at that sample rate and bitrate instead of 44.1 kHz and 96 kbps (PÓŁNOC FM: seven
lo-fi tracks synthesised at 22.05 kHz by tools/make_music.py --set=polnoc, 3.6 MB together).
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "data", "raw", "music")
OUT = os.path.join(ROOT, "game", "audio", "radio")
JSON_PATH = os.path.join(ROOT, "game", "data", "radio.json")
EXTENSIONS = (".wav", ".mp3", ".flac", ".m4a", ".aiff", ".aif")

# The radio's level: the mean of the three original loops (-14.6, -14.2, -13.2 LUFS).
TARGET_LUFS = -14.0
# The true peak ceiling after the gain, in dBTP.
PEAK_CEILING = -1.0
SILENCE_DB = -50
SILENCE_KEEP = 0.2
OGGENC_KBPS = "96"


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    return r.returncode, r.stdout, r.stderr


def have_libvorbis():
    code, out, _ = run(["ffmpeg", "-hide_banner", "-encoders"])
    return code == 0 and "libvorbis" in out


def pick_encoder():
    """'oggenc' if it is on PATH, else 'libvorbis' if ffmpeg has it, else 'vorbis' (ffmpeg's own)."""
    if shutil.which("oggenc"):
        return "oggenc"
    return "libvorbis" if have_libvorbis() else "vorbis"


def slug(text):
    """A file name: ASCII, lower case, words joined by underscores."""
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    text = re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")
    return text or "track"


def title_of(stem):
    """Night_on_Smolna -> Night on Smolna."""
    return re.sub(r"\s+", " ", stem.replace("_", " ")).strip()


def read_sidecar(raw_path):
    """<name>.txt next to the song: 'key: value' lines (licence, title, artist) or one bare
    line, the licence."""
    path = os.path.splitext(raw_path)[0] + ".txt"
    found = {}
    if not os.path.isfile(path):
        return found
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            m = re.match(r"(licen[cs]e|title|artist)\s*:\s*(.*)$", line, re.I)
            if m:
                key = m.group(1).lower()
                found["licence" if key.startswith("licen") else key] = m.group(2).strip()
            elif "licence" not in found:
                found["licence"] = line
    return found


def measure(path):
    """Integrated loudness (LUFS) and true peak (dBTP) of a file, by ffmpeg's ebur128."""
    code, _, err = run(["ffmpeg", "-hide_banner", "-nostats", "-i", path,
                        "-af", "ebur128=peak=true", "-f", "null", "-"])
    tail = err[err.rfind("Summary:"):]
    mi = re.search(r"I:\s+(-?[\d.]+) LUFS", tail)
    mp = re.search(r"Peak:\s+(-?[\d.]+|-inf) dBFS", tail)
    if code != 0 or not mi or not mp:
        raise RuntimeError("could not measure " + path)
    peak = float("-inf") if mp.group(1) == "-inf" else float(mp.group(1))
    return float(mi.group(1)), peak


def duration_of(path):
    code, out, _ = run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                        "-of", "csv=p=0", path])
    if code != 0:
        raise RuntimeError("ffprobe failed on " + path)
    return float(out.strip())


def decode_trimmed(src, dst):
    """Any audio file -> 44.1 kHz stereo float WAV with the silence at both ends trimmed."""
    cut = ("silenceremove=start_periods=1:start_duration=0.1:start_threshold=%ddB"
           ":start_silence=%s:detection=peak" % (SILENCE_DB, SILENCE_KEEP))
    chain = "%s,areverse,%s,areverse" % (cut, cut)
    code, _, err = run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", src, "-vn",
                        "-ar", "44100", "-ac", "2", "-af", chain, "-c:a", "pcm_f32le", dst])
    if code != 0:
        raise RuntimeError("decode failed: " + err.strip()[-300:])


def encode(src, dst, gain_db, encoder, rate=44100, kbps=96):
    """Float WAV -> Ogg Vorbis with one static gain (a plain volume filter, nothing else).
    encoder is 'oggenc' (a temporary 16-bit WAV, then oggenc), 'libvorbis' or 'vorbis'.
    `rate` and `kbps` come from the station's "encode" entry (loop MW-5), else 44.1 kHz, 96."""
    common = ["-af", "volume=%.2fdB" % gain_db, "-ar", str(rate), "-ac", "2", "-map_metadata", "-1"]
    if encoder == "oggenc":
        with tempfile.TemporaryDirectory() as tmp:
            wav16 = os.path.join(tmp, "gain16.wav")
            code, _, err = run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", src]
                               + common + ["-c:a", "pcm_s16le", wav16])
            if code != 0:
                raise RuntimeError("gain/convert failed: " + err.strip()[-300:])
            code, _, err = run(["oggenc", "-b", str(kbps), "--quiet", "-o", dst, wav16])
            if code != 0:
                raise RuntimeError("oggenc failed: " + err.strip()[-300:])
        return
    codec = ["-c:a", "libvorbis", "-b:a", "%dk" % kbps] if encoder == "libvorbis" else ["-c:a", "vorbis", "-strict", "-2"]
    code, _, err = run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", src]
                       + common + codec + [dst])
    if code != 0:
        raise RuntimeError("encode failed: " + err.strip()[-300:])


def convert(raw_path, out_path, encoder, rate=44100, kbps=96):
    """Returns (seconds, gain_db, lufs, true_peak) of the finished file."""
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "trimmed.wav")
        decode_trimmed(raw_path, wav)
        lufs, peak = measure(wav)
        if lufs < -69 or peak == float("-inf"):
            raise RuntimeError("the file is silent")
        gain = TARGET_LUFS - lufs
        if peak + gain > PEAK_CEILING:
            gain = PEAK_CEILING - peak
        gain = round(gain, 2)
        # The lossy encoder can overshoot the true peak a little: check the real file and
        # lower the gain until it is under the ceiling (a gain change, never a limiter).
        for _ in range(4):
            encode(wav, out_path, gain, encoder, rate, kbps)
            out_lufs, out_peak = measure(out_path)
            if out_peak <= PEAK_CEILING + 0.001:
                break
            gain = round(gain - (out_peak - PEAK_CEILING) - 0.05, 2)
        return duration_of(out_path), gain, out_lufs, out_peak


def load_radio():
    if not os.path.isfile(JSON_PATH):
        sys.exit("add_music: %s is missing" % JSON_PATH)
    with open(JSON_PATH, encoding="utf-8") as f:
        return json.load(f)


def save_radio(radio):
    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(radio, f, indent=2, ensure_ascii=False)
        f.write("\n")


def raw_files(station_id):
    folder = os.path.join(RAW, station_id)
    if not os.path.isdir(folder):
        return []
    return sorted(f for f in os.listdir(folder) if f.lower().endswith(EXTENSIONS) and not f.startswith("."))


def size_mb(n):
    return "%.2f MB" % (n / 1048576.0)


def clock(seconds):
    return "%d:%02d" % (seconds // 60, seconds % 60)


def radio_size():
    total = 0
    for base, _, files in os.walk(OUT):
        for f in files:
            if f.endswith(".ogg"):
                total += os.path.getsize(os.path.join(base, f))
    return total


def file_size(track):
    return os.path.getsize(os.path.join(ROOT, "game", track["file"][len("res://"):]))


def list_all(radio):
    for st in radio["stations"]:
        print("%s  %s %s  (%s)" % (st["id"], st["freq"], st["name"], st["colour"]))
        for t in st["tracks"]:
            path = os.path.join(ROOT, "game", t["file"][len("res://"):])
            size = size_mb(os.path.getsize(path)) if os.path.isfile(path) else "MISSING"
            artist = ("  by " + t["artist"]) if t.get("artist") else ""
            print("    %-30s %-9s %6s  %+6.2f dB  licence: %s  (from %s)%s" % (
                t["title"], size, clock(int(round(t["seconds"]))), t["gain_db"], t["licence"],
                t["source"], artist))
        known = {t["source"] for t in st["tracks"]}
        waiting = [f for f in raw_files(st["id"]) if f not in known]
        if waiting:
            print("    waiting in data/raw/music/%s/: %s" % (st["id"], ", ".join(waiting)))
    print("radio total: %s" % size_mb(radio_size()))


def main():
    ap = argparse.ArgumentParser(description="Convert songs for the game's radio.")
    ap.add_argument("--station", help="only this station id")
    ap.add_argument("--force", action="store_true", help="convert every file again")
    ap.add_argument("--dry-run", action="store_true", help="say what would be done, change nothing")
    ap.add_argument("--list", action="store_true", help="print the stations and their tracks")
    ap.add_argument("--licence", help="licence text for the files converted in this run")
    args = ap.parse_args()

    radio = load_radio()
    if args.list:
        list_all(radio)
        return 0

    ids = [s["id"] for s in radio["stations"]]
    if args.station and args.station not in ids:
        print("add_music: no station '%s' in radio.json (stations: %s)" % (args.station, ", ".join(ids)))
        return 2
    # Folders without a station: say how to add one.
    if os.path.isdir(RAW):
        for d in sorted(os.listdir(RAW)):
            if os.path.isdir(os.path.join(RAW, d)) and d not in ids and not d.startswith("."):
                if args.station and d != args.station:
                    continue
                print("add_music: data/raw/music/%s/ has no station in radio.json. To add one, put an entry in"
                      " game/data/radio.json's \"stations\" list:\n"
                      "    {\"id\": \"%s\", \"name\": \"NAME FM\", \"freq\": \"99,9\", \"colour\": \"#ffaa33\", \"tracks\": []}\n"
                      "  then run this again." % (d, d))

    if not os.path.isdir(RAW):
        print("add_music: nothing to do (no data/raw/music/ folder; make data/raw/music/<station_id>/ and put songs in it)")
    encoder = pick_encoder()
    if encoder == "vorbis" and not args.dry_run:
        print("add_music: NOTE no oggenc on PATH and this ffmpeg has no libvorbis; using ffmpeg's built-in vorbis\n"
              "  encoder, which ignores the 96 kbps target and writes about 185 kb/s. Files are valid; install\n"
              "  oggenc (brew install vorbis-tools) for files half the size.")

    failed = 0
    done = 0
    for st in radio["stations"]:
        if args.station and st["id"] != args.station:
            continue
        known = {t["source"]: i for i, t in enumerate(st["tracks"])}
        # Loop MW-5: a station may set its own encoding ("encode": {"rate": Hz, "kbps": N}), e.g.
        # PÓŁNOC FM's lo-fi tracks, made at 22.05 kHz, at 22.05 kHz and 40 kbps.
        enc = st.get("encode", {})
        rate = int(enc.get("rate", 44100))
        kbps = int(enc.get("kbps", int(OGGENC_KBPS)))
        for name in raw_files(st["id"]):
            if name in known and not args.force:
                continue
            raw_path = os.path.join(RAW, st["id"], name)
            side = read_sidecar(raw_path)
            old = st["tracks"][known[name]] if name in known else {}
            stem = os.path.splitext(name)[0]
            out_name = slug(stem) + ".ogg"
            if old:
                out_name = os.path.basename(old["file"])
            else:
                used = {os.path.basename(t["file"]) for s in radio["stations"] for t in s["tracks"]
                        if s["id"] == st["id"]}
                n = 2
                while out_name in used:
                    out_name = "%s_%d.ogg" % (slug(stem), n)
                    n += 1
            out_path = os.path.join(OUT, st["id"], out_name)
            title = side.get("title") or old.get("title") or title_of(stem)
            artist = side.get("artist", old.get("artist", ""))
            licence = args.licence or side.get("licence") or old.get("licence") or "unknown"
            if args.dry_run:
                print("would convert %s/%s -> game/audio/radio/%s/%s  \"%s\"  licence: %s" % (
                    st["id"], name, st["id"], out_name, title, licence))
                continue
            os.makedirs(os.path.dirname(out_path), exist_ok=True)
            try:
                seconds, gain, lufs, peak = convert(raw_path, out_path, encoder, rate, kbps)
            except RuntimeError as e:
                print("FAILED %s/%s: %s" % (st["id"], name, e))
                if os.path.isfile(out_path) and not old:
                    os.remove(out_path)
                failed += 1
                continue
            entry = {
                "file": "res://audio/radio/%s/%s" % (st["id"], out_name),
                "title": title,
                "artist": artist,
                "seconds": round(seconds, 2),
                "gain_db": gain,
                "licence": licence,
                "source": name,
            }
            if old:
                st["tracks"][known[name]] = entry
            else:
                st["tracks"].append(entry)
            done += 1
            print("%-10s %-28s %9s  %6s  gain %+6.2f dB  -> %.1f LUFS, %.1f dBTP  licence: %s" % (
                st["id"], out_name, size_mb(os.path.getsize(out_path)), clock(int(round(seconds))),
                gain, lufs, peak, licence))
            save_radio(radio)

    if not args.dry_run:
        print("converted %d, failed %d; radio total %s" % (done, failed, size_mb(radio_size())))
    unknown = [t["title"] for s in radio["stations"] for t in s["tracks"] if t["licence"] == "unknown"]
    if unknown:
        print("licence unknown (check before a release): " + ", ".join(unknown))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
