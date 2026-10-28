"""Check the baked roads against the aerial photo: draws game/map/centrum.json's road
surface, kerbs, painted lines and the lane graph's lanes over the GUGiK orthophoto
(data/raw/gugik/ortho.bmp, fetched by tools/fetch_gugik.py).

Usage: python3 tools/overlay_ortho.py OUT.png X Z HALF [PX_PER_M]
  X, Z: map metres (+x east, +z south) of the centre; HALF: half the side in metres.

Legend: road surface outlined red (areas from area:highway solid, road strips dashed
thin), kerbs cyan, edge/lane/stop lines white/yellow, the lane graph's lane centres
magenta, traffic islands and medians green, hatched areas orange.
Needs Pillow (`pip3 install pillow`); runs without -I so it finds it.
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bake_osm  # noqa: E402  (bounding box and projection)

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def main(out, cx, cz, half, scale=None):
    scale = scale or 900.0 / (2 * half)
    c = json.load(open(os.path.join(ROOT, "game", "map", "centrum.json"), encoding="utf-8"))
    ortho = Image.open(os.path.join(ROOT, "data", "raw", "gugik", "ortho.bmp")).convert("RGB")
    s, w, n, e = bake_osm.BBOX
    x0, z0 = bake_osm.project(n, w)
    x1, z1 = bake_osm.project(s, e)

    def opx(x, z):
        return ((x - x0) / (x1 - x0) * ortho.width, (z - z0) / (z1 - z0) * ortho.height)

    a = opx(cx - half, cz - half)
    b = opx(cx + half, cz + half)
    size = int(2 * half * scale)
    img = ortho.crop((int(a[0]), int(a[1]), int(b[0]), int(b[1]))).resize((size, size), Image.BILINEAR).convert("RGBA")
    # Fade the photo a little so the lines read.
    img = Image.blend(img, Image.new("RGBA", img.size, (0, 0, 0, 255)), 0.25)
    ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)

    def px(x, z):
        return ((x - (cx - half)) * scale, (z - (cz - half)) * scale)

    def pts(f):
        return [px(f[i], f[i + 1]) for i in range(0, len(f) - 1, 2)]

    def width(m):
        return max(1, int(m * scale))

    for k in c.get("carriage", []):
        col = (255, 150, 0, 255) if k["k"] in ("emergency", "prohibited") else (255, 40, 40, 255)
        p = pts(k["p"])
        d.line(p + p[:1], fill=col, width=2)
    for r in c["roads"]:
        if r["k"] in ("service", "living_street"):
            continue
        p = list(zip(r["p"][0::2], r["p"][1::2]))
        for side in (-1, 1):
            q = _offset(p, r.get("c", 0.0) + side * r["w"] * 0.5)
            d.line([px(*v) for v in q], fill=(255, 90, 90, 160), width=1)
    for i in c.get("islands", []):
        p = pts(i["p"])
        d.line(p + p[:1], fill=(60, 255, 60, 255), width=2)
    for m in c.get("medians", []):
        s4 = m["s"]
        q = [px(s4[i], s4[i + 1]) for i in range(0, len(s4), 4)] + [px(s4[i + 2], s4[i + 3]) for i in range(0, len(s4), 4)][::-1]
        d.polygon(q, outline=(60, 255, 60, 255))
    for k in c.get("kerbs", []):
        d.line(pts(k["p"]), fill=(0, 230, 255, 255), width=width(0.3))
    for m in c.get("markings", []):
        col = {"lane": (255, 230, 0, 255), "stop": (255, 255, 255, 255), "stripe": (255, 170, 60, 255),
               "cyclefill": (200, 110, 92, 200), "bus": (255, 255, 255, 255)}.get(m["k"], (240, 240, 240, 220))
        d.line(pts(m["p"]), fill=col, width=width(0.5 if m["k"] == "stop" else 0.2))
    g = c["graph"]
    for edge in g["edges"]:
        p = list(zip(edge["p"][0::2], edge["p"][1::2]))
        for lane in range(edge["n"]):
            q = _offset(p, edge["o"] + lane * edge["lw"])
            for v in q[::1]:
                x, y = px(*v)
                d.ellipse((x - 1.5, y - 1.5, x + 1.5, y + 1.5), fill=(255, 0, 255, 255))
            d.line([px(*v) for v in q], fill=(255, 0, 255, 140), width=1)
    for s_ in c.get("symbols", []):
        x, y = px(s_["x"], s_["z"])
        d.text((x - 4, y - 5), {"arrow": s_.get("t", "?"), "bus": "B", "bike": "o"}.get(s_["k"], "?"), fill=(255, 255, 255, 255))
    img = Image.alpha_composite(img, ov).convert("RGB")
    img.save(out)
    print(f"{out}: {size}x{size} px, {scale:.2f} px/m around {cx:.0f},{cz:.0f}")


def _offset(p, off):
    out = []
    for i in range(len(p)):
        a = p[max(i - 1, 0)]
        b = p[min(i + 1, len(p) - 1)]
        dx, dz = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(dx, dz) or 1.0
        out.append((p[i][0] - dz / ln * off, p[i][1] + dx / ln * off))
    return out


if __name__ == "__main__":
    main(sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4]),
         float(sys.argv[5]) if len(sys.argv) > 5 else None)
