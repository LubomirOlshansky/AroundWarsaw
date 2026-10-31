# Zachęta – Narodowa Galeria Sztuki: spec

Site key `zacheta` in `game/scripts/landmarks.gd` (`_find_zacheta`, `_build_zacheta`). Written
2026-10-31 in a cloud thread from the user's street photo of the front (May 2017, taken face on
from the square), the OpenStreetMap outline and GUGiK's LoD2 heights. Until now the gallery was a
skin: LoD2's massing in an ochre that the photo shows is wrong (it is white). Values marked
*(photo check)* wait for the Mac's `refs/` (no photo of the back or the roof here).

## 1. Identity

Stefan Szyller's gallery (1898-1900) on Plac Małachowskiego, Holy Trinity's dome beside it.

1. **A white classical front** of two floors over a basement: a rusticated ground floor, tall
   windows above, a cornice and a balustrade.
2. **The centre**: two pylons framing two giant grey columns before three dark doors.
3. **The pediment** over an attic (ARTIBVS), its tympanum full of white sculpture.
4. **End pavilions** standing forward under ornaments; **steps** between two candelabra.
5. Behind, the top-lit halls' **glass roof**.

## 2. Massing

Plan frame: origin (-833.4, -593.3), the middle of the front; u along the front, axis
(0.3339, 0.9426), from its north end (u < 0) to the church's end; +v out of the front (east).
Body u -24..23, v -45..0 (the outline: 47 x 45 m). From the photo (1 px = 0.0326 m): basement
3.0 m, rusticated ground floor to 8.2 m, band to 8.8 m, upper floor to 14.6 m, cornice to 15.3 m,
balustrade to 16.6 m; pylons to 17.0 m; attic to 18.4 m (cornice 18.8 m), pediment apex 23.0 m.
LoD2 agrees: walls 17-18 m, the halls' roof 22-24 m.

## 3. Facade, base to top

- **Front windows** (photo): wings u ±9.8, ±13.4, ±17.0, pavilions u ±20.4. Basement 1.1 x
  1.2 m (0.7-1.9 m), ground floor 1.5 x 3.0 m (4.2-7.2 m), upper 1.6 x 3.4 m (9.6-13.0 m). The
  centre: three doors (1.9 x 5 m, 1.8-6.8 m) at u -4.2, 0, 4.1 and three upper windows over them.
  Arched heads are drawn square *(photo check)*.
- **Pylons**: u ±(5.4..8.6), 1.2 m forward, to 17.0 m.
- **Columns**: u ±2.2, 1.6 m out, on pedestals to 3.4 m, shafts to 15.2 m, r 0.62 m.
- **End pavilions**: u -24..-18.2 and 17.2..23, 0.5 m forward, an attic to 17.4 m, an
  acroterion (a stone pyramid) to 19.2 m.
- **Sides and back**: the same bands; the upper floors in tall windows between piers
  (M_MONUMENT) *(photo check: rhythm)*.

## 4. Roof

Flat grey behind the balustrade at 15.3 m; over the halls a white block (u -11..9,
v -36..-8, to 19 m) under a glass hip roof to 23.8 m (LoD2: 22-24 m) *(photo check: ortho.jpg)*.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls, pylons, cornices, pediment | #ebeae4 | M_STONE (front), M_MONUMENT (other faces) |
| Basement and rusticated base, steps | #d4d3cd (basement a step darker) | M_STONE |
| Columns | #b9bab5 | M_STONE |
| Windows | #3d4850 | M_GLASS |
| Doors | #4a3328 | M_STONE |
| Sculpture, acroteria | #f4f3ee | M_STONE |
| Roof | #8d9092 | M_STONE |
| Halls' glass | #9fb0b8 | M_GLASS_ROOF |
| Candelabra | #2f3331, lamps #f3e3b0 | M_STONE, M_LAMP |

## 6. Ground and night

Steps 12 m wide, four of 0.45 m, 4 m out; the candelabra on pedestals before the pylons
(u ±7, v 3), lit at night (M_LAMP). The square's paving and lawns are the map's. Card (kept):
"Zachęta", PL "Galeria sztuki w gmachu z 1900 roku.", EN "An art gallery in a building of 1900."

## 7. Detail level and budget

L3, triangle budget 720 (about 600 measured, plus 20 %, in `check_mesh_quality.gd`). Shots:
`--solo=zacheta --solo-look=sil` and `flat`, in the city from the square (the photo's angle).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | four walls in three bands | 47 x 45 m | u -24..23, v -45..0, y -0.5..15.3 | M_STONE, M_MONUMENT | 1 front |
| band | ring | 0.18 m proud, 0.6 m | y 8.2..8.8 | M_STONE | 1 front |
| cornice | ring with the roof | 0.5 m proud | y 14.6..15.3 | M_STONE, roof #8d9092 | 1 front |
| balustrade | parapet | 1.3 m | y 15.3..16.6 | M_STONE | 1 front |
| windows | 32 flush panels | listed in section 3 | 7 cm proud | M_GLASS #3d4850 | 1 front |
| doors | 3 panels | 1.9 x 5 m | u -4.2, 0, 4.1 | M_STONE #4a3328 | 2 centre |
| pylons | 2 boxes | 3.2 x 1.2 m | u ±7, y to 17 | M_STONE | 2 centre |
| columns | 2 on pedestals | r 0.62, 11.8 m | u ±2.2, v 1.6 | M_STONE #b9bab5 | 2 centre |
| entablature | 2 boxes | 17.2 x 3 m | y 15.2..18.4 | M_STONE | 3 pediment |
| attic | box | 17.2 x 2.6 x 2 m | y 16.4..18.4 | M_STONE | 3 ARTIBVS attic |
| pediment | gable | 19.2 m wide, 4.2 m high | front v 2.5, y 18.8..23 | M_STONE | 3 pediment |
| sculpture | 5 blocks | 0.9 to 3.1 m tall | tympanum, v 2.45..2.85 | M_STONE #f4f3ee | 3 frieze |
| raking | 2 beams | 0.45 m | along the pediment's edges | M_STONE | 3 pediment |
| pavilions | 2 boxes, attic, acroterion | 5.8 x 0.5 m forward | u -21.1, 20.1 | M_STONE | 4 pavilions |
| steps | 4 boxes | 12 x 1-4 m | v 0..4 | M_STONE #d4d3cd | 4 steps |
| candelabra | pedestal, post, 3 lamps | 1.4 m pedestal, 6 m | u ±7, v 3 | M_STONE, M_LAMP | 4 steps |
| halls | box and glass hip | 20 x 28 m | u -1, v -22, y 15.3..23.8 | M_STONE, M_GLASS_ROOF | 5 glass roof |
