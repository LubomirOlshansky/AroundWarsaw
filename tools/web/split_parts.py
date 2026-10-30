"""Gzip a big file and cut it into parts small enough for Cloudflare (25 MiB a file).

Usage: python3 -I tools/web/split_parts.py <file> [<file> ...]

For each file writes parts/<file>.<hash>.<n> (the gzip stream cut every 20 MiB; the hash, from
the file's contents, keeps a cached part from an older build out) and <file>.parts.json
({"size": unzipped bytes, "packed": gzipped bytes, "type": MIME type, "parts": [names]}), then deletes the file.
tools/web/split_loader.js joins them again in the browser (tools/export_web.sh).
"""

import gzip
import hashlib
import json
import sys
from pathlib import Path

PART = 20 * 1024 * 1024
TYPES = {".wasm": "application/wasm", ".pck": "application/octet-stream"}


def split(path: Path) -> None:
	data = path.read_bytes()
	tag = hashlib.sha256(data).hexdigest()[:10]
	packed = gzip.compress(data, compresslevel=9, mtime=0)
	parts = path.parent / "parts"
	parts.mkdir(exist_ok=True)
	for old in parts.glob(path.name + ".*"):
		old.unlink()
	names = []
	for n, at in enumerate(range(0, len(packed), PART)):
		name = f"parts/{path.name}.{tag}.{n:03d}"
		(path.parent / name).write_bytes(packed[at:at + PART])
		names.append(name)
	manifest = {"size": len(data), "packed": len(packed), "type": TYPES.get(path.suffix, "application/octet-stream"), "parts": names}
	(path.parent / (path.name + ".parts.json")).write_text(json.dumps(manifest) + "\n")
	path.unlink()
	print(f"{path.name}: {len(data) / 1e6:.1f} MB -> {len(packed) / 1e6:.1f} MB gzip in {len(names)} parts")


if __name__ == "__main__":
	if len(sys.argv) < 2:
		sys.exit(__doc__.strip().splitlines()[2])
	for arg in sys.argv[1:]:
		split(Path(arg))
