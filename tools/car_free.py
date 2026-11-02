"""Streets the city has closed to cars since the OpenStreetMap data the bake reads was drawn.

    python3 -I tools/car_free.py [MAP.json] [--dry]       (rewrites the map in place, idempotent)

Skwer Linearny na Złotej (F, 2026-11-02): Złota between Marszałkowska and Jasna became a linear
park, opened on 3 August 2026 (Nowe Centrum Warszawy, RS Architektura Krajobrazu): lawns with
free-standing stone blocks, a mineral walk, rows of young limes (81 on Złota, planted 9 m tall),
a fountain where the 1970 tunnel ramp under Marszałkowska was and a rock fountain mid-street.
Through traffic and parking are gone; only residents' cars and deliveries pass the bollards.
OpenStreetMap already draws the new lawns, tree pits, fountains and walks, but still the old
one-way car loop round the parking median, and the 2018 laser scan has none of the new trees.

For every zone of CAR_FREE this module, on the finished map data (bake_osm.py calls `apply(out)`
after snap_props; this file is also a command line tool for a map that is already baked, as the
cloud has no OpenStreetMap download):

- drops the zone's drivable ways (`roads` named as the zone says, and the unnamed service stubs
  that only led off them) whose every point lies inside the zone's road box;
- marks the lane graph's edges along them `cf: 1` (lane_graph.gd leaves them out of the
  adjacency and the spawn grid: no traffic, no routes; the indices stay, so the portals and
  stops that point at edges are untouched), and takes their inner nodes out of `scc`;
- drops the road `markings`, the road-bed `fills` and the bed's retaining `walls`
  (bake_structures.py) lying wholly in the zone: without the road they stood in the lawn;
- adds the zone as a `ped_zones` polygon (ped_zones.gd: the player's car at 20 km/h, the guards);
- plants the new trees: a lime (TREE) in every mapped tree pit (an OpenStreetMap `park` area
  under PIT_MAX m² inside the zone), in `trees3d` with its crown scale in `trees3d_crown`.

Deterministic, standard library only. Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import json
import math
import os
import sys

# Marszałkowska's frame at the start (first_scene.gd FRAME_O/S/T): s metres north along the
# street, t metres east of it. Złota leaves Marszałkowska's east kerb (t 21.6) at s 53 and meets
# Jasna at t 192; the facades stand at about s 40 (Sawa, Wojskowe Biuro) and s 67 (Relax, Złota 7/9).
FRAME_O = (-937.0, 210.1)
FRAME_S = (-0.34917, -0.93706)
FRAME_T = (0.93706, -0.34917)

# (id, ped zone box (s0, s1, t0, t1), road box (the same, reaching the junction node), road names,
# what it is). The ped zone stops short of Marszałkowska's pavement and of Jasna's carriageway.
CAR_FREE = [
    ("zlota", (36.5, 72.0, 23.0, 189.0), (34.0, 70.0, 20.0, 198.0), {"Złota"},
     "Skwer Linearny na Złotej: Złota between Marszałkowska and Jasna, a park since 3 August 2026"),
]
PIT_MAX = 40.0          # a mapped `park` area smaller than this (m²) is a tree pit
# The new limes: planted 9 m tall (crown base 2.6 m, radius 2.0 m), broadleaf.
TREE = (9.0, 2.0, 2.6, 0)
TREE_NEAR = 1.5          # a tree already this close to a pit's centre stands for it
# More limes on the lawns' edges (s, t in the frame), where the opening's aerial photos show them
# standing in the grass, clear of the walks, the pool and skwer_zlota.gd's stone blocks.
EXTRA_TREES = {
    "zlota": [(56.5, 89.0), (55.5, 104.0), (57.0, 117.5), (47.5, 117.0), (57.5, 142.5), (55.5, 152.0),
              (54.0, 168.5), (50.0, 175.0), (52.0, 183.0)],
}
SERVICE_KINDS = {"service"}


def st_of(x, z):
    dx, dz = x - FRAME_O[0], z - FRAME_O[1]
    return dx * FRAME_S[0] + dz * FRAME_S[1], dx * FRAME_T[0] + dz * FRAME_T[1]


def xz_of(s, t):
    return (round(FRAME_O[0] + FRAME_S[0] * s + FRAME_T[0] * t, 2),
            round(FRAME_O[1] + FRAME_S[1] * s + FRAME_T[1] * t, 2))


def in_box(x, z, box):
    s, t = st_of(x, z)
    return box[0] <= s <= box[1] and box[2] <= t <= box[3]


def all_in(flat, box):
    return len(flat) >= 2 and all(in_box(flat[i], flat[i + 1], box) for i in range(0, len(flat) - 1, 2))


def ring_of(box):
    s0, s1, t0, t1 = box
    return [v for p in (xz_of(s0, t0), xz_of(s0, t1), xz_of(s1, t1), xz_of(s1, t0)) for v in p]


def area_of(flat):
    pts = list(zip(flat[0::2], flat[1::2]))
    return abs(sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(pts, pts[1:] + pts[:1]))) / 2.0


def apply(out):
    """Applies every CAR_FREE zone to the map data `out` in place; returns a summary line."""
    said = []
    for zid, zone, rbox, names, _ in CAR_FREE:
        before = len(out["roads"])
        out["roads"] = [r for r in out["roads"] if not (
            all_in(r["p"], rbox) and (r.get("name", "") in names or (r.get("name", "") == "" and r["k"] in SERVICE_KINDS)))]
        dropped = before - len(out["roads"])
        graph = out.get("graph", {})
        marked, nodes = 0, set()
        for e in graph.get("edges", []):
            if e.get("name", "") in names and all_in(e["p"], rbox):
                if not e.get("cf"):
                    marked += 1
                e["cf"] = 1
                nodes.update((e["a"], e["b"]))
        # A node keeps its scc flag while a drivable edge still touches it (the junction nodes).
        for e in graph.get("edges", []):
            if not e.get("cf"):
                nodes.discard(e["a"])
                nodes.discard(e["b"])
        for n in nodes:
            graph["scc"][n] = 0
        before_m = len(out.get("markings", []))
        out["markings"] = [m for m in out.get("markings", []) if not all_in(m["p"], rbox)]
        before_w = len(out.get("walls", [])) + len(out.get("fills", []))
        out["walls"] = [w for w in out.get("walls", []) if not all_in(w["p"], rbox)]
        out["fills"] = [f for f in out.get("fills", []) if not (f.get("k") == "road" and all_in(f["p"], rbox))]
        walls_out = before_w - len(out["walls"]) - len(out["fills"])
        if not any(z.get("z") == zid for z in out.get("ped_zones", [])):
            out.setdefault("ped_zones", []).append({"z": zid, "p": ring_of(zone)})
        trees = out.get("trees3d", [])
        crowns = out.get("trees3d_crown", [])
        planted = 0
        spots = []
        for a in out.get("areas", []):
            if a["k"] != "park" or not all_in(a["p"], zone) or area_of(a["p"]) >= PIT_MAX:
                continue
            pts = list(zip(a["p"][0::2], a["p"][1::2]))
            spots.append((round(sum(p[0] for p in pts) / len(pts), 1), round(sum(p[1] for p in pts) / len(pts), 1)))
        spots += [tuple(round(v, 1) for v in xz_of(s, t)) for s, t in EXTRA_TREES.get(zid, [])]
        for cx, cz in spots:
            if any(math.hypot(trees[k] - cx, trees[k + 1] - cz) < TREE_NEAR for k in range(0, len(trees) - 5, 6)):
                continue
            trees.extend([cx, cz, *TREE])
            crowns.append(100)
            planted += 1
        said.append(f"{zid}: {dropped} roads out, {marked} graph edges car-free, {len(nodes)} nodes off scc, "
                    f"{before_m - len(out['markings'])} markings, {walls_out} road-bed walls and fills out, "
                    f"{planted} trees planted")
    return "; ".join(said)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    path = args[0] if args else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "map", "centrum.json")
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    print("car_free: " + apply(data))
    if "--dry" not in sys.argv[1:]:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"))


if __name__ == "__main__":
    main()
