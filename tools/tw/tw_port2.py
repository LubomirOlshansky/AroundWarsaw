"""Port the matched Tiny Warsaw models of one street into our frame (trial; not for main until F confirms rights).

Usage: python3 -I tw_port2.py SCRATCH [--only=id,id] [--skip=id,id]

Reads SCRATCH/tw/meta.json (matches, snap moves) and SCRATCH/tw/run/ID.json (tw_run.mjs). For each model:
frame + snap onto our outline, drop faces nobody can see (undersides, faces turned inward) and hairline
bars, sort triangles into wall / glass / roof / trim, write game/data/tw_port/ID.json, and the
index game/data/tw_port/index.json (id, outline). Logs triangles before and after per block.
"""
import cmath
import json
import math
import os
import sys

ROT = cmath.exp(1j * math.radians(1.4651))
MOVE = complex(-1228.52, 240.62)
THIN = 0.12
OVERRIDES = {}
EXTRA = {}


def tf(x, z):
    c = ROT * complex(x, z) + MOVE
    return c.real, c.imag


def calm(h):
    """A roof a little darker and less saturated: their reds read as toy bricks under our sun."""
    c = [int(h[i:i + 2], 16) for i in (1, 3, 5)]
    m = sum(c) / 3
    return "#" + "".join(f"{int(max(0, min(255, (v + (m - v) * 0.22) * 0.9))):02x}" for v in c)


def nearest_out(p, ring, sign):
    """Outward normal of the outline edge nearest p."""
    best = None
    for i in range(len(ring)):
        ax, az = ring[i - 1]
        bx, bz = ring[i]
        ex, ez = bx - ax, bz - az
        l2 = ex * ex + ez * ez
        if l2 < 1e-6:
            continue
        t = max(0.0, min(1.0, ((p[0] - ax) * ex + (p[1] - az) * ez) / l2))
        d = math.hypot(ax + ex * t - p[0], az + ez * t - p[1])
        if best is None or d < best[0]:
            l = math.sqrt(l2)
            best = (d, ez / l * sign, -ex / l * sign)
    return best


def signed_area(r):
    return sum(r[i - 1][0] * r[i][1] - r[i][0] * r[i - 1][1] for i in range(len(r))) / 2


def components(tris):
    """Groups of triangles sharing vertices (one box each, in their soup)."""
    parent = list(range(len(tris)))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    seen = {}
    for i, t in enumerate(tris):
        for v in t:
            k = (round(v[0], 2), round(v[1], 2), round(v[2], 2))
            if k in seen:
                parent[find(i)] = find(seen[k])
            else:
                seen[k] = i
    out = {}
    for i in range(len(tris)):
        out.setdefault(find(i), []).append(i)
    return list(out.values())


def extent_sorted(tris, idxs):
    """A piece's three box sizes, along its own wall direction when it has one."""
    pts = [v for i in idxs for v in tris[i]]
    ys = [p[1] for p in pts]
    # the plan size: smallest of the projections on the piece's long axis and its normal
    best = None
    cx = sum(p[0] for p in pts) / len(pts)
    cz = sum(p[2] for p in pts) / len(pts)
    far = max(pts, key=lambda p: (p[0] - cx) ** 2 + (p[2] - cz) ** 2)
    ang = math.atan2(far[2] - cz, far[0] - cx)
    for k in range(0, 12):
        a = ang + k * math.pi / 12
        ca, sa = math.cos(a), math.sin(a)
        u = [p[0] * ca + p[2] * sa for p in pts]
        v = [-p[0] * sa + p[2] * ca for p in pts]
        du, dv = max(u) - min(u), max(v) - min(v)
        if best is None or du * dv < best[0] * best[1]:
            best = (du, dv)
    return sorted([best[0], best[1], max(ys) - min(ys)])


def port(r, S, ours):
    run = json.load(open(f"{S}/tw/run/{r['id']}.json"))
    dx, dz = r["dx"], r["dz"]
    sign = 1.0 if signed_area(ours) > 0 else -1.0
    tot = kept = 0
    # the group holding the highest upward faces is the roof
    groups = []
    for g in run["groups"]:
        v = g["v"]
        tris = []
        for i in range(0, len(v) - 8, 9):
            t = []
            for k in (0, 3, 6):
                x, z = tf(v[i + k], v[i + k + 2])
                t.append((x + dx, v[i + k + 1], z + dz))
            tris.append(t)
        tot += len(tris)
        comps = components(tris)
        drop = set()
        for c in comps:
            if len(c) <= 12:
                e = extent_sorted(tris, c)
                if e[0] < THIN and e[1] < THIN + 0.08:  # a bar: a mullion, a rail post
                    drop.update(c)
        out = []
        up_area = area = 0.0
        for i, t in enumerate(tris):
            if i in drop:
                continue
            ax, ay, az = t[1][0] - t[0][0], t[1][1] - t[0][1], t[1][2] - t[0][2]
            bx, by, bz = t[2][0] - t[0][0], t[2][1] - t[0][1], t[2][2] - t[0][2]
            nx, ny, nz = ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
            l = math.sqrt(nx * nx + ny * ny + nz * nz)
            if l < 1e-6:
                continue
            nx, ny, nz = nx / l, ny / l, nz / l
            # their transform keeps winding, and our frame's rotation does too; x/z are unmirrored
            if ny < -0.5:
                continue
            area += l
            if ny > 0.3:
                up_area += l
            if abs(ny) < 0.3:
                cx = (t[0][0] + t[1][0] + t[2][0]) / 3
                cz = (t[0][2] + t[1][2] + t[2][2]) / 3
                n = nearest_out((cx, cz), ours, sign)
                if n and n[0] < 2.5 and nx * n[1] + nz * n[2] < -0.7:
                    continue
            out.append(t)
        if not out:
            continue
        ymax = max(p[1] for t in out for p in t)
        groups.append({"role": g["role"], "color": g["color"], "tris": out, "up": up_area / max(area, 1e-6), "ymax": ymax, "wall_area": area - up_area})
    top = max(g["ymax"] for g in groups)
    res = []
    wall = OVERRIDES.get(str(r["id"]))
    if wall:  # the photo check's wall colour: the solid group with the most upright surface
        best = max((g for g in groups if g["role"] != "glass" and g["up"] < 0.5), key=lambda g: g["wall_area"])
        best["color"] = wall
    for g in groups:
        kind = g["role"]
        if kind != "glass":
            kind = "roof" if g["up"] > 0.8 and g["ymax"] > top * 0.7 else "solid"
        if kind == "roof":
            g["color"] = calm(g["color"])
        flat = [round(c, 3) for t in g["tris"] for p in t for c in p]
        kept += len(g["tris"])
        item = {"role": kind, "color": g["color"], "v": flat}
        if kind == "glass":
            # one number per triangle, shared by a pane's triangles: its lit-or-dark state
            pane = [0.0] * len(g["tris"])
            for c in components(g["tris"]):
                p0 = g["tris"][c[0]][0]
                h = (math.sin(p0[0] * 12.9898 + p0[1] * 78.233 + p0[2] * 37.719) * 43758.5453) % 1.0
                for i in c:
                    pane[i] = round(0.02 + h * 0.96, 3)
            item["pane"] = pane
        res.append(item)
    return res, tot, kept, top


def main(argv):
    S = argv[0]
    only = next((a.split("=")[1].split(",") for a in argv if a.startswith("--only=")), None)
    skip = next((a.split("=")[1].split(",") for a in argv if a.startswith("--skip=")), [])
    data = json.load(open(f"{S}/twport/game/map/centrum.json"))
    meta = json.load(open(f"{S}/tw/meta.json"))
    OVERRIDES.update(json.load(open(f"{S}/tw/overrides.json")))
    EXTRA.update(json.load(open(f"{S}/tw/extra.json")))
    outdir = f"{S}/twport/game/data/tw_port"
    os.makedirs(outdir, exist_ok=True)
    index = []
    sum_t = sum_k = 0
    for r in meta:
        mid = str(r["id"])
        if r["skip_pre"] or mid in skip or (only and mid not in only):
            continue
        b = data["buildings"][r["bi"]]
        ours = list(zip(b["p"][0::2], b["p"][1::2]))
        groups, tot, kept, top = port(r, S, ours)
        sum_t += tot
        sum_k += kept
        print(f"tw_port: {mid} {r['no']:8} {tot:6} -> {kept:6} tris, top {top:.1f} m")
        json.dump({"id": mid, "groups": groups}, open(f"{outdir}/{mid}.json", "w"), separators=(",", ":"))
        index.append({"id": mid, "outline": [c for q in ours for c in (round(q[0], 2), round(q[1], 2))], "extra": EXTRA.get(mid, [])})
    json.dump(index, open(f"{outdir}/index.json", "w"), separators=(",", ":"))
    print(f"tw_port: {len(index)} blocks, {sum_t} -> {sum_k} triangles")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
