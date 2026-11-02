# Brama Główna Uniwersytetu Warszawskiego (the University's main gate): spec

Site key `brama_uw` in `game/scripts/landmarks.gd` (`_build_brama_uw`). Written 2026-11-01 in a cloud thread (BACKLOG K3) from the OpenStreetMap outline in `centrum.json`; no photo, no LoD2 here. Values marked *(photo check)* wait for the Mac's `refs/`. Pałac Kazimierzowski behind it is a kept skin (site `kazimierzowski`, pale yellow plaster, a card, no model). The gate's spot (-494.5, -684) is *not* confirmed: it is where the campus entrance opens in the street's east frontage.

## 1. Identity

The campus's door on Krakowskie Przedmieście 26/28 (the University since 1816): two stone pylons with urns, an iron gate, and iron railings on stone plinths to either side.

## 2. Massing

Frame: origin (-494.5, -684.0), u along the street (axis (0.364, 0.932), south), +v to the street (west). 28 m along the pavement: pylons at u -3.8 and 3.8 (2 m square plinth, 1.6 m shafts to 5.1 m, caps and urns to 6.6 m), end piers at u 14 and -14 to 2.8 m, the gate's 6 m between the pylons, 3.15 m tall with 7 bars to 3.4 m.

## 3. Facade

Pylons: a plinth band, a plain shaft, a cornice, a hipped cap and an urn. Railings: a 0.9 m stone plinth wall with five iron bars and a rail on top (to 2.3 m).

## 4. Roof

No roof; the pylon caps are small hips.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Stone | #d8cdb4 | M_STONE |
| Plinth | #b3a994 | M_STONE |
| Iron | #25282a | M_STONE |

No new material or draw call.

## 6. Ground and night

A collision ring along the whole 29 m (a car cannot enter the campus). Card: "Brama Główna Uniwersytetu". Open *(photo check)*: the gate's true spot and width, the pylons' shape and finials.

## 7. Detail level and budget

L2; 458 triangles measured, budget 550 (`check_mesh_quality.gd`).

Shot: `--at=-494.5,-684 --yaw=245 --pitch=-22 --size=40 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| pylons | 2 x (plinth, shaft, cornice, hip, urn) | 2 m plinth, 1.6 m shaft, 6.6 m high | u +-3.8 | M_STONE | 2 massing |
| gate | 2 rails, 7 bars | 6 m wide, 3.4 m high | between the pylons | M_STONE | 3 gate |
| plinth walls | 2 boxes | 9 x 0.6 m, 1.2 m high | u +-9.3 | M_STONE | 3 railings |
| end piers | 2 boxes | 1 m square, 3.1 m high | u +-14 | M_STONE | 3 railings |
| railings | 10 bars, 2 rails | 0.1 m bars, 1.4 m high | u 5.9..12.3 both sides | M_STONE | 3 railings |
