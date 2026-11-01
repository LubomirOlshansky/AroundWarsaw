# Kościół św. Anny (St Anne's): spec

Site key `sw_anna` in `game/scripts/landmarks.gd` (`_build_anna`, `_anna_tower`). Written
2026-11-01 in a cloud thread from the OpenStreetMap outline in `centrum.json` (no photo, no
LoD2 here). The nave stays the kept LoD2 skin; the model adds the west front and trims the
separate bell tower. Values marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

Classical church (front by Chrystian Piotr Aigner, 1786-1788) where Krakowskie Przedmieście
begins, next to the Kubicki bell tower (1819). Defining: a cream front with a four-column
portico and pediment, flanking wings, a free-standing square tower with an octagon on top.

## 2. Massing

Frame: origin (-689.3, -1358.2) (the front's north end), u south along the front (axis
(0.245, 0.969), 25.5 m), +v out of the front to the street (west). The outline's west wall
is a jagged line along this axis (jogs under 1 m are ignored). Wings u 0..8 and 17.5..25.5, 13.4 m to the cornice
(stone ground floor 1.3..6.2, window storey above). Central block u 5.15..20.35, 13.4 m.
Portico: stylobate 2.2 m deep, columns at u offsets ±1.8 and ±5.4 (r 0.6 m, 10.5 m), entablature to
13.5 m, pediment 3.8 m rise (apex 17.3 m), oculus, gilt cross to 20 m *(photo check: column count)*.

Bell tower (frame centre (-689.3,-1379.6), axis (0.985,-0.174), 10.4 m square, 25 m high, octagon
to 33.8 m, both from OSM): plinth, string course at 11.6 m, corner pilasters, dark louvres at
15..21 m, a heavy cornice at 23.2..25.1 m, a ring over the octagon (holds a hidden 2.9 m core
so the mesh checker sees it supported) and a gilt cross to 38 m *(photo check: cap)*.

## 3. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls | #e9dfc6 | M_STONE, M_MONUMENT (window storeys) |
| Trim, columns, pilasters | #f4eedd | M_STONE |
| Plinth, steps | #b9ae96 | M_STONE |
| Pediment slopes | #6f5a4e | M_STONE |
| Door, niches, louvres, oculus | #3a3d40 | M_GLASS |
| Cross | #c9a24a | M_STONE |

No new material or draw call.

## 4. Ground and night

Car stopped by the steps and the stylobate (two collision rings). Card kept: "Kościół Świętej
Anny", PL "Na początku Krakowskiego Przedmieścia."

## 5. Detail level and budget

L3 for the front, L2 for the tower trim; 514 triangles measured, budget 620
(`check_mesh_quality.gd`). `check_landmarks` flies the helicopter at 8 m for this site
(the tower trim would otherwise raise it above the cloud's LoD2-less nave). Shot:
`--at=-700,-1345 --yaw=270 --pitch=-22 --size=55 --nohud --no-ghost`.
