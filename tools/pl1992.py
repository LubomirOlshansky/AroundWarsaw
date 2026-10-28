"""Poland CS92 (EPSG:2180) <-> WGS84 latitude/longitude.

Transverse Mercator on GRS80 with the Krüger series: central meridian 19°E,
scale 0.9993, false easting 500 000 m, false northing -5 300 000 m.
GUGiK writes coordinates as "x y" = northing, easting.
"""
import math

A_AXIS = 6378137.0
FLAT = 1 / 298.257222101
LON0 = math.radians(19.0)
K0 = 0.9993
E0 = 500000.0
N0 = -5300000.0

_n = FLAT / (2 - FLAT)
_A = A_AXIS / (1 + _n) * (1 + _n ** 2 / 4 + _n ** 4 / 64)
_e = math.sqrt(FLAT * (2 - FLAT))
_alpha = (_n / 2 - 2 * _n ** 2 / 3 + 5 * _n ** 3 / 16, 13 * _n ** 2 / 48 - 3 * _n ** 3 / 5, 61 * _n ** 3 / 240)
_beta = (_n / 2 - 2 * _n ** 2 / 3 + 37 * _n ** 3 / 96, _n ** 2 / 48 + _n ** 3 / 15, 17 * _n ** 3 / 480)
_delta = (2 * _n - 2 * _n ** 2 / 3 - 2 * _n ** 3, 7 * _n ** 2 / 3 - 8 * _n ** 3 / 5, 56 * _n ** 3 / 15)


def to_pl1992(lat, lon):
    """Return (northing, easting) in metres."""
    phi = math.radians(lat)
    dl = math.radians(lon) - LON0
    t = math.sinh(math.atanh(math.sin(phi)) - _e * math.atanh(_e * math.sin(phi)))
    xi = math.atan2(t, math.cos(dl))
    eta = math.atanh(math.sin(dl) / math.sqrt(1 + t * t))
    north = xi + sum(a * math.sin(2 * j * xi) * math.cosh(2 * j * eta) for j, a in enumerate(_alpha, 1))
    east = eta + sum(a * math.cos(2 * j * xi) * math.sinh(2 * j * eta) for j, a in enumerate(_alpha, 1))
    return N0 + K0 * _A * north, E0 + K0 * _A * east


def from_pl1992(northing, easting):
    """Return (lat, lon) in degrees."""
    xi = (northing - N0) / (K0 * _A)
    eta = (easting - E0) / (K0 * _A)
    xi1 = xi - sum(b * math.sin(2 * j * xi) * math.cosh(2 * j * eta) for j, b in enumerate(_beta, 1))
    eta1 = eta - sum(b * math.cos(2 * j * xi) * math.sinh(2 * j * eta) for j, b in enumerate(_beta, 1))
    chi = math.asin(math.sin(xi1) / math.cosh(eta1))
    phi = chi + sum(d * math.sin(2 * j * chi) for j, d in enumerate(_delta, 1))
    lam = LON0 + math.atan2(math.sinh(eta1), math.cos(xi1))
    return math.degrees(phi), math.degrees(lam)


if __name__ == "__main__":
    n, e = to_pl1992(52.2318, 21.0060)
    lat, lon = from_pl1992(n, e)
    print(f"Palace of Culture: x={n:.1f} y={e:.1f} -> back {lat:.7f} {lon:.7f}")
