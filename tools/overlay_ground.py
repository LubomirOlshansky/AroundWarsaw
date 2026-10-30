"""Loop 3d-2a: the ground mesh's wireframe over the aerial photo, to look at what
map_builder.gd's `_build_ground` draws and leaves out (docs/DEVELOPMENT.md "Map data").

Usage: python3 tools/overlay_ground.py DUMP.json OUT.png X Z HALF [PX_PER_M]
  DUMP.json: from `godot --headless --path game --script res://tools/check_ground.gd -- --dump=DUMP.json`
  X, Z: map metres (+x east, +z south) of the centre; HALF: half the side in metres.

Legend: the drawn ground triangles' edges yellow (the 1 m apron sub-cells and their runs show
as a finer mesh), the 10 m triangles left out under the roads, areas and paths shaded blue.
Needs Pillow (`pip3 install pillow`); runs without -I so it finds it.
"""
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bake_osm  # noqa: E402  (bounding box and projection)


def main(dump, out, cx, cz, half, scale=None):
    scale = scale or 900.0 / (2 * half)
    g = json.load(open(dump))
    ortho = Image.open(bake_osm.ORTHO).convert("RGB")
    s, w, n, e = bake_osm.ortho_box()
    x0, z0 = bake_osm.project(n, w)
    x1, z1 = bake_osm.project(s, e)

    def opx(x, z):
        return ((x - x0) / (x1 - x0) * ortho.width, (z - z0) / (z1 - z0) * ortho.height)

    a = opx(cx - half, cz - half)
    b = opx(cx + half, cz + half)
    size = int(2 * half * scale)
    img = ortho.crop((int(a[0]), int(a[1]), int(b[0]), int(b[1]))).resize((size, size), Image.BILINEAR).convert("RGBA")
    img = Image.blend(img, Image.new("RGBA", img.size, (0, 0, 0, 255)), 0.3)
    ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)

    def px(x, z):
        return ((x - (cx - half)) * scale, (z - (cz - half)) * scale)

    step, gx, gz = g["step"], g["x0"], g["z0"]
    left = g["left"]
    for k in range(0, len(left), 3):
        i, j, h = left[k], left[k + 1], left[k + 2]
        x, z = gx + i * step, gz + j * step
        if abs(x + step / 2 - cx) > half + step or abs(z + step / 2 - cz) > half + step:
            continue
        tri = [(x, z), (x + step, z), (x + step, z + step)] if h == 0 else [(x, z), (x + step, z + step), (x, z + step)]
        d.polygon([px(*p) for p in tri], fill=(40, 110, 255, 110))
    t = g["ground"]
    for k in range(0, len(t), 6):
        tri = [(t[k], t[k + 1]), (t[k + 2], t[k + 3]), (t[k + 4], t[k + 5])]
        mx = (tri[0][0] + tri[1][0] + tri[2][0]) / 3
        mz = (tri[0][1] + tri[1][1] + tri[2][1]) / 3
        if abs(mx - cx) > half + step or abs(mz - cz) > half + step:
            continue
        q = [px(*p) for p in tri]
        d.line(q + q[:1], fill=(255, 220, 40, 230), width=1)
    Image.alpha_composite(img, ov).convert("RGB").save(out)
    print("overlay_ground: wrote %s (%d x %d px, %.1f px per m)" % (out, size, size, scale))


if __name__ == "__main__":
    if len(sys.argv) < 6:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4]), float(sys.argv[5]),
         float(sys.argv[6]) if len(sys.argv) > 6 else None)
