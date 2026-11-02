"""The map pack: the GUGiK-derived map files that are not in git, as one release download.

Usage (from the repository root):
    python3 -I tools/map_pack.py make [--version N]   pack game/map's files, write tools/map_pack.json
    python3 -I tools/map_pack.py fetch                download the pack tools/map_pack.json names,
                                                      check it and unpack it into game/map
    python3 -I tools/map_pack.py check                are game/map's files the pack's? (no network)

Loop 3d-1 took game/map/lod2.bin (90 MB), lod2.json and terrain.json out of git: they are built
from GUGiK's raw downloads (tools/setup_map.sh --full), which only the Mac has. Without them a clone
cannot split the map or build the city, so GitHub CI and the cloud threads could not run the map,
road, drape, drive and landmark checks. The pack carries exactly those three files, as a
GitHub release asset of this repository (public, like the data: GUGiK's open data, the same files
that were committed before loop 3d-1).

`make` (on the Mac, after a full bake that changed one of them) writes
build/map-pack/map-pack-<N>.tar.gz, byte for byte the same for the same files (sorted, no times,
no owners), and tools/map_pack.json (the version, the release tag and asset, the SHA-256 of the
archive and of each file). Commit tools/map_pack.json and publish the archive as the asset of a
release tagged map-pack-<N> (the command prints the link). The version goes up by one each time.

`fetch` skips the download when game/map already has the pack's files. Otherwise it downloads the
asset with curl (the proxy and CA settings of the shell apply), checks the archive's SHA-256 and
each file's, and unpacks into game/map. tools/setup_map.sh runs it when the files are missing.

Exit codes: 0 done (or already there), 1 an error (a hash mismatch, a broken download), 2 usage,
3 the pack is not published yet (the release asset answers 404) or, for `check`, the files differ.
"""
import argparse
import gzip
import hashlib
import io
import json
import os
import subprocess
import sys
import tarfile

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
MAP = os.path.join(ROOT, "game", "map")
MANIFEST = os.path.join(ROOT, "tools", "map_pack.json")
OUT = os.path.join(ROOT, "build", "map-pack")
REPO = "LubomirOlshansky/AroundWarsaw"
# What the pack holds: the files setup_map.sh cannot make without the GUGiK raw downloads.
FILES = ["lod2.bin", "lod2.json", "terrain.json"]


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def load_manifest():
    with open(MANIFEST, encoding="utf-8") as f:
        return json.load(f)


def url_of(m):
    return "https://github.com/%s/releases/download/%s/%s" % (REPO, m["tag"], m["asset"])


def have_pack(m):
    """True when game/map holds every file of the pack, hash for hash."""
    for name, digest in m["files"].items():
        p = os.path.join(MAP, name)
        if not os.path.isfile(p) or sha256(p) != digest:
            return False
    return True


def cmd_make(args):
    missing = [n for n in FILES if not os.path.isfile(os.path.join(MAP, n))]
    if missing:
        print("map_pack: game/map has no %s (tools/setup_map.sh --full builds them)" % ", ".join(missing))
        return 1
    version = args.version
    if version is None:
        version = (load_manifest()["version"] + 1) if os.path.isfile(MANIFEST) else 1
    tag = "map-pack-%d" % version
    asset = tag + ".tar.gz"
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, asset)
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.PAX_FORMAT) as tar:
        for name in sorted(FILES):
            src = os.path.join(MAP, name)
            info = tarfile.TarInfo(name)
            info.size = os.path.getsize(src)
            info.mode = 0o644
            info.mtime = 0
            with open(src, "rb") as f:
                tar.addfile(info, f)
    with open(path, "wb") as raw:
        with gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0, compresslevel=9) as gz:
            gz.write(buf.getvalue())
    m = {
        "version": version,
        "tag": tag,
        "asset": asset,
        "sha256": sha256(path),
        "bytes": os.path.getsize(path),
        "files": {name: sha256(os.path.join(MAP, name)) for name in sorted(FILES)},
    }
    with open(MANIFEST, "w", encoding="utf-8") as f:
        json.dump(m, f, indent="\t")
        f.write("\n")
    print("map_pack: %s, %.1f MB, sha256 %s" % (os.path.relpath(path, ROOT), m["bytes"] / 1e6, m["sha256"]))
    print("map_pack: wrote tools/map_pack.json; commit it and publish the archive as release %s:" % tag)
    print("  https://github.com/%s/releases/new?tag=%s&title=Map+pack+%d" % (REPO, tag, version))
    print("  (or: gh release create %s %s --title 'Map pack %d' --notes 'tools/map_pack.py')" % (tag, os.path.relpath(path, ROOT), version))
    return 0


def cmd_check(_args):
    m = load_manifest()
    if have_pack(m):
        print("map_pack: OK, game/map has pack %d" % m["version"])
        return 0
    print("map_pack: game/map's %s are not pack %d's (python3 -I tools/map_pack.py fetch)" % (", ".join(m["files"]), m["version"]))
    return 3


def cmd_fetch(_args):
    m = load_manifest()
    if have_pack(m):
        print("map_pack: game/map already has pack %d" % m["version"])
        return 0
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, m["asset"])
    if not (os.path.isfile(path) and sha256(path) == m["sha256"]):
        url = url_of(m)
        print("map_pack: downloading %s (%.1f MB)" % (url, m.get("bytes", 0) / 1e6))
        part = path + ".part"
        r = subprocess.run(["curl", "-sSL", "--retry", "4", "--retry-delay", "2", "-o", part,
                "-w", "%{http_code}", url], capture_output=True, text=True)
        code = r.stdout.strip()
        if code == "404":
            print("map_pack: pack %d is not published yet (%s answers 404)" % (m["version"], url))
            return 3
        if r.returncode != 0 or code != "200":
            print("map_pack: download failed (HTTP %s, curl %d): %s" % (code, r.returncode, r.stderr.strip()[:200]))
            return 1
        os.replace(part, path)
        if sha256(path) != m["sha256"]:
            print("map_pack: the download's sha256 is not tools/map_pack.json's")
            return 1
    with tarfile.open(path, "r:gz") as tar:
        names = sorted(tar.getnames())
        if names != sorted(m["files"]):
            print("map_pack: the archive holds %s, not %s" % (names, sorted(m["files"])))
            return 1
        for member in tar.getmembers():
            if not member.isfile():
                print("map_pack: %s is not a plain file" % member.name)
                return 1
            src = tar.extractfile(member)
            dst = os.path.join(MAP, member.name)
            with open(dst + ".part", "wb") as f:
                for block in iter(lambda: src.read(1 << 20), b""):
                    f.write(block)
            os.replace(dst + ".part", dst)
    if not have_pack(m):
        print("map_pack: the unpacked files don't match tools/map_pack.json")
        return 1
    print("map_pack: unpacked pack %d into game/map (%s)" % (m["version"], ", ".join(m["files"])))
    return 0


def main():
    ap = argparse.ArgumentParser(description="The map pack (lod2.bin, lod2.json, terrain.json) as a release download.")
    sub = ap.add_subparsers(dest="cmd", required=True)
    mk = sub.add_parser("make")
    mk.add_argument("--version", type=int)
    sub.add_parser("fetch")
    sub.add_parser("check")
    args = ap.parse_args()
    return {"make": cmd_make, "fetch": cmd_fetch, "check": cmd_check}[args.cmd](args)


if __name__ == "__main__":
    sys.exit(main())
