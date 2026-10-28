"""A small GeoTIFF reader for the GUGiK height grids (loop 3b, R2), standard library only.

Usage: python3 -I tools/geotiff.py FILE.tif [FILE.tif ...]   prints each file's layout, its
       georeference and its value range (a quick look; the bake imports `read`).

What it reads: baseline TIFF, little or big endian; one band (SamplesPerPixel 1) of float32,
float64, or signed/unsigned 8/16/32-bit integers; laid out in strips (any RowsPerStrip) or in
tiles; uncompressed (Compression 1), Deflate (8 and the old 32946, with zlib) or LZW (5), with
no predictor or the horizontal (2) or floating-point (3) predictor. The georeference comes from
ModelPixelScale (33550) and ModelTiepoint (33922), the CRS code from the GeoKey directory (34735,
ProjectedCSTypeGeoKey 3072, e.g. 2180 for PL-1992), the no-data value from GDAL_NODATA (42113).

GUGiK's corridor grids in data/raw/demo/gugik/nmpt05 and nmt1 are what tools/fetch_demo.py
writes from the services' Arc/Info ASCII grids: float32, one uncompressed strip, pixel-is-area,
EPSG:2180, no no-data cells (checked: `python3 -I tools/geotiff.py data/raw/demo/gugik/nmt1/*.tif`).
The rest is here so a GeoTIFF from another tool (gdal_translate's tiles and Deflate) reads too.
"""
import array
import struct
import sys
import zlib

TYPES = {1: ("B", 1), 2: ("c", 1), 3: ("H", 2), 4: ("I", 4), 5: ("II", 8), 6: ("b", 1), 7: ("B", 1),
         8: ("h", 2), 9: ("i", 4), 10: ("ii", 8), 11: ("f", 4), 12: ("d", 8), 16: ("Q", 8)}
SAMPLE = {(1, 8): "B", (1, 16): "H", (1, 32): "I", (2, 8): "b", (2, 16): "h", (2, 32): "i",
          (3, 32): "f", (3, 64): "d"}


class Grid:
    """One band: `ncols`, `nrows`, `values` (row by row from the top, an array), the top-left
    corner's map coordinates `x0`, `y0` (easting, northing for EPSG:2180), the cell sizes
    `dx`, `dy`, `epsg`, `nodata` (or None) and `point` (True when the tiepoint is a cell centre,
    RasterPixelIsPoint)."""

    def __init__(self, ncols, nrows, values, x0, y0, dx, dy, epsg, nodata, point):
        self.ncols, self.nrows, self.values = ncols, nrows, values
        self.x0, self.y0, self.dx, self.dy = x0, y0, dx, dy
        self.epsg, self.nodata, self.point = epsg, nodata, point

    def at_cell(self, col, row):
        if 0 <= col < self.ncols and 0 <= row < self.nrows:
            v = self.values[row * self.ncols + col]
            return None if self.nodata is not None and v == self.nodata else v
        return None

    def at(self, x, y):
        """The cell holding map point (x = easting, y = northing), nearest-cell, or None."""
        fx = (x - self.x0) / self.dx + (0.5 if self.point else 0.0)
        fy = (self.y0 - y) / self.dy + (0.5 if self.point else 0.0)
        return self.at_cell(int(fx // 1), int(fy // 1))

    def bounds(self):
        """(x0, y0 bottom, x1, y1 top) of the cells' outer edges."""
        h = 0.5 if self.point else 0.0
        return (self.x0 - h * self.dx, self.y0 - (self.nrows - h) * self.dy,
                self.x0 + (self.ncols - h) * self.dx, self.y0 + h * self.dy)


def _lzw(data):
    """TIFF LZW (MSB-first codes, 9 to 12 bits, ClearCode 256, EOI 257, early change)."""
    out = bytearray()
    table = [bytes([i]) for i in range(256)] + [b"", b""]
    bits, pos, nbits, prev = 0, 0, 9, None
    total = len(data) * 8
    while pos + nbits <= total:
        byte, off = pos >> 3, pos & 7
        chunk = int.from_bytes(data[byte:byte + 3].ljust(3, b"\0"), "big")
        code = (chunk >> (24 - off - nbits)) & ((1 << nbits) - 1)
        pos += nbits
        if code == 256:
            table = table[:258]
            nbits, prev = 9, None
            continue
        if code == 257:
            break
        if prev is None:
            entry = table[code]
        elif code < len(table):
            entry = table[code]
            table.append(prev + entry[:1])
        else:
            entry = prev + prev[:1]
            table.append(entry)
        out += entry
        prev = entry
        if len(table) + 1 >= (1 << nbits) and nbits < 12:
            nbits += 1
    return bytes(out)


def _undo_predictor(buf, pred, width, rows, size, fmt, big):
    if pred == 1:
        return buf
    b = bytearray(buf)
    if pred == 2:
        a = array.array({1: "B", 2: "H", 4: "I", 8: "Q"}[size])
        a.frombytes(bytes(b))
        if big and size > 1:
            a.byteswap()
        mask = (1 << (8 * size)) - 1
        for r in range(rows):
            for c in range(1, width):
                k = r * width + c
                a[k] = (a[k] + a[k - 1]) & mask
        if big and size > 1:
            a.byteswap()
        return a.tobytes()
    if pred == 3:
        # Floating point: bytes differenced, then split by byte significance per row.
        out = bytearray(len(b))
        row = width * size
        for r in range(rows):
            seg = b[r * row:(r + 1) * row]
            for i in range(1, row):
                seg[i] = (seg[i] + seg[i - 1]) & 0xFF
            for c in range(width):
                for k in range(size):
                    src = seg[k * width + c]
                    out[r * row + c * size + (k if big else size - 1 - k)] = src
        return bytes(out)
    raise ValueError(f"predictor {pred} not supported")


def read(path):
    """Reads the first image of a GeoTIFF into a Grid."""
    raw = open(path, "rb").read()
    if raw[:2] == b"II":
        e = "<"
    elif raw[:2] == b"MM":
        e = ">"
    else:
        raise ValueError(f"{path}: not a TIFF")
    magic, ifd = struct.unpack(e + "HI", raw[2:8])
    if magic != 42:
        raise ValueError(f"{path}: BigTIFF or not a TIFF (magic {magic})")
    n, = struct.unpack(e + "H", raw[ifd:ifd + 2])
    tags = {}
    for i in range(n):
        tag, typ, cnt, val = struct.unpack(e + "HHI4s", raw[ifd + 2 + i * 12:ifd + 14 + i * 12])
        fmt, size = TYPES.get(typ, ("B", 1))
        nbytes = size * cnt
        data = val if nbytes <= 4 else raw[struct.unpack(e + "I", val)[0]:struct.unpack(e + "I", val)[0] + nbytes]
        if typ == 2:
            tags[tag] = data[:cnt].rstrip(b"\0").decode("latin-1")
        else:
            tags[tag] = list(struct.unpack(e + fmt * cnt, data[:nbytes]))
    width, height = tags[256][0], tags[257][0]
    bps = tags.get(258, [1])[0]
    spp = tags.get(277, [1])[0]
    comp = tags.get(259, [1])[0]
    pred = tags.get(317, [1])[0]
    sfmt = tags.get(339, [1])[0]
    if spp != 1:
        raise ValueError(f"{path}: {spp} samples per pixel (one band expected)")
    fmt = SAMPLE.get((sfmt, bps))
    if fmt is None:
        raise ValueError(f"{path}: sample format {sfmt} at {bps} bits not supported")
    size = bps // 8

    def decode(chunk):
        if comp == 1:
            return chunk
        if comp in (8, 32946):
            return zlib.decompress(chunk)
        if comp == 5:
            return _lzw(chunk)
        raise ValueError(f"{path}: compression {comp} not supported")
    out = bytearray(width * height * size)
    if 322 in tags:   # tiles
        tw, th = tags[322][0], tags[323][0]
        offs, cnts = tags[324], tags[325]
        across = (width + tw - 1) // tw
        for k, (o, c) in enumerate(zip(offs, cnts)):
            buf = _undo_predictor(decode(raw[o:o + c]), pred, tw, th, size, fmt, e == ">")
            ty, tx = divmod(k, across)
            for r in range(th):
                y = ty * th + r
                if y >= height:
                    break
                w = min(tw, width - tx * tw)
                out[(y * width + tx * tw) * size:(y * width + tx * tw + w) * size] = buf[r * tw * size:(r * tw + w) * size]
    else:             # strips
        rps = tags.get(278, [height])[0]
        offs, cnts = tags[273], tags.get(279, [width * height * size])
        y = 0
        for o, c in zip(offs, cnts):
            rows = min(rps, height - y)
            buf = _undo_predictor(decode(raw[o:o + c]), pred, width, rows, size, fmt, e == ">")
            out[y * width * size:(y + rows) * width * size] = buf[:rows * width * size]
            y += rows
    vals = array.array(fmt)
    vals.frombytes(bytes(out))
    if (e == "<") != (sys.byteorder == "little") and size > 1:
        vals.byteswap()
    scale = tags.get(33550, [1.0, 1.0, 0.0])
    tie = tags.get(33922, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    keys = tags.get(34735, [])
    epsg, point = None, False
    for i in range(4, len(keys) - 3, 4):
        if keys[i] in (3072, 2048) and keys[i + 1] == 0:
            epsg = epsg or keys[i + 3]
        if keys[i] == 1025 and keys[i + 1] == 0:
            point = keys[i + 3] == 2
    nodata = None
    if 42113 in tags:
        try:
            nodata = float(str(tags[42113]).strip())
            if fmt in "fd":
                nodata = array.array(fmt, [nodata])[0]
        except ValueError:
            nodata = None
    # The tiepoint (i, j) -> (x, y): the corner of pixel (0, 0).
    x0 = tie[3] - tie[0] * scale[0]
    y0 = tie[4] + tie[1] * scale[1]
    return Grid(width, height, vals, x0, y0, scale[0], scale[1], epsg, nodata, point)


def main(argv):
    if not argv:
        print(__doc__.split("\n\n")[1])
        return 2
    for p in argv:
        g = read(p)
        vals = [v for v in g.values if g.nodata is None or v != g.nodata]
        b = g.bounds()
        print(f"{p}: {g.ncols} x {g.nrows}, cell {g.dx} x {g.dy}, EPSG {g.epsg}, "
              f"{'point' if g.point else 'area'}, E {b[0]:.2f}..{b[2]:.2f} N {b[1]:.2f}..{b[3]:.2f}, "
              f"values {min(vals):.2f}..{max(vals):.2f}, no-data {g.ncols * g.nrows - len(vals)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
