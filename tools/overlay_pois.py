"""Loop "content POIs" (2026-10-31): the street pois of tools/bake_street_pois.py over the aerial
photo, to look at them (tools/check_pois.py counts them over the whole map).

Usage: python3 tools/overlay_pois.py OUT.png X Z HALF [--map=game/map] [--px=PX_PER_M]
  X, Z: map metres (+x east, +z south) of the centre; HALF: half the side in metres.

Legend: the carriageway red (areas outlined, road strips thin), kerbs cyan, crossings yellow,
footways thin white, buildings grey; scooters violet bars along their length (odd poses: grass
green, bench brown, frogs lime, hedge dark green, roof orange, the standing one gold), zones white
3 x 1.5 m rectangles (the egg's gold), subway entrances blue squares with a tick down their way,
corner shops green dots (the Frogs' chain lime), city bike docks orange bars.
Needs Pillow; runs without -I so it finds it.
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bake_osm  # noqa: E402  (the photo's box and the projection)
from overlay_ortho import _offset  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
POSE = {"lie": (170, 80, 255), "grass": (60, 220, 60), "bench": (160, 100, 40), "frogs": (170, 255, 60),
        "hedge": (0, 120, 40), "roof": (255, 150, 0), "stand": (255, 215, 0)}


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    out, cx, cz, half = args[0], float(args[1]), float(args[2]), float(args[3])
    map_dir = next((a.split("=", 1)[1] for a in argv if a.startswith("--map=")), os.path.join(ROOT, "game", "map"))
    scale = float(next((a.split("=", 1)[1] for a in argv if a.startswith("--px=")), 1000.0 / (2 * half)))
    c = json.load(open(os.path.join(map_dir, "centrum.json"), encoding="utf-8"))
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
    img = Image.blend(img, Image.new("RGBA", img.size, (0, 0, 0, 255)), 0.35)
    ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)

    def px(x, z):
        return ((x - (cx - half)) * scale, (z - (cz - half)) * scale)

    def pts(f):
        return [px(f[i], f[i + 1]) for i in range(0, len(f) - 1, 2)]

    def near(f):
        return any(abs(f[i] - cx) < half + 50 and abs(f[i + 1] - cz) < half + 50 for i in range(0, len(f) - 1, 2))

    for bl in c["buildings"]:
        if near(bl["p"]):
            p = pts(bl["p"])
            d.line(p + p[:1], fill=(150, 150, 150, 200), width=1)
    for k in c.get("carriage", []):
        if near(k["p"]):
            p = pts(k["p"])
            d.line(p + p[:1], fill=(255, 40, 40, 255), width=2)
    for r in c["roads"]:
        if not near(r["p"]):
            continue
        p = list(zip(r["p"][0::2], r["p"][1::2]))
        for side in (-1, 1):
            q = _offset(p, r.get("c", 0.0) + side * r["w"] * 0.5)
            d.line([px(*v) for v in q], fill=(255, 90, 90, 160), width=1)
    for k in c.get("kerbs", []):
        if near(k["p"]):
            d.line(pts(k["p"]), fill=(0, 230, 255, 255), width=max(1, int(0.3 * scale)))
    for p in c["paths"]:
        if not near(p["p"]):
            continue
        if p["k"] in ("zebra", "cyclecross"):
            d.line(pts(p["p"]), fill=(255, 230, 0, 200), width=max(1, int(p["w"] * scale)))
        elif p["k"] == "foot" and "dk" not in p:
            d.line(pts(p["p"]), fill=(255, 255, 255, 110), width=max(1, int(p["w"] * scale)))
    for poi in c["pois"]:
        k = poi["k"]
        if k not in ("scooter", "scooter_zone", "subway_entrance", "convenience", "bicycle_rental") or abs(poi["x"] - cx) > half or abs(poi["z"] - cz) > half:
            continue
        x, z = poi["x"], poi["z"]
        yaw = poi.get("yaw", 0.0)
        ux, uz = math.sin(yaw), math.cos(yaw)
        if k == "scooter":
            col = POSE.get(poi["p"], (255, 0, 255)) + (255,)
            d.line([px(x - ux * 0.55, z - uz * 0.55), px(x + ux * 0.55, z + uz * 0.55)], fill=col, width=max(3, int(0.35 * scale)))
            q = px(x, z)
            d.ellipse((q[0] - 4, q[1] - 4, q[0] + 4, q[1] + 4), outline=col, width=2)
        elif k == "scooter_zone":
            col = (255, 215, 0, 255) if poi.get("egg") else (255, 255, 255, 255)
            corners = [(x + ux * sa * 1.5 - uz * sb * 0.75, z + uz * sa * 1.5 + ux * sb * 0.75) for sa, sb in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
            q = [px(*v) for v in corners]
            d.line(q + q[:1], fill=col, width=2)
        elif k == "subway_entrance":
            q = px(x, z)
            d.rectangle((q[0] - 5, q[1] - 5, q[0] + 5, q[1] + 5), outline=(40, 120, 255, 255), width=3)
            if "yaw" in poi:
                d.line([q, px(x + ux * 6, z + uz * 6)], fill=(40, 120, 255, 255), width=3)
        elif k == "convenience":
            q = px(x, z)
            col = (170, 255, 60, 255) if poi.get("fr") else (40, 200, 90, 255)
            d.ellipse((q[0] - 5, q[1] - 5, q[0] + 5, q[1] + 5), fill=col)
            d.line([q, px(*poi["door"])], fill=col[:3] + (120,), width=1)
        elif k == "bicycle_rental":
            ln = poi.get("l", 6.0) * 0.5
            d.line([px(x - ux * ln, z - uz * ln), px(x + ux * ln, z + uz * ln)], fill=(255, 140, 0, 255), width=4)
    img = Image.alpha_composite(img, ov)
    img.convert("RGB").save(out)
    print(f"overlay_pois: {out} ({size} px, {half * 2:.0f} m)")


if __name__ == "__main__":
    main(sys.argv[1:])
