"""The Palace of Culture's grounds (F, 2026-11-07): the parking lots, their bays and the shrub beds
round the Palace, which the main map bake folds away (amenity=parking is not an area there, and
natural=scrub becomes a plain lawn).

    python3 -I tools/bake_pkin_grounds.py [--raw=DIR] [--out=FILE]

Reads the raw OpenStreetMap downloads (default data/raw/: osm_centrum.json, osm_wide.json,
osm_more.json, Overpass JSON; the Mac's tools/setup_map.sh fetches them) and writes
game/data/pkin_grounds.json:

    {"_about", "zone": [x, z, ...], "parking": [{"p": [...], "s": "asphalt" | "pavers"}, ...],
     "bays": [[x, z, ...], ...], "scrub": [[x, z, ...], ...]}

`zone` is the grounds between Emilii Plater, Świętokrzyska, Marszałkowska and Al. Jerozolimskie
(game metres, +x east, +z south), drawn about 8 m inside the four streets' carriageways; only
closed ways whose centre lies in it are kept. map_builder.gd draws the lots (asphalt for the big
Plac Defilad lot, grey pavers for the kerbside lots along the Palace's service roads) and the bay
lines, and a shrub bed with bushes on each scrub; it also draws every OSM `wall` inside `zone`
as the low granite planter or retaining wall it is (PKIN_WALL), not a 1.9 m wall. Deterministic
(sorted by OSM id, coordinates to 0.01 m). Standard library only.
"""
import argparse
import json
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
from bake_osm import project  # noqa: E402

RAW_FILES = ["osm_centrum.json", "osm_wide.json", "osm_more.json"]
## The grounds, clockwise from Emilii Plater x Świętokrzyska (read off the baked carriageways).
ZONE = [(-1452, 10), (-1426, -2), (-1358, -29), (-1180, -86), (-1064, -105), (-1025, -1), (-993, 86),
        (-974, 137), (-945, 212), (-933, 245), (-898, 296), (-880, 345), (-879, 440), (-925, 469),
        (-1000, 500), (-1147, 550), (-1272, 525), (-1303, 440), (-1334, 349), (-1370, 250), (-1391, 190),
        (-1413, 129), (-1429, 82)]


def inside(x, z, poly):
    c = False
    n = len(poly)
    for i in range(n):
        x1, z1 = poly[i]
        x2, z2 = poly[(i + 1) % n]
        if (z1 > z) != (z2 > z) and x < x1 + (z - z1) * (x2 - x1) / (z2 - z1):
            c = not c
    return c


def ways(raw_dir):
    """Every closed way of the raw files once, as (id, tags, [(x, z), ...]) without the repeat point."""
    seen = {}
    for name in RAW_FILES:
        path = os.path.join(raw_dir, name)
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as f:
            els = json.load(f).get("elements", [])
        nodes = {e["id"]: e for e in els if e.get("type") == "node"}
        for e in els:
            if e.get("type") != "way" or e["id"] in seen:
                continue
            if "geometry" in e:
                pts = [project(g["lat"], g["lon"]) for g in e["geometry"]]
            else:
                ids = e.get("nodes", [])
                if any(n not in nodes for n in ids):
                    continue
                pts = [project(nodes[n]["lat"], nodes[n]["lon"]) for n in ids]
            if len(pts) < 4 or abs(pts[0][0] - pts[-1][0]) > 0.01 or abs(pts[0][1] - pts[-1][1]) > 0.01:
                continue
            seen[e["id"]] = (e.get("tags", {}), pts[:-1])
    return [(i, seen[i][0], seen[i][1]) for i in sorted(seen)]


def flat(pts):
    return [round(v, 2) for p in pts for v in p]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--raw", default=os.path.join(ROOT, "data", "raw"))
    ap.add_argument("--out", default=os.path.join(ROOT, "game", "data", "pkin_grounds.json"))
    args = ap.parse_args()
    parking, bays, scrub = [], [], []
    for _wid, tags, pts in ways(args.raw):
        cx = sum(p[0] for p in pts) / len(pts)
        cz = sum(p[1] for p in pts) / len(pts)
        if not inside(cx, cz, ZONE):
            continue
        if tags.get("amenity") == "parking":
            surf = tags.get("surface", "")
            kind = "asphalt" if surf == "asphalt" or (not surf and tags.get("parking") == "surface") else "pavers"
            parking.append({"p": flat(pts), "s": kind})
        elif tags.get("amenity") == "parking_space":
            bays.append(flat(pts))
        elif tags.get("natural") in ("scrub", "shrubbery"):
            scrub.append(flat(pts))
    if not parking and not bays and not scrub:
        sys.exit("bake_pkin_grounds: no raw OSM under %s (the Mac's data/raw/)" % args.raw)
    out = {
        "_about": "The Palace of Culture's grounds (tools/bake_pkin_grounds.py from the raw OSM): parking lots "
                  "(s: asphalt or pavers), their bays, the shrub beds, and the zone whose walls are low planters.",
        "zone": flat(ZONE),
        "parking": parking,
        "bays": bays,
        "scrub": scrub,
    }
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")
    print("bake_pkin_grounds: %d lots, %d bays, %d shrub beds -> %s" % (len(parking), len(bays), len(scrub),
                                                                   os.path.relpath(args.out, ROOT)))


if __name__ == "__main__":
    main()
