# Browary Warszawskie: spec

Site key `browary` in `game/scripts/landmarks.gd` (`_build_browary`). Written 2026-11-01 in a cloud thread from the
OpenStreetMap outline in `centrum.json` and the sites' public descriptions (no photo in the cloud).
Values marked *(photo check)* wait for the Mac's `refs/`. Shared helpers: `_works_walls`,
`_works_top`, `_works_chimney` (the brick works block, end of `landmarks.gd`).

## 1. Identity
1. **The old Haberbusch i Schiele brewery buildings** in dark brick: the Warzelnia (brewhouse), the Laboratorium and Willa Schielego.
2. **New office blocks between them** (Biura przy Bramie, Warzelni, Willi) in warm grey with brick bases.
3. **The brewery chimney** by the Warzelnia *(photo check: count and place)*.

## 2. Massing
Six mapped outlines (the site's zone): Warzelnia 14 m, Laboratorium and the villa 8 m, the offices 22 m (Biura przy Warzelni) and 30 m (the others; OSM 37 m at the gate block, kept at 30 m *guess*). Chimney 46 m at the Warzelnia's far corner.

## 3. Facade, base to top
Old buildings: plinth, narrow arched windows every 3.4 m in one or two rows, cream cornice. Offices: brick base 3 m, warm grey wall, glass bays every 3 m from 3.4 m up (`_bays`), a parapet.

## 4. Roof
Flat zinc grey with a cream cornice or parapet; no pitched roofs yet *(photo check)*.

## 5. Colour and material
| Part | Colour | Material code |
| --- | --- | --- |
| Old brick | #7d3b2c, #9b4d39 | M_STONE |
| Offices | #b3a894 | M_STONE |
| Bays, windows | #2f3a40 | M_GLASS |

No new material or draw call.

## 6. Ground and night
The car is stopped by each outline's ring. The yard between the blocks holds the chill crowd (`chill_browary`, 36 people). Open: the beer-hall vaults, the Brama's arch.

## 7. Detail level and budget
L2, triangle budget 3600 (an exception to the L2 limit: six buildings in one site). Shots: `--solo=browary --solo-look=lit`, then in the city.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| warzelnia | prism | 27 x 18 x 14 m | mapped | M_STONE | 1 identity |
| lab, villa | prisms | 8 m | mapped | M_STONE | 1 identity |
| offices | 3 prisms + glass bays | 22 to 30 m | mapped | M_STONE, M_GLASS | 1 identity |
| windows | arched panels | 3.4 m pitch | old walls | M_GLASS | 3 facade |
| chimney | frustum, 2 bands | 46 m, r 1.7 to 1.05 | Warzelnia corner | M_STONE | 1 identity |
