# Dworzec Wodny: spec

Site `dworzec_wodny` in `game/scripts/landmarks.gd` (`_build_dworzec_wodny`, `_long_frame`).
Written 2026-11-01 in a cloud thread (the Powiśle boulevards). No photo reachable: the plan is
the OpenStreetMap outline "Dworzec Wodny" (6 corners, 440 m2, mapped 7.6 m high, centre about
632, -680, on the water just off the boulevard); the look is a guess *(photo check)* of a
low modern water station.

## 1. Identity

The Vistula's water station: a landing stage with a low glass-and-timber pavilion, where river
boats and the boulevard's water trips start. Replaces the mapped box.

## 2. Massing

Frame: the outline's long axis (about 40 x 11 m); `u` along it, `v` across (+v the land side). A
deck slab over the whole outline, 1.5 m under to 0.5 m over the ground; the pavilion on it: a
hall `u` +-(L/2 - 4.5) m, 5 m deep, 3 m high, offset 0.6 m to the land side *(photo check: size,
position on the stage)*. Roof 3.5 to 3.85 m, overhanging the hall 1.2 m along.

## 3. Facade, base to top

Skirt: dark steel-grey slab under a timber deck. Hall: glass (lit from inside at night) between
two timber end walls, 7 slim timber posts along the water front. Deck edge: a pale rail on both
ends and the water side, with 9 timber posts *(photo check: rail, whether the sides are open)*.

## 4. Roof

Flat, a timber fascia under a grey membrane; no equipment modelled *(photo check)*.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Skirt | #4c5559 | M_STONE |
| Deck, hall ends, fascia | #8e6b47 | M_STONE |
| Posts | #a98259 | M_STONE |
| Hall glass | #9dc0cc | M_PAVILION |
| Roof membrane, rail | #808a89, #c9ccc9 | M_STONE |

No new material or draw call.

## 6. Ground and night

Collision on the outline (the car stays on the quay). Card "Dworzec Wodny". The glass glows at
night through the existing M_PAVILION mode; no lights of their own. The stage sits on the mapped
ground under the outline: if the river bed there is lower than the quay on the real terrain the
skirt (1.5 m) reaches down *(photo check: the deck's height over the water)*.

## 7. Detail level and budget

L2. Measured 2026-11-01: 257 triangles, budget 310 (`check_mesh_quality.gd`). Shot: `--at=620,-655
--size=40 --pitch=-35 --yaw=60 --nohud --no-ghost --no-traffic`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| stage | prism on the outline | 40 x 11 m, 2 m | outline | M_STONE | 2 massing |
| hall | box | about 31 x 5 m, 3 m high | u 0, v +0.6 | M_PAVILION | 3 glass |
| ends | 2 boxes | 0.7 m thick, 3.05 m high | hall ends | M_STONE | 3 timber |
| posts | 7 boxes | 0.24 m square, 3.05 m | water front | M_STONE | 3 timber |
| roof | box | about 40 x 8 m, 0.35 m | 3.5..3.85 m | M_STONE | 4 roof |
| rail | 3 boxes, 9 posts | 0.7 m high | deck edge | M_STONE | 3 rail |
