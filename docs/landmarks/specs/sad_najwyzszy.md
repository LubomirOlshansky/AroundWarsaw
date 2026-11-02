# Sąd Najwyższy (the colonnade): spec

Site key `sad_najwyzszy` in `game/scripts/landmarks.gd` (`_find_sad_najwyzszy`, `_build_sad_najwyzszy`,
`_sn_column`). Written 2026-11-02 from the Mac's Plac Krasińskich photo reports
(`docs/landmarks/photo-reports/pomnik_powstania.md` and `krasinskich.md` on branch
`claude/project-thread-conzxt`: photos `13_columns.jpg`, `01_whole_square.jpg`, `11_panorama.jpg`,
`08_kanaly_group.jpg` in `refs/pomnik_powstania/`, and `04_east_oblique_corner.jpg` in `refs/krasinski/`)
and the OpenStreetMap parts.

## 1. Scope

Only the **colonnade** is a model: the reports describe it (colour, ribs, lettering, capitals) and
OpenStreetMap maps every column. The court's main block (OSM "Sąd Najwyższy", 18 m) is drawn by its
GUGiK LoD2 model with its real roof and stays the map's. No photo report covers the main block's
fronts, the roof garden, the caryatids or the Świętojerska side, so they are not guessed (QUESTIONS).

## 2. What the photos say

- The columns are **green**, about **#738483** (green glass / patina), with **vertical ribs**.
- **Dark metal lettering** on the shafts' lower parts.
- **Capitals with relief rosettes**; a green band (the beam) on top at about 14 m.
- Behind them the court's wall is blue-black reflective glass (the LoD2 block's colour: not changed here).
- OSM tags the columns "marble #deeded", which drew them white: wrong.

## 3. Plan and heights (from OSM)

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

## 4. The model

| Piece | Heights over the column's ground | Colour |
| --- | --- | --- |
| Plinth (outline + 6 cm) | -0.3 to 0.5 m | #4f5c59 darkened |
| Lettering band (+1.5 cm) | 0.5 to 3.0 m | #4f5c59 |
| Shaft (the OSM box) | 3.0 m to 1 m under the top | #738483 |
| Ribs: two fins on every face, 10 cm wide, 8 cm proud | the shaft's height | #83948f |
| Capital (+14 cm) | the top metre | #8b9b95 |
| Rosette, one per face, 6-sided disc r 0.32 m, 6 cm proud | the capital's middle | #a9b5ab |
| Beams | 12 to 14 m, with a darker soffit | #6f807e, top #5c6b69 |

A column under a beam ends at the beam's underside, whatever the ground does. Each column keeps its
car collision (the map's did). One surface, no new draw call; 6669 triangles (budget 8000).

## 5. Left

- The main block's fronts and roof garden, the caryatids (Faith, Hope, Love), the Latin maxims'
  text, the night look of the glass: a Mac photo gather for Sąd Najwyższy itself (QUESTIONS).
- F's look check on the Mac or the phone: the green, the rib rhythm.
