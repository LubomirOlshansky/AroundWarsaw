"""Diagnostics: how LoD2 buildings line up with the OSM bake (counts, offsets)."""
import json
import os
import sys

sys.path.insert(0, sys.argv[1])
import bake_gugik as bg  # noqa: E402
import bake_osm  # noqa: E402
from pl1992 import from_pl1992  # noqa: E402

raw, out = sys.argv[2], sys.argv[3]
osm = json.load(open(os.path.join(out, "centrum.json")))
bx0, bz0, bx1, bz1 = osm["bounds"]
polys = [list(zip(b["p"][0::2], b["p"][1::2])) for b in osm["buildings"]]


def convert(e, n, h):
    lat, lon = from_pl1992(n, e)
    x, z = bake_osm.project(lat, lon)
    return (x, h, z)


inb = matched = 0
tall = []
offsets = []
import glob
for path in sorted(glob.glob(os.path.join(raw, "sheets", "*.gml"))):
    for gid, surfaces in bg.buildings_in(path, convert):
        ground = [s for s in surfaces if s[0] == "GroundSurface"]
        if not ground:
            continue
        fp = ground[0][1]
        cx = sum(v[0] for v in fp) / len(fp)
        cz = sum(v[2] for v in fp) / len(fp)
        if not (bx0 <= cx <= bx1 and bz0 <= cz <= bz1):
            continue
        inb += 1
        hit = any(bake_osm.point_in_poly(cx, cz, p) for p in polys)
        matched += hit
        top = max(v[1] for s in surfaces for v in s[1])
        tall.append((top - min(v[1] for v in fp), round(cx), round(cz), hit))
        if not hit and len(offsets) < 400:
            best = min(((sum(q[0] for q in p) / len(p) - cx) ** 2 + (sum(q[1] for q in p) / len(p) - cz) ** 2, p) for p in polys)
            offsets.append(best[0] ** 0.5)
print("LoD2 in bounds", inb, "with centroid inside an OSM building", matched)
offsets.sort()
print("unmatched: distance to nearest OSM centroid (m) median", offsets[len(offsets) // 2] if offsets else None)
for t in sorted(tall, reverse=True)[:6]:
    print("tall", t)
