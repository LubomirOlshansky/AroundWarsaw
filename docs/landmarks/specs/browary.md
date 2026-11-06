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
Old buildings: flat zinc grey with a cream cornice. Offices (2026-11-02, photo report
`browary.md`): green sedum (#7c8f55) a step up inside a 1.6 m planted edge (#5e7444); on the north
slab (Biura przy Warzelni) a roof garden: a gravel walk down its length and two small garden houses.

## 5. Colour and material
| Part | Colour | Material code |
| --- | --- | --- |
| Old brick | #7d3b2c, #9b4d39 | M_STONE |
| Offices | #b3a894 | M_STONE |
| Bays, windows | #2f3a40 | M_GLASS |

No new material or draw call.

## 6. Ground and night
The car is stopped by each outline's ring. The Central Garden (the lawn OSM maps at x -2480..-2440,
z -123..-79; photo report `browary.md`): 22 tree crowns (the scan's 5 along the south edge and 17
young lindens, birches and maples, `planted_trees.py` PLACE `browary`), an S-shaped gravel path 2.4 m
wide from the south gate to the north slab and two clearings beside its bends, each with two white
tables, four chairs and a dark-blue parasol (`BROWARY_PATH`, `BROWARY_CLEARINGS`, the same numbers in
both files); 4 more trees by Willa Schielego. The yard west of the lawn holds the chill crowd
(`chill_browary`, 36 people). Open: the beer-hall vaults, the Brama's arch, the AK memorial boulder
(not located in the ortho), the Grzybowska plaza's granite grid.

## 7. Detail level and budget
L2, triangle budget 3800 (an exception to the L2 limit: six buildings in one site, plus the garden since 2026-11-02, 3725 tris; no new draw call). Shots: `--solo=browary --solo-look=lit`, then in the city.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| warzelnia | prism | 27 x 18 x 14 m | mapped | M_STONE | 1 identity |
| lab, villa | prisms | 8 m | mapped | M_STONE | 1 identity |
| offices | 3 prisms + glass bays | 22 to 30 m | mapped | M_STONE, M_GLASS | 1 identity |
| windows | arched panels | 3.4 m pitch | old walls | M_GLASS | 3 facade |
| chimney | frustum, 2 bands | 46 m, r 1.7 to 1.05 | Warzelnia corner | M_STONE | 1 identity |
| sedum roofs | inset prisms | 0.12 m | the offices | M_STONE | 4 roof |
| roof garden | gravel walk + 2 houses | 1.6 m, 3 x 3 x 2.6 m | north slab | M_STONE | 4 roof |
| garden path | gravel caps | 2.4 m wide | BROWARY_PATH | M_STONE | 6 ground |
| café clearings | 2 x (2 tables, 4 chairs, parasol) | r 3.6 m | BROWARY_CLEARINGS | M_STONE | 6 ground |

F's look check (2026-11-03): trees grouped (four clumps, tools/planted_trees.py groups), the path edged, the clearings paved in pale stone (BROWARY_CLEARING_R 4.2).
