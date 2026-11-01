# Kościół Karmelitów (Carmelite church): spec

Site key `karmelici` in `game/scripts/landmarks.gd` (`_build_karmelici`). Written 2026-11-01 in a cloud thread (BACKLOG K1) from the OpenStreetMap outline in `centrum.json`; no photo, no LoD2 here. Values marked *(photo check)* wait for the Mac's `refs/`. The nave stays the kept LoD2 skin; the model adds the street front.

## 1. Identity

Church of the Assumption and St Joseph (Efraim Szreger and Jakub Fontana, 1761-1781) on Krakowskie Przedmieście, next to the Presidential Palace. Defining: a tall two-storey stucco front with pilasters, scrolls down to the ends, an attic and a small pediment under a gilt globe and cross.

## 2. Massing

Frame: origin (-597.0, -1043.5) (the front's north end on the outline), u along the front (axis (0.507, 0.862), 26 m, to the south-south-east), +v out of it to the street (west-south-west). The outline's west edge steps in 1.5 m jogs, so the front plane sits on its outermost points. Heights *(photo check)*: ground floor 9.2 m, entablature 10 m, upper storey 17 m (16 m wide), cornice 17.9 m, attic tiers to 21.2 m, pediment apex 22.9 m, globe 23.5 m, cross 26.4 m.

## 3. Facade

Plinth 1.6 m; six pilasters on the ground floor (u 3.5, 8, 12.4 each side of the middle), a central dark door (3 x 5.2 m) under a small cornice with three steps, two side doors, two windows; an entablature; an upper storey four pilasters narrower with a tall central window and two side windows; a cornice; the two-tier attic.

## 4. Roof

- **Pediment**: 7.2 m wide, rise 1.7 m on the attic, copper-grey slopes (#7d8a7c), with the gilt globe (r 0.95 m, 8 sides) and a cross 2.2 m tall on top.
- **Nave**: the kept skin's roof, #7d8a7c.
- **Scrolls**: two stepped blocks down each side from the upper storey to the ends, with a ball finial.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster | #e2d8c0 | M_STONE, M_MONUMENT (upper windows) |
| Trim | #f1eadb | M_STONE |
| Plinth, steps | #b3a994 | M_STONE |
| Door, windows | #3a3d40 | M_GLASS |
| Globe, cross | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

Car stopped by the steps (one ring). Card: "Kościół Karmelitów". Open *(photo check)*: the real front's colours (white and grey?), the number of pilasters, the scrolls' shape.

## 7. Detail level and budget

L3 for the front; 374 triangles measured, budget 450 (`check_mesh_quality.gd`).

Shot: `--at=-600,-1034 --yaw=245 --pitch=-20 --size=45 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | box | 26.6 x 1.4 m, 1.6 m high | u 13, v 0 | M_STONE | 3 plinth |
| ground floor | box | 26 x 1.2 m, 8.2 m high | u 13, 1..9.2 m | M_STONE | 3 ground floor |
| upper storey | box | 16 x 1.2 m, 7.8 m high | u 13, 9.2..17 m | M_MONUMENT | 3 upper storey |
| pilasters | 10 boxes | 0.8 x 0.6 m, 8.2 and 7 m high | u 3.5, 8, 12.4; 3.2, 7.4 | M_STONE | 3 facade |
| entablature, cornice | 2 boxes | 26.6 x 1.8 m; 16.6 x 1.8 m | 9.2..10, 17..17.9 m | M_STONE | 3 facade |
| scrolls | 4 boxes, 2 balls | 4 x 1.2 m and 2.8 x 1.2 m | u 9.5 and 10.6 each side | M_STONE | 3 facade |
| doors and windows | 7 dark panes | 3 x 5.2 m door; 1.8 x 3.6 m; 1.6 x 4 m | ground and upper storey | M_GLASS | 3 facade |
| portal cornice, steps | box and 3 boxes | 4 x 1.2 m; 6.8 to 4.8 m wide | u 13, in front of the door | M_STONE | 3 portal |
| attic | 2 boxes | 11.2 and 7.2 m wide, 1.8 and 1.5 m high | 17.9..21.2 m | M_STONE | 3 attic |
| pediment | gable | 7.2 m wide, rise 1.7 m | 21.2..22.9 m | M_STONE | 4 roof |
| globe and cross | 2 frustums, 2 boxes | r 0.95 m; cross 2.2 m | apex, 22.9..26.4 m | M_STONE | 4 roof |
