"""Print the GUGiK LoD2 sheets in a zip whose envelope overlaps the map's bounding box."""
import re
import sys
import zipfile

sys.path.insert(0, sys.argv[2])
from pl1992 import to_pl1992

# Optional third to sixth arguments: south west north east (defaults to the current map).
S, W, N, E = (float(v) for v in sys.argv[3:7]) if len(sys.argv) >= 7 else (52.2260, 20.9980, 52.2370, 21.0160)
corners = [to_pl1992(lat, lon) for lat in (S, N) for lon in (W, E)]
xmin, xmax = min(c[0] for c in corners), max(c[0] for c in corners)
ymin, ymax = min(c[1] for c in corners), max(c[1] for c in corners)
print(f"bbox x(north) {xmin:.0f}-{xmax:.0f}  y(east) {ymin:.0f}-{ymax:.0f}")
z = zipfile.ZipFile(sys.argv[1])
for info in z.infolist():
    if not info.filename.endswith(".gml"):
        continue
    with z.open(info) as f:
        head = f.read(6000).decode("utf-8", "replace")
    lo = re.search(r"<gml:lowerCorner[^>]*>([^<]+)<", head)
    hi = re.search(r"<gml:upperCorner[^>]*>([^<]+)<", head)
    if not lo or not hi:
        continue
    a = [float(v) for v in lo.group(1).split()]
    b = [float(v) for v in hi.group(1).split()]
    # These files write easting first, then northing.
    if a[1] <= xmax and b[1] >= xmin and a[0] <= ymax and b[0] >= ymin:
        print(info.filename, info.file_size, a[:2], b[:2])
