# Hotel Bristol (the corner tower): spec

Site key `bristol` in `game/scripts/landmarks.gd` (`_build_bristol`). Written 2026-11-01 in a cloud thread (BACKLOG K5) from the OpenStreetMap outline in `centrum.json`; no photo, no LoD2 here. Values marked *(photo check)* wait for the Mac's `refs/`. The mass stays the kept LoD2 skin (sand plaster, brown roof); the model adds a round tower with a copper dome at the street corner.

## 1. Identity

The grand hotel of 1901 (Krakowskie Przedmieście 42/44): the rounded street corner rises into a round tower with a copper dome, lantern and spire.

## 2. Massing

Centre (-557.8, -894.0) on the mapped corner, which rounds at about 4 m radius. A 12-sided drum r 3.4 m from the ground (inside the mass) to 32.4 m (the roof at OSM's 27.4 m, so a LoD2 roof a metre higher or lower shows no gap), eight pilasters, a ring cornice at 32.4..33.2 m, the dome to 37.4 m, lantern to 39.6 m, spire to 42.4 m, a gilt ball and tip to 43.4 m *(photo check: is the dome on this corner, its height)*.

## 3. Facade

Drum with plaster walls and eight small pilasters; the cornice ring r 4.2 m; the dome in two frustums (r 3.9 to 3.1 to 1.4 m); a lantern (r 0.9 m, M_MONUMENT); a spire to a gilt ball.

## 4. Roof

Copper dome and spire (#6f9382).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster | #e4d2b4 | M_MONUMENT |
| Trim | #f1eadb | M_STONE |
| Copper | #6f9382 | M_STONE |
| Gilt | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

No collision of its own (the hotel's mapped walls are the car's). Card: "Hotel Bristol". Open *(photo check)*: tower position, the dome's profile, the facade's real colours and its mansard.

## 7. Detail level and budget

L2; 334 triangles measured, budget 400 (`check_mesh_quality.gd`).

Shot: `--at=-557.8,-894 --yaw=245 --pitch=-22 --size=45 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| drum | 12-gon prism | r 3.4 m, 32.4 m high | ground to 32.4 m | M_MONUMENT | 2 massing |
| pilasters | 8 prisms | r 0.3 m, 6.4 m high | round the drum, 26..32.4 m | M_STONE | 3 facade |
| cornice ring | 12-gon prism | r 4.2 m, 0.8 m high | 32.4..33.2 m | M_STONE | 3 facade |
| dome | 3 frustums | r 3.9 m to 1.4 m | 33.2..37.4 m | M_STONE | 4 roof |
| lantern | prism | r 0.9 m, 1.6 m high | 38..39.6 m | M_MONUMENT | 4 roof |
| spire, ball | frustums | r 1 m to 0.1 m; ball r 0.5 m | 39.6..43.4 m | M_STONE | 4 roof |
