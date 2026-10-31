"""Loop 3e: the structures over the aerial photo: bridge decks (by group, with their heights),
tunnel pieces (dashed, floor heights), approaches and pits (fills), retaining walls, piers,
portals and frames, roads at their names, and optionally the findings of check_roads
(shots/check_roads.json) and check_drive (--dump file) in the window.

Usage: python3 tools/overlay_structures.py OUT.png X Z HALF [--map=DIR] [--roads=REPORT.json]
       [--drive=DUMP.txt] [--labels]
  X, Z: map metres (+x east, +z south) of the centre; HALF: half the side in metres.
  --map=DIR reads DIR/centrum.json (a scratch bake) instead of game/map.

Legend: decks yellow (their group's number and heights every ~30 m with --labels), tunnels
blue dashed (floor heights), fills (approaches) orange, pits pale orange, walls white
(tunnel walls cyan), piers red squares, portals and frames magenta, the lane graph's lane
centres thin magenta; check_roads findings as red rings with their rule, check_drive
contacts as yellow crosses.
Needs Pillow; runs without -I so it finds it.
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bake_osm  # noqa: E402  (bounding box and projection)

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def main(out, cx, cz, half, map_dir=None, roads_report=None, drive_dump=None, labels=False):
    scale = 1000.0 / (2 * half)
    c = json.load(open(os.path.join(map_dir or os.path.join(ROOT, "game", "map"), "centrum.json"), encoding="utf-8"))
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

    def inside(x, z, pad=0.0):
        return abs(x - cx) <= half + pad and abs(z - cz) <= half + pad

    def pts(f):
        return [(f[i], f[i + 1]) for i in range(0, len(f) - 1, 2)]

    def band(p, l, r, col, outline=None):
        left = _offset(p, -l)
        right = _offset(p, r)
        poly = [px(*v) for v in left] + [px(*v) for v in right[::-1]]
        if len(poly) >= 3:
            d.polygon(poly, fill=col, outline=outline)

    def heights(p, hs, col, every=30.0):
        if not labels:
            return
        run = every
        for k in range(len(p)):
            if k:
                run += math.dist(p[k - 1], p[k])
            if (run >= every or k == len(p) - 1) and inside(*p[k]):
                x, y = px(*p[k])
                d.text((x + 3, y - 6), f"{hs[k]:.1f}", fill=col)
                run = 0.0

    for f in c.get("fills", []):
        p = pts(f["p"])
        if any(inside(*v, 40) for v in p):
            band(p, f.get("l", 3), f.get("r", 3), (255, 200, 120, 60) if f.get("pit") else (255, 140, 0, 90))
            heights(p, f["h"], (255, 180, 80, 255))
    for t in c.get("tunnels", {}).get("pieces", []):
        p = pts(t["p"])
        if not any(inside(*v, 40) for v in p):
            continue
        for k in range(len(p) - 1):
            if k % 2 == 0:
                band(p[k:k + 2], t["l"], t["r"], (60, 140, 255, 110))
        d.line([px(*v) for v in p], fill=(80, 170, 255, 255), width=2)
        heights(p, t["h"], (140, 200, 255, 255))
        x, y = px(*p[len(p) // 2])
        d.text((x + 4, y + 4), f"T{t['g']}", fill=(140, 200, 255, 255))
    for pc in c.get("decks", {}).get("pieces", []):
        p = pts(pc["p"])
        if not any(inside(*v, 40) for v in p):
            continue
        band(p, pc["l"], pc["r"], (255, 230, 0, 70), outline=(255, 230, 0, 200))
        heights(p, pc["h"], (255, 240, 120, 255))
        x, y = px(*p[len(p) // 2])
        d.text((x - 4, y - 12), f"d{pc['g']}", fill=(255, 255, 160, 255))
    for wl in c.get("walls", []):
        p = pts(wl["p"])
        if any(inside(*v, 5) for v in p):
            d.line([px(*v) for v in p], fill=(120, 255, 255, 255) if wl.get("k") == "tunnel" else (255, 255, 255, 230),
                   width=max(1, int(0.5 * scale)))
    for pr in c.get("decks", {}).get("piers", []):
        q = pr.get("c") or pr.get("p")
        if q and inside(q[0], q[1]):
            x, y = px(q[0], q[1])
            d.rectangle((x - 3, y - 3, x + 3, y + 3), outline=(255, 50, 50, 255))
    for po in c.get("tunnels", {}).get("portals", []):
        if inside(po[0], po[1]):
            x, y = px(po[0], po[1])
            d.ellipse((x - 6, y - 6, x + 6, y + 6), outline=(255, 0, 255, 255), width=2)
    for fr in c.get("tunnels", {}).get("frames", []):
        q = fr.get("c") if isinstance(fr, dict) else fr
        if q and inside(q[0], q[1]):
            x, y = px(q[0], q[1])
            d.rectangle((x - 5, y - 5, x + 5, y + 5), outline=(255, 0, 255, 255), width=1)
    g = c["graph"]
    for edge in g["edges"]:
        p = list(zip(edge["p"][0::2], edge["p"][1::2]))
        if not any(inside(*v, 20) for v in p):
            continue
        for lane in range(edge["n"]):
            q = _offset(p, edge["o"] + lane * edge["lw"])
            d.line([px(*v) for v in q], fill=(255, 0, 255, 150), width=1)
    if labels:
        seen = set()
        for r in c["roads"] + c.get("tunnels", {}).get("roads", []):
            p = pts(r["p"])
            name = r.get("name") or r["k"]
            for v in p[len(p) // 2:len(p) // 2 + 1]:
                key = (name, round(v[0] / 60), round(v[1] / 60))
                if inside(*v) and key not in seen:
                    seen.add(key)
                    x, y = px(*v)
                    d.text((x, y), name[:22], fill=(200, 255, 200, 255))
    if roads_report and os.path.exists(roads_report):
        for f in json.load(open(roads_report, encoding="utf-8")).get("findings", []):
            if inside(f["x"], f["z"]):
                x, y = px(f["x"], f["z"])
                d.ellipse((x - 7, y - 7, x + 7, y + 7), outline=(255, 40, 40, 255), width=2)
                d.text((x + 8, y - 4), f["rule"], fill=(255, 90, 90, 255))
    if drive_dump and os.path.exists(drive_dump):
        for line in open(drive_dump, encoding="utf-8"):
            f = line.split()
            if len(f) >= 9:
                x, z = float(f[6]), float(f[8])
                if inside(x, z):
                    u, v = px(x, z)
                    d.line((u - 4, v - 4, u + 4, v + 4), fill=(255, 255, 0, 255), width=2)
                    d.line((u - 4, v + 4, u + 4, v - 4), fill=(255, 255, 0, 255), width=2)
    # A 50 m scale bar.
    d.line((10, size - 12, 10 + 50 * scale, size - 12), fill=(255, 255, 255, 255), width=3)
    d.text((12, size - 28), f"50 m   ({cx:.0f}, {cz:.0f})", fill=(255, 255, 255, 255))
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
    args = [a for a in sys.argv[1:] if not a.startswith("--")]  # (negative numbers are arguments)
    opts = {a.split("=", 1)[0]: (a.split("=", 1)[1] if "=" in a else True) for a in sys.argv[1:] if a.startswith("--")}
    main(args[0], float(args[1]), float(args[2]), float(args[3]), map_dir=opts.get("--map"),
         roads_report=opts.get("--roads"), drive_dump=opts.get("--drive"), labels=bool(opts.get("--labels")))
