"""Map north (2026-10-31): the map's shape, a rectangle with corners left out.

    from map_shape import Shape        (standard library only; imported by the bakes and checks)

Until the map-north loop the map was one box (bake_osm.BBOX). Its north extension (Rondo
Radosława, Arkadia, Forest, Andersa to Dworzec Gdański) covers only the west part of the
strip north of the old edge, so the map is now the bounding rectangle (centrum.json `bounds`,
as before) minus the rectangles listed in `outside` (centrum.json `outside`; today one: the
box's north-east corner, east of the extension and north of the old edge).

A Shape is a tuple (x0, z0, x1, z1), the bounding rectangle, so code that unpacks or indexes
`rect` keeps working unchanged; what needs the real outline asks the Shape:

  contains(x, z)        inside the map (the edges count as inside)
  grow(d)               the map grown by d metres (shrunk for d < 0), as a Shape
  parts()               plain rectangles whose union is the map (for clipping)
  outline()             the map's outline, a polygon (clockwise seen from above, +z south)
  rim(x, z)             the distance from (x, z) to the outline
  clip_segments(a, b)   the pieces of segment a-b inside the map: 0, 1 or 2 (a, b) pairs
  meets(box)            whether a rectangle (x0, z0, x1, z1) overlaps the map (by area)

Every `outside` rectangle must hold one corner of the bounding rectangle (a notch); that is
all the extension needs and keeps the parts two rectangles.
"""


EPS = 0.05   # centrum.json writes the bounds to 0.1 m: an outside side this close to one is on it


def _clip(a, b, rect):
    """Liang-Barsky: (t0, t1) of the part of segment a-b inside rect (closed), or None."""
    x0, z0, x1, z1 = rect
    dx, dz = b[0] - a[0], b[1] - a[1]
    t0, t1 = 0.0, 1.0
    for p, q in ((-dx, a[0] - x0), (dx, x1 - a[0]), (-dz, a[1] - z0), (dz, z1 - a[1])):
        if p == 0:
            if q < 0:
                return None
            continue
        r = q / p
        if p < 0:
            t0 = max(t0, r)
        else:
            t1 = min(t1, r)
        if t0 > t1:
            return None
    return t0, t1


def _seg_dist(x, z, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    l2 = dx * dx + dz * dz
    t = 0.0 if l2 == 0 else max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / l2))
    px, pz = a[0] + dx * t - x, a[1] + dz * t - z
    return (px * px + pz * pz) ** 0.5


class Shape(tuple):
    """The bounding rectangle (x0, z0, x1, z1) with `outside`, the corner rectangles that are
    not map (see the module's docstring)."""

    def __new__(cls, rect, outside=()):
        s = super().__new__(cls, tuple(float(v) for v in rect))
        s.outside = tuple(tuple(float(v) for v in o) for o in outside)
        x0, z0, x1, z1 = s
        for o in s.outside:
            if not ((o[0] <= x0 + EPS or o[2] >= x1 - EPS) and (o[1] <= z0 + EPS or o[3] >= z1 - EPS)):
                raise ValueError("map_shape: an outside rectangle must hold a corner of the bounds: %r" % (o,))
        return s

    def __reduce__(self):
        return (Shape, (tuple(self), self.outside))

    # -- tests ----------------------------------------------------------------------------

    def contains(self, x, z):
        x0, z0, x1, z1 = self
        if not (x0 <= x <= x1 and z0 <= z <= z1):
            return False
        return not any(o[0] < x < o[2] and o[1] < z < o[3] for o in self.outside)

    def meets(self, box):
        """True when the rectangle box overlaps the map by some area."""
        for p in self.parts():
            if box[0] < p[2] and p[0] < box[2] and box[1] < p[3] and p[1] < box[3]:
                return True
        return False

    def grow(self, d):
        """The map grown by d metres (an outside rectangle's sides on the bounds move with
        them; its inner sides move the other way)."""
        x0, z0, x1, z1 = self
        out = []
        for o in self.outside:
            out.append((o[0] - d if o[0] <= x0 + EPS else o[0] + d, o[1] - d if o[1] <= z0 + EPS else o[1] + d,
                        o[2] + d if o[2] >= x1 - EPS else o[2] - d, o[3] + d if o[3] >= z1 - EPS else o[3] - d))
        return Shape((x0 - d, z0 - d, x1 + d, z1 + d), out)

    # -- geometry -------------------------------------------------------------------------

    def parts(self):
        """Plain rectangles whose union is the map: the bounds alone, or for a corner notch the
        full-width band beside it and the rest of the notch's side."""
        x0, z0, x1, z1 = self
        if not self.outside:
            return [tuple(self)]
        if len(self.outside) > 1:
            raise ValueError("map_shape: parts() handles one outside rectangle")
        o = self.outside[0]
        top = o[1] <= z0 + EPS
        band = (x0, o[3], x1, z1) if top else (x0, z0, x1, o[1])
        zr = (z0, o[3]) if top else (o[1], z1)
        side = (x0, zr[0], o[0], zr[1]) if o[2] >= x1 - EPS else (o[2], zr[0], x1, zr[1])
        return [r for r in (band, side) if r[2] > r[0] and r[3] > r[1]]

    def outline(self):
        """The outline: the bounds' corners clockwise from the north-west (+z south), each
        corner an outside rectangle holds replaced by its inner corner and the two points
        where its sides meet the bounds."""
        x0, z0, x1, z1 = self
        corners = [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]
        pts = []
        for k, c in enumerate(corners):
            o = next((o for o in self.outside if o[0] - EPS <= c[0] <= o[2] + EPS and o[1] - EPS <= c[1] <= o[3] + EPS), None)
            if o is None:
                pts.append(c)
                continue
            ix = o[2] if c[0] == x0 else o[0]
            iz = o[3] if c[1] == z0 else o[1]
            prev, nxt = corners[k - 1], corners[(k + 1) % 4]
            # The edge from the previous corner, the inner corner, the edge to the next one.
            pts.append((ix, c[1]) if prev[1] == c[1] else (c[0], iz))
            pts.append((ix, iz))
            pts.append((ix, c[1]) if nxt[1] == c[1] else (c[0], iz))
        return pts

    def rim(self, x, z):
        """Distance from (x, z) to the map's outline."""
        if not self.outside:
            x0, z0, x1, z1 = self
            return min(abs(x - x0), abs(x - x1), abs(z - z0), abs(z - z1))
        ring = self.outline()
        return min(_seg_dist(x, z, ring[k - 1], ring[k]) for k in range(len(ring)))

    def clip_segments(self, a, b):
        """The pieces of a-b inside the map, in order from a: [] or [(p, q)] or two."""
        t = _clip(a, b, self)
        if t is None:
            return []
        spans = [t]
        for o in self.outside:
            cut = []
            for s0, s1 in spans:
                u = _clip(a, b, o)
                if u is None or u[1] <= s0 or u[0] >= s1 or u[1] - u[0] <= 0.0:
                    cut.append((s0, s1))
                    continue
                if u[0] > s0:
                    cut.append((s0, u[0]))
                if u[1] < s1:
                    cut.append((u[1], s1))
            spans = cut
        dx, dz = b[0] - a[0], b[1] - a[1]
        return [((a[0] + dx * s0, a[1] + dz * s0), (a[0] + dx * s1, a[1] + dz * s1)) for s0, s1 in spans]


def of(data):
    """The Shape of a baked map (centrum.json or index.json: `bounds`, `outside`)."""
    return Shape(data["bounds"], data.get("outside", []))
