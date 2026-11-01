# Centrum Nauki Kopernik: log

Spec: [specs/kopernik.md](specs/kopernik.md). Site key `kopernik` (`landmarks.gd`
`_find_kopernik`, `_build_kopernik`, `_kop_windows`, `_kop_roof`, `_kop_planet`).

## 2026-11-01: skin to model (cloud thread)

- Before: a skin (LoD2's massing in dark grey with a green roof, `SKINS`); the planetarium a
  plain OpenStreetMap box at 7.6 m.
- After: L2 model from OpenStreetMap and LoD2 (no photos in the cloud): the block to LoD2's
  flat roof 13 m over the street (OSM says 7.6), dark grey-brown panels with windows scattered
  like pixels (lit warm at night), the river corner (OSM's part from 3.3 m) hanging 5 m over a
  glazed ground floor, the west wing and the link to the planetarium as low glass wings, the
  roof garden as raised lawns between one path along and four across, a parapet; the
  planetarium a black boulder (upright walls, then facets to an apex at 11.5 m).
- Checks: `check_spec` OK; `check_mesh_quality` 0 defects, 467 tris, budget 560;
  `check_landmarks` for the centre: tallest cell found, tap finds it, 12/12 car rays stopped,
  the heli blocked and landing beside it; `check_roads` one finding fewer than main (C9);
  `check_sites`, `check_eggs` (the dog's ball on the roof), `check_city_life` OK; bake_city OK
  (the prebuilt path).
- Scores: none yet (no photos in the cloud; art-director pass waits for the Mac).

## Still differs / photo check on the Mac

- The panels: colour, pattern, and how many windows (built: about four in ten slots).
- The overhang: which corner, how deep, how high (built: OSM's river corner, soffit 5 m).
- The planetarium: its height and facets (built: walls 6.5 m, apex 11.5 m).
- The garden: its real paths, trees and the ramps down to the boulevard.
