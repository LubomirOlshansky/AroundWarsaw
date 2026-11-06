# Sąd Najwyższy (the colonnade): spec

Site key `sad_najwyzszy` in `game/scripts/landmarks.gd` (`_find_sad_najwyzszy`, `_build_sad_najwyzszy`,
`_sn_column`). Written 2026-11-02 from the Mac's Plac Krasińskich photo reports
(`docs/landmarks/photo-reports/pomnik_powstania.md` and `krasinskich.md` on branch
`claude/project-thread-conzxt`: photos `13_columns.jpg`, `01_whole_square.jpg`, `11_panorama.jpg`,
`08_kanaly_group.jpg` in `refs/pomnik_powstania/`, and `04_east_oblique_corner.jpg` in `refs/krasinski/`)
and the OpenStreetMap parts.

## 1. Identity

The Supreme Court (Marek Budzyński and Zbigniew Badowski, 1999) closes Plac Krasińskich behind the
Uprising Monument. What makes it read from the square:

1. **A colonnade of green columns** (green glass / patina, about #738483), not white: OSM tags them
   "marble #deeded", which drew them white.
2. **Vertical ribs** on the shafts and **dark metal lettering** on their lower parts.
3. **Capitals with relief rosettes**, under a green band (the beams) at about 14 m.

Only the colonnade is a model: the reports describe it and OSM maps every column. The main block (OSM
"Sąd Najwyższy", 18 m) is drawn by its GUGiK LoD2 model and stays the map's. No report covers its
fronts, the roof garden, the caryatids or the Świętojerska side, so they are not guessed (QUESTIONS).

## 2. Massing

- 54 columns, OSM boxes about 2 x 2 m, 12 m tall (`h` 12, `mh` 0), "#deeded", in an L: the long wing
  from (-1208, -1696) to (-1285, -1724) along the monument's steps and the square, the short wing from
  (-1287, -1727) to (-1337, -1767) to the north-west.
- Four beams 12-14 m (`mh` 12, `h` 14) over them: three "#deeded" (centres (-1224, -1711),
  (-1249, -1706), (-1280, -1717)) and the north-west wing's, mapped without a colour (centre
  (-1316, -1763), `SN_WEST_BEAM`).
- The site picks them inside `SN_BOX` (x -1345..-1200, z -1790..-1690); the zone is the parts' own
  outlines, so nothing else (the LoD2 block, the small glass parts, the columns at (-1300, -1781)
  under the uncoloured beam there) is replaced. `tools/bake_sectors.py` SITE_AREAS carries the box for
  the streamed city.

## 3. Facade, base to top

Each column over its own ground: a plinth (outline + 6 cm, -0.3 to 0.5 m), the lettering band
(+1.5 cm, 0.5 to 3.0 m), the shaft (the OSM box, 3.0 m to 1 m under the top) with two ribs on every
face (10 cm wide, 8 cm proud), the capital (+14 cm, the top metre) with a six-sided rosette (r 0.32 m,
6 cm proud) in the middle of every face. A column under a beam ends at the beam's underside, whatever
the ground does.

## 4. Roof

The beams' flat tops (#5c6b69) at 14 m, a darker soffit under them. The court's own roof is LoD2's.

## 5. Colour and material

All M_STONE. Shaft #738483, ribs #83948f (sides a step darker), capital #8b9b95, rosettes #a9b5ab,
lettering band #4f5c59, plinth the same darkened, beams #6f807e. The glass behind (blue-black in the
photos) is the LoD2 block's and is not changed here.

## 6. Ground and night

Each column keeps its car collision (the map's did). Nothing lit at night (the photos show only the
monument's up-lights and the glass reading bluish); the night look is the city's.

## 7. Detail level and budget

L3 (the backdrop of a hero monument, 54 columns), 6669 triangles, budget 8000 (check_mesh_quality
BUDGET "sad_najwyzszy"). One surface, no new draw call. Shots: `--at=-1236,-1690 --yaw=0 --size=45
--pitch=-35 --no-ghost`, close `--at=-1215,-1690 --yaw=300 --size=20 --pitch=-20`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | prism | outline + 6 cm, 0.8 m | each OSM column | M_STONE #4f5c59 darkened | 2 the base |
| letters | prism | outline + 1.5 cm, 2.5 m | each column, 0.5-3.0 m | M_STONE #4f5c59 | 2 the lettering |
| shaft | prism | the OSM box | each column, 3.0 m to top - 1 m | M_STONE #738483 | 1 the green |
| ribs | fins | 0.1 x 0.08 m, 2 per face | each face at 1/3, 2/3 | M_STONE #83948f | 2 the ribs |
| capital | prism | outline + 14 cm, 1 m | each column's top metre | M_STONE #8b9b95 | 3 the capitals |
| rosette | disc | r 0.32 m, 6 sides | each face of the capital | M_STONE #a9b5ab | 3 the rosettes |
| beam | prism | the OSM beam, 2 m | 12-14 m over its ground | M_STONE #6f807e, top #5c6b69 | 3 the band |

## Left

- The main block's fronts and roof garden, the caryatids, the Latin maxims' text, the night look of
  the glass: a Mac photo gather for Sąd Najwyższy itself (QUESTIONS).
- F's look check on the Mac or the phone: the green, the rib rhythm.
