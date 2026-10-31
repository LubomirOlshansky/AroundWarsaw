"""Map north (2026-10-31): nothing of the map lies where the map isn't, and the map's edge is
closed where the map grew.

Usage: python3 -I tools/check_outline.py [--map=game/map] [--quiet]

The map is its bounds without the parts listed in `outside` (tools/map_shape.py; the north
extension left the box's north-east corner out). Over centrum.json, lod2.json and index.json
this counts, by class:

  O1 lines     a vertex of a road, path, tram, rail, kerb, marking, median, guard rail, wall,
               step, line, shore, lane-graph edge, deck, approach or tunnel more than PAD
               outside the map (the bake clips them at its edge)
  O2 areas     a vertex of an area, carriageway, surface, island, platform, sand, sandbar or
               pedestrian zone more than PAD outside
  O3 buildings an OSM building or LoD2 footprint vertex more than BUILDING_SLACK outside (the bakes
               keep buildings that hang over the edge by up to 6 m)
  O4 points    a scanned or mapped tree, lamp, signal, parked car, bench, bin, bike rack, column,
               shelter, point of interest (or its door) or river spot outside
  O5 sectors   a sector of the index that doesn't meet the map (grown by a ground cell), or a
               place on the map no sector holds
  O6 dead ends a drivable road's end on the map's edge that the lane graph can't leave or enter
               (no off-map link, bake_osm.bake_graph `portals`: traffic and rivals stuck there)

Prints each class's count (and up to 5 places with a ready --at=), `check_outline: OK` and
exits 0 when O1-O5 are all 0 (O6 is reported: the box's own edges have always had some; its
count in the extension is printed apart); exit 1 otherwise. Standard library only (~3 s).
"""
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import map_shape  # noqa: E402

PAD = 0.5
BUILDING_SLACK = 6.0
GROUND_CELL = 10.0
SECTOR = 512.0
LINES = ["roads", "paths", "trams", "rails", "kerbs", "markings", "guards", "walls", "steps", "lines", "shore"]
AREAS = ["areas", "carriage", "surfaces", "islands", "platforms", "sand", "sandbars", "ped_zones"]
POINTS = {"trees3d": 6, "trees": 4, "lamps": 2, "signals": 3, "parked": 4, "benches": 3, "bins": 3, "bikes": 3,
          "columns": 3, "shelters": 3}


def pairs(flat):
    return list(zip(flat[0::2], flat[1::2]))


class Report:
    def __init__(self):
        self.found = {}

    def add(self, rule, x, z, what):
        self.found.setdefault(rule, []).append((x, z, what))


def main(argv):
    map_dir = os.path.join(ROOT, "game", "map")
    quiet = False
    for a in argv:
        if a.startswith("--map="):
            map_dir = a.split("=", 1)[1]
        elif a == "--quiet":
            quiet = True
        else:
            print(__doc__.strip().splitlines()[2])
            return 2
    d = json.load(open(os.path.join(map_dir, "centrum.json"), encoding="utf-8"))
    shape = map_shape.of(d)
    near = shape.grow(PAD)
    slack = shape.grow(BUILDING_SLACK)
    rep = Report()

    def line(rule, kind, flat, label=""):
        for x, z in pairs(flat):
            if not near.contains(x, z):
                rep.add(rule, x, z, f"{kind} {label}".strip())
                return

    for kind in LINES:
        for it in d.get(kind, []):
            line("O1", kind, it.get("p", []), it.get("name", "") or it.get("k", ""))
    for it in d.get("medians", []):
        line("O1", "median", it.get("s", []))
    for e in d.get("graph", {}).get("edges", []):
        line("O1", "lane edge", e["p"], e.get("name", ""))
    for kind, pieces in (("deck", d.get("decks", {}).get("pieces", [])), ("approach", d.get("fills", [])),
                         ("tunnel", d.get("tunnels", {}).get("pieces", []))):
        for it in pieces:
            line("O1", kind, it.get("p", []))
    for kind in AREAS:
        for it in d.get(kind, []):
            for x, z in pairs(it.get("p", [])):
                if not near.contains(x, z):
                    rep.add("O2", x, z, f"{kind} {it.get('k', '')}".strip())
                    break
    for b in d.get("buildings", []):
        for x, z in pairs(b["p"]):
            if not slack.contains(x, z):
                rep.add("O3", x, z, "building " + (b.get("name") or ""))
                break
    lp = os.path.join(map_dir, "lod2.json")
    if os.path.exists(lp):
        for fp in json.load(open(lp)).get("footprints", []):
            for x, z in pairs(fp):
                if not slack.contains(x, z):
                    rep.add("O3", x, z, "LoD2 footprint")
                    break
    for kind, stride in POINTS.items():
        flat = d.get(kind, [])
        for i in range(0, len(flat) - stride + 1, stride):
            if not near.contains(flat[i], flat[i + 1]):
                rep.add("O4", flat[i], flat[i + 1], kind)
    for p in d.get("pois", []):
        for x, z in [(p["x"], p["z"])] + ([tuple(p["door"])] if p.get("door") else []):
            if not near.contains(x, z):
                rep.add("O4", x, z, f"poi {p['k']} {p.get('name', '')}".strip())
                break
    for s in d.get("drivable_bank", []) if isinstance(d.get("drivable_bank"), list) else []:
        if isinstance(s, list) and len(s) >= 2 and not near.contains(s[0], s[1]):
            rep.add("O4", s[0], s[1], "river spot")

    ip = os.path.join(map_dir, "index.json")
    sectors_note = "no index.json"
    if os.path.exists(ip):
        idx = json.load(open(ip, encoding="utf-8"))
        keys = {tuple(k) for k in idx["sectors"]["keys"]}
        grown = shape.grow(GROUND_CELL)
        for i, j in sorted(keys):
            if not grown.meets((i * SECTOR, j * SECTOR, (i + 1) * SECTOR, (j + 1) * SECTOR)):
                rep.add("O5", (i + 0.5) * SECTOR, (j + 0.5) * SECTOR, f"sector {i}_{j} off the map")
        for px, pz in shape.outline():
            for dx, dz in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                x, z = px + dx, pz + dz
                if shape.contains(x, z) and (math.floor(x / SECTOR), math.floor(z / SECTOR)) not in keys:
                    rep.add("O5", x, z, "map with no sector")
        sectors_note = f"{len(keys)} sectors"

    # O6: drivable ends on the edge the graph can't leave or enter (no off-map link).
    g = d.get("graph", {})
    nodes, edges = g.get("nodes", []), g.get("edges", [])
    linked_out = {p[0] for p in g.get("portals", [])}
    linked_in = {p[1] for p in g.get("portals", [])}
    outs, ins = {}, {}
    for k, e in enumerate(edges):
        outs.setdefault(e["a"], []).append(k)
        ins.setdefault(e["b"], []).append(k)
    dead, dead_new = 0, 0
    old_north = shape.outside[0][3] if shape.outside else None
    for k, e in enumerate(edges):
        for end, n, own, linked in (("exit", e["b"], outs, linked_out), ("entry", e["a"], ins, linked_in)):
            x, z = nodes[n * 2], nodes[n * 2 + 1]
            if shape.rim(x, z) > 0.5 or k in linked:
                continue
            if end == "exit":
                other = [f for f in own.get(n, []) if edges[f]["b"] != e["a"]]
            else:
                other = [f for f in own.get(n, []) if edges[f]["a"] != e["b"]]
            if other:
                continue
            dead += 1
            if old_north is not None and z < old_north - 0.5:
                dead_new += 1
                rep.add("O6", x, z, f"{end} of {e.get('name') or e['k']} with no off-map link")

    names = {"O1": "lines off the map", "O2": "areas off the map", "O3": "buildings off the map",
             "O4": "points off the map", "O5": "sectors", "O6": "dead ends on the extension's edge"}
    bad = 0
    print(f"check_outline: the map {tuple(round(v, 1) for v in shape)} without {[[round(v, 1) for v in o] for o in shape.outside]}; {sectors_note}")
    for rule in ("O1", "O2", "O3", "O4", "O5", "O6"):
        found = rep.found.get(rule, [])
        extra = f" (whole map {dead})" if rule == "O6" else ""
        print(f"{rule} {names[rule]}: {len(found)}{extra}")
        if rule != "O6":
            bad += len(found)
        if not quiet:
            for x, z, what in found[:5]:
                print(f"  {what} at ({x:.0f}, {z:.0f})  [--at={x:.0f},{z:.0f}]")
    print("check_outline counts: " + " ".join(f"{r} {len(rep.found.get(r, []))}" for r in ("O1", "O2", "O3", "O4", "O5", "O6")))
    print("check_outline: OK" if bad == 0 else f"check_outline: {bad} findings")
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
