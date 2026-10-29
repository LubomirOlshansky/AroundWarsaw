"""Loop 3d-1: place the speed traps of docs/design/police.md section 2 that the map now holds.

    python3 -I tools/bake_traps.py [--write]     (prints the spots; --write puts them in the file)

Reads game/map/centrum.json (the lane graph) and game/data/police_traps.json, and for every trap
row with no spot yet (no `officer`) looks for its road by name in the lane graph, in the area and
direction AREAS gives it: a run of that road's edges, joined through nodes that are no junction,
at least RUN long and as straight as STRAIGHT; the officer stands in its middle (so the nearest
junction is at least RUN / 2 away). The spot is placed by the rules the first four used
(police.md section 2, the file's `_about`): the patrol car 1.5 m past the outer lane's edge
facing the traffic, the officer 3 m upstream at the kerb (0.7 m past the lane's edge), the start
150 m before the officer heading into the radar. Rows that already have a spot are left alone,
and checked: their road must still be within 14 m of the officer, as police.gd's test.
police.md 13 asks for these as `pois` kind `trap` in the bake; until police.gd reads that, the
spots stay in the file police.gd reads (the file's other fields are unchanged).
"""
import json
import math
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TRAPS = os.path.join(ROOT, "game", "data", "police_traps.json")
MAP = os.path.join(ROOT, "game", "map", "centrum.json")

# id: (OSM names that count as the road, x0, z0, x1, z1 of where to look, the measured direction
# as a unit vector on the map (x east, z south)). From police.md section 2's table.
AREAS = {
    5: (("Aleja „Solidarności”", "aleja „Solidarności”", "Aleja Solidarności"), -1560.0, -1700.0, -700.0, -1050.0, (1.0, 0.0)),
    6: (("Trasa Łazienkowska", "Aleja Armii Ludowej", "aleja Armii Ludowej"), 0.0, 1100.0, 1450.0, 1736.0, (1.0, 0.0)),
    7: (("Aleje Ujazdowskie",), -600.0, 600.0, 200.0, 1736.0, (0.0, -1.0)),
}
RUN = 150.0   # police.md asks 250 m with no junction within 80 m; Warsaw's blocks give 150-195 m runs (the officer in the middle: the junctions 75-98 m away)
STRAIGHT = 0.985   # the run's chord over its length


def pairs(flat):
    return list(zip(flat[0::2], flat[1::2]))


def cum(pts):
    c = [0.0]
    for a, b in zip(pts, pts[1:]):
        c.append(c[-1] + math.dist(a, b))
    return c


def at(pts, cm, s):
    for k in range(len(pts) - 1):
        if cm[k + 1] >= s:
            t = (s - cm[k]) / max(cm[k + 1] - cm[k], 1e-9)
            a, b = pts[k], pts[k + 1]
            d = ((b[0] - a[0]) / max(cm[k + 1] - cm[k], 1e-9), (b[1] - a[1]) / max(cm[k + 1] - cm[k], 1e-9))
            return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t), d
    a, b = pts[-2], pts[-1]
    ln = max(math.dist(a, b), 1e-9)
    return b, ((b[0] - a[0]) / ln, (b[1] - a[1]) / ln)


def compass(d):
    return round(math.degrees(math.atan2(d[0], -d[1])) % 360.0, 1)


def runs(edges, names, area, want):
    """Chains of edges of the road, through nodes that are no junction, in the area."""
    deg = {}
    for e in edges:
        for n in (e["a"], e["b"]):
            deg.setdefault(n, set())
        deg[e["a"]].add(e["b"])
        deg[e["b"]].add(e["a"])
    mine = [i for i, e in enumerate(edges) if e.get("name") in names]
    nxt = {}
    for i in mine:
        nxt.setdefault(edges[i]["a"], []).append(i)
    out = []
    for i in mine:
        e = edges[i]
        prev = [j for j in mine if edges[j]["b"] == e["a"]]
        if len(deg[e["a"]]) == 2 and len(prev) == 1:
            continue   # not a chain's first edge
        chain, n = [i], e["b"]
        while len(deg[n]) == 2 and len(nxt.get(n, [])) == 1 and nxt[n][0] not in chain:
            chain.append(nxt[n][0])
            n = edges[nxt[n][0]]["b"]
        pts = []
        for j in chain:
            q = pairs(edges[j]["p"])
            pts += q if not pts else q[1:]
        cm = cum(pts)
        mid, d = at(pts, cm, cm[-1] / 2)
        if not (area[0] <= mid[0] <= area[2] and area[1] <= mid[1] <= area[3]):
            continue
        chord = math.dist(pts[0], pts[-1])
        heading = ((pts[-1][0] - pts[0][0]) / max(chord, 1e-9), (pts[-1][1] - pts[0][1]) / max(chord, 1e-9))
        if heading[0] * want[0] + heading[1] * want[1] < 0.5:
            continue
        out.append((cm[-1], chord / max(cm[-1], 1e-9), chain, pts, cm))
    return sorted(out, key=lambda r: -r[0])


def place(row, edges, names, area, want):
    found = runs(edges, names, area, want)
    good = [r for r in found if r[0] >= RUN and r[1] >= STRAIGHT]
    if not good:
        return None, "no straight run of %d m (longest: %s)" % (RUN, ", ".join("%.0f m x%.3f" % r[:2] for r in found[:3]) or "none")
    length, straight, chain, pts, cm = good[0]
    e = edges[chain[len(chain) // 2]] if len(chain) > 1 else edges[chain[0]]
    edge_index = chain[len(chain) // 2] if len(chain) > 1 else chain[0]
    lane_edge = e["o"] + e["lw"] * (e["n"] - 1) + e["lw"] / 2
    s_off = cm[-1] / 2
    o_pt, d = at(pts, cm, s_off)
    right = (-d[1], d[0])
    officer = (o_pt[0] + right[0] * (lane_edge + 0.7), o_pt[1] + right[1] * (lane_edge + 0.7))
    c_pt, _ = at(pts, cm, s_off + 3.0)
    car = (c_pt[0] + right[0] * (lane_edge + 1.5), c_pt[1] + right[1] * (lane_edge + 1.5))
    s_pt, sd = at(pts, cm, max(s_off - 150.0, 0.0))
    start = (s_pt[0], s_pt[1])
    spot = {"car": [round(car[0], 1), round(car[1], 1)], "car_heading": compass((-d[0], -d[1])),
            "direction": [round(d[0], 4), round(d[1], 4)], "officer": [round(officer[0], 1), round(officer[1], 1)],
            "start": [round(start[0], 1), round(start[1], 1)], "start_heading": compass(sd), "graph_edge": edge_index,
            "limit_kmh": round(e["v"] * 3.6) if e.get("v") else row.get("limit_kmh")}
    return spot, "%s: run %.0f m (straight %.3f), edge %d, limit %s km/h" % (e["name"], length, straight, edge_index, spot["limit_kmh"])


def near(edges, name, p, reach=14.0):
    best = None
    for e in edges:
        if e.get("name") != name:
            continue
        pts = pairs(e["p"])
        for a, b in zip(pts, pts[1:]):
            dx, dz = b[0] - a[0], b[1] - a[1]
            l2 = dx * dx + dz * dz
            t = max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dz) / l2)) if l2 else 0.0
            d = math.hypot(a[0] + dx * t - p[0], a[1] + dz * t - p[1])
            best = d if best is None else min(best, d)
    return best is not None and best <= reach


def main(argv):
    write = "--write" in argv
    edges = json.load(open(MAP, encoding="utf-8"))["graph"]["edges"]
    data = json.load(open(TRAPS, encoding="utf-8"))
    changed = 0
    for row in data["traps"]:
        if "officer" in row:
            ok = near(edges, row["road"], row["officer"])
            print("trap %d %s: %s" % (row["id"], row["road"], "still on its road" if ok else "ROAD NOT FOUND at the officer"))
            continue
        if row["id"] not in AREAS:
            print("trap %d %s: no area to look in" % (row["id"], row["road"]))
            continue
        names, x0, z0, x1, z1, want = AREAS[row["id"]]
        spot, why = place(row, edges, set(names), (x0, z0, x1, z1), want)
        print("trap %d %s: %s" % (row["id"], row["road"], why))
        if spot:
            spot["road"] = edges[spot["graph_edge"]]["name"]
            row.update(spot)
            changed += 1
    if write and changed:
        data["_about"] = data["_about"].replace(
            "Spots 5-7 lie in the demo area (loop 3d): no spot yet, so the game skips them.",
            "Spots 5-7 lie in the demo area: placed by tools/bake_traps.py (loop 3d-1) on the demo map's graph by the same rules.")
        # One row a line, as the file was written by hand.
        rows = ",\n".join("    " + json.dumps(r, ensure_ascii=False) for r in data["traps"])
        text = '{\n  "_about": %s,\n  "traps": [\n%s\n  ]\n}\n' % (json.dumps(data["_about"], ensure_ascii=False), rows)
        with open(TRAPS, "w", encoding="utf-8") as fh:
            fh.write(text)
        print("bake_traps: %d spots written to game/data/police_traps.json" % changed)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
