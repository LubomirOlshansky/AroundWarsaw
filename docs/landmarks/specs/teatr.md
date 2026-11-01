# Teatr Wielki: spec

Site key `teatr` in `game/scripts/landmarks.gd` (`_build_teatr`). Written 2026-11-01 in a cloud
thread from the OpenStreetMap outline and GUGiK's LoD2 (no photo here). Until now the opera was
a kept skin: LoD2's flat front in cream with a green roof. The mass stays that skin; the model
adds the front LoD2 flattens. Values marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

Antonio Corazzi's National Opera (1825-1833, rebuilt after 1944) on Plac Teatralny.

1. **The portico**: eight Ionic columns on a high rusticated base, under a heavy entablature.
2. **Wide steps** across the whole portico.
3. **An attic** over it, crowned by a sculpture group *(photo check: its subject and height)*.
4. Behind and beside, the kept LoD2 mass: wings, stage house, green roofs.

## 2. Massing

Plan frame: origin (-903.1, -952.5), the front's west end on the outline; u along the front
(axis (0.7956, -0.6058), 96.4 m), +v out of it to the square (south-east, (0.606, 0.796)). The
portico is centred at u 48.2 and stands 7 m out of the front. Base to 3.4 m, columns to 14.6 m,
entablature to 17.7 m, attic to 20.7 m, sculpture to 25 m. OSM maps the front's columns
(parts h 14 m over 5 m) in groups along the front; the model's eight stand in front of the
middle two groups.

## 3. Facade, base to top

- **Base**: u 33..63.4, v 0..7, rusticated stone, to 3.4 m. Steps: five, 0.5 m rise, v 7..11.
- **Columns**: eight, r 0.62 m, at u ±1.7, ±5.1, ±8.5, ±11.9 from the middle, v 4.6, 3.4..14.6 m.
- **Back wall**: slightly proud of the mass, five dark doors (2 x 4.4 m) in it.
- **Entablature**: architrave, frieze, cornice to 17.7 m, running back to the wall.

## 4. Roof

LoD2's green copper roofs, unchanged. The attic (u ±13.4, 2.6 m) and its sculpture block group
(five blocks, 2.4-4.6 m) top the portico.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Portico stone, entablature, attic | #eee6d0 | M_STONE |
| Base, steps | #cdc3a9 | M_STONE |
| Columns | #f1ead7 | M_STONE |
| Sculpture | #d9d2bf | M_STONE |
| Doors | #3a3d40 | M_GLASS |
| Mass behind | #ddd2b6 (skin) | M_MONUMENT |

## 6. Ground and night

Collision on the portico's footprint (steps stay drivable up to the base). Card (kept):
"Teatr Wielki", PL "Opera Narodowa. Gmach Antonia Corazziego z 1833 roku."

## 7. Detail level and budget

L3, triangle budget 600 (442 measured, in `check_mesh_quality.gd`). Shots: city, from the square.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| base | box | 30.4 x 7 m | u 33..63.4, y to 3.4 | M_STONE | 1 portico |
| steps | 5 boxes | 25 m wide | v 7..11 | M_STONE | 2 steps |
| columns | 8 on 8-sided shafts | r 0.62, 11.2 m | u 48.2 ± 1.7, 5.1, 8.5, 11.9 | M_STONE | 1 portico |
| back wall | box | 27 m wide | v -0.2..0.2 | M_STONE | 1 portico |
| doors | 5 panels | 2 x 4.4 m | u 48.2, ±3.4, ±6.8 | M_GLASS | 1 portico |
| entablature | 3 boxes | 28-29 m wide | y 14.6..17.7 | M_STONE | 1 portico |
| attic | 2 boxes | 27 m wide | y 17.7..20.7 | M_STONE | 3 attic |
| sculpture | 5 blocks | 2.4-4.6 m | y 20.7..25.3 | M_STONE | 3 attic |
