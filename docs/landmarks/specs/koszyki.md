# Hala Koszyki: spec

Site key `koszyki` in `game/scripts/landmarks.gd` (`_build_koszyki`). Written 2026-11-01 in a cloud thread from the
OpenStreetMap outline in `centrum.json` and the sites' public descriptions (no photo in the cloud).
Values marked *(photo check)* wait for the Mac's `refs/`. Shared helpers: `_works_walls`,
`_works_top`, `_works_chimney` (the brick works block, end of `landmarks.gd`).

## 1. Identity
1. **A brick market hall of 1909** (Juliusz Dzierżanowski), reopened in 2016 as a food hall.
2. **Big round-headed windows** in the brick between cream trim.
3. **A glass lantern** along the ridge.

## 2. Massing
The mapped outline (83 x 90 m, a notch on Koszykowa) at 11 m; the lantern along the outline's long axis, 60 % of its length, 6.4 m wide, 11 to 13.6 m with a glass roof to 15 m.

## 3. Facade, base to top
Plinth 1.6 m, one row of arched windows every 4.4 m (foot 1.3 m, spring 6.0 m, half width 1.3 m), cornice 0.9 m.

## 4. Roof
Flat zinc grey under the lantern *(photo check: the real roof is an iron truss under glass)*.

## 5. Colour and material
| Part | Colour | Material code |
| --- | --- | --- |
| Brick | #a05643 | M_STONE |
| Trim | #d3c7ab | M_STONE |
| Lantern | #9db4be | M_GLASS, M_GLASS_ROOF |

No new material or draw call.

## 6. Ground and night
The car is stopped by the ring. The notch on Koszykowa holds the chill crowd (`chill_koszyki`, 30 people), the ramen queue stays the notebook's (`hala_koszyki`).

## 7. Detail level and budget
L2, triangle budget 1370. Shots: `--solo=koszyki --solo-look=lit`, then in the city.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| hall | prism | 83 x 90 x 11 m | outline | M_STONE | 2 massing |
| windows | arched panels | 4.4 m pitch | all walls | M_GLASS | 3 facade |
| cornice | grown ring | 0.9 m | y 10.1..11 | M_STONE | 3 facade |
| lantern | box + glass roof | 50 x 6.4 m, 11 to 15 m | ridge axis | M_GLASS | 1 identity |
