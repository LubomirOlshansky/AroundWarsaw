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

## 2026-11-01: the Mac's photo check applied (cloud thread)

The Mac session compared the first model with the photos in `refs/`; its findings, applied:
- The planetarium is copper-red perforated metal, not black: a faceted drum with leaning walls,
  its roof edge just over the block's roof (about 18 m over its own ground), a chamfered ring
  round a glazed clerestory (glowing at night) and a white dome about 17 m across. No apex.
- The block's fronts are vertical strips in warm, varied tones (dusty rose, beige-grey, grey, a
  few copper-red), with tall slits and multi-storey glazed bays, some slanted, not dark panels
  with pixel windows. The south-east end is glass behind a light steel frame of galleries and
  stairs.
- The roof garden: meandering paths round mixed beds (greens, ochre, dark shrub), concrete
  skylight craters (five of the seven fit the garden's width; one with a glazed pyramid), a
  teal glass strip on the city side of the southern half, a small glass pavilion at the south.
- A dark strip cantilevers 12 m over the court on the planetarium's side.
- Card: "obok miedzianoczerwone planetarium" / "the copper-red planetarium beside it".
- Checks: `check_mesh_quality` 0 defects, 1428 tris, budget 1720; `check_spec` OK.

## Third pass, 2026-11-01 (the Mac's re-check of main 7973386)

- The roof's seven features laid out 2 + 3 + 2 as in the orthophoto: two big hexagonal craters
  (15.6 m) 24 m in from the river wall of the wide north part, 25 m apart; 39 m further to the
  city a row of a crater on the outer edge, the glazed-pyramid crater and a small dark octagonal
  stair and lift head (9 m, not a crater); two more (14 and 12 m) down the south wing, 55 m apart.
  Craters are hexagons now. The row sits 8 m nearer the city than measured on the photo so it
  clears the planetarium notch's corner.
- The planetarium: its outline simplified to about ten sides with chamfered corners, and a dark
  glass clerestory ring (4.5 m wide, glowing at night) between the copper top and the white dome.
- Checks: `check_mesh_quality` 0 defects, 1478 tris, budget 1720.

## Still differs / photo check on the Mac (after the third pass)

- The steel frame's stairs; the south-east end stands close to the car park's building.
- The court under the cantilever is the map's paving.
- The river corner's glazed ground floor (kept, parked by the Mac check).

## Still differs / photo check on the Mac (first pass, now answered above)

- The panels: colour, pattern, and how many windows (built: about four in ten slots).
- The overhang: which corner, how deep, how high (built: OSM's river corner, soffit 5 m).
- The planetarium: its height and facets (built: walls 6.5 m, apex 11.5 m).
- The garden: its real paths, trees and the ramps down to the boulevard.
