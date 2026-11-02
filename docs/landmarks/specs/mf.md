# Ministerstwo Finansów (Świętokrzyska 12): spec

Site key `mf` in `game/scripts/landmarks.gd` (`_find_mf`, `_build_mf`). Written 2026-11-01 in a
cloud thread from the OpenStreetMap outline (213 points, 11 000 m², height 17.5 m) and public
facts: Stanisław Bieńkuński and Stanisław Rychłowski, 1953-1956, socialist realism with art déco
and Renaissance and Baroque palace principles, pale pink-grey Suchedniów sandstone and terrazzo
plaster, a monument since 2012, the block between Świętokrzyska, Czackiego, Traugutta and
Krakowskie Przedmieście. There is no photo here: shapes beyond the outline and the colour are a
first pass *(photo check)*.

## 1. Identity

1. **A pale pink-grey stone palace** round a court that opens south to Świętokrzyska.
2. **The comb plan**: two wings reaching south, each ending in a transverse pavilion; the
   central block between them; the long wing running north-west.
3. **The central entrance** in the south face: a risalit of six pilasters over three doors and
   steps, raised above the roof in an attic.
4. **The court's round fountain**: the map's own (water and a driveway loop); not modelled here.

## 2. Massing

The mapped outline, `_simplify`d to 1.8 m (its 1.3 m pilaster notches go), 17.5 m high (OSM).
The central block's south face runs from (-506.7, -409.1) to (-586.1, -384.4), 83 m, parallel to
Świętokrzyska; the entrance frame sits on its middle: u along the face (east to west), +v into the
court. The two south pavilions are the 35 m transverse bars (edges from (-464.2, -336.0) to
(-497.5, -325.0) and from (-545.4, -310.1) to (-578.8, -300.1)), 13 m deep.

## 3. Facade, base to top

- **Ground floor** to 4.6 m: rusticated, a darker sandstone (#b9aca3), 1.4 x 3.1 m windows every
  3.6 m (1.0-4.1 m).
- **String course** at 4.6-5.0 m, 0.15 m proud.
- **Three upper storeys** to 15.2 m in plain sandstone (#d9ccc4), tall bays 1.7 m wide every 3.6 m
  (5.5-14.0 m; the glass shader's transoms every 4 m make the floors).
- **Cornice** at 15.2-15.9 m, 0.45 m proud, and a plain attic parapet 1.1 m (to 18.6 m).
- **Risalit** on the south face: u ±12, v -1.5..2.4, rusticated below, pilasters at u ±2.25,
  ±6.75, ±11.25 (0.9 x 0.7 m), five tall bays and three doors (u -4.5, 0, 4.5, 2.4 x 3.6 m), two
  small windows at u ±9, a cornice at 19.5-20.3 m (2.8 m over the roof).
- **Steps**: three, 20 m wide, 0.18 m each.

## 4. Roof

Flat dark green-grey sheet (#6b716f) behind the parapet; a hipped roof rising 3.4 m over each
south pavilion (the roof colour, 15 % lighter) *(photo check: whether the pavilions are raised)*.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls | #d9ccc4 (pale pink-grey) | M_STONE |
| Rusticated floor | #b9aca3 | M_STONE |
| Cornice, string course, pilasters, steps | #e7ded8 | M_STONE |
| Windows | #3b4650 | M_GLASS (lit at night) |
| Doors | #34393d | M_STONE |
| Roof | #6b716f, hips #7e8481 | M_STONE |

## 6. Ground and night

Car stops at the outline (`_collide`). The windows glow at night through the glass shader. The
court, its fountain and lawns are the map's.
Card: "Ministerstwo Finansów", PL "Gmach z lat 1953–56 przy Świętokrzyskiej. Tu liczą cudze
pieniądze.", EN "1953–56 on Świętokrzyska: where the country's money is counted."

## 7. Detail level and budget

L2, triangle budget 1870 (1555 measured plus 20 %, in `check_mesh_quality.gd`). Shots:
`--solo=mf --solo-look=flat` from the north (heading 0) and in the city from Świętokrzyska.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| base | prism of the outline | 4.6 m + 0.6 below | ring, y -0.6..4.6 | M_STONE #b9aca3 | 1 palace |
| walls | prism of the outline | 12.6 m | ring, y 4.6..17.5 | M_STONE #d9ccc4 | 1 palace |
| course | ring | 0.4 m | y 4.6..5.0 | M_STONE | 1 palace |
| cornice | ring | 0.7 m | y 15.2..15.9 | M_STONE | 1 palace |
| parapet | parapet | 1.1 m | y 17.5..18.6 | M_STONE | 1 palace |
| ground windows | panes every 3.6 m | 1.4 x 3.1 m | y 1.0..4.1 | M_GLASS | 1 palace |
| upper windows | panes every 3.6 m | 1.7 x 8.5 m | y 5.5..14.0 | M_GLASS | 1 palace |
| risalit | box and cornice | 24 x 3.9 m | u ±12, v -1.5..2.4, y to 20.3 | M_STONE | 3 entrance |
| pilasters | 6 boxes | 0.9 x 0.7 m | u ±2.25, ±6.75, ±11.25 | M_STONE | 3 entrance |
| doors, side windows | 8 panels | 2.4 x 3.6 m | v 2.43 | M_STONE, M_GLASS | 3 entrance |
| steps | 3 boxes | 20 m wide | v 2.4..5.4 | M_STONE | 3 entrance |
| pavilion roofs | 2 hips | 34 x 12 m, 3.4 m | on the south bars, y 18.6 | M_STONE | 2 comb plan |
