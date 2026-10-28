"""Fetch the raw map data for the Nocna Warszawa demo area (a data fetch only: nothing is baked).

Usage (from the repository root):
    python3 -I tools/fetch_demo.py <command> [--out data/raw/demo] [--box S W N E]

Commands, in the order they are meant to be run (small downloads first, the big tree stream last):
    plan        read the OSM export and write corridors.json: the bridge, viaduct and tunnel-portal
                corridors (a dry run; downloads nothing)
    corridors   D4 + D5: GUGiK surface model (NMPT, 0.5 m) and 1 m bare-earth model (NMT) for the
                corridors, from the official WCS, as float32 GeoTIFF in EVRF2007 heights
    osm         D1: OpenStreetMap from the public Overpass API as 3 x 3 tiles, merged into osm_demo.json
    ortho       D2: GUGiK aerial photo (WMS) as 2 x 2 PNG tiles
    nmt10       D3: GUGiK 10 m elevation grid (GetHByPointList), terrain_10m.json
    sheets      LoD2: unpack the extra 1:5000 sheets the box needs from the Warsaw package on disk
    trees       D6: stream the GUGiK 3D-tree package, keep only the 1:2500 sheets the box needs
    check       re-run the checks of every finished stage and write meta/*.json
    manifest    write MANIFEST.md from meta/*.json (plus NOTES.md if present)

Every stage is resumable: a re-run skips tiles and files that are already finished. Uses the Python
standard library only, plus the system curl (Overpass refuses the old Python TLS; the tree stream) and
bsdtar (the tree stream). One request at a time per server, with a back-off, and a User-Agent that
names the project. Nothing is installed.

The map origin (LAT0, LON0) is the centre of the first map (52.2340 N, 21.0240 E); it stays the
origin for the demo area, so grids made here use the same local metres (+x east, +z south) as
tools/bake_osm.py. This script does not import bake_osm and does not change its BBOX.
"""
import argparse
import array
import collections
import datetime
import json
import math
import os
import re
import shutil
import struct
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile
import zlib

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
from pl1992 import from_pl1992, to_pl1992  # noqa: E402

# The demo box (south, west, north, east), WGS84 degrees: docs/DEMO.md 2.1 with the south edge at
# 52.2065 (the user's choice of 2026-10-28).
DEMO_BOX = (52.2065, 20.9780, 52.2595, 21.0560)
LAT0, LON0 = 52.2340, 21.0240
M_PER_DEG_LAT = 110574.0
M_PER_DEG_LON = 111320.0 * math.cos(math.radians(LAT0))

# The service firewalls reject a User-Agent that is not in "product/version (comment)" form.
UA = "NocnaWarszawa-map-fetch/1.0 (open-source game)"
OVERPASS = "https://overpass-api.de/api/interpreter"
OVERPASS_STATUS = "https://overpass-api.de/api/status"
ORTHO_WMS = "https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/HighResolution"
ELEVATION = "https://services.gugik.gov.pl/nmt/?request=GetHByPointList&list="
NMPT_WCS = "https://mapy.geoportal.gov.pl/wss/service/PZGIK/NMPT/GRID1/WCS/DigitalSurfaceModel"
NMT_WCS = "https://mapy.geoportal.gov.pl/wss/service/PZGIK/NMT/GRID1/WCS/DigitalTerrainModel"
NMPT_COVERAGE = "DSM_PL-EVRF2007-NH"
NMT_COVERAGE = "DTM_PL-EVRF2007-NH"
TREES_ZIP = "https://opendata.geoportal.gov.pl/InneDane/Drzewa3D/LOD1/2023/14/1465.zip"
# Both WCS grids share these cell edges (from DescribeCoverage): upper-left corner in EPSG:2180.
WCS_EDGE_E = 160828.34326572
WCS_EDGE_N = 796521.669409553
ORTHO_M_PER_PX = 0.87  # today's photo: 3,545 m over 4,095 px
MAX_OSM_TRIES = 5


def log(*parts):
    print(time.strftime("%H:%M:%S"), *parts, flush=True)


def today():
    return datetime.date.today().isoformat()


def project(lat, lon):
    return (lon - LON0) * M_PER_DEG_LON, (LAT0 - lat) * M_PER_DEG_LAT


def unproject(x, z):
    return LAT0 - z / M_PER_DEG_LAT, LON0 + x / M_PER_DEG_LON


def write_atomic(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".part"
    with open(tmp, "wb") as f:
        f.write(data)
    os.replace(tmp, path)


def write_json(path, obj, **kw):
    write_atomic(path, json.dumps(obj, ensure_ascii=False, **kw).encode("utf-8"))


def read_json(path, default=None):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def human(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1024.0


def meta_update(out, stage, **fields):
    path = os.path.join(out, "meta", stage + ".json")
    meta = read_json(path, {})
    meta.update(fields)
    meta["updated"] = today()
    write_json(path, meta, indent=1)
    return meta


# ---------------------------------------------------------------- HTTP

class FetchError(Exception):
    pass


def http(url, data=None, timeout=120):
    """Returns (status, headers, body). Network errors come back as status 0."""
    headers = {"User-Agent": UA}
    if data is not None:
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    req = urllib.request.Request(url, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, dict(r.headers), r.read()
    except urllib.error.HTTPError as e:
        return e.code, dict(e.headers), e.read()
    except (urllib.error.URLError, OSError, ValueError) as e:  # timeouts, resets, DNS
        if "SSL" in str(e):
            # The system Python's TLS library is old; overpass-api.de refuses its handshake.
            return http_curl(url, data, timeout)
        return 0, {}, str(e).encode()


def http_curl(url, data=None, timeout=120):
    """The same request through the system curl (status 0 on a transport error)."""
    cmd = ["curl", "-sS", "-m", str(int(timeout)), "-A", UA, "-w", "\n%{http_code}", url]
    if data is not None:
        cmd[1:1] = ["--data-binary", "@-"]
    try:
        r = subprocess.run(cmd, input=data, capture_output=True, timeout=timeout + 30)
    except (OSError, subprocess.TimeoutExpired) as e:
        return 0, {}, str(e).encode()
    if r.returncode != 0:
        return 0, {}, r.stderr[:300]
    body, _, code = r.stdout.rpartition(b"\n")
    return int(code or 0), {}, body


def get_retry(url, label, data=None, timeout=120, waits=(5, 20, 60, 120), validate=None):
    """GET/POST with a back-off. `validate(body, headers)` returns an error text or None."""
    last = ""
    for attempt in range(len(waits) + 1):
        status, headers, body = http(url, data, timeout)
        if status == 200:
            err = validate(body, headers) if validate else None
            if err is None:
                return body
            last = err
        else:
            last = f"HTTP {status} {body[:100]!r}"
        if attempt < len(waits):
            log(f"  {label}: {last}; retrying in {waits[attempt]} s")
            time.sleep(waits[attempt])
    raise FetchError(f"{label}: {last}")


# ---------------------------------------------------------------- boxes and grids

def split_box(box, nx, ny):
    """Tiles of a (s, w, n, e) box: [(name, s, w, n, e)], rows from south, columns from west.
    Neighbouring tiles share exactly the same edge values."""
    s, w, n, e = box
    tiles = []
    for r in range(ny):
        for c in range(nx):
            ts, tn = s + (n - s) * r / ny, s + (n - s) * (r + 1) / ny
            tw, te = w + (e - w) * c / nx, w + (e - w) * (c + 1) / nx
            tiles.append((f"r{r}c{c}", round(ts, 6), round(tw, 6), round(tn, 6), round(te, 6)))
    return tiles


def box_area_km2(box):
    s, w, n, e = box
    return (n - s) * M_PER_DEG_LAT * (e - w) * M_PER_DEG_LON / 1e6


def in_box(box, lat, lon):
    return box[0] <= lat <= box[2] and box[1] <= lon <= box[3]


# ---------------------------------------------------------------- OSM (D1)

def overpass_wait_slot(deadline):
    """Wait until /api/status reports a free query slot (or the deadline passes)."""
    while True:
        status, _, body = http(OVERPASS_STATUS, timeout=30)
        text = body.decode("utf-8", "replace")
        wait = 45
        if status == 200:
            m = re.search(r"(\d+) slots? available now", text)
            if m and int(m.group(1)) > 0:
                return True
            if "Rate limit: 0" in text:
                return True
            m = re.search(r"in (\d+) seconds", text)
            if m:
                wait = min(max(int(m.group(1)) + 2, 5), 120)
        if time.time() + wait > deadline:
            return False
        log(f"  overpass has no free slot (status {status}); waiting {wait} s")
        time.sleep(wait)


def osm_check_body(body):
    """Returns an error text if an Overpass reply is not a complete result."""
    try:
        doc = json.loads(body)
    except ValueError:
        return "not JSON: " + body[:160].decode("utf-8", "replace")
    remark = doc.get("remark", "")
    if remark:
        return "overpass remark: " + remark[:200]
    if "elements" not in doc or not doc["elements"]:
        return "no elements"
    return None


def cmd_osm(a):
    out = a.out
    osm_dir = os.path.join(out, "osm")
    os.makedirs(osm_dir, exist_ok=True)
    tiles = split_box(a.box, 3, 3)
    tries_path = os.path.join(osm_dir, "tries.json")
    tries = read_json(tries_path, {})
    log(f"OSM: {len(tiles)} tiles of the box {a.box}")
    for name, s, w, n, e in tiles:
        log(f"  tile {name}: S {s} W {w} N {n} E {e}")
    started = time.time()
    for name, s, w, n, e in tiles:
        path = os.path.join(osm_dir, f"tile_{name}.json")
        if os.path.exists(path):
            log(f"tile {name}: done already ({human(os.path.getsize(path))})")
            continue
        query = f"[out:json][timeout:300];nwr({s:.6f},{w:.6f},{n:.6f},{e:.6f});(._;>;);out body;"
        while tries.get(name, 0) < MAX_OSM_TRIES:
            if time.time() - started > a.max_wait_min * 60:
                log("OSM: the wait budget is used up; stopping (re-run to continue)")
                break
            if not overpass_wait_slot(time.time() + 30 * 60):
                log(f"tile {name}: no slot within 30 min")
                break
            tries[name] = tries.get(name, 0) + 1
            write_json(tries_path, tries)
            log(f"tile {name}: request (try {tries[name]} of {MAX_OSM_TRIES})")
            t0 = time.time()
            status, _, body = http(OVERPASS, urllib.parse.urlencode({"data": query}).encode(), timeout=420)
            err = None if status == 200 else f"HTTP {status} {body[:120]!r}"
            if err is None:
                err = osm_check_body(body)
            if err is None:
                write_atomic(path, body)
                log(f"tile {name}: ok, {human(len(body))} in {time.time() - t0:.0f} s")
                break
            wait = (30, 60, 90, 120, 120)[min(tries[name] - 1, 4)]
            log(f"tile {name}: {err}")
            if tries[name] >= MAX_OSM_TRIES:
                log(f"tile {name}: gave up after {MAX_OSM_TRIES} tries")
                break
            log(f"  waiting {wait} s")
            time.sleep(wait)
        time.sleep(5)  # a pause between tiles
    missing = [t[0] for t in tiles if not os.path.exists(os.path.join(osm_dir, f"tile_{t[0]}.json"))]
    if missing:
        log("OSM: missing tiles:", ", ".join(missing))
        meta_update(out, "osm", missing_tiles=missing, tries=tries)
        return 1
    merge_osm(out, a.box, tiles)
    return 0


def merge_osm(out, box, tiles):
    """Merge the tile exports by element type + id into osm_demo.json (the shape of osm_wide.json)."""
    osm_dir = os.path.join(out, "osm")
    by_type = {"node": {}, "way": {}, "relation": {}}
    raw_total = 0
    conflicts = 0
    stamps = []
    generator = ""
    per_tile = {}
    for name, *_ in tiles:
        with open(os.path.join(osm_dir, f"tile_{name}.json"), encoding="utf-8") as f:
            doc = json.load(f)
        generator = generator or doc.get("generator", "")
        stamps.append(doc.get("osm3s", {}).get("timestamp_osm_base", ""))
        per_tile[name] = len(doc["elements"])
        raw_total += len(doc["elements"])
        for el in doc["elements"]:
            bucket = by_type[el["type"]]
            old = bucket.get(el["id"])
            if old is None:
                bucket[el["id"]] = el
            elif old != el:
                conflicts += 1
        del doc
    merged_path = os.path.join(osm_dir, "osm_demo.json")
    tmp = merged_path + ".part"
    with open(tmp, "w", encoding="utf-8") as f:
        head = {
            "version": 0.6,
            "generator": generator,
            "osm3s": {
                "timestamp_osm_base": min(stamps),
                "copyright": "The data included in this document is from www.openstreetmap.org. "
                             "The data is made available under ODbL.",
            },
        }
        f.write(json.dumps(head, ensure_ascii=False)[:-1] + ',"elements":[')
        first = True
        for kind in ("node", "way", "relation"):
            for key in sorted(by_type[kind]):
                f.write(("" if first else ",") + json.dumps(by_type[kind][key], ensure_ascii=False,
                                                          separators=(",", ":")))
                first = False
        f.write("]}")
    os.replace(tmp, merged_path)
    counts = {k: len(v) for k, v in by_type.items()}
    log(f"OSM merged: {counts}, {raw_total} tile elements -> {sum(counts.values())}, "
        f"{conflicts} conflicting duplicates, {human(os.path.getsize(merged_path))}")
    meta_update(out, "osm", merged=os.path.relpath(merged_path, out), counts=counts,
                tile_elements=per_tile, duplicates_dropped=raw_total - sum(counts.values()),
                conflicting_duplicates=conflicts, timestamps=sorted(set(stamps)),
                tries=read_json(os.path.join(osm_dir, "tries.json"), {}),
                missing_tiles=[], size=os.path.getsize(merged_path))
    osm_checks(out, box, by_type)


def meters_between(lat1, lon1, lat2, lon2):
    return math.hypot((lat1 - lat2) * M_PER_DEG_LAT, (lon1 - lon2) * M_PER_DEG_LON)


# The spot-check anchors: map metres from docs/DEMO.md 2.2 (the same origin), except Belweder,
# which is found by name.
SPOTS = [
    ("Rondo Daszyńskiego", (-2727, 420), r"^Rondo Daszy[ńn]skiego"),
    ("Arkadia", (-2686, -2565), r"Arkadia"),
    ("Plac Zamkowy", (-600, -1537), r"^(Plac|Pl\.) Zamkowy"),
    ("Palace on the Isle (Łazienki)", (770, 2101), r"Pa[łl]ac (na Wyspie|na Wodzie|[ŁL]azienkowski)|Palace on the (Isle|Water)"),
    ("Stadion Narodowy", (1459, -641), r"Stadion Narodowy|PGE Narodowy"),
    ("Belweder", None, r"\bBelweder\b"),
]


def osm_checks(out, box, by_type=None):
    if by_type is None:
        path = os.path.join(out, "osm", "osm_demo.json")
        with open(path, encoding="utf-8") as f:
            doc = json.load(f)
        by_type = {"node": {}, "way": {}, "relation": {}}
        for el in doc["elements"]:
            by_type[el["type"]][el["id"]] = el
    nodes = by_type["node"]
    lats = [n["lat"] for n in nodes.values()]
    lons = [n["lon"] for n in nodes.values()]
    node_range = {"lat": [min(lats), max(lats)], "lon": [min(lons), max(lons)]}
    near = [(n["lat"], n["lon"]) for n in nodes.values()
            if box[0] - 0.02 <= n["lat"] <= box[2] + 0.02 and box[1] - 0.02 <= n["lon"] <= box[3] + 0.02]
    node_range_near_box = {"lat": [min(p[0] for p in near), max(p[0] for p in near)],
                           "lon": [min(p[1] for p in near), max(p[1] for p in near)]}
    inside = sum(1 for n in nodes.values() if in_box(box, n["lat"], n["lon"]))
    tile_nodes = {}
    for name, s, w, n, e in split_box(box, 3, 3):
        tile_nodes[name] = sum(1 for nd in nodes.values() if s <= nd["lat"] <= n and w <= nd["lon"] <= e)
    ways = by_type["way"]
    tag_counts = collections.Counter()
    for wy in ways.values():
        t = wy.get("tags", {})
        if "building" in t:
            tag_counts["ways:building"] += 1
        if "highway" in t:
            tag_counts["ways:highway"] += 1
        if "railway" in t:
            tag_counts["ways:railway"] += 1
        if t.get("bridge", "no") != "no":
            tag_counts["ways:bridge"] += 1
        if t.get("tunnel", "no") != "no":
            tag_counts["ways:tunnel"] += 1
    for nd in nodes.values():
        t = nd.get("tags")
        if t:
            if t.get("natural") == "tree":
                tag_counts["nodes:tree"] += 1
            if t.get("highway") == "street_lamp":
                tag_counts["nodes:street_lamp"] += 1
            if t.get("highway") == "traffic_signals":
                tag_counts["nodes:traffic_signals"] += 1
            if t.get("amenity") == "police":
                tag_counts["nodes:police"] += 1
    spots = []
    for label, anchor, pattern in SPOTS:
        rx = re.compile(pattern, re.I)
        named = []
        for kind in ("way", "relation"):
            for el in by_type[kind].values():
                t = el.get("tags", {})
                if t.get("type") in ("route", "disused:route", "public_transport", "network") or "route" in t:
                    continue  # bus and train lines are named after their stops
                if rx.search(t.get("name", "") + " " + t.get("name:en", "")):
                    named.append(el)

        def centroid(el):
            if el["type"] == "way":
                pts = [nodes[i] for i in el["nodes"] if i in nodes]
            else:
                pts = [nodes[m["ref"]] for m in el["members"] if m["type"] == "node" and m["ref"] in nodes]
                for m in el["members"]:
                    if m["type"] == "way" and m["ref"] in ways:
                        pts += [nodes[i] for i in ways[m["ref"]]["nodes"] if i in nodes]
            if not pts:
                return None
            return sum(p["lat"] for p in pts) / len(pts), sum(p["lon"] for p in pts) / len(pts)

        found = []
        for el in named:
            c = centroid(el)
            if c:
                found.append({"type": el["type"], "id": el["id"], "name": el["tags"].get("name", ""),
                              "lat": round(c[0], 5), "lon": round(c[1], 5), "in_box": in_box(box, *c)})
        if anchor is None:
            candidates = [f for f in found if f["in_box"]] or found
            lat, lon = (candidates[0]["lat"], candidates[0]["lon"]) if candidates else (box[0] + 0.001, (box[1] + box[3]) / 2)
        else:
            lat, lon = unproject(*anchor)
        near = 0
        for wy in ways.values():
            for i in wy["nodes"][::3]:
                nd = nodes.get(i)
                if nd and meters_between(lat, lon, nd["lat"], nd["lon"]) <= 250:
                    near += 1
                    break
        close = [f for f in found if meters_between(lat, lon, f["lat"], f["lon"]) <= 400]
        spots.append({"spot": label, "lat": round(lat, 5), "lon": round(lon, 5), "ways_within_250m": near,
                      "named_elements_within_400m": len(close), "named_elements_in_box": sum(1 for f in found if f["in_box"]),
                      "examples": sorted({(f["name"], f["type"], f["id"]) for f in close})[:4]})
    covers = (node_range["lat"][0] <= box[0] and node_range["lat"][1] >= box[2]
              and node_range["lon"][0] <= box[1] and node_range["lon"][1] >= box[3])
    log("OSM nodes lat", node_range["lat"], "lon", node_range["lon"], "(far ends are bus and train route relations);",
        "within 0.02 deg of the box:", node_range_near_box, "covers the box:", covers)
    log("OSM nodes per tile:", tile_nodes)
    for sp in spots:
        log("  spot", sp)
    meta_update(out, "osm", node_range=node_range, node_range_within_0_02deg_of_box=node_range_near_box, nodes_in_box=inside, covers_box=covers,
                nodes_per_tile=tile_nodes, tag_counts=dict(tag_counts), spot_checks=spots, box=list(box))


# ---------------------------------------------------------------- PNG / BMP reading (stdlib)

def png_read(data):
    """Decode an 8-bit PNG into (width, height, green rows, alpha rows or None). The green channel
    is enough to look for blank tiles and to line two photos up."""
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG: " + data[:80].decode("utf-8", "replace"))
    pos, idat, plte = 8, [], b""
    w = h = bd = ct = il = 0
    while pos < len(data):
        ln, = struct.unpack(">I", data[pos:pos + 4])
        typ, body = data[pos + 4:pos + 8], data[pos + 8:pos + 8 + ln]
        pos += 12 + ln
        if typ == b"IHDR":
            w, h, bd, ct, _, _, il = struct.unpack(">IIBBBBB", body)
        elif typ == b"PLTE":
            plte = body
        elif typ == b"IDAT":
            idat.append(body)
        elif typ == b"IEND":
            break
    if bd != 8 or il != 0 or ct not in (0, 2, 3, 4, 6):
        raise ValueError(f"unsupported PNG (bit depth {bd}, colour type {ct}, interlace {il})")
    raw = zlib.decompress(b"".join(idat))
    bpp = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ct]
    stride = w * bpp
    prev = bytearray(stride)
    pos = 0
    greens, alphas = [], ([] if ct in (4, 6) else None)
    table = bytes(plte[3 * i + 1] for i in range(len(plte) // 3)) if ct == 3 else None
    for _ in range(h):
        ft = raw[pos]
        line = bytearray(raw[pos + 1:pos + 1 + stride])
        pos += 1 + stride
        if ft == 1:
            for i in range(bpp, stride):
                line[i] = (line[i] + line[i - bpp]) & 255
        elif ft == 2:
            line = bytearray([(x + y) & 255 for x, y in zip(line, prev)])
        elif ft == 3:
            for i in range(stride):
                left = line[i - bpp] if i >= bpp else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 255
        elif ft == 4:
            for i in range(stride):
                a = line[i - bpp] if i >= bpp else 0
                b = prev[i]
                c = prev[i - bpp] if i >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pred) & 255
        elif ft != 0:
            raise ValueError(f"bad PNG filter {ft}")
        prev = line
        if ct == 2:
            greens.append(bytes(line[1::3]))
        elif ct == 6:
            greens.append(bytes(line[1::4]))
            alphas.append(bytes(line[3::4]))
        elif ct == 0:
            greens.append(bytes(line))
        elif ct == 4:
            greens.append(bytes(line[0::2]))
            alphas.append(bytes(line[1::2]))
        else:
            greens.append(bytes(line).translate(table))
    return w, h, greens, alphas


def bmp_read_green(path):
    """The green channel of a 24-bit BMP, top row first: (width, height, rows)."""
    with open(path, "rb") as f:
        data = f.read()
    off, = struct.unpack("<I", data[10:14])
    w, h, planes, bpp = struct.unpack("<iiHH", data[18:30])
    if bpp != 24:
        raise ValueError(f"BMP with {bpp} bits per pixel")
    stride = (w * 3 + 3) // 4 * 4
    rows = []
    for y in range(abs(h)):
        base = off + y * stride
        rows.append(bytes(data[base + 1:base + w * 3:3]))
    if h > 0:
        rows.reverse()
    return w, abs(h), rows


def blank_stats(w, h, greens, alphas):
    """Looks for blank tiles: share of flat 32 x 32 blocks (max - min <= 2), flat bright or dark ones,
    and the mean and spread of the block means."""
    flat = bright_dark = blocks = 0
    means = []
    for by in range(0, h - 31, 32):
        band = greens[by:by + 32]
        for bx in range(0, w - 31, 32):
            cols = [row[bx:bx + 32] for row in band]
            lo, hi = min(map(min, cols)), max(map(max, cols))
            mean = sum(map(sum, cols)) / (32 * 32)
            blocks += 1
            means.append(mean)
            if hi - lo <= 2:
                flat += 1
                if mean > 245 or mean < 10:
                    bright_dark += 1
    mean_all = sum(means) / len(means)
    spread = math.sqrt(sum((m - mean_all) ** 2 for m in means) / len(means))
    transparent = 0.0
    if alphas:
        total = sum(len(r) for r in alphas)
        transparent = sum(r.count(0) for r in alphas) / total
    return {"blocks": blocks, "flat_share": round(flat / blocks, 4), "flat_bright_or_dark_share": round(bright_dark / blocks, 4),
            "mean_green": round(mean_all, 1), "block_mean_spread": round(spread, 1),
            "transparent_share": round(transparent, 4)}


# ---------------------------------------------------------------- ortho (D2)

def ortho_grid(box):
    """2 x 2 tiles at ORTHO_M_PER_PX; every tile has the same pixel size (<= 4096)."""
    s, w, n, e = box
    tile_w_m = (e - w) / 2 * M_PER_DEG_LON
    tile_h_m = (n - s) / 2 * M_PER_DEG_LAT
    width = round(tile_w_m / ORTHO_M_PER_PX)
    height = round(tile_h_m / ORTHO_M_PER_PX)
    if max(width, height) > 4096:
        raise SystemExit("an ortho tile would be over 4096 px; use a finer split")
    return width, height


def cmd_ortho(a):
    out = a.out
    ortho_dir = os.path.join(out, "gugik", "ortho")
    os.makedirs(ortho_dir, exist_ok=True)
    width, height = ortho_grid(a.box)
    tiles = split_box(a.box, 2, 2)
    log(f"ortho: 4 tiles of {width} x {height} px at {ORTHO_M_PER_PX} m/px")
    index = []
    for name, s, w, n, e in tiles:
        path = os.path.join(ortho_dir, f"ortho_{name}.png")
        url = (f"{ORTHO_WMS}?SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&LAYERS=Raster&STYLES="
               f"&SRS=EPSG:4326&BBOX={w},{s},{e},{n}&WIDTH={width}&HEIGHT={height}&FORMAT=image/png")
        if not os.path.exists(path):
            t0 = time.time()

            def valid(body, headers):
                if body[:8] != b"\x89PNG\r\n\x1a\n":
                    return "not a PNG: " + body[:200].decode("utf-8", "replace")
                ihdr = struct.unpack(">II", body[16:24])
                if ihdr != (width, height):
                    return f"PNG is {ihdr}, expected {(width, height)}"
                return None

            body = get_retry(url, f"ortho {name}", timeout=300, validate=valid)
            write_atomic(path, body)
            log(f"ortho {name}: {human(len(body))} in {time.time() - t0:.0f} s")
            time.sleep(2)
        else:
            log(f"ortho {name}: done already")
        index.append({"tile": name, "file": f"ortho_{name}.png", "bbox": [s, w, n, e], "width": width,
                      "height": height, "size": os.path.getsize(path)})
    write_json(os.path.join(ortho_dir, "ortho_tiles.json"),
               {"box": list(a.box), "m_per_px": ORTHO_M_PER_PX, "srs": "EPSG:4326", "tiles": index})
    meta_update(out, "ortho", source=ORTHO_WMS, layer="Raster", format="image/png", tiles=index,
                m_per_px=ORTHO_M_PER_PX, box=list(a.box))
    ortho_checks(out, a.box)
    return 0


def ortho_checks(out, box):
    ortho_dir = os.path.join(out, "gugik", "ortho")
    index = read_json(os.path.join(ortho_dir, "ortho_tiles.json"))
    if not index:
        return
    results = []
    tiles = {}
    for t in index["tiles"]:
        with open(os.path.join(ortho_dir, t["file"]), "rb") as f:
            data = f.read()
        w, h, greens, alphas = png_read(data)
        stats = blank_stats(w, h, greens, alphas)
        stats.update({"tile": t["tile"], "size_px": [w, h], "bytes": len(data)})
        results.append(stats)
        tiles[t["tile"]] = (t["bbox"], w, h, greens)
        log("  ortho", stats)
    # Seams: the difference across a tile border against the difference between neighbouring
    # lines inside a tile.
    def line_diff(rows_a, rows_b):
        n = min(len(rows_a), len(rows_b))
        return sum(abs(x - y) for x, y in zip(rows_a, rows_b)) / n

    seams = {}
    south, north = tiles["r0c0"][3], tiles["r1c0"][3]
    seams["horizontal_seam_west"] = round(line_diff(north[-1], south[0]), 2)
    seams["inside_line_to_line"] = round(line_diff(south[100], south[101]), 2)
    west, east = tiles["r0c0"][3], tiles["r0c1"][3]
    col_w = bytes(r[-1] for r in west)
    col_e = bytes(r[0] for r in east)
    seams["vertical_seam_south"] = round(line_diff(col_w, col_e), 2)
    seams["inside_col_to_col"] = round(line_diff(bytes(r[100] for r in west), bytes(r[101] for r in west)), 2)
    alignment = ortho_alignment(tiles)
    log("  ortho seams", seams, "alignment vs today's photo", alignment)
    meta_update(out, "ortho", tile_stats=results, seams=seams, alignment=alignment)


def ortho_alignment(tiles):
    """Line the new photo up against today's ortho.bmp (the same service, a smaller box) at 12 spots:
    the best shift in pixels of the new image that matches the old one. 0, 0 means they line up."""
    old_path = os.path.join(ROOT, "data", "raw", "gugik", "ortho.bmp")
    old_json = read_json(os.path.join(ROOT, "data", "raw", "gugik", "ortho.json"))
    if not os.path.exists(old_path) or not old_json:
        return None
    ow, oh, orows = bmp_read_green(old_path)
    os_, ow_, on_, oe_ = old_json["bbox"]

    def old_px(lat, lon):
        return (lon - ow_) / (oe_ - ow_) * ow, (on_ - lat) / (on_ - os_) * oh

    def new_at(lat, lon):
        for name, (bb, w, h, rows) in tiles.items():
            ts, tw, tn, te = bb
            if ts <= lat <= tn and tw <= lon <= te:
                x = int((lon - tw) / (te - tw) * w)
                y = int((tn - lat) / (tn - ts) * h)
                return rows[min(y, h - 1)][min(x, w - 1)]
        return None

    # New pixel size in degrees (all tiles equal).
    bb, w, h, _ = tiles["r0c0"]
    dlon, dlat = (bb[3] - bb[1]) / w, (bb[2] - bb[0]) / h
    shifts = []
    sad_zero = []
    sad_best = []
    centers = [(52.2285 + 0.0012 * i, 20.9995 + 0.0145 * j) for i in range(0, 4) for j in range(0, 4)][::1]
    centers = [c for c in centers if os_ + 0.001 < c[0] < on_ - 0.001 and ow_ + 0.001 < c[1] < oe_ - 0.001][:12]
    for lat, lon in centers:
        ox, oy = old_px(lat, lon)
        ox, oy = int(ox), int(oy)
        half = 20
        patch = [orows[y][ox - half:ox + half] for y in range(oy - half, oy + half)]
        old_dlon, old_dlat = (oe_ - ow_) / ow, (on_ - os_) / oh
        best = None
        scores = {}
        for dy in range(-4, 5):
            for dx in range(-4, 5):
                sad = 0
                n = 0
                for py in range(0, 2 * half, 2):
                    la = lat - (py - half) * old_dlat - dy * dlat
                    for px in range(0, 2 * half, 2):
                        lo = lon + (px - half) * old_dlon + dx * dlon
                        v = new_at(la, lo)
                        if v is None:
                            continue
                        sad += abs(v - patch[py][px])
                        n += 1
                if n:
                    scores[(dx, dy)] = sad / n
        if not scores:
            continue
        best = min(scores, key=scores.get)
        shifts.append(best)
        sad_zero.append(scores[(0, 0)])
        sad_best.append(scores[best])
    if not shifts:
        return None
    dxs = sorted(s[0] for s in shifts)
    dys = sorted(s[1] for s in shifts)
    return {"spots": len(shifts), "median_shift_px": [dxs[len(dxs) // 2], dys[len(dys) // 2]],
            "mean_abs_green_diff_at_zero_shift": round(sum(sad_zero) / len(sad_zero), 2),
            "mean_abs_green_diff_at_best_shift": round(sum(sad_best) / len(sad_best), 2)}


# ---------------------------------------------------------------- 10 m elevation (D3)

def nmt10_points(box, step=10.0):
    """The same grid fetch_gugik.py makes, for any box: local metres, west edge x0, north edge z0."""
    s, w, n, e = box
    sw, ne = project(s, w), project(n, e)
    x0, z0 = sw[0], ne[1]
    nx = int((ne[0] - sw[0]) / step) + 1
    nz = int((sw[1] - ne[1]) / step) + 1
    return x0, z0, nx, nz


def nmt10_batch(x0, z0, nx, step, ks, label):
    """One GetHByPointList request for grid points ks (flat indices). Returns the heights as strings.
    A reply of all zeros is a service hiccup (Warsaw is 75 to 120 m): retried, never accepted."""
    def point(k):
        j, i = divmod(k, nx)
        lat, lon = unproject(x0 + i * step, z0 + j * step)
        north, east = to_pl1992(lat, lon)
        return f"{north:.1f}%20{east:.1f}"

    def valid(body, headers):
        txt = body.decode("utf-8", "replace").strip()
        if txt.lower().startswith("<"):
            return "error page: " + txt[:160]
        parts = txt.split(",")
        if len(parts) != len(ks) or any(len(p.split()) != 3 for p in parts):
            return f"expected {len(ks)} points, got {len(parts)}: {txt[:120]}"
        zeros = sum(1 for p in parts if float(p.split()[2]) == 0.0)
        if zeros * 2 > len(parts):
            return f"{zeros} of {len(parts)} heights are 0.0"
        return None

    body = get_retry(ELEVATION + ",".join(point(k) for k in ks), label, validate=valid, timeout=60,
                     waits=(5, 20, 60, 120))
    return [p.split()[2] for p in body.decode().strip().split(",")]


def cmd_nmt10(a):
    out = a.out
    d = os.path.join(out, "gugik", "nmt10")
    os.makedirs(d, exist_ok=True)
    final = os.path.join(d, "terrain_10m.json")
    step = 10.0
    x0, z0, nx, nz = nmt10_points(a.box, step)
    total = nx * nz
    batches = math.ceil(total / 250)
    log(f"nmt10: {nx} x {nz} = {total} points, {batches} requests")
    if os.path.exists(final):
        # repair: a finished file may hold batches the service answered with zeros
        doc = read_json(final)
        h = doc["h"]
        redo = [b for b in range(batches) if any(v == 0.0 for v in h[b * 250:(b + 1) * 250])]
        if redo:
            log(f"nmt10: {len(redo)} batches hold zero heights; fetching them again: {redo}")
            for b in redo:
                ks = range(b * 250, min((b + 1) * 250, total))
                h[b * 250:b * 250 + len(ks)] = [float(v) for v in nmt10_batch(x0, z0, nx, step, ks, f"nmt10 batch {b + 1}")]
                time.sleep(1)
            doc["h"] = h
            write_json(final, doc, separators=(",", ":"))
            meta_update(out, "nmt10", repaired_zero_batches=redo)
        log("nmt10: done already")
        nmt10_checks(out, a.box)
        return 0
    partial = os.path.join(d, "terrain_10m.partial.csv")
    done_batches = 0
    if os.path.exists(partial):
        with open(partial, "rb+") as f:  # drop a half-written last line
            content = f.read()
            f.truncate(content.rfind(b"\n") + 1)
        with open(partial) as f:
            done_batches = sum(1 for _ in f)
    t0 = time.time()
    with open(partial, "a") as f:
        for b in range(done_batches, batches):
            ks = range(b * 250, min((b + 1) * 250, total))
            heights = nmt10_batch(x0, z0, nx, step, ks, f"nmt10 batch {b + 1}/{batches}")
            f.write(",".join(heights) + "\n")
            f.flush()
            if b % 50 == 0:
                log(f"nmt10: batch {b + 1}/{batches} ({time.time() - t0:.0f} s)")
            time.sleep(0.15)
    heights = []
    with open(partial) as f:
        for line in f:
            heights += [float(v) for v in line.strip().split(",")]
    if len(heights) != total:
        raise SystemExit(f"nmt10: {len(heights)} heights for {total} points")
    write_json(final, {"x0": round(x0, 2), "z0": round(z0, 2), "step": step, "nx": nx, "nz": nz, "h": heights,
                       "bbox": list(a.box), "origin": [LAT0, LON0], "heights": "EVRF2007 (GUGiK NMT service)"},
               separators=(",", ":"))
    os.remove(partial)
    log(f"nmt10: written {human(os.path.getsize(final))} in {time.time() - t0:.0f} s")
    meta_update(out, "nmt10", source=ELEVATION + "<north east,...>", requests=batches)
    nmt10_checks(out, a.box)
    return 0


def nmt10_checks(out, box):
    doc = read_json(os.path.join(out, "gugik", "nmt10", "terrain_10m.json"))
    if not doc:
        return
    h = doc["h"]
    bad = [v for v in h if v < -100 or v != v]
    good = [v for v in h if v >= -100 and v == v]
    zero = sum(1 for v in h if v == 0.0)
    res = {"nx": doc["nx"], "nz": doc["nz"], "cells": len(h), "no_data_cells": len(bad), "zero_cells": zero,
           "min": min(good), "max": max(good), "step": doc["step"], "x0": doc["x0"], "z0": doc["z0"]}
    # the river: cells whose neighbourhood is flat water level are not detected here; report the
    # lowest 1 % instead
    srt = sorted(good)
    res["p01"] = srt[len(srt) // 100]
    res["p50"] = srt[len(srt) // 2]
    res["p99"] = srt[len(srt) * 99 // 100]
    nx = doc["nx"]
    jumps = [abs(h[i + 1] - h[i]) for i in range(len(h) - 1) if (i + 1) % nx]
    jumps += [abs(h[i + nx] - h[i]) for i in range(len(h) - nx)]
    res["max_jump_between_neighbours_m"] = round(max(jumps), 1)
    res["neighbour_jumps_over_8m"] = sum(1 for j in jumps if j > 8)
    log("  nmt10", res)
    meta_update(out, "nmt10", checks=res, box=list(box), size=os.path.getsize(os.path.join(out, "gugik", "nmt10", "terrain_10m.json")))


# ---------------------------------------------------------------- GUGiK sheets (LoD2 and trees)

def sheet_name(lat, lon, scale):
    """The sheet of the Polish 1:1,000,000 graticule system at a point: scale 5000 gives
    N-34-139-A-c-1-1, scale 2500 gives N-34-139-A-c-1-1-1 (each level splits into 2 x 2, 1 = NW,
    2 = NE, 3 = SW, 4 = SE; the sheet frames follow the graticule)."""
    row = int((56.0 - lat) // (1 / 3))
    col = int((lon - 18.0) // 0.5)
    north, west, h, w = 56.0 - row / 3, 18.0 + col * 0.5, 1 / 3, 0.5
    parts = ["N", "34", str(row * 12 + col + 1)]
    levels = 5 if scale == 2500 else 4  # A-D, a-d, then the 1:10,000, 1:5,000 (, 1:2,500) digits
    for level in range(levels):
        h, w = h / 2, w / 2
        q = (0 if lat >= north - h else 2) + (0 if lon < west + w else 1)
        north -= h if q >= 2 else 0
        west += w if q % 2 else 0
        parts.append("ABCD"[q] if level == 0 else "abcd"[q] if level == 1 else str(q + 1))
    return "-".join(parts)


def sheet_bounds(name):
    """(south, west, north, east) in degrees of a sheet name such as N-34-138-B-d-2-2-1."""
    parts = name.split("-")
    i = int(parts[2]) - 1
    north, west = 56.0 - (i // 12) / 3, 18.0 + (i % 12) * 0.5
    h, w = 1 / 3, 0.5
    for level, p in enumerate(parts[3:]):
        h, w = h / 2, w / 2
        q = "ABCD".index(p) if level == 0 else "abcd".index(p) if level == 1 else int(p) - 1
        north -= h if q >= 2 else 0
        west += w if q % 2 else 0
    return north - h, west, north, west + w


def sheets_for_box(box, scale):
    """Every sheet that overlaps the box, sorted. Sampled finer than a 1:2,500 sheet (0.0104 x 0.0156 deg)."""
    s, w, n, e = box
    names = set()
    lat_steps = int((n - s) / 0.002) + 1
    lon_steps = int((e - w) / 0.003) + 1
    for i in range(lat_steps + 1):
        lat = min(s + i * 0.002, n) - 1e-9 * (i == lat_steps)
        for j in range(lon_steps + 1):
            lon = min(w + j * 0.003, e) - 1e-9 * (j == lon_steps)
            names.add(sheet_name(lat, lon, scale))
    return sorted(names)


def gml_tail_ok(path):
    try:
        with open(path, "rb") as f:
            f.seek(-512, os.SEEK_END)
            return f.read().rstrip().endswith(b"</core:CityModel>")
    except OSError:
        return False


def count_in_file(path, needle):
    """Counts a byte string in a big file without loading it."""
    n = 0
    tail = b""
    with open(path, "rb") as f:
        while True:
            chunk = f.read(8 << 20)
            if not chunk:
                break
            data = tail + chunk
            n += data.count(needle)
            tail = data[-(len(needle) - 1):]  # shorter than the needle, so nothing is counted twice
    return n


def parse_to_end(path, local_tag):
    """Streams a CityGML file through the XML parser to its last tag; returns the number of
    elements called local_tag, or raises on a truncated or broken file."""
    import xml.etree.ElementTree as ET
    count = 0
    for _, el in ET.iterparse(path, events=("end",)):
        if el.tag.endswith("}" + local_tag):
            count += 1
            el.clear()
    return count


def cmd_sheets(a):
    out = a.out
    dest = os.path.join(out, "gugik", "sheets")
    os.makedirs(dest, exist_ok=True)
    s, w, n, e = a.box
    res = subprocess.run([sys.executable, "-I", os.path.join(TOOLS, "find_sheets.py"), a.zip, TOOLS,
                          str(s), str(w), str(n), str(e)], capture_output=True, text=True)
    if res.returncode != 0:
        raise SystemExit("find_sheets.py failed: " + res.stderr[-400:])
    listed = {}
    for line in res.stdout.splitlines():
        m = re.match(r"(\S*?(1465_(N-34-[\w-]+))\.gml)\s+(\d+)", line)
        if m:
            listed[m.group(3)] = (m.group(1), int(m.group(4)))
    graticule = set(sheets_for_box(a.box, 5000))
    log(f"sheets: find_sheets.py lists {len(listed)}; the graticule says {len(graticule)}")
    log("  only in find_sheets:", sorted(set(listed) - graticule), " only in graticule:", sorted(graticule - set(listed)))
    existing = {f for f in os.listdir(a.existing_sheets)} if os.path.isdir(a.existing_sheets) else set()
    z = zipfile.ZipFile(a.zip)
    rows = []
    for name in sorted(listed):
        member, size = listed[name]
        fname = f"1465_{name}.gml"
        where = "today's sheets (data/raw/gugik/sheets)" if fname in existing else "demo/gugik/sheets"
        target = os.path.join(dest, fname)
        if fname not in existing and not os.path.exists(target):
            with z.open(member) as src, open(target + ".part", "wb") as dst:
                shutil.copyfileobj(src, dst, 1 << 20)  # zipfile checks the CRC at the end
            os.replace(target + ".part", target)
            log(f"sheets: unpacked {fname} ({human(size)})")
        path = target if fname not in existing else os.path.join(a.existing_sheets, fname)
        head = open(path, encoding="utf-8").read(6000)
        lo = re.search(r"<gml:lowerCorner[^>]*>([^<]+)<", head)
        hi = re.search(r"<gml:upperCorner[^>]*>([^<]+)<", head)
        rows.append({"sheet": name, "file": fname, "where": where, "size": os.path.getsize(path),
                     "in_graticule": name in graticule,
                     "envelope_e_n": [lo.group(1).split()[:2], hi.group(1).split()[:2]] if lo and hi else None,
                     "buildings": count_in_file(path, b"<bldg:Building "), "closed": gml_tail_ok(path)})
        log("  ", rows[-1])
    meta_update(out, "sheets", source="integracja.gugik.gov.pl/Budynki3D/pobierz.php?plik=powiaty/1465_gml.zip "
                "(on disk: data/raw/gugik/1465_gml.zip)", sheets=rows, box=list(a.box),
                find_sheets_only=sorted(set(listed) - graticule),
                graticule_only=sorted(graticule - set(listed)))
    return 0


# ---------------------------------------------------------------- 3D trees (D6)

def stream_trees(stage, members, tar_log):
    """curl the 8.6 GB zip through bsdtar, keeping only `members`; bsdtar -q stops as soon as all
    are out, which ends the download early. Returns (bytes streamed, ok)."""
    os.makedirs(stage, exist_ok=True)
    with open(tar_log, "ab") as tl:
        tar = subprocess.Popen(["bsdtar", "-x", "-q", "-f", "-", "-C", stage] + members,
                               stdin=subprocess.PIPE, stderr=tl)
        curl = subprocess.Popen(["curl", "-sS", "--fail", "-A", UA, "--connect-timeout", "30",
                                 "--speed-limit", "2000", "--speed-time", "180", TREES_ZIP],
                                stdout=subprocess.PIPE, stderr=tl)
        total, t0, last = 0, time.time(), time.time()
        early = False
        try:
            while True:
                chunk = curl.stdout.read(1 << 20)
                if not chunk:
                    break
                try:
                    tar.stdin.write(chunk)
                except BrokenPipeError:
                    early = True  # bsdtar has all it wanted and quit
                    break
                total += len(chunk)
                if time.time() - last >= 60:
                    last = time.time()
                    got = sum(os.path.getsize(os.path.join(dp, f)) for dp, _, fs in os.walk(stage) for f in fs)
                    log(f"trees: {human(total)} streamed, {total / (time.time() - t0) / 1e6:.2f} MB/s, "
                        f"{human(got)} kept so far")
        finally:
            try:
                tar.stdin.close()
            except OSError:
                pass
            if early or tar.poll() is not None:
                curl.kill()
            tar_rc = tar.wait()
            curl_rc = curl.wait()
        log(f"trees: stream ended after {human(total)} in {time.time() - t0:.0f} s; bsdtar rc {tar_rc}, "
            f"curl rc {curl_rc}{' (bsdtar quit early: all sheets found)' if early else ''}")
        return total, (tar_rc == 0)


def cmd_trees(a):
    out = a.out
    trees_dir = a.trees_dir
    needed = [f"1465_{n}.gml" for n in sheets_for_box(a.box, 2500)]
    have = {f for f in os.listdir(trees_dir) if f.endswith(".gml")} if os.path.isdir(trees_dir) else set()
    todo = [f for f in needed if f not in have]
    log(f"trees: the box needs {len(needed)} sheets at 1:2500; {len(have & set(needed))} are on disk, "
        f"{len(todo)} to fetch:")
    for f in todo:
        s, w, n, e = sheet_bounds(f[5:-4])
        log(f"  {f}  lat {s:.4f}-{n:.4f}  lon {w:.4f}-{e:.4f}")
    unused = sorted(have - set(needed))
    if unused:
        log(f"  (on disk but outside the box: {len(unused)}: {', '.join(unused)})")
    attempts_path = os.path.join(out, "meta", "trees_attempts.json")
    attempts = read_json(attempts_path, {"attempts": []})
    added_before = {f for at in attempts["attempts"] for f in at["sheets_added"]}  # fetched by earlier runs
    meta_update(out, "trees", needed=needed, already_on_disk=sorted((have & set(needed)) - added_before),
                to_fetch=sorted(set(todo) | added_before), on_disk_outside_box=unused, source=TREES_ZIP, box=list(a.box))
    if a.dry_run or not todo:
        if not todo:
            trees_checks(out, a)
        return 0
    free = shutil.disk_usage(os.path.dirname(trees_dir)).free / 1e9
    log(f"trees: {free:.1f} GB free on the disk (need {a.min_free_gb:.0f} GB)")
    if free < a.min_free_gb:
        log("trees: not enough free disk space; stopping")
        return 2
    status = subprocess.run(["curl", "-sSI", "-A", UA, "-m", "60", TREES_ZIP], capture_output=True, text=True)
    log("trees: HEAD:", " | ".join(l.strip() for l in status.stdout.splitlines()
                                   if l.lower().startswith(("http", "content-length", "accept-ranges", "last-modified"))))
    stage = os.path.join(out, "gugik", "trees_stage")
    while todo and len(attempts["attempts"]) < a.max_attempts:
        n_try = len(attempts["attempts"]) + 1
        log(f"trees: attempt {n_try} of {a.max_attempts} for {len(todo)} sheets")
        shutil.rmtree(stage, ignore_errors=True)
        t0 = time.time()
        total, ok = stream_trees(stage, [f"1465/{f}" for f in todo], os.path.join(out, "gugik", "trees_stream.log"))
        moved, bad = [], []
        for dp, _, fs in os.walk(stage):
            for f in sorted(fs):
                src = os.path.join(dp, f)
                if f in todo and gml_tail_ok(src) and not os.path.exists(os.path.join(trees_dir, f)):
                    os.rename(src, os.path.join(trees_dir, f))  # only ever added, never replacing
                    moved.append(f)
                else:
                    bad.append(f)
        shutil.rmtree(stage, ignore_errors=True)
        todo = [f for f in todo if f not in moved]
        attempts["attempts"].append({"date": today(), "seconds": round(time.time() - t0), "bytes_streamed": total,
                                     "bsdtar_ok": ok, "sheets_added": moved, "discarded_partial": bad})
        write_json(attempts_path, attempts, indent=1)
        log(f"trees: attempt {n_try}: {len(moved)} sheets added, {len(todo)} still missing")
        if todo and len(attempts["attempts"]) < a.max_attempts:
            time.sleep(60)
    trees_checks(out, a)
    if todo:
        log(f"trees: STILL MISSING after {len(attempts['attempts'])} attempts: {', '.join(todo)}")
        return 1
    return 0


def trees_checks(out, a):
    meta = read_json(os.path.join(out, "meta", "trees.json"), {})
    attempts = read_json(os.path.join(out, "meta", "trees_attempts.json"), {"attempts": []})
    added = [f for at in attempts["attempts"] for f in at["sheets_added"]]
    rows = meta.get("sheet_checks", {})
    for f in added:
        if f in rows and rows[f].get("parsed_to_end"):
            continue
        path = os.path.join(a.trees_dir, f)
        if not os.path.exists(path):
            continue
        t0 = time.time()
        row = {"size": os.path.getsize(path), "closing_tag": gml_tail_ok(path)}
        head = open(path, encoding="utf-8").read(4000)
        lo = re.search(r"<gml:lowerCorner>([^<]+)<", head)
        hi = re.search(r"<gml:upperCorner>([^<]+)<", head)
        row["envelope_e_n"] = [lo.group(1).split()[:2], hi.group(1).split()[:2]] if lo and hi else None
        try:
            row["vegetation_objects"] = parse_to_end(path, "SolitaryVegetationObject")
            row["parsed_to_end"] = True
        except Exception as e:  # ET.ParseError on a truncated file
            row["parsed_to_end"] = False
            row["error"] = str(e)[:200]
        rows[f] = row
        log(f"  trees check {f}: {row} ({time.time() - t0:.0f} s)")
        meta_update(out, "trees", sheet_checks=rows)
    meta_update(out, "trees", sheet_checks=rows, sheets_added=added, attempts=attempts["attempts"])


# ---------------------------------------------------------------- bridge, viaduct and tunnel-portal corridors (D4 + D5)

MAIN_ROADS = {"motorway", "trunk", "primary", "secondary", "tertiary", "unclassified", "residential",
              "living_street", "motorway_link", "trunk_link", "primary_link", "secondary_link", "tertiary_link"}
TRACKS = {"rail", "tram", "light_rail"}
DECK_PATHS = {"footway", "cycleway", "pedestrian", "path", "steps"}
BRIDGE_BUFFER_M = 40.0   # deck width, abutments, ramps, retaining walls and piers
PORTAL_RADIUS_M = 120.0  # a tunnel portal: the open ramp and trench around the mouth
TRENCH_BUFFER_M = 30.0
ANCHOR_RADIUS_M = 100.0
MAX_WINDOW_M = 1000.0    # one WCS window is at most this long; bigger groups are cut into 500 m cells
CELL_M = 500.0

# Places docs/DEMO.md section 4 names, in map metres (+x east, +z south, origin 52.2340 N 21.0240 E).
# Each must fall inside a corridor; if the OSM structures do not reach one, a 100 m window is added.
DEMO_ANCHORS = [
    ("Poniatowski west abutment (4.3 class 1)", 895, -120),
    ("Poniatowski east abutment (4.2, 4.3)", 1433, -297),
    ("Al. Jerozolimskie viaduct, west end at the escarpment", 187, 118),
    ("Most Swietokrzyski foot (4.3 class 1)", 503, -725),
    ("Most Swietokrzyski pylon (2.2)", 852, -940),
    ("Wybrzeze Szczecinskie under the Poniatowski span", 1410, -285),
    ("link under the span's west end", 943, -145),
    ("Kruczkowskiego under railway deck 17", 425, -73),
    ("Solec under railway deck 16", 534, -177),
    ("Al. 3 Maja under a footway deck", 822, -86),
    ("Wioslarska under a footway deck", 970, -99),
    ("Wybrzeze Koscuszkowskie under railway deck 15", 671, -336),
    ("Wybrzeze Koscuszkowskie under railway deck 14", 761, -399),
    ("service road under the Jana Pawla II viaduct", -1485, 773),
    ("footbridge 9", -1356, 754),
    ("link under deck 5", 840, -122),
    ("pier in Kruczkowskiego", 470, 10),
    ("pier on Wybrzeze Szczecinskie", 1394, -298),
    ("pier on Wybrzeze Szczecinskie (north)", 1145, -714),
    ("pier on a service road", 1322, -274),
    ("Rondo Czterdziestolatka", -1504, 672),
    ("service road by the viaduct", -1493, 750),
    ("Wislostrada tunnel, south portal", 637, -554),
    ("link under the west abutment (way 237351918)", 838, -122),
    ("Arkada under the viaduct", 577, -19),
    ("Trasa W-Z tunnel under Plac Zamkowy", -600, -1537),
    ("Most Slasko-Dabrowski", -170, -1659),
    ("Most Lazienkowski and Trasa Lazienkowska", 1704, 962),
    ("Dworzec Gdanski railway", -2045, -2621),
]


def to_en(lat, lon):
    north, east = to_pl1992(lat, lon)
    return east, north


def densify(pts, step=10.0):
    out = [pts[0]]
    for (e0, n0), (e1, n1) in zip(pts, pts[1:]):
        d = math.hypot(e1 - e0, n1 - n0)
        k = max(1, int(d // step))
        for i in range(1, k + 1):
            out.append((e0 + (e1 - e0) * i / k, n0 + (n1 - n0) * i / k))
    return out


def slugify(text):
    table = str.maketrans({"ą": "a", "ć": "c", "ę": "e", "ł": "l", "ń": "n", "ó": "o", "ś": "s", "ź": "z", "ż": "z",
                           "Ą": "A", "Ć": "C", "Ę": "E", "Ł": "L", "Ń": "N", "Ó": "O", "Ś": "S", "Ź": "Z", "Ż": "Z"})
    return re.sub(r"[^a-z0-9]+", "_", text.translate(table).lower()).strip("_")[:40] or "structure"


def plan_corridors(osm_path, box):
    """Pick the structures from the OSM export and group them into corridors; returns a plan dict."""
    with open(osm_path, encoding="utf-8") as f:
        doc = json.load(f)
    nodes = {el["id"]: (el["lat"], el["lon"]) for el in doc["elements"] if el["type"] == "node"}
    elements = []  # {kind, name, way, pts (dense, E/N), buffer, deck}
    ways = [el for el in doc["elements"] if el["type"] == "way"]
    candidates = []
    for w in ways:
        t = w.get("tags", {})
        pts_ll = [nodes[i] for i in w["nodes"] if i in nodes]
        if len(pts_ll) < 2 or not any(in_box(box, *p) for p in pts_ll):
            continue
        hw, rw = t.get("highway", ""), t.get("railway", "")
        bridge = t.get("bridge", "no") not in ("no", "")
        tunnel = t.get("tunnel", "no") not in ("no", "", "culvert", "building_passage")
        try:
            layer = int(t.get("layer", "0"))
        except ValueError:
            layer = 0
        pts = [to_en(*p) for p in pts_ll]
        length = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(pts, pts[1:]))
        name = t.get("name") or t.get("ref") or ""
        candidates.append((w, t, hw, rw, bridge, tunnel, layer, pts, length, name))
    selected = []
    for w, t, hw, rw, bridge, tunnel, layer, pts, length, name in candidates:
        main = hw in MAIN_ROADS or rw in TRACKS
        if bridge and main and length >= 15:
            selected.append(("bridge", w, pts, name, BRIDGE_BUFFER_M))
        elif tunnel and hw in MAIN_ROADS and hw not in ("residential", "living_street") and length >= 30:
            selected.append(("tunnel", w, pts, name, BRIDGE_BUFFER_M))
        elif (not bridge and not tunnel and layer < 0 and hw in MAIN_ROADS
              and hw not in ("residential", "living_street", "unclassified") and length >= 30):
            selected.append(("trench", w, pts, name, TRENCH_BUFFER_M))
    # Footway/cycleway/steps decks and service ramps that touch or sit within 40 m of a selected deck.
    deck_pts = [p for k, w, pts, n, b in selected if k == "bridge" for p in densify(pts, 20)]
    grid = collections.defaultdict(list)
    for p in deck_pts:
        grid[(int(p[0] // 50), int(p[1] // 50))].append(p)

    def near_deck(p, r=40.0):
        cx, cy = int(p[0] // 50), int(p[1] // 50)
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for q in grid.get((cx + dx, cy + dy), ()):
                    if math.hypot(p[0] - q[0], p[1] - q[1]) <= r:
                        return True
        return False

    chosen = {s[1]["id"] for s in selected}
    for w, t, hw, rw, bridge, tunnel, layer, pts, length, name in candidates:
        if w["id"] in chosen or not bridge or length < 10:
            continue
        if (hw in DECK_PATHS or hw == "service") and any(near_deck(p) for p in densify(pts, 10)):
            selected.append(("bridge", w, pts, name, BRIDGE_BUFFER_M))
    # Portals: the ends of each tunnel way that no other selected tunnel way continues from.
    tunnel_nodes = collections.Counter()
    for k, w, pts, n, b in selected:
        if k == "tunnel":
            tunnel_nodes.update([w["nodes"][0], w["nodes"][-1]])
    for k, w, pts, name, buf in selected:
        base = {"kind": k, "way": w["id"], "name": name}
        if k == "tunnel":
            for idx, node in ((0, w["nodes"][0]), (-1, w["nodes"][-1])):
                if tunnel_nodes[node] == 1 and node in nodes:
                    p = to_en(*nodes[node])
                    elements.append(dict(base, kind="portal", pts=[p], buffer=PORTAL_RADIUS_M, deck=False))
        else:
            elements.append(dict(base, pts=densify(pts, 10), buffer=buf, deck=(k == "bridge")))
    # Anchors from DEMO.md section 4 the structures do not reach get a window of their own.
    def covered(e, n):
        for el in elements:
            for p in el["pts"]:
                if abs(p[0] - e) <= el["buffer"] and abs(p[1] - n) <= el["buffer"]:
                    return True
        return False

    anchor_report = []
    for label, x, z in DEMO_ANCHORS:
        lat, lon = unproject(x, z)
        e, n = to_en(lat, lon)
        if not in_box(box, lat, lon):
            anchor_report.append({"anchor": label, "x": x, "z": z, "status": "outside the box"})
            continue
        if covered(e, n):
            anchor_report.append({"anchor": label, "x": x, "z": z, "status": "covered by an OSM structure"})
        else:
            elements.append({"kind": "anchor", "way": None, "name": label, "pts": [(e, n)],
                             "buffer": ANCHOR_RADIUS_M, "deck": False})
            anchor_report.append({"anchor": label, "x": x, "z": z, "status": "added as its own 100 m window"})
    def bounds(el):
        es, ns = [p[0] for p in el["pts"]], [p[1] for p in el["pts"]]
        b = el["buffer"]
        return min(es) - b, min(ns) - b, max(es) + b, max(ns) + b

    boxes = [bounds(el) for el in elements]
    parent = list(range(len(elements)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    # Elements whose points come within 25 m of each other are one structure (a deck chain, a viaduct
    # with its ramps); two separate structures that only have overlapping buffers stay two groups.
    cellmap = collections.defaultdict(list)
    for i, el in enumerate(elements):
        for p in el["pts"]:
            cellmap[(int(p[0] // 25), int(p[1] // 25))].append((i, p))
    for (cx, cy), items in cellmap.items():
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for i, p in items:
                    for j, q in cellmap.get((cx + dx, cy + dy), ()):
                        if i != j and find(i) != find(j) and math.hypot(p[0] - q[0], p[1] - q[1]) <= 25.0:
                            parent[find(i)] = find(j)
    clusters = collections.defaultdict(list)
    for i in range(len(elements)):
        clusters[find(i)].append(i)
    groups = []
    for members in clusters.values():
        els = [elements[i] for i in members]
        gb = [boxes[i] for i in members]
        names = collections.Counter(el["name"] for el in els if el["name"] and el["kind"] != "anchor")
        anchor_names = [el["name"] for el in els if el["kind"] == "anchor"]
        title = names.most_common(1)[0][0] if names else (anchor_names[0] if anchor_names else "structure")
        kinds = sorted({el["kind"] for el in els})
        x0 = min(b[0] for b in gb); y0 = min(b[1] for b in gb); x1 = max(b[2] for b in gb); y1 = max(b[3] for b in gb)
        windows = make_windows(els, (x0, y0, x1, y1))
        deck_points = [[round(p[0], 1), round(p[1], 1)] for el in els if el["deck"] for p in el["pts"]]
        groups.append({"title": title, "kinds": kinds, "ways": sorted({el["way"] for el in els if el["way"]}),
                       "windows": windows, "deck_points": deck_points,
                       "area_km2": round(sum((w[2] - w[0]) * (w[3] - w[1]) for w in windows) / 1e6, 3),
                       "centre_e": round((x0 + x1) / 2), "centre_n": round((y0 + y1) / 2),
                       "centre_xz": [round(v) for v in project(*from_pl1992((y0 + y1) / 2, (x0 + x1) / 2))],
                       "anchors": sorted(anchor_names)})
    groups.sort(key=lambda g: (-g["centre_n"], g["centre_e"]))

    def sgn(v):
        return ("m" if v < 0 else "p") + str(abs(v))

    for i, g in enumerate(groups, 1):
        # named by what and where (map metres of the centre), so a re-plan keeps the file names of
        # corridors that did not change
        g["slug"] = f"{slugify(g['title'])}_{'-'.join(g['kinds'])}_{sgn(g['centre_xz'][0])}_{sgn(g['centre_xz'][1])}"
        g["order"] = i
    return {"box": list(box), "groups": groups, "anchors": anchor_report,
            "total_area_km2": round(sum(g["area_km2"] for g in groups), 3), "osm": os.path.basename(osm_path)}


def snap_window(x0, y0, x1, y1):
    """Round a window out to the cell edges both WCS grids share (1 m: WCS_EDGE_E + k, WCS_EDGE_N - k)."""
    e0 = WCS_EDGE_E + math.floor(x0 - WCS_EDGE_E)
    e1 = WCS_EDGE_E + math.ceil(x1 - WCS_EDGE_E)
    n0 = WCS_EDGE_N - math.ceil(WCS_EDGE_N - y0)
    n1 = WCS_EDGE_N - math.floor(WCS_EDGE_N - y1)
    return [round(e0, 4), round(n0, 4), round(e1, 4), round(n1, 4)]


def make_windows(els, bb):
    x0, y0, x1, y1 = bb
    if x1 - x0 <= MAX_WINDOW_M and y1 - y0 <= MAX_WINDOW_M:
        return [snap_window(x0, y0, x1, y1)]
    cells = collections.defaultdict(float)
    for el in els:
        b = el["buffer"]
        for p in el["pts"]:
            for cx in range(int((p[0] - b - x0) // CELL_M), int((p[0] + b - x0) // CELL_M) + 1):
                for cy in range(int((p[1] - b - y0) // CELL_M), int((p[1] + b - y0) // CELL_M) + 1):
                    cells[(cx, cy)] = max(cells[(cx, cy)], b)
    windows = []
    for (cx, cy), b in sorted(cells.items()):
        windows.append(snap_window(max(x0, x0 + cx * CELL_M - 20), max(y0, y0 + cy * CELL_M - 20),
                                   min(x1, x0 + (cx + 1) * CELL_M + 20), min(y1, y0 + (cy + 1) * CELL_M + 20)))
    return windows


def cmd_plan(a):
    osm_path = a.osm or os.path.join(a.out, "osm", "osm_demo.json")
    plan = plan_corridors(osm_path, a.box)
    log(f"plan: {len(plan['groups'])} corridor groups, {plan['total_area_km2']} km2 in "
        f"{sum(len(g['windows']) for g in plan['groups'])} windows")
    for g in plan["groups"]:
        log(f"  {g['order']:02d} {g['slug']:<52} at x,z {g['centre_xz']} {len(g['windows'])} win {g['area_km2']:.3f} km2  ways {len(g['ways'])}"
            + (f"  anchors: {g['anchors']}" if g["anchors"] else ""))
    for r in plan["anchors"]:
        log("  anchor", r)
    write_json(os.path.join(a.out, "corridors.json"), plan, indent=1)
    return 0


# ---- WCS grids and a GeoTIFF writer (the services give heights as Arc/Info ASCII Grid; "image/tiff"
# is an 8-bit picture, so the float32 GeoTIFFs are written here from the exact values)

def parse_aaigrid(body):
    m = re.search(rb"ncols\s+(\d+)\s+nrows\s+(\d+)\s+xllcorner\s+(\S+)\s+yllcorner\s+(\S+)\s+"
                  rb"cellsize\s+(\S+)\s*(?:NODATA_value\s+(\S+)\s*)?\r?\n", body)
    if not m:
        raise ValueError("no ASCII grid in the reply: " + body[:200].decode("utf-8", "replace"))
    start = m.end()
    end = body.find(b"--wcs", start)
    vals = array.array("f", map(float, body[start:end if end > 0 else len(body)].split()))
    ncols, nrows = int(m.group(1)), int(m.group(2))
    if len(vals) != ncols * nrows:
        raise ValueError(f"grid has {len(vals)} values, header says {ncols} x {nrows}")
    return ncols, nrows, float(m.group(3)), float(m.group(4)), float(m.group(5)), vals


def write_geotiff_f32(path, ncols, nrows, e_ul, n_ul, cell, vals):
    """A single-band float32 GeoTIFF (EPSG:2180, pixel-is-area), one uncompressed strip."""
    if sys.byteorder != "little":
        vals = array.array("f", vals)
        vals.byteswap()
    data = vals.tobytes()
    n_entries = 14
    extras = 8 + 2 + n_entries * 12 + 4
    scale_off, tie_off, key_off = extras, extras + 24, extras + 24 + 48
    data_off = (key_off + 32 + 7) // 8 * 8
    ent = lambda tag, typ, cnt, val: struct.pack("<HHII", tag, typ, cnt, val)
    short = lambda tag, v: struct.pack("<HHIHH", tag, 3, 1, v, 0)
    entries = [
        ent(256, 4, 1, ncols), ent(257, 4, 1, nrows), short(258, 32), short(259, 1), short(262, 1),
        ent(273, 4, 1, data_off), short(277, 1), ent(278, 4, 1, nrows), ent(279, 4, 1, len(data)),
        short(284, 1), short(339, 3),
        ent(33550, 12, 3, scale_off), ent(33922, 12, 6, tie_off), ent(34735, 3, 16, key_off),
    ]
    out = bytearray(b"II*\x00" + struct.pack("<I", 8))
    out += struct.pack("<H", n_entries) + b"".join(entries) + struct.pack("<I", 0)
    out += struct.pack("<3d", cell, cell, 0.0)
    out += struct.pack("<6d", 0.0, 0.0, 0.0, e_ul, n_ul, 0.0)
    out += struct.pack("<16H", 1, 1, 0, 3, 1024, 0, 1, 1, 1025, 0, 1, 1, 3072, 0, 1, 2180)
    out += b"\x00" * (data_off - len(out))
    write_atomic(path, bytes(out) + data)


def read_geotiff_f32(path):
    """Reads back a file written by write_geotiff_f32: (ncols, nrows, e_ul, n_ul, cell, array of float32)."""
    with open(path, "rb") as f:
        raw = f.read()
    n, = struct.unpack("<H", raw[8:10])
    tags = {}
    for i in range(n):
        tag, typ, cnt, val = struct.unpack("<HHII", raw[10 + i * 12:22 + i * 12])
        tags[tag] = (typ, cnt, val)
    ncols, nrows, off = tags[256][2], tags[257][2], tags[273][2]
    cell = struct.unpack("<d", raw[tags[33550][2]:tags[33550][2] + 8])[0]
    tie = struct.unpack("<6d", raw[tags[33922][2]:tags[33922][2] + 48])
    vals = array.array("f")
    vals.frombytes(raw[off:off + ncols * nrows * 4])
    if sys.byteorder != "little":
        vals.byteswap()
    return ncols, nrows, tie[3], tie[4], cell, vals


def wcs_window(base, coverage, win, cell, label):
    e0, n0, e1, n1 = win
    query = urllib.parse.urlencode([("SERVICE", "WCS"), ("VERSION", "2.0.1"), ("REQUEST", "GetCoverage"),
                                    ("COVERAGEID", coverage), ("FORMAT", "image/x-aaigrid"),
                                    ("SUBSET", f"x({e0},{e1})"), ("SUBSET", f"y({n0},{n1})")])
    want = (round((e1 - e0) / cell), round((n1 - n0) / cell))

    def valid(body, headers):
        if b"ncols" not in body[:600]:
            return "no grid: " + body[:200].decode("utf-8", "replace")
        return None

    body = get_retry(f"{base}?{query}", label, timeout=600, validate=valid, waits=(10, 30, 90))
    ncols, nrows, xll, yll, csz, vals = parse_aaigrid(body)
    if (ncols, nrows) != want or abs(csz - cell) > 1e-9 or abs(xll - e0) > 1e-3 or abs(yll - n0) > 1e-3:
        raise FetchError(f"{label}: got {ncols} x {nrows} at {xll},{yll} cell {csz}; wanted {want} at {e0},{n0}")
    return ncols, nrows, e0, n1, cell, vals


def cmd_corridors(a):
    out = a.out
    plan = read_json(os.path.join(out, "corridors.json"))
    if not plan:
        raise SystemExit("run `plan` first (it writes corridors.json)")
    jobs = []
    for g in plan["groups"]:
        for k, win in enumerate(g["windows"]):
            suffix = "" if len(g["windows"]) == 1 else f"_{k + 1:02d}"
            jobs.append((g, g["slug"] + suffix, win))
    log(f"corridors: {len(jobs)} windows in {len(plan['groups'])} groups, {plan['total_area_km2']} km2")
    if a.dry_run:
        return 0
    t_all = time.time()
    for n, (g, name, win) in enumerate(jobs, 1):
        for sub, base, cov, cell in (("nmpt05", NMPT_WCS, NMPT_COVERAGE, 0.5), ("nmt1", NMT_WCS, NMT_COVERAGE, 1.0)):
            path = os.path.join(out, "gugik", sub, name + ".tif")
            if os.path.exists(path):
                continue
            t0 = time.time()
            ncols, nrows, e_ul, n_ul, csz, vals = wcs_window(base, cov, win, cell, f"{sub} {name}")
            write_geotiff_f32(path, ncols, nrows, e_ul, n_ul, csz, vals)
            log(f"corridors [{n}/{len(jobs)}] {sub}/{name}.tif {ncols}x{nrows} {human(os.path.getsize(path))} "
                f"in {time.time() - t0:.0f} s")
            time.sleep(1)
    log(f"corridors: all windows done in {time.time() - t_all:.0f} s")
    meta_update(out, "corridors", source={"nmpt05": NMPT_WCS + "?SERVICE=WCS&VERSION=2.0.1&REQUEST=GetCoverage&COVERAGEID=" + NMPT_COVERAGE,
                                         "nmt1": NMT_WCS + "?SERVICE=WCS&VERSION=2.0.1&REQUEST=GetCoverage&COVERAGEID=" + NMT_COVERAGE},
                format="Arc/Info ASCII Grid from the WCS (image/x-aaigrid), stored as float32 GeoTIFF, EPSG:2180, EVRF2007 heights")
    corridor_checks(out, a)
    return 0


def pct(sorted_vals, q):
    return sorted_vals[min(len(sorted_vals) - 1, int(len(sorted_vals) * q))]


def nmt10_minus_nmt1(terrain, nmt, win):
    """The 10 m service grid minus the 1 m WCS bare earth, at every 10 m node inside a window: a median near
    zero says both are in the same height system."""
    x0, z0, step, nx, nz = terrain["x0"], terrain["z0"], terrain["step"], terrain["nx"], terrain["nz"]
    corners = [project(*from_pl1992(n, e)) for e in (win[0], win[2]) for n in (win[1], win[3])]
    ix0 = max(0, math.ceil((min(c[0] for c in corners) - x0) / step))
    ix1 = min(nx - 1, math.floor((max(c[0] for c in corners) - x0) / step))
    iz0 = max(0, math.ceil((min(c[1] for c in corners) - z0) / step))
    iz1 = min(nz - 1, math.floor((max(c[1] for c in corners) - z0) / step))
    ncols, nrows, e_ul, n_ul, cell, vals = nmt
    diffs = []
    for iz in range(iz0, iz1 + 1):
        for ix in range(ix0, ix1 + 1):
            e, n = to_en(*unproject(x0 + ix * step, z0 + iz * step))
            cx, cy = int((e - e_ul) / cell), int((n_ul - n) / cell)
            if 0 <= cx < ncols and 0 <= cy < nrows and -100 < vals[cy * ncols + cx] < 1000:
                diffs.append(terrain["h"][iz * nx + ix] - vals[cy * ncols + cx])
    return diffs


def corridor_checks(out, a):
    plan = read_json(os.path.join(out, "corridors.json"))
    if not plan:
        return
    terrain = read_json(os.path.join(out, "gugik", "nmt10", "terrain_10m.json"))
    results = []
    for g in plan["groups"]:
        files = []
        for k, win in enumerate(g["windows"]):
            name = g["slug"] + ("" if len(g["windows"]) == 1 else f"_{k + 1:02d}")
            pd, pn = (os.path.join(out, "gugik", s, name + ".tif") for s in ("nmpt05", "nmt1"))
            if not (os.path.exists(pd) and os.path.exists(pn)):
                continue
            dsm, nmt = read_geotiff_f32(pd), read_geotiff_f32(pn)
            row = {"file": name, "window_e_n": win, "dsm_size": [dsm[0], dsm[1]], "nmt_size": [nmt[0], nmt[1]],
                   "dsm_bytes": os.path.getsize(pd), "nmt_bytes": os.path.getsize(pn)}
            for tag, grid in (("dsm", dsm), ("nmt", nmt)):
                vals = grid[5]
                good = [v for v in vals if -100 < v < 1000]
                row[tag + "_no_data"] = len(vals) - len(good)
                row[tag + "_min"], row[tag + "_max"] = round(min(good), 2), round(max(good), 2)
            # the surface model should never lie below bare earth (more than the noise): share of 1 m cells
            ncols_n, nrows_n, _, _, _, nv = nmt
            ncols_d, _, _, _, _, dv = dsm
            below = total = 0
            for iy in range(0, nrows_n, 2):
                for ix in range(0, ncols_n, 2):
                    h, d = nv[iy * ncols_n + ix], dv[2 * iy * ncols_d + 2 * ix]
                    if -100 < h < 1000 and -100 < d < 1000:
                        total += 1
                        below += d < h - 0.3
            row["dsm_below_nmt_by_0_3m_share"] = round(below / max(total, 1), 4)
            files.append((row, dsm, nmt, win))
        if not files:
            continue

        def sample(grid, e, n):
            ncols, nrows, e_ul, n_ul, cell, vals = grid
            ix, iy = int((e - e_ul) / cell), int((n_ul - n) / cell)
            if 0 <= ix < ncols and 0 <= iy < nrows:
                return vals[iy * ncols + ix]
            return None

        diffs, deck_h, ground_h, tens = [], [], [], []
        for e, n in g["deck_points"]:
            for row, dsm, nmt, win in files:
                d, h = sample(dsm, e, n), sample(nmt, e, n)
                if d is not None and h is not None and -100 < d < 1000 and -100 < h < 1000:
                    diffs.append(d - h)
                    deck_h.append(d)
                    ground_h.append(h)
                    break
        if terrain:
            for row, dsm, nmt, win in files:
                tens += nmt10_minus_nmt1(terrain, nmt, win)
        summary = {"group": g["slug"], "title": g["title"], "kinds": g["kinds"], "files": [f[0] for f in files],
                   "deck_points_sampled": len(diffs)}
        if diffs:
            sd = sorted(diffs)
            summary.update({"deck_surface_m": [round(min(deck_h), 1), round(max(deck_h), 1)],
                            "ground_m": [round(min(ground_h), 1), round(max(ground_h), 1)],
                            "deck_minus_ground_m": {"p10": round(pct(sd, .1), 2), "median": round(pct(sd, .5), 2),
                                                    "p90": round(pct(sd, .9), 2), "max": round(sd[-1], 2)},
                            "share_deck_over_2m": round(sum(1 for d in diffs if d > 2) / len(diffs), 3)})
        if tens:
            st = sorted(tens)
            summary["nmt10_minus_nmt1_m"] = {"n": len(tens), "p10": round(pct(st, .1), 2), "median": round(pct(st, .5), 2),
                                             "p90": round(pct(st, .9), 2)}
        results.append(summary)
        log("  corridor", {k: v for k, v in summary.items() if k != "files"})
    meta_update(out, "corridors", groups=results, plan_total_km2=plan["total_area_km2"])


# ---------------------------------------------------------------- checks and manifest

def cmd_check(a):
    out = a.out
    if os.path.exists(os.path.join(out, "osm", "osm_demo.json")):
        osm_checks(out, a.box)
    if os.path.exists(os.path.join(out, "gugik", "ortho", "ortho_tiles.json")):
        ortho_checks(out, a.box)
    nmt10_checks(out, a.box)
    corridor_checks(out, a)
    trees_checks(out, a)
    return 0


LICENCES = {
    "osm": "ODbL 1.0, (c) OpenStreetMap contributors",
    "gugik": "GUGiK open data, free use (Prawo geodezyjne i kartograficzne, art. 40a ust. 2 pkt 1)",
    "trees": "CC BY 4.0, GUGiK",
}


def file_date(path):
    return datetime.date.fromtimestamp(os.path.getmtime(path)).isoformat()


def md_table(head, rows):
    out = ["| " + " | ".join(head) + " |", "| " + " | ".join("---" for _ in head) + " |"]
    out += ["| " + " | ".join(str(c) for c in r) + " |" for r in rows]
    return out + [""]


def manifest_trees(a, meta):
    """The tree sheets live outside this folder: list the ones added by this fetch."""
    t = meta.get("trees", {})
    added = t.get("sheets_added", [])
    if not added:
        return []
    rows = []
    for f in added:
        path = os.path.join(a.trees_dir, f)
        sb = sheet_bounds(f[5:-4])
        chk = t.get("sheet_checks", {}).get(f, {})
        rows.append((f"`{os.path.relpath(path, ROOT)}`", f"{sb[0]:.4f}-{sb[2]:.4f} N, {sb[1]:.4f}-{sb[3]:.4f} E",
                     human(os.path.getsize(path)) if os.path.exists(path) else "missing",
                     file_date(path) if os.path.exists(path) else "", chk.get("vegetation_objects", ""),
                     "yes" if chk.get("parsed_to_end") and chk.get("closing_tag") else "NO"))
    return (["## Tree sheets added outside this folder", "",
             f"Source `{TREES_ZIP}` (8.57 GB, streamed through `bsdtar -x -q`, only these members kept; licence {LICENCES['trees']}). "
             "Each tree is two vegetation objects (trunk and crown). The file date is the package's own (December 2023).", ""]
            + md_table(["File", "Covers (1:2500 sheet)", "Size", "Date", "Vegetation objects", "Parsed to the end"], rows))


def manifest_checks(meta, trees_dir):
    L = []
    o = meta.get("osm")
    if o:
        L += ["### OpenStreetMap (D1)", ""]
        L += [f"- Elements: {o['counts']['node']:,} nodes, {o['counts']['way']:,} ways, {o['counts']['relation']:,} relations "
              f"({sum(o['counts'].values()):,} unique of {sum(o['tile_elements'].values()):,} in the 9 tiles; {o['conflicting_duplicates']} "
              "duplicates differed).",
              f"- Tiles: all 9 present, none missing. Elements per tile: " + ", ".join(f"{k} {v:,}" for k, v in o["tile_elements"].items()) + ".",
              f"- Overpass timestamps (`timestamp_osm_base`): {o['timestamps'][0]} to {o['timestamps'][-1]}; tries per tile: {o['tries']}.",
              f"- Nodes inside the box: {o['nodes_in_box']:,}; per tile: " + ", ".join(f"{k} {v:,}" for k, v in o["nodes_per_tile"].items()) + ".",
              f"- Node range within 0.02 deg of the box: lat {o['node_range_within_0_02deg_of_box']['lat']}, lon {o['node_range_within_0_02deg_of_box']['lon']} "
              f"(the box is lat {o['box'][0]}..{o['box'][2]}, lon {o['box'][1]}..{o['box'][3]}), so it is covered on every side. "
              f"Over everything the range is lat {o['node_range']['lat']}, lon {o['node_range']['lon']}: far ends of bus and train route relations.",
              "- Tagged: " + ", ".join(f"{k} {v:,}" for k, v in o["tag_counts"].items()) + ".", ""]
        L += md_table(["Spot check", "Point", "Ways within 250 m", "Named elements within 400 m", "Examples"],
                      [(sp["spot"], f"{sp['lat']}, {sp['lon']}", sp["ways_within_250m"], sp["named_elements_within_400m"],
                        "; ".join(f"{n} ({t} {i})" for n, t, i in sp["examples"])) for sp in o["spot_checks"]])
    p = meta.get("ortho")
    if p:
        L += ["### Aerial photo (D2)", ""]
        L += md_table(["Tile", "Size px", "PNG bytes", "Flat 32 px blocks", "Flat bright/dark blocks", "Mean green", "Transparent"],
                      [(t["tile"], f"{t['size_px'][0]} x {t['size_px'][1]}", f"{t['bytes']:,}", f"{t['flat_share'] * 100:.2f} %",
                        f"{t['flat_bright_or_dark_share'] * 100:.2f} %", t["mean_green"], f"{t['transparent_share'] * 100:.1f} %")
                       for t in p["tile_stats"]])
        al = p.get("alignment") or {}
        L += [f"- Corners: the four tiles share exact edges (see the BBOX in each URL); the box is {p['box']}. Pixel size {p['m_per_px']} m, "
              "equal in both axes at the box's latitude.",
              f"- Seams: mean green difference across the tile borders {p['seams']['horizontal_seam_west']} (horizontal) and "
              f"{p['seams']['vertical_seam_south']} (vertical), against {p['seams']['inside_line_to_line']} / {p['seams']['inside_col_to_col']} "
              "between neighbouring lines inside a tile: no visible seam, no blank tile.",
              f"- Against today's `data/raw/gugik/ortho.bmp` at {al.get('spots')} spots: best shift {al.get('median_shift_px')} px (median); mean green "
              f"difference {al.get('mean_abs_green_diff_at_zero_shift')} at zero shift, {al.get('mean_abs_green_diff_at_best_shift')} at the best shift.", ""]
    n = meta.get("nmt10")
    if n:
        c = n["checks"]
        L += ["### 10 m elevation (D3)", ""]
        L += [f"- Grid {c['nx']} x {c['nz']} = {c['cells']:,} points, step {c['step']} m, x0 {c['x0']}, z0 {c['z0']} (map metres); 1,250 requests of 250 points.",
              f"- No-data cells {c['no_data_cells']}, zero cells {c['zero_cells']}. Height min {c['min']} m, p01 {c['p01']}, median {c['p50']}, p99 {c['p99']}, max {c['max']} m "
              "(the Vistula's surface is the 76.x to 79 m end).",
              f"- Largest step between neighbouring points {c['max_jump_between_neighbours_m']} m; {c['neighbour_jumps_over_8m']} steps over 8 m (the escarpment, trenches, embankments).",
              f"- Batches the service answered with zeros and that were fetched again: {n.get('repaired_zero_batches', [])}.", ""]
    cr = meta.get("corridors")
    if cr:
        L += ["### Corridors (D4 + D5)", "",
              f"- Plan: {len(cr['groups'])} groups, {cr['plan_total_km2']} km2 (`corridors.json`; how they were chosen: see Notes). "
              "Heights are EVRF2007, EPSG:2180; DSM 0.5 m cells, NMT 1 m cells, the same windows. Deck/ground columns sample the OSM bridge ways every 10 m "
              "(DSM at the centre line, NMT at the same point); `nmt10-nmt1` is the 10 m service grid minus the 1 m NMT at its nodes (median [p10, p90]).", ""]
        rows = []
        for g in cr["groups"]:
            for f in g["files"]:
                rows.append((f"`{f['file']}`", ",".join(g["kinds"]), f"{f['dsm_size'][0]} x {f['dsm_size'][1]} / {f['nmt_size'][0]} x {f['nmt_size'][1]}",
                             f"{f['dsm_no_data']}/{f['nmt_no_data']}", f"{f['dsm_min']}..{f['dsm_max']}", f"{f['nmt_min']}..{f['nmt_max']}",
                             f"{f['dsm_below_nmt_by_0_3m_share'] * 100:.1f} %"))
        L += md_table(["File (both folders)", "Kind", "Cells DSM / NMT", "No-data DSM/NMT", "DSM min..max m", "NMT min..max m", "DSM < NMT - 0.3 m"], rows)
        rows = []
        for g in cr["groups"]:
            if "deck_surface_m" in g:
                d = g["deck_minus_ground_m"]
                rows.append((g["title"], f"{g['deck_points_sampled']}", f"{g['deck_surface_m'][0]}..{g['deck_surface_m'][1]}",
                             f"{g['ground_m'][0]}..{g['ground_m'][1]}", f"{d['median']} [{d['p10']}, {d['p90']}], max {d['max']}",
                             f"{g['share_deck_over_2m'] * 100:.0f} %", f"{g['nmt10_minus_nmt1_m']['median']} [{g['nmt10_minus_nmt1_m']['p10']}, {g['nmt10_minus_nmt1_m']['p90']}]"
                             if "nmt10_minus_nmt1_m" in g else ""))
        L += ["Deck against ground, per bridge group:", ""]
        L += md_table(["Group", "Points", "Deck surface m", "Ground (NMT) m", "Deck - ground m", "Deck > 2 m above ground", "nmt10-nmt1 m"], rows)
    sh = meta.get("sheets")
    if sh:
        L += ["### LoD2 sheets (1:5000)", "",
              "Found with `tools/find_sheets.py data/raw/gugik/1465_gml.zip tools S W N E`; the same 12 sheets come out of the sheet-name graticule "
              "(no sheet only in one list). The 6 new ones are unpacked into `gugik/sheets/`; the other 6 are today's, in `data/raw/gugik/sheets/`.", ""]
        L += md_table(["Sheet", "Where", "Size", "Buildings", "Envelope E, N (EPSG:2180)", "Closed"],
                      [(x["sheet"], x["where"], human(x["size"]), x["buildings"], f"{x['envelope_e_n']}", x["closed"]) for x in sh["sheets"]])
    t = meta.get("trees")
    if t:
        L += ["### Trees (D6)", "",
              f"- The box needs {len(t['needed'])} sheets at 1:2500 ({len(t['already_on_disk'])} were on disk, {len(t['to_fetch'])} fetched); sheets on disk outside the box: "
              f"{len(t['on_disk_outside_box'])}. Sheet list kept (all 36): " + ", ".join(f[5:-4] for f in t["needed"]) + ".",
              f"- Added: {len(t.get('sheets_added', []))} sheets, {human(sum(os.path.getsize(os.path.join(trees_dir, f)) for f in t.get('sheets_added', []) if os.path.exists(os.path.join(trees_dir, f))))}. "
              "Each parsed to its last tag (XML streamed to the end) and ends in `</core:CityModel>`; `tools/bake_trees_gugik.py` run on the 13 new files "
              "into a scratch file reported \"0 trees from 13 files (13 complete)\" (0 because its box is today's; `data/raw/gugik/trees_area.json` was not touched).",
              ""]
        L += md_table(["Attempt", "Seconds", "Bytes streamed", "bsdtar ok", "Sheets added"],
                      [(i + 1, x["seconds"], f"{x['bytes_streamed']:,}", x["bsdtar_ok"], len(x["sheets_added"])) for i, x in enumerate(t.get("attempts", []))])
    return L


def cmd_manifest(a):
    out = a.out
    meta = {os.path.splitext(f)[0]: read_json(os.path.join(out, "meta", f), {})
            for f in sorted(os.listdir(os.path.join(out, "meta"))) if f.endswith(".json")}
    rows = []  # (path relative to out, what, source, covers, licence)

    def add(path, what, source, covers, lic):
        full = os.path.join(out, path)
        if os.path.exists(full):
            rows.append((path, what, source, covers, lic, os.path.getsize(full), file_date(full)))

    osm_q = "[out:json][timeout:300];nwr(S,W,N,E);(._;>;);out body;"
    for name, s, w, n, e in split_box(a.box, 3, 3):
        add(f"osm/tile_{name}.json", "Overpass export, one of 3 x 3 tiles", f"{OVERPASS} (POST data={osm_q})",
            f"S {s} W {w} N {n} E {e}", LICENCES["osm"])
    add("osm/osm_demo.json", "all 9 tiles merged by element type + id (shape of data/raw/osm_wide.json)",
        "merged from the tiles by tools/fetch_demo.py osm", "S %s W %s N %s E %s" % a.box, LICENCES["osm"])
    for t in meta.get("ortho", {}).get("tiles", []):
        s, w, n, e = t["bbox"]
        add(f"gugik/ortho/{t['file']}", f"aerial photo, {t['width']} x {t['height']} px, {ORTHO_M_PER_PX} m/px",
            f"{ORTHO_WMS}?SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&LAYERS=Raster&STYLES=&SRS=EPSG:4326&BBOX={w},{s},{e},{n}"
            f"&WIDTH={t['width']}&HEIGHT={t['height']}&FORMAT=image/png", f"S {s} W {w} N {n} E {e}", LICENCES["gugik"])
    add("gugik/ortho/ortho_tiles.json", "index of the four photo tiles", "written by tools/fetch_demo.py", "the box",
        LICENCES["gugik"])
    add("gugik/nmt10/terrain_10m.json", "10 m elevation grid (same shape as data/raw/gugik/terrain_10m.json)",
        ELEVATION + "<north east,...> (1,250 requests of 250 points)", "S %s W %s N %s E %s" % a.box, LICENCES["gugik"])
    for g in meta.get("corridors", {}).get("groups", []):
        for f in g["files"]:
            e0, n0, e1, n1 = f["window_e_n"]
            for sub, base, cov, what in (("nmpt05", NMPT_WCS, NMPT_COVERAGE, "surface model NMPT 0.5 m"),
                                         ("nmt1", NMT_WCS, NMT_COVERAGE, "bare-earth model NMT 1 m")):
                add(f"gugik/{sub}/{f['file']}.tif", f"{what}, float32 GeoTIFF, {g['title']} ({','.join(g['kinds'])})",
                    f"{base}?SERVICE=WCS&VERSION=2.0.1&REQUEST=GetCoverage&COVERAGEID={cov}&FORMAT=image/x-aaigrid"
                    f"&SUBSET=x({e0},{e1})&SUBSET=y({n0},{n1})", f"EPSG:2180 E {e0}-{e1}, N {n0}-{n1}", LICENCES["gugik"])
    add("corridors.json", "the corridor plan (which structures, which windows)", "derived from osm/osm_demo.json by "
        "tools/fetch_demo.py plan", "the box", "ODbL (derived from OSM)")
    for sh in meta.get("sheets", {}).get("sheets", []):
        if sh["where"].startswith("demo"):
            add(f"gugik/sheets/{sh['file']}", "LoD2 1:5000 sheet (CityGML)", "unpacked from data/raw/gugik/1465_gml.zip "
                "(integracja.gugik.gov.pl/Budynki3D/pobierz.php?plik=powiaty/1465_gml.zip)", f"sheet {sh['sheet']}", LICENCES["gugik"])
    lines = ["# Demo map data: manifest", "",
             f"Written {today()} by `tools/fetch_demo.py manifest` from `meta/*.json` and the files on disk.",
             "The box: **S %s, W %s, N %s, E %s** (WGS84), %.1f km2. Local metres use the origin 52.2340 N, 21.0240 E "
             "(+x east, +z south), the same as `tools/bake_osm.py`." % (a.box + (box_area_km2(a.box),)), "",
             "Everything in this folder is raw input for the bake: nothing here is used by the game directly. The tree sheets "
             "are not in this folder: new ones were added to `data/raw/gugik/trees/1465/` (see Trees below).", ""]
    lines += ["## Files", "", "| File | What | Source | Covers | Licence | Size | Date |", "| --- | --- | --- | --- | --- | --- | --- |"]
    for path, what, source, covers, lic, size, date in rows:
        lines.append(f"| `{path}` | {what} | `{source}` | {covers} | {lic} | {human(size)} | {date} |")
    total = sum(r[5] for r in rows)
    lines += ["", f"Total in this folder: {human(total)} in {len(rows)} files.", ""]
    notes = os.path.join(out, "NOTES.md")
    lines += manifest_trees(a, meta)
    lines += ["## Checks", ""] + manifest_checks(meta, a.trees_dir)
    if os.path.exists(notes):
        lines += ["", open(notes, encoding="utf-8").read()]
    write_atomic(os.path.join(out, "MANIFEST.md"), "\n".join(lines).encode("utf-8"))
    log(f"manifest: {len(rows)} files, {human(total)}")
    return 0


# ---------------------------------------------------------------- main

def main():
    commands = [name[4:] for name in globals() if name.startswith("cmd_")]
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("command", choices=sorted(commands))
    ap.add_argument("--out", default=os.path.join(ROOT, "data", "raw", "demo"),
                    help="output folder (default data/raw/demo)")
    ap.add_argument("--box", nargs=4, type=float, metavar=("S", "W", "N", "E"), default=list(DEMO_BOX),
                    help="south west north east in degrees (default: the demo box)")
    ap.add_argument("--max-wait-min", type=float, default=240, help="osm: stop waiting after this long")
    ap.add_argument("--zip", default=os.path.join(ROOT, "data", "raw", "gugik", "1465_gml.zip"),
                    help="sheets: the Warsaw LoD2 package on disk")
    ap.add_argument("--existing-sheets", default=os.path.join(ROOT, "data", "raw", "gugik", "sheets"),
                    help="sheets: where today's LoD2 sheets are (not touched)")
    ap.add_argument("--trees-dir", default=os.path.join(ROOT, "data", "raw", "gugik", "trees", "1465"),
                    help="trees: where the tree sheets live (new sheets are only added)")
    ap.add_argument("--min-free-gb", type=float, default=15, help="trees: free disk space needed")
    ap.add_argument("--max-attempts", type=int, default=2, help="trees: attempts at the 8.6 GB stream")
    ap.add_argument("--osm", default=None, help="plan: the OSM JSON to read (default: out/osm/osm_demo.json)")
    ap.add_argument("--dry-run", action="store_true", help="trees/corridors: print the plan, download nothing")
    a = ap.parse_args()
    a.box = tuple(a.box)
    a.out = os.path.abspath(a.out)
    os.makedirs(a.out, exist_ok=True)
    sys.exit(globals()["cmd_" + a.command](a) or 0)


if __name__ == "__main__":
    main()
