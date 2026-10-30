"""Write the AO and lamp-light maps as PNGs for Godot to import VRAM-compressed (2026-10-30).

    python3 -I tools/bake_map_textures.py [game/map]

The prebuilt city (tools/bake_city.gd) used to save game/map/ao.bin and lights.bin as plain
RG8 textures in map/shared/*.res: 40 MB of video memory each on the phone, and 18.5 MB of the
web build's first download (the .res files barely compress). This writes them as
map/shared/ao_map.png and light_map.png (RGB, blue 0) with an .import file that asks for
"VRAM Compressed" with the channels packed as RG: Godot's import makes EAC RG11 (phones, the
etc2 variant) and BC5 / RGTC (desktops, s3tc), one byte a texel instead of two. The import pads
each to a multiple of 4 texels (5320 x 3784), repeating the edge; the maps' rects cover the PNG's
size, so every texel stays where it was. Measured against the .bin: AO off by at most 12 / 255 (mean
0.5), the lamp pools at most 31 at their sharpest cut edges (mean 0.15).

tools/setup_map.sh runs this, then `godot --headless --import`, before bake_city.gd. The phones
use the imports, the web keeps the RG8 .res (both formats in its pack would hold 80 MB more in
the browser's memory): the export presets leave out one or the other, and map_builder.gd
attach_maps picks what is there. Derived and
not committed (map/shared/ is gitignored). A PNG is only rewritten when its pixels change, so
an unchanged map isn't imported again. Standard library only.
"""
import os
import struct
import sys
import zlib

MAPS = [("ao.bin", "ao_map.png"), ("lights.bin", "light_map.png")]
# Only the params: Godot adds the rest. channel_pack=1 (Optimized) packs a map with blue 0 and
# alpha 255 as RG; normal_map=2 (disabled) keeps the importer from treating it as a normal map
# (that would renormalise the two channels as a vector); no mipmaps (the ground is seen from one
# height, and the .bin had none).
IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"

[params]

compress/mode=2
compress/high_quality=false
compress/normal_map=2
compress/channel_pack=1
mipmaps/generate=false
detect_3d/compress_to=0
"""


def png_bytes(w, h, rg):
    """An RGB PNG of the RG8 map, padded to a multiple of 4 texels each way by repeating the last
    column and row (the block size of the VRAM formats: Godot would pad it anyway, but then the
    GPU texture is wider than the texture says and the map would stretch by up to 3 texels)."""
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)
    pw, ph = (w + 3) // 4 * 4, (h + 3) // 4 * 4
    rows = []
    for j in range(ph):
        jj = min(j, h - 1)
        row = rg[jj * w * 2:(jj + 1) * w * 2]
        out = bytearray(pw * 3)
        out[0:w * 3:3] = row[0::2]
        out[1:w * 3:3] = row[1::2]
        for i in range(w, pw):
            out[i * 3] = row[(w - 1) * 2]
            out[i * 3 + 1] = row[(w - 1) * 2 + 1]
        rows.append(b"\x00" + bytes(out))
    w, h = pw, ph
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(b"".join(rows), 6)) + chunk(b"IEND", b""))


def main():
    mapdir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "map")
    shared = os.path.join(mapdir, "shared")
    os.makedirs(shared, exist_ok=True)
    for src, dst in MAPS:
        with open(os.path.join(mapdir, src), "rb") as f:
            data = f.read()
        w, h = struct.unpack("<II", data[:8])
        png = png_bytes(w, h, data[20:20 + w * h * 2])
        path = os.path.join(shared, dst)
        old = None
        if os.path.exists(path):
            with open(path, "rb") as f:
                old = f.read()
        if old != png:
            with open(path, "wb") as f:
                f.write(png)
        imp = path + ".import"
        keep = None
        if os.path.exists(imp):
            with open(imp) as f:
                keep = f.read()
        # Godot rewrites the file with every param after an import: only write it when ours are
        # missing from it (a first run, or a change to IMPORT).
        if keep is None or any(line not in keep.splitlines() for line in IMPORT.splitlines() if "=" in line and "/" in line):
            with open(imp, "w") as f:
                f.write(IMPORT)
        print("bake_map_textures: %s %dx%d -> shared/%s (%.1f MB)%s" % (src, w, h, dst, len(png) / 1e6,
              "" if old != png else ", unchanged"))


if __name__ == "__main__":
    main()
