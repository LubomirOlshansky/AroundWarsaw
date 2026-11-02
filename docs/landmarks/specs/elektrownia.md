# Elektrownia Powiśle: spec

Site key `elektrownia` in `game/scripts/landmarks.gd` (`_build_elektrownia`). Written 2026-11-01 in a cloud thread from the
OpenStreetMap outline in `centrum.json` and the sites' public descriptions (no photo in the cloud).
Values marked *(photo check)* wait for the Mac's `refs/`. Shared helpers: `_works_walls`,
`_works_top`, `_works_chimney` (the brick works block, end of `landmarks.gd`).

## 1. Identity
1. **A 1904 brick power station** on Dobra, a T of halls, now shops and a food hall.
2. **Two storeys of tall arches** in the walls.
3. **Chimneys** *(photo check: how many, where)*.

## 2. Massing
The mapped T outline (118 x 96 m) at 19 m (OSM says 14 m, the halls are taller *guess*); two chimneys of 48 m at the two ends farthest apart.

## 3. Facade, base to top
Plinth 1.6 m, two rows of tall arches every 5 m (feet 1.4 and 9.4 m, springs 7.4 and 15.6 m), cornice and parapet.

## 4. Roof
Flat zinc grey behind a 0.9 m parapet *(photo check: gabled halls)*.

## 5. Colour and material
| Part | Colour | Material code |
| --- | --- | --- |
| Brick | #9b4d39 | M_STONE |
| Trim | #d3c7ab | M_STONE |
| Windows | #2f3a40 | M_GLASS |

No new material or draw call.

## 6. Ground and night
The car is stopped by the ring and the chimneys. The yard to the east holds the chill crowd (`chill_elektrownia`, 34 people). The notebook's `stara_elektrownia` place is a known 331 m off its hint.

## 7. Detail level and budget
L2, triangle budget 1950. Shots: `--solo=elektrownia --solo-look=lit`, then in the city.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| halls | prism | T, 19 m | outline | M_STONE | 2 massing |
| windows | arched panels x 2 rows | 5 m pitch | all walls | M_GLASS | 3 facade |
| cornice | grown ring + parapet | 0.9 m | y 18.1..19.9 | M_STONE | 3 facade |
| chimneys | 2 frustums, 2 bands | 48 m, r 2.0 to 1.2 | far ends | M_STONE | 1 identity |
