# Rynek Mariensztacki (the Rynek's relief panels): spec

Site key `mariensztat` in `game/scripts/landmarks.gd` (`_build_mariensztat`). Written 2026-11-01 in a cloud thread (BACKLOG M2) from the OpenStreetMap outline in `centrum.json`; no photo, no LoD2 here. Values marked *(photo check)* wait for the Mac's `refs/`. The houses themselves are M1's (Old Town palette in `map_builder`); the card is this site's.

## 1. Identity

The 1949 estate's market square: its south side, Mariensztat 19-25, six houses facing north across the Rynek, each with a relief panel on its street face (the estate's socialist-realist decoration). A placeholder composition until the Mac's photos name the real subjects.

## 2. Massing

Six panels, one per house, on the faces at z about -1334.4 (centres x -522.2, -506.9, -494.8, -482.8, -470.9, -457.3), each frame 4 m wide and 3.5 m high at 5.5..9 m, over a 0.9 m stone plinth with two thin pilasters up to it.

## 3. Facade

Frame (cream #efe6d2) round a terracotta field (#b0634a) 3.4 x 2.9 m; a pale sun (r 0.7 m, 8 sides) and two standing figures (0.56 m wide, 2 m tall) as relief boxes.

## 4. Roof

No roof of its own: the houses keep the M1 tile roofs.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Frame, figures, sun | #efe6d2 | M_STONE |
| Field | #b0634a | M_STONE |
| Plinth | #bdb08f | M_STONE |

No new material or draw call.

## 6. Ground and night

No collision. Card "Rynek Mariensztacki" (the estate rebuilt in 1949; the 1954 film "Przygoda na Mariensztacie"). Open *(photo check)*: the real reliefs' number, subjects and places; the well or fountain in the square (the map's fountain ring stays).

## 7. Detail level and budget

L2; 540 triangles measured, budget 660 (`check_mesh_quality.gd`).

Shot: `--at=-490,-1334 --yaw=0 --pitch=-20 --size=45 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | box | 4.6 x 0.2 m, 1.2 m high | per house, 0..0.9 m | M_STONE | 3 facade |
| pilasters | 2 boxes | 0.2 x 0.16 m, 4.6 m high | u +-1.95 | M_STONE | 3 facade |
| frame | box | 4 x 0.2 m, 3.5 m high | 5.5..9 m | M_STONE | 3 relief |
| field | box | 3.4 x 0.2 m, 2.9 m high | 5.8..8.7 m | M_STONE | 3 relief |
| figures | 4 boxes | 0.56 x 0.24 m, 1.5 and 0.5 m high | u +-1.1 | M_STONE | 3 relief |
| sun | disc | r 0.7 m, 8 sides | 7.8 m up, in front of the field | M_STONE | 3 relief |
