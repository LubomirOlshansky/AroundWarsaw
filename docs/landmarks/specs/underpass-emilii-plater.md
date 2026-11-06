# The Emilii Plater underpass's entrances: spec

Site key `underpass` in `game/scripts/landmarks.gd` (`_build_sunken` with the site's key,
`_sunk_edges` styles `parapet` and `canopy_*`, `_sunk_mouth`, `_sunk_canopy`); the ground is
`map_builder.gd` SUNKEN (the `epl_*` entries); the walkers' ways in are `pedestrians.gd`
(`_portals`). Written 2026-11-06 from F's game screenshots of the crossing ("rework this entrance,
add stairs and arrange it like in real life with people going in and out"), street photos from
Mapillary (CC BY-SA 4.0, 2020-2026, `tools/street_photos.py`, refs/epl_ne, epl_nw, epl_n2, epl_s,
epl_s2; evidence only) and the mapped geometry in `centrum.json`: the walls round two wells
(`lines` 419, 421), the flights (`steps` 36, 76, 217, 220, 1093) and the footways that end at
their tops.

## 1. Identity

The pedestrian underpass under Aleje Jerozolimskie at Emilii Plater, which leads to Warszawa
Śródmieście and Centralna's passages. What makes it read:

1. **Stairs going down**: every entrance is a flight into the ground, not a box on the pavement.
2. **Granite parapets** about 1.1 m tall round the wells in the lawn (north-east) and on
   Centralna's forecourt (north-west).
3. **Steel canopies over the pavement flights**: Śródmieście's green ones with posters on the
   south side, and a dark one on the north side.
4. **People going in and out**: walkers go down into the passage's dark mouth and come up out of it.

## 2. Massing

| Volume | Plan | Heights |
| --- | --- | --- |
| North-east well | the mapped walls (line 421): a flight south to a landing, a second flight south into the passage | 1.7 m to the landing, 3.6 m at the mouth |
| North-west box | the mapped walls (line 419), open to the north where footway 8754 ends | one flight, 3.6 m down over 7 m |
| North pavement flight | steps 76, 2.8 m wide, a 2 m landing at its foot | 3.6 m down over 12.2 m |
| South pavement flights | steps 36 and 220, 2.8 m wide, facing each other | 3.6 m down over 11.8 and 11.9 m |
| Parapet | every ring edge that drops, in pieces up to 2 m | from floor - 0.3 m to the street + 1.1 m (+ 0.9 m under a canopy) |
| Canopy | over each pavement ring | posts every ~2.6 m, beams at the street + 2.8 m |
| Mouth | where the walk leaves the ring | 2.2 m wide, floor - 0.3 to floor + 2.3 m, lintel to + 2.55 m |

## 3. Facade, base to top

- **Parapet**: granite, one quad per piece on the well side from just under the floor; a coping
  0.3 m wide on top; a short face down to the band on the street side. No railing.
- **Treads**: risers about 0.16 m across the ring, alternate treads a shade darker.
- **Mouth**: a dark opening in the retaining face at the bottom of each flight, with a lighter
  lintel band. Walkers going in pass behind the face and under the street.
- **Canopy**: square steel posts on the low parapet, a beam along each side and across every
  bay; on the green canopies, posters behind glass in the two middle bays of each side.

## 4. Roof

The canopies' roofs are left open between their beams: glass there would hide the stair and its
people from the game's camera, and the frame alone reads as the canopy. The site stays out of the
roof grid (`_no_roof`).

## 5. Colour and material

| Part | Colour | Material |
| --- | --- | --- |
| Parapet face | #8e8a83 | M_STONE |
| Parapet coping | #a8a49c | M_STONE |
| Band | #cdc7bb | M_STONE |
| Treads | #c4beb1, risers darker | M_STONE |
| Mouth | #24272b, lintel #a8a49c | M_STONE |
| Green canopy | #2e5a45 | M_STONE |
| Dark canopy | #2b3035 | M_STONE |
| Posters | #d94f3d, #3f6fb0, #e8c547, #f2efe8, glass back #8fa9a6 | M_STONE |

## 6. Ground and night

The ground is `map_builder.gd`'s. Inside each ring, terrain_height is the floor: a flat landing,
or a stair from its top `a` to its foot `b`. A lower flight's top is set `top` metres under the
grid at `at` (the upper flight's top), so the landing and the next flight meet. The drawn ground
is lowered in 0.5 m sub-cells over each ring grown by one sub-cell's diagonal. The band, 1.6 m
wide, covers the trench that this leaves outside, so it stays clear of the kerbs. The mapped
walls on a ring are the site's: `_build_barriers` leaves them out, and they no longer stand at
1.9 m. The car collides with every walled edge from the floor to 0.6 m over the parapet, and the
stair tops stay open.

Walkers: each `walk` is a footway that joins the mapped footway at its street end. A walker
reaching the hidden end goes in: 70 % leave there, and the rest turn back. 12 % of spawns come up
out of a mouth that is in view. Heights come from the sunken floors, carried on past the mouth.

## 7. Detail level and budget

L2, triangle budget 3000 (2550 measured 2026-11-06 on the flat stub, `check_mesh_quality.gd`
BUDGET): five entrances, ~120 m of walled edge, six flights of treads, two canopy frames with
posters and one without. The site adds no material. The walkers are the pedestrians' MultiMesh,
so +0 draw calls.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| face | quad per piece | up to 2 m x the drop + 1.4 m | on each ring edge, facing in | M_STONE #8e8a83 | 2 parapets |
| coping | flat top, clipped at corners | 0.3 m wide | on the face, street side | M_STONE #a8a49c | 2 parapets |
| band | flat top on the grid, clipped | 1.3 m wide | past the coping | M_STONE #cdc7bb | 1 stairs |
| treads | prisms cut by the ring | riser ~0.16 m | each flight's ring | M_STONE #c4beb1 | 1 stairs |
| mouth | dark quad and lintel band | 2.2 x 2.6 m | where the walk leaves the ring | M_STONE #24272b | 4 people |
| posts | square beams | 0.1 m, to 2.8 m | both long sides, every ~2.6 m | M_STONE #2e5a45 / #2b3035 | 3 canopies |
| beams | square beams | 0.14 m along, 0.08 m across | at the street + 2.8 m | M_STONE #2e5a45 / #2b3035 | 3 canopies |
| posters | two-sided quads | a bay less 0.5 m x 1.7 m | two middle bays each side (green) | M_STONE posters / #8fa9a6 | 3 canopies |
