"""Lay the v0.8 landmarks' roof-grid cells over the GUGiK orthophoto, to check placement.

Usage: godot --headless --path game --script res://tools/check_landmarks.gd -- --grid=/tmp/grid.png
       python3 tools/overlay_landmarks.py /tmp/grid.png OUT_PREFIX
Writes OUT_PREFIX_<landmark>.png: the photo (left) and the photo with the cells the model
covers tinted (right). The photo is not a true orthophoto: tall buildings lean away from
the point it was taken from, so a tower's roof sits off its footprint in it.
Needs Pillow; runs without -I so it finds it.
"""
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bake_osm  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def main(grid_png, prefix):
    meta = json.load(open(os.path.splitext(grid_png)[0] + ".json"))
    grid = Image.open(grid_png).convert("RGBA")
    ortho = Image.open(bake_osm.ORTHO).convert("RGB")
    s, w, n, e = bake_osm.ortho_box()
    ox0, oz0 = bake_osm.project(n, w)
    ox1, oz1 = bake_osm.project(s, e)
    cell = meta["cell"]
    for k, (key, name, cx, cz) in enumerate(meta["landmarks"]):
        half = {"stadium": 190, "palace": 160, "tarasy": 110, "varso": 70, "centralna": 90}.get(key, 50)
        if key == "poniatowski":
            continue  # two pairs 500 m apart: see the bridge's own shots
        scale = 900.0 / (2 * half)
        x0, z0 = cx - half, cz - half

        def opx(x, z):
            return ((x - ox0) / (ox1 - ox0) * ortho.width, (z - oz0) / (oz1 - oz0) * ortho.height)
        a, b = opx(x0, z0), opx(x0 + 2 * half, z0 + 2 * half)
        size = int(2 * half * scale)
        photo = ortho.crop((int(a[0]), int(a[1]), int(b[0]), int(b[1]))).resize((size, size), Image.BILINEAR)
        tinted = photo.convert("RGBA")
        over = Image.new("RGBA", tinted.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(over)
        i0 = int((x0 - meta["x0"]) / cell)
        j0 = int((z0 - meta["z0"]) / cell)
        for j in range(j0, j0 + int(2 * half / cell) + 2):
            for i in range(i0, i0 + int(2 * half / cell) + 2):
                if not (0 <= i < grid.width and 0 <= j < grid.height):
                    continue
                r, g, bb, al = grid.getpixel((i, j))
                if al and r == (k + 1) * 30:
                    px = (meta["x0"] + i * cell - x0) * scale
                    pz = (meta["z0"] + j * cell - z0) * scale
                    d.rectangle([px, pz, px + cell * scale - 1, pz + cell * scale - 1], fill=(255, 40, 200, 90))
        tinted = Image.alpha_composite(tinted, over).convert("RGB")
        out = Image.new("RGB", (size * 2 + 8, size), (30, 30, 30))
        out.paste(photo, (0, 0))
        out.paste(tinted, (size + 8, 0))
        ImageDraw.Draw(out).text((6, 6), name, fill=(255, 255, 0))
        out.save("%s_%s.png" % (prefix, key))
        print("wrote %s_%s.png" % (prefix, key))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
