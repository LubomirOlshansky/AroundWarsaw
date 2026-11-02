# Hotel Polonia Palace: spec

Site key `polonia` in `game/scripts/landmarks.gd` (`_build_polonia`, shared builder `_palace_hotel`). Written 2026-11-01 in a cloud thread (hotels pass) from the OpenStreetMap outline in `centrum.json`; no photo, no LoD2 here. Values marked *(photo check)* wait for the Mac's `refs/`. The OSM outline is a 4.3 m shed, so the model builds the whole building (and its car walls).

## 1. Identity

The hotel of 1913 on Al. Jerozolimskie 45, the grand hotel that stood through the Uprising.

## 2. Massing

The mapped outline simplified (0.7 m), 25.5 m to the roof *(photo check: storeys)*. The shared east wall with Hotel Metropol carries no trim and no windows.

## 3. Facade, base to top

A plinth of rusticated courses (four or five, alternating tone) to 5.4 m with tall dark ground-floor openings; a balcony band over it (0.45 m out, 0.45 m deep); the upper floors in the M_MONUMENT window shader; a string course under the top floor; a cornice (frieze, then a ledge 0.8 m out); a parapet plinth. On the longest public front a forward bay 10 m wide stands 1 m out: the lit glass door between two trim surrounds, a canopy on two posts (two lamps), a dark board with the name in gold neon, and above it the cornice, an attic and a pediment *(photo check: where the real entrance is)*.

## 4. Roof

A slate mansard (inset 0.9 m to 2.8 m over 3.25 m) with a flat top, and a hipped dormer with a window every 4.4 m on every public front longer than 9 m.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Wall | #e6d9b2 | M_MONUMENT |
| Plinth | #b8a888 | M_STONE |
| Trim | #f2ebd8 | M_STONE |
| Slate | #5d5a57 | M_STONE |
| Canopy | #6b2a2f | M_STONE |
| Door | #f3d9a8 | M_PAVILION |

No new material or draw call.

## 6. Ground and night

The model builds the mass, so it brings its own car walls (8 along the simplified ring). The door glows and the name board burns gold at night. Card: "Hotel Polonia Palace". Open *(photo check)*: the facade's real colour, the entrance's position, the real storey count and mansard.

## 7. Detail level and budget

L2; 1202 triangles measured, budget 1450 (`check_mesh_quality.gd`).

Shot: `--at=-930,540 --heading=20 --size=45 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | simplified outline prism | 25.5 m high | ground to roof | M_STONE courses, M_MONUMENT | 2 massing |
| plinth | 4-5 stacked rings | 6 m high, 0.25 m out | ground | M_STONE | 3 facade |
| balcony band | ring | 0.45 m high, 0.45 m out | 5.4 m | M_STONE | 3 facade |
| cornice | 3 rings | 2 m high, up to 0.8 m out | 25.5 m, top | M_STONE | 3 facade |
| mansard | frustum | 3.25 m high | above the parapet | M_STONE | 4 roof |
| dormers | boxes with hips | 1.1 m wide | every 4.4 m on the mansard | M_STONE, M_GLASS | 4 roof |
| entrance bay | box | 10 m wide, 1 m out | longest public front | M_MONUMENT | 3 facade |
| canopy, board, pediment | boxes, gable | 7.4 m wide canopy | over the door | M_STONE | 3 facade |
