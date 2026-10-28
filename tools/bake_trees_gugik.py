"""Extract GUGiK LoD1 tree models (CityGML, CC BY 4.0) inside the map into a compact list.

Usage: python3 -I tools/bake_trees_gugik.py data/raw/gugik/trees/1465 data/raw/gugik/trees_area.json

Every tree is stored as two veg:SolitaryVegetationObjects with the same veg:height:
a 12-face trunk cylinder and a 128-face crown (rings at many heights, EPSG:2180
easting, northing, height). Only crowns are kept: the tree stands at the crown's
centre, the widest ring gives the crown radius, and the lowest ring minus the
ground height (h_nmt) gives where the crown starts.
Output: {"trees": [x, z, height, crown_radius, crown_base, ...], "sheets": [[x, z] * 4, ...]}
in local map metres. "sheets" are the corners of every file that parsed to the end, so
bake_osm.py can drop OpenStreetMap trees only where the GUGiK data really covers.
"""
import glob
import json
import math
import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bake_osm  # noqa: E402  (bounding box and local projection)
from pl1992 import from_pl1992  # noqa: E402

VEG = "{http://www.opengis.net/citygml/vegetation/2.0}"
GML = "{http://www.opengis.net/gml}"
GEN = "{http://www.opengis.net/citygml/generics/2.0}"


def envelope(path):
    """The file's gml:Envelope (easting, northing) corners, from its header."""
    head = open(path, encoding="utf-8").read(4000)
    lo = head.split("<gml:lowerCorner>")[1].split("<")[0].split()
    hi = head.split("<gml:upperCorner>")[1].split("<")[0].split()
    return float(lo[0]), float(lo[1]), float(hi[0]), float(hi[1])


def trees_in(path, complete):
    """Yields crowns; sets complete[0] False if the file ends early (still streaming)."""
    try:
        for _, el in ET.iterparse(path, events=("end",)):
            if el.tag != VEG + "SolitaryVegetationObject":
                continue
            height_el = el.find(VEG + "height")
            ground = None
            for attr in el.iter(GEN + "stringAttribute"):
                if attr.get("name") == "h_nmt":
                    ground = float(attr.find(GEN + "value").text)
            pts = []
            for pl in el.iter(GML + "posList"):
                v = [float(t) for t in pl.text.split()]
                pts += [(v[k], v[k + 1], v[k + 2]) for k in range(0, len(v) - 2, 3)]
            el.clear()
            if height_el is None or ground is None or len({round(p[2], 2) for p in pts}) <= 2:
                continue  # a trunk cylinder (two ring heights): its crown carries the tree
            ce = sum(p[0] for p in pts) / len(pts)
            cn = sum(p[1] for p in pts) / len(pts)
            crown = max(math.hypot(p[0] - ce, p[1] - cn) for p in pts)
            base = min(p[2] for p in pts) - ground
            yield ce, cn, float(height_el.text), crown, base
    except ET.ParseError:
        complete[0] = False  # a truncated file (still streaming) ends here


def main(src, dst):
    out = []
    sheets = []
    files = sorted(glob.glob(os.path.join(src, "*.gml")))
    for path in files:
        complete = [True]
        for east, north, height, crown, base in trees_in(path, complete):
            lat, lon = from_pl1992(north, east)
            if not bake_osm.in_bbox(lat, lon):
                continue
            x, z = bake_osm.project(lat, lon)
            out += [round(x, 1), round(z, 1), round(height, 1), round(max(crown, 1.0), 1),
                    round(min(max(base, 0.0), height * 0.8), 1)]
        if complete[0]:
            e0, n0, e1, n1 = envelope(path)
            corners = []
            for east, north in ((e0, n0), (e1, n0), (e1, n1), (e0, n1)):
                corners += [round(c, 1) for c in bake_osm.project(*from_pl1992(north, east))]
            sheets.append(corners)
    with open(dst, "w") as f:
        json.dump({"trees": out, "sheets": sheets, "source": "GUGiK 3D tree models LoD1 2023, CC BY 4.0"},
                  f, separators=(",", ":"))
    print(f"{len(out) // 5} trees from {len(files)} files ({len(sheets)} complete)")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
