# Fabryka Norblina: spec

Site key `norblin` in `game/scripts/landmarks.gd` (`_build_norblin`). Written 2026-11-01 in a cloud thread from the
OpenStreetMap outline in `centrum.json` and the sites' public descriptions (no photo in the cloud).
Values marked *(photo check)* wait for the Mac's `refs/`. **Revised 2026-11-02 from the Mac's photo
report** `docs/landmarks/photo-reports/norblin.md` (GUGiK ortho; the photos show the halls' machines
and the pre-rebuild fronts): the site moved onto its real block, see 2 and 9. Shared helpers: `_works_walls`,
`_works_top`, `_works_chimney` (the brick works block, end of `landmarks.gd`).

## 1. Identity
1. **Restored brick factory halls** (Norblin, Bracia Buch i T. Werner, Żelazna 51/53, Wola).
2. **Glazed office storeys** floating over the halls (the developer's designs show seven floors).
3. **The court of big candelabra planes** north of the glazed internal street, and green roofs
   with garden terraces upstairs. (The first pass's chimney is gone: the ortho shows none.)

## 2. Massing
The mapped outlines of the block between Łucka, Żelazna and Prosta, OSM's `Plater` (east) and
`Galwan` (west), each with its court carved open as a notch from the glass street
(`tools/planted_trees.py` COURTS: Plater's 16 x 30 m, Galwan's 13 x 30 m). Brick halls 12 m; glazed
storeys (3.6 m each, inset 1.8 m) over them up to the mapped 50 m (ten storeys). The first pass used
OSM's `Modsen` north of Łucka, which is another block.

## 3. Facade, base to top
Plinth 1.6 m (grey), two rows of round-headed windows every 4.2 m (feet 1.3 and 7.0 m, springs 5.0 and 10.4 m), cream surrounds, a cornice 0.9 m.

## 4. Roof
Green sedum (#7c8f55) a step up inside a 1.4 m planted edge (#5e7444), a cream parapet, two grey
plant rooms (6 x 4 x 2.7 m) on the long axis. The garden terraces upstairs (report: x -2290..-2275,
z 140..160 and x -2315..-2300, z 135..150): a timber deck with four planters and small trees, pulled
onto the nearest roof.

## 5. Colour and material
| Part | Colour | Material code |
| --- | --- | --- |
| Brick | #9b4d39 | M_STONE |
| Trim, cornice | #d3c7ab | M_STONE |
| Window panes | #2f3a40 | M_GLASS |
| Glazed storeys | #9db4be | M_GLASS |

No new material or draw call.

## 6. Ground and night
The car is stopped by the outlines' rings (the courts are open). Trees (map data, `planted_trees.py`):
4 candelabra planes in Plater's court (x -2239..-2225, z 173..190), 3 young limes and maples on the
Żelazna front, 3 cherries along the glass street's south side, 2 in Galwan's west court. KROWA 2.0,
the milk bar, queues on Plater's Żelazna front (crowds.gd `MILK`); the chill crowd (`chill_norblin`,
30 people) stands at the court's mouth on the glass street. Open: the lit windows at night, the
climbers (no photo), the glass street's roof (the map's 2018 LoD2 halls stand on it).

## 7. Detail level and budget
L2, triangle budget 4500 (an exception to the L2 limit: two office blocks in one site, 2026-11-02, 4382 tris built; one material set, no new draw call). Shots: `--solo=norblin --solo-look=lit`, then in the city.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| halls | prisms | Plater and Galwan, 12 m | outlines | M_STONE | 2 massing |
| plinth | grown ring | 1.6 m | the foot | M_STONE | 3 plinth |
| windows | arched panels x 2 rows | 4.2 m pitch | all long walls | M_GLASS | 3 facade |
| cornice | grown ring | 0.9 m | y 11.1..12 | M_STONE | 3 facade |
| glazed storeys | inset prism | 10 x 3.6 m | y 12..48 | M_GLASS | 2 massing |
| sedum roof | inset prism | 0.12 m | 3.2 m inside each block | M_STONE | 4 roof |
| plant rooms | boxes x 2 | 6 x 4 x 2.7 m | long axis | M_STONE | 4 roof |
| terraces | deck + 4 planters + trees | 6.8 m | NORBLIN_TERRACES | M_STONE | 1 identity |
