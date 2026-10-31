# Biblioteka Uniwersytecka (BUW): spec

Site key `buw` in `game/scripts/landmarks.gd` (`_find_buw`, `_build_buw`, `_buw_front`,
`_buw_roof`). Written 2026-10-31 in a cloud thread from OpenStreetMap alone: the library's
outline (101 points, its Dobra front traced panel by panel), its eleven building parts with
heights, and the roof garden, which OpenStreetMap maps as 60 park and lawn areas inside the
outline, with the bare roof between them (the glass roofs). Until now the library was a skin:
LoD2's massing in one green. There is no usable free photo (`refs/` holds interiors only), and
the cloud reaches neither Commons nor GUGiK: the values marked *(photo check)* wait for the
Mac (or the user's own photo).

## 1. Identity

Marek Budzyński's and Zbigniew Badowski's library (1999) on Dobra in Powiśle, by the
boulevards. What makes a passer-by say its name:

1. **The copper pages on Dobra**: the front is a row of tall green-patina copper plates
   standing before the glass, covered in lines of old text (Greek, Hebrew, Arabic, Sanskrit,
   old Polish, music, mathematics).
2. **The four philosophers**: four slim columns before the entrance, a statue on each
   (Twardowski, Łukasiewicz, Tarski, Leśniewski) *(photo check: which front they stand at;
   built on Dobra, before the copper pages)*.
3. **The roof garden** (2002): lawns and beds in the mapped shapes over the whole roof, paths
   between them; what the helicopter and the cassette land on.
4. **The glass roofs in the garden**: the long glazed roof over the central hall with its
   green trusses, a second glass roof, two round glass lights.
5. **Green on glass**: the other fronts glass behind a patina-green trellis rising above the
   parapet.

## 2. Massing

Plan frame for the front: origin (-15.1, -965.9), the outline's west corner; u along Dobra,
axis (0.667, 0.745), to the south-east; +v out of the front (south-west). Heights above the
site's ground (the lowest terrain under the outline).

| Volume | Plan | Heights | Source |
| --- | --- | --- | --- |
| Block | the outline, straightened to 0.8 m (about 180 x 130 m, 11,000 m²) | 0 to 10.9 m | the roof garden's mapped parts, h 10.9 *(photo check: LoD2 may say higher)* |
| Copper screen | 12 plates, u 1.5 to 72.5, 5 m wide, 1 m apart, v 0.2 to 0.6 | 0 to 13.5 m | the outline's zigzag on Dobra (plates every ~6 m) |
| Long glass roof | 57 x 23 m, corners (29.2,-952) (80,-977.5) (90,-956) (40,-930.3) | 10.9 to 17.1 m | the bare band between the mapped lawns |
| Second glass roof | 18 x 19 m, corners (95,-985.8) (111.7,-994.2) (122.5,-972.5) (105,-964.7) | 10.9 to 15.9 m | the mapped part with no lawn on it |
| Round lights | r 8.2 m at (124.3,-947.1), r 4.1 m at (92.7,-970.4) | 10.9 to 16.7 and 14.3 m | the mapped round parts |
| Lift head | 6 x 6 m at (101.8,-952) | 10.9 to 14.0 m, cap to 14.8 | mapped part |
| Long roof house | the mapped 4.5 x 34 m part at (78,-998) | 10.9 to 14 m, cap to 14.8 | mapped part h 14 |
| Stair head | the mapped pentagon at (12,-958) | 10.9 to 14 m, cap to 14.8 | mapped part h 14 |

## 3. Facade, base to top

- **Dobra (u 0-75)**: the glass wall behind; before it the 12 copper plates from the pavement
  to 13.5 m (2.6 m over the roof). Plates 6 and 7 (u 31.5-42.5) start at 4.5 m: the entrance
  under them, dark glass doors. On each plate's face, lines of text: dark copper strokes 0.25 m
  tall every 0.9 m from 2 m to 12.6 m, each line a different length (a page, not a grid).
- **The other fronts**: glass (M_GLASS: mullions every 1.5 m, a floor every 4 m, lit
  windows at night) in a green tint, a patina-green trellis post every 6 m 0.3 m out, from
  the ground to 2 m over the roof (12.9 m).
- **Top**: a copper parapet, 1.1 m, round the roof's edge.

## 4. Roof

The deck at 10.9 m in pale paving: the paths. On it the garden: every mapped park and lawn
area inside the outline over 6 m², clipped to the outline and kept off the glass roofs, as a
bed 0.12 m over the deck (park areas darker green, lawns lighter), so the paths read between
them. The long glass roof: a low copper curb (0.8 m) and a glazed pitch (about 25 degrees) to
a ridge along its length at 17.1 m, with a green truss across it every 6 m. The second glass
roof: a curb (0.6 m) and a glass pyramid to 15.9 m. The round lights: copper curbs (0.9 m) and
glass cones (rise 0.6 x radius). The lift head, the roof house and the stair head: copper
boxes under low pyramid caps (0.8 m). The cassette (`cassettes.json` `c01_buw`) lies on the
roof's highest flat spot (`missions.roof_spot`: a 4 m cell whose neighbours are within a
metre): every glass roof and house slopes more than that, so the spot is in the garden
(checked: (95, -938)). *(photo check: the glass roofs' real pitch)*

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Glass walls | #7a978c | M_GLASS |
| Copper plates | #6f9c86, plates vary ±4 % | M_STONE |
| Text strokes | #3e6252 | M_STONE |
| Trellis, parapet, curbs, roof houses | #557f6b | M_STONE |
| Deck (paths) | #a9a799 | M_STONE |
| Beds | park #5f8f4a, lawn #78a85a, sides #55684a | M_STONE |
| Glass roofs | #9cbdb6 | M_GLASS_ROOF |
| Trusses | #4c7563 | M_STONE |
| Doors | #34423f | M_GLASS |
| Columns | #cfc9b8 | M_STONE |
| Statues | #4a4239 | M_STONE |

Calmer than life; the old skin's green (#7f9e8a) moves to the copper. No new material, no
draw call of its own.

## 6. Ground and night

The pavement on Dobra and the lower garden round the building stay the map's. The car
collides with the outline, the copper plates and the four columns (`tools/check_roads.py`
mirrors the outline). At night the glass walls light floor by floor, the glass roofs glow
from the halls under them, the copper stays dark. Card: "Biblioteka Uniwersytecka", PL
"Otwarta w 1999 roku. Miedziane strony z tekstami, ogród na dachu.", EN "Opened in 1999.
Copper pages of text out front, a garden on the roof."

## 7. Detail level and budget

L2 (a named landmark on the boulevards; the roof garden is a beat of the first ten minutes),
triangle budget 2250 (1860 measured after the build, plus about 20 %, in
`check_mesh_quality.gd` BUDGET; the beds and the text strokes are most of it). Shots:
`--solo=buw --solo-look=sil` and `flat` (the `first` set), the roof from the helicopter by
day with the cassette, and Dobra at night.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| block | outline prism | 180 x 130 m, 0-10.9 m | the outline | M_GLASS #7a978c | 5 green on glass |
| plates | 12 boxes | 5 x 0.4 m, 0-13.5 m | Dobra, u 1.5-72.5 | M_STONE #6f9c86 | 1 copper pages |
| text | quads | 0.25 m lines every 0.9 m | the plates' faces | M_STONE #3e6252 | 1 copper pages |
| doors | wall | 11 x 4 m | Dobra, u 31.5-42.5 | M_GLASS #34423f | 1 copper pages |
| columns | 4 columns + statues | r 0.35 m, 9 m + 2.2 m | Dobra, v 4, u 31-43 | M_STONE #cfc9b8, #4a4239 | 2 philosophers |
| trellis | posts | 0.3 m, every 6 m, to 12.9 m | the other fronts | M_STONE #557f6b | 5 green on glass |
| parapet | wall | 1.1 m | the roof's edge | M_STONE #557f6b | 3 roof garden |
| deck | cap | the outline | 10.9 m | M_STONE #a9a799 | 3 roof garden |
| beds | mapped caps | 0.12 m over the deck | the mapped lawns | M_STONE #5f8f4a / #78a85a | 3 roof garden |
| hall_roof | curb + glass pitch + 9 trusses | 57 x 23 m, to 17.1 m | the bare band | M_GLASS_ROOF #9cbdb6 | 4 glass roofs |
| light_roof | curb + glass pyramid | 18 x 19 m, to 15.9 m | the bare part | M_GLASS_ROOF #9cbdb6 | 4 glass roofs |
| rounds | 2 curbs + glass cones | r 8.2 and 4.1 m, to 16.7 and 14.3 m | the round parts | M_GLASS_ROOF #9cbdb6 | 4 glass roofs |
| houses | 3 copper boxes + caps | mapped, to 14.8 m | lift, roof house, stair | M_STONE #557f6b | 3 roof garden |
