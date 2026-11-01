# Fabryka Norblina: spec

Site key `norblin` in `game/scripts/landmarks.gd` (`_build_norblin`). Written 2026-11-01 in a cloud thread from the
OpenStreetMap outline in `centrum.json` and the sites' public descriptions (no photo in the cloud).
Values marked *(photo check)* wait for the Mac's `refs/`. Shared helpers: `_works_walls`,
`_works_top`, `_works_chimney` (the brick works block, end of `landmarks.gd`).

## 1. Identity
1. **Restored brick factory halls** (Norblin, Bracia Buch i T. Werner, Żelazna 51/53, Wola).
2. **Glazed office storeys** floating over the halls (the developer's designs show seven floors).
3. **A brick chimney** standing in the court *(photo check: it is there, which corner)*.

## 2. Massing
The mapped outline (landmark `Modsen`, 63 x 53 m, a U round a court) is the footprint. Brick halls 12 m; three glazed storeys (3.6 m each, inset 1.8 m) over them; the tall mapped wing (OSM 43.9 m) two storeys higher; the chimney 36 m in the open court.

## 3. Facade, base to top
Plinth 1.6 m (grey), two rows of round-headed windows every 4.2 m (feet 1.3 and 7.0 m, springs 5.0 and 10.4 m), cream surrounds, a cornice 0.9 m.

## 4. Roof
Flat zinc grey under the glazed storeys, thin cream parapet on the glass.

## 5. Colour and material
| Part | Colour | Material code |
| --- | --- | --- |
| Brick | #9b4d39 | M_STONE |
| Trim, cornice | #d3c7ab | M_STONE |
| Window panes | #2f3a40 | M_GLASS |
| Glazed storeys | #9db4be | M_GLASS |

No new material or draw call.

## 6. Ground and night
The car is stopped by the outline's ring and the chimney's. KROWA 2.0, the milk bar, queues on the Żelazna front (crowds.gd `MILK`); the court holds the chill crowd (`chill_norblin`, 30 people, lunch to late evening). Open: the lit windows at night.

## 7. Detail level and budget
L2, triangle budget 1480. Shots: `--solo=norblin --solo-look=lit`, then in the city.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| halls | prism | 63 x 53 x 12 m | outline | M_STONE | 2 massing |
| plinth | grown ring | 1.6 m | the foot | M_STONE | 3 plinth |
| windows | arched panels x 2 rows | 4.2 m pitch | all long walls | M_GLASS | 3 facade |
| cornice | grown ring | 0.9 m | y 11.1..12 | M_STONE | 3 facade |
| glazed storeys | inset prism | 3 x 3.6 m | y 12..22.8 | M_GLASS | 2 massing |
| wing top | inset prism | 2 x 3.6 m | the 43.9 m wing | M_GLASS | 2 massing |
| chimney | frustum, 2 bands | 36 m, r 1.5 to 0.9 | the court | M_STONE | 1 identity |
