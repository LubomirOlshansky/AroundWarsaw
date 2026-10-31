#!/usr/bin/env python3
"""Loop "content POIs" (2026-10-31): the street pois of tools/bake_street_pois.py, over the whole map.

    python3 -I tools/check_pois.py [--map=game/map] [--points=FILE.json] [--verbose]

Reads centrum.json (and lod2.json for the LoD2 footprints; the OpenStreetMap kerb and crossing
nodes from data/work/demo/osm_demo.json when it is there, else from the crossings' ends alone)
and counts, by class:

  Q1 off the map    a convenience, subway_entrance, bicycle_rental, scooter_zone or scooter poi
                    outside the map's outline (a scooter or zone closer than RIM to it)
  Q2 drivable       a scooter or a zone's corner on the carriageway: a carriageway area or median,
                    a road strip (its width + 0.8 m), a kerb (0.6 m), a tram track or a rail
  Q3 crossings      a scooter or a zone on a crossing (its width + 1.2 m) or a kerb ramp (3 m from
                    a crossing's end or a mapped kerb or crossing node)
  Q4 solid          a scooter or a zone in a building or LoD2 footprint, wall, fence, steps,
                    platform, island, fountain, flowerbed, water, pier, tunnel portal, garage ramp,
                    or against a pole, tree, bench, bin, bike rack, column, shelter or parked car
                    (the pose's own thing excepted: a bench's front, a hedge, a shelter's roof)
  Q5 not on its spot a lying, standing or zone point off the footways (more than its half-width + 1 m
                    from a footway), a "grass" one off the grass, a "hedge" one more than 0.6 m from
                    a hedge, a "roof" one off a shelter's roof, a "bench" one not at a bench
  Q6 rules          the density (a 500 m square over 30 a km²: at most 9), zones closer than
                    ZONE_SPACING, not exactly one egg zone with one standing scooter, an odd share
                    off 1 in 15 or a roof share off 1 in 40, a subway entrance without a yaw, a corner
                    shop without its door

Prints each class's count (up to 5 places with a ready --at=), the counts per kind and pose,
a `check_pois counts:` line, `check_pois: OK` and exits 0 when all are 0; exit 1 otherwise. --points=FILE checks a list of
[x, z] (e.g. a dump of the runtime picks) against Q1-Q4 as lying scooters and only reports.
Standard library only (~6 s).
"""
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import bake_street_pois as bsp  # noqa: E402

CLASS = {
    "map edge": "Q1",
    "carriageway": "Q2", "kerb": "Q2", "tram track": "Q2", "rail": "Q2",
    "crossing": "Q3", "kerb ramp": "Q3",
}
NAMES = {"Q1": "off the map", "Q2": "on the carriageway", "Q3": "on a crossing or kerb ramp",
         "Q4": "in or against something solid", "Q5": "not on its spot", "Q6": "rules"}


class Report:
    def __init__(self):
        self.found = {k: [] for k in NAMES}

    def add(self, cls, x, z, what):
        self.found[cls].append((x, z, what))


def kerb_nodes():
    """The OSM kerb and crossing nodes, when the demo's OSM export is on disk (else none)."""
    path = os.path.join(ROOT, "data", "work", "demo", "osm_demo.json")
    if not os.path.exists(path):
        return [], "no OSM export (data/work/demo): kerb ramps from the crossings' ends only"
    with open(path, encoding="utf-8") as f:
        els = json.load(f)["elements"]
    return bsp.kerb_points(els, None), "kerb and crossing nodes from data/work/demo/osm_demo.json"


def main(argv):
    map_dir = next((a.split("=", 1)[1] for a in argv if a.startswith("--map=")), os.path.join(ROOT, "game", "map"))
    points = next((a.split("=", 1)[1] for a in argv if a.startswith("--points=")), None)
    verbose = "--verbose" in argv
    with open(os.path.join(map_dir, "centrum.json"), encoding="utf-8") as f:
        data = json.load(f)
    lod2 = None
    if os.path.exists(os.path.join(map_dir, "lod2.json")):
        with open(os.path.join(map_dir, "lod2.json"), encoding="utf-8") as f:
            lod2 = json.load(f)
    kerbs, kerb_note = kerb_nodes()
    solids = bsp.Solids(data, lod2, kerbs)
    shape = solids.shape
    pois = data.get("pois", [])
    rep = Report()

    def clear(x, z, r, skip=()):
        why = solids.blocked(x, z, r, skip)
        if why:
            rep.add(CLASS.get(why, "Q4"), x, z, why)
        return why is None

    if points:
        with open(points, encoding="utf-8") as f:
            pts = json.load(f)
        for x, z in pts:
            clear(x, z, bsp.R)
        print(f"check_pois --points: {len(pts)} points from {points} ({kerb_note})")
        for cls in ("Q1", "Q2", "Q3", "Q4"):
            print(f"  {cls} {NAMES[cls]}: {len(rep.found[cls])}{_by_what(rep.found[cls])}")
        return 0

    # What the poses need nearby.
    foot = bsp.Segs()
    for p in data.get("paths", []):
        if p["k"] == "foot" and "dk" not in p:
            foot.add_line(bsp.pairs(p["p"]), p["w"] * 0.5 + 1.0, "footway")
    green = bsp.Polys()
    for a in data.get("areas", []):
        if a["k"] in ("grass", "park"):
            green.add(bsp.pairs(a["p"]), a["k"])
    hedges = bsp.Segs()
    for line in data.get("lines", []):
        if line["k"] == "hedge":
            hedges.add_line(bsp.pairs(line["p"]), 0.6, "hedge")
    props = {}
    for key in ("benches", "shelters"):
        v = data.get(key, [])
        props[key] = bsp.Segs()
        for i in range(0, len(v) - 2, 3):
            props[key].add((v[i], v[i + 1]), (v[i], v[i + 1]), 1.0 if key == "benches" else 1.6, key)

    new = [p for p in pois if p["k"] in bsp.KINDS]
    for p in new:
        if not shape.contains(p["x"], p["z"]):
            rep.add("Q1", p["x"], p["z"], p["k"])
    zones = [p for p in pois if p["k"] == "scooter_zone"]
    scooters = [p for p in pois if p["k"] == "scooter"]
    for zi, zn in enumerate(zones):
        x, z, yaw = zn["x"], zn["z"], zn["yaw"]
        ux, uz = math.sin(yaw), math.cos(yaw)
        for a in (-1, 0, 1):
            for b in (-1, 0, 1):
                cx = x + ux * a * bsp.ZONE_SIZE[0] * 0.5 - uz * b * bsp.ZONE_SIZE[1] * 0.5
                cz = z + uz * a * bsp.ZONE_SIZE[0] * 0.5 + ux * b * bsp.ZONE_SIZE[1] * 0.5
                if not clear(cx, cz, 0.2):
                    break
        if foot.near(x, z) is None:
            rep.add("Q5", x, z, "zone off the footways")
        for zj in range(zi):
            d = math.hypot(zones[zj]["x"] - x, zones[zj]["z"] - z)
            if d < bsp.ZONE_SPACING - 0.5:
                rep.add("Q6", x, z, f"zones {d:.0f} m apart")
    for s in scooters:
        x, z, pose = s["x"], s["z"], s["p"]
        if pose == "roof":
            if props["shelters"].near(x, z) is None or abs(s.get("h", 0) - bsp.SHELTER_ROOF) > 0.05:
                rep.add("Q5", x, z, "roof scooter off a shelter's roof")
            if not shape.contains(x, z) or shape.rim(x, z) < bsp.RIM - 0.5:
                rep.add("Q1", x, z, "roof scooter")
            continue
        skip = {"bench": ("bench",), "hedge": ("hedge",)}.get(pose, ())
        clear(x, z, 0.3 if pose == "stand" else bsp.R, skip)
        if pose in ("lie", "stand") and foot.near(x, z) is None:
            rep.add("Q5", x, z, f"{pose} off the footways")
        elif pose == "grass" and green.inside(x, z) is None:
            rep.add("Q5", x, z, "grass scooter off the grass")
        elif pose == "hedge" and hedges.near(x, z) is None:
            rep.add("Q5", x, z, "hedge scooter away from a hedge")
        elif pose == "bench" and props["benches"].near(x, z) is None:
            rep.add("Q5", x, z, "bench scooter away from a bench")
    # Q6: the rules.
    cells = {}
    for s in scooters:
        c = (math.floor(s["x"] / bsp.CELL), math.floor(s["z"] / bsp.CELL))
        cells[c] = cells.get(c, 0) + 1
    cap = int(math.ceil(bsp.PER_KM2_HERO * (bsp.CELL / 1000.0) ** 2)) + 1
    for c, n in sorted(cells.items()):
        if n > cap:
            rep.add("Q6", (c[0] + 0.5) * bsp.CELL, (c[1] + 0.5) * bsp.CELL, f"{n} scooters in a 500 m square (at most {cap})")
    eggs = [i for i, zn in enumerate(zones) if zn.get("egg") == "easter_lezak"]
    standing = [s for s in scooters if s["p"] == "stand"]
    if len(eggs) != 1 or len(standing) != 1 or (eggs and standing and standing[0].get("zn") != eggs[0]):
        rep.add("Q6", 0, 0, f"{len(eggs)} egg zones, {len(standing)} standing scooters (want one each, in it)")
    n = len(scooters)
    odd = sum(1 for s in scooters if s["p"] not in ("lie", "stand"))
    roof = sum(1 for s in scooters if s["p"] == "roof")
    if n and abs(odd - n / bsp.ODD_EVERY) > max(3, n * 0.02):
        rep.add("Q6", 0, 0, f"{odd} of {n} in odd places (want ~1 in {bsp.ODD_EVERY})")
    if n and abs(roof - n / bsp.ROOF_EVERY) > max(2, n * 0.01):
        rep.add("Q6", 0, 0, f"{roof} of {n} on shelter roofs (want ~1 in {bsp.ROOF_EVERY})")
    for p in pois:
        if p["k"] == "subway_entrance" and "yaw" not in p:
            rep.add("Q6", p["x"], p["z"], "subway entrance without a yaw")
        if p["k"] == "convenience" and not p.get("door"):
            rep.add("Q6", p["x"], p["z"], "corner shop without a door")

    kinds = {}
    for p in pois:
        kinds[p["k"]] = kinds.get(p["k"], 0) + 1
    poses = {}
    for s in scooters:
        poses[s["p"]] = poses.get(s["p"], 0) + 1
    print("check_pois: " + ", ".join(f"{k} {kinds.get(k, 0)}" for k in bsp.KINDS)
          + f", addresses {kinds.get('address', 0)} ({sum(1 for p in pois if p['k'] == 'address' and p.get('v'))} places' extra)"
          + "; poses " + ", ".join(f"{k} {poses[k]}" for k in sorted(poses)) + f" ({kerb_note})")
    bad = 0
    for cls, items in rep.found.items():
        bad += len(items)
        print(f"  {cls} {NAMES[cls]}: {len(items)}{_by_what(items)}")
        for x, z, what in items[:(len(items) if verbose else 5)]:
            print(f"      {what} at --at={x:.0f},{z:.0f}")
    print("check_pois counts: " + " ".join(f"{cls} {len(items)}" for cls, items in rep.found.items())
          + f" · scooters {len(scooters)}, zones {len(zones)}")
    print("check_pois: " + ("OK" if bad == 0 else f"{bad} problems"))
    return 0 if bad == 0 else 1


def _by_what(items):
    if not items:
        return ""
    by = {}
    for _, _, w in items:
        by[w] = by.get(w, 0) + 1
    return " (" + ", ".join(f"{w} {n}" for w, n in sorted(by.items(), key=lambda kv: -kv[1])) + ")"


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
