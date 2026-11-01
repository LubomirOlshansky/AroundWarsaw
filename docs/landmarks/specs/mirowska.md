# Hala Mirowska (Mirowski Hall): spec

Site key `mirowska` in `game/scripts/landmarks.gd` (`_build_mirowska`, a model instead of a
skin). Written 2026-11-01 in a cloud thread from the OpenStreetMap parts in `centrum.json`
(the hall is mapped in 3D: about 330 small parts, colour #E37B42) and the hall's known look
(no photo here). Values marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

Stefan Szyller and Czesław Domaniewski's market hall (1899-1901), the western of the twin
halls on Plac Mirowski (the eastern is Hala Gwardii, a separate site, not modelled yet).

1. **Red brick walls** under cream pilasters, round-headed windows in every bay.
2. **A long nave roof** with a glazed lantern on the ridge.
3. **Thin tall gable ends** between four corner turrets with pyramid caps.

## 2. Massing

Plan frame: origin (-1857.4, -501.8) at the south-west corner, u east along the long side
(axis (0.970, -0.242)), +v to the north across the hall. The hall is 97.4 x 43.6 m; the
main front faces east, to the square. Heights above the ground, all from the mapped parts:
walls 10 m; annex (u 0..12.5) walls 4 m under a red hipped roof to 10 m; nave roof from 10 m
to a 14.5 m ridge over v 8.5..35.1; lantern u 18.4..80.5, v 16.7..27.7, top 17.4 m; gable
ends at u 7.7..9.1 and 88.7..90.1, apex 18 m; corner turrets 5 x 5 m, 10..15 m, caps to
18.8 m, at u 10.1 / 88.0 and v 11.3 / 32.3.

## 3. Facade, base to top

- **Plinth**: granite band, 1.7 m, 0.2 m proud, the whole foot.
- **Long sides** (north and south): 17 cream pilasters (pitch 4.56 m) and 18 windows, each
  a dark glass pane (2.3 m wide, 2.4..6.6 m, round head to 7.75 m) in a cream surround.
- **East front**: seven bays; the middle one a round-headed portal (1.3..5.6 m) with three
  steps, the six others windows; pilasters between; a cornice (9..10 m) round the main block.
- **West end**: the annex's low arcade, eight small arches.
- **Gable ends**: a window with a round head (11..13.8 m) in each, a pinnacle at the apex.

## 4. Roof

Nave: a gable roof in pale zinc (#8b948f) over the central 26.6 m; the aisles under flat grey
(#6d7470). Lantern: glass sides and a glass roof in two slopes. Annex: red tile (#a8493a).
Turret caps green-grey (#6f7f78).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls | #a85c40 | M_STONE |
| Pilasters, cornice, window surrounds, gable coping | #d6ccb4 | M_STONE |
| Plinth, steps | #857e74 | M_STONE |
| Window panes, portal | #323a40, #33271f | M_GLASS |
| Lantern | #a9bcc4 | M_GLASS, M_GLASS_ROOF |

No new material or draw call.

## 6. Ground and night

The car is stopped by the outline's ring. Card (kept): "Hala Mirowska", PL "Ceglana hala
targowa.", EN "A brick market hall." Open: the hall's name on the front, the market stalls
round it, the lit windows at night *(photo check: whether the lantern glows)*.

## 7. Detail level and budget

L2, triangle budget 1750 (1458 measured, plus about 20 %, in `check_mesh_quality.gd`). Shots:
`--solo=mirowska --solo-look=lit`, then in the city from Plac Mirowski.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | box | 85 x 43.6 x 10 m | u 12.5..97.4 | M_STONE | 2 massing |
| annex | box + hipped roof | 12.5 x 43.6 m, 4 m + 6 m | u 0..12.5 | M_STONE | 2 massing |
| plinth | 4 boxes | 1.7 m | the foot | M_STONE | 3 plinth |
| cornice | 3 boxes | 1 m | y 9..10 | M_STONE | 3 east front |
| pilasters | 20 + 8 boxes | 0.5 x 0.3 m | long sides, east | M_STONE | 3 long sides |
| windows | 18 + 18 + 6 + 8 | 2.3 m | the walls | M_GLASS | 3 |
| portal | arch + 3 steps | 3.4 m wide | east, v 21.8 | M_GLASS | 3 east front |
| nave roof | gable | 26.6 m, rise 4.5 m | u 9.1..88.7 | M_STONE | 4 roof |
| gable ends | 2 thin gables | rise 8 m | u 7.7, 90.1 | M_STONE | 3 gable ends |
| turrets | 4 boxes + pyramids | 5 x 5 m, 10..18.8 m | nave corners | M_STONE | 2 massing |
| lantern | box + glass roof | 62 x 11 m | the ridge | M_GLASS | 4 roof |
