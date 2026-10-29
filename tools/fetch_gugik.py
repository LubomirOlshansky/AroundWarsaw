"""Download the GUGiK aerial photo (WMS, BMP) and a 10 m elevation grid for the map area.

Usage: python3 -I tools/fetch_gugik.py data/raw/gugik
"""
import json
import os
import sys
import time
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bake_osm  # noqa: E402  (bounding box and local projection)
from pl1992 import to_pl1992  # noqa: E402

UA = {"User-Agent": "AroundWarsaw-prototype/0.1"}
ORTHO_WMS = "https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/HighResolution"
ELEVATION = "https://services.gugik.gov.pl/nmt/?request=GetHByPointList&list="


def get(url, timeout=180):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def local_to_latlon(x, z):
    return bake_osm.LAT0 - z / bake_osm.M_PER_DEG_LAT, bake_osm.LON0 + x / bake_osm.M_PER_DEG_LON


def main(out):
    s, w, n, e = bake_osm.BBOX
    sw_m = bake_osm.project(s, w)
    ne_m = bake_osm.project(n, e)
    # The service allows at most 4096 pixels a side; long maps get coarser pixels.
    span_x, span_z = ne_m[0] - sw_m[0], sw_m[1] - ne_m[1]
    scale = min(4096 / span_x, 4096 / span_z, 2.5)
    width, height = int(span_x * scale), int(span_z * scale)
    url = (f"{ORTHO_WMS}?SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&LAYERS=Raster&STYLES="
           f"&SRS=EPSG:4326&BBOX={w},{s},{e},{n}&WIDTH={width}&HEIGHT={height}&FORMAT=image/bmp")
    data = get(url, timeout=300)
    if data[:2] != b"BM":
        raise SystemExit("orthophoto request failed: " + data[:300].decode("utf-8", "replace"))
    with open(os.path.join(out, "ortho.bmp"), "wb") as f:
        f.write(data)
    with open(os.path.join(out, "ortho.json"), "w") as f:
        json.dump({"bbox": [s, w, n, e], "width": width, "height": height}, f)
    print("ortho", len(data), "bytes")

    sw = bake_osm.project(s, w)
    ne = bake_osm.project(n, e)
    step = 10.0
    x0, z0 = sw[0], ne[1]
    nx = int((ne[0] - sw[0]) / step) + 1
    nz = int((sw[1] - ne[1]) / step) + 1
    points = []
    for j in range(nz):
        for i in range(nx):
            lat, lon = local_to_latlon(x0 + i * step, z0 + j * step)
            north, east = to_pl1992(lat, lon)
            points.append(f"{north:.1f} {east:.1f}")
    heights = []
    for k in range(0, len(points), 250):
        batch = ",".join(points[k:k + 250]).replace(" ", "%20")
        reply = get(ELEVATION + batch).decode().strip()
        heights += [float(p.split()[2]) for p in reply.split(",")]
        time.sleep(0.05)
    with open(os.path.join(out, "terrain_10m.json"), "w") as f:
        json.dump({"x0": round(x0, 2), "z0": round(z0, 2), "step": step, "nx": nx, "nz": nz, "h": heights}, f)
    print(f"terrain {nx}x{nz} min {min(heights):.1f} max {max(heights):.1f}")


if __name__ == "__main__":
    main(sys.argv[1])
