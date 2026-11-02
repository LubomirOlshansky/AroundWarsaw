# Hortus: spec

Site key `hortus` in `game/scripts/landmarks.gd` (`_find_hortus`, `_build_hortus`). Written
2026-11-02 in a cloud thread from the OpenStreetMap outlines and heights and the published
description (iwaw.pl, urbanity.pl, office listings); no photo reachable and no LoD2 here, so the
colours and the pier rhythm are estimates *(photo check)*. It replaces the plain blocks the map
builder drew from the same outlines.

## 1. Identity

Hortus, Topiel 12 in Powiśle, built 2009-2011 (Naj studio: Beata Korwin-Szymanowska, Jadwiga
Romiszewska) on the plot of a sweet factory. A closed block between Topiel, Zajęcza and
Drewniana: offices on Topiel and Zajęcza ("big glass panes and a recessed ground floor"), flats
on Drewniana styled after a pre-war tenement, a garden with 12 m trees in the courtyard ("hortus"
is Latin for garden). Card: "Hortus", PL "Biura i kamienica wokół ogrodu, tam gdzie stała
fabryka cukierków. Hortus to po łacinie ogród."

## 2. Massing

- Offices: the outline OSM names "Hortus" (an L, about 95 by 80 m, 12-15 m deep), 20.8 m (OSM),
  simplified 0.35 m. The ground floor (to 4.5 m) is pulled in 1.4 m; the five floors above
  overhang it; a 0.6 m parapet band on top.
- Flats: the unnamed 20.8 m outline north of it on Drewniana (found by `HORTUS_FLATS_AT`
  (110, -580); its part is kept for the sector path by "Hortus" in `tools/bake_sectors.py`
  SITE_NAMES). Walls to 17.9 m, a cornice 0.35 m proud to 18.45 m, a mansard floor pulled in
  1.2 m to 20.8 m.
- The L's box centre lies in the courtyard, so the zone adds the outline's hull (only the garden
  is in it; its trees are the scanned ones).

## 3. Facade, base to top

Offices: dark glass ground floor (`S_DARK`, lit warm at night) behind white piers 0.5 m square
every ~7.5 m on the street sides (an edge whose outside falls outside the hull); above, big
panes in a white frame (`S_GRID`). Flats: warm plaster with tall windows between piers
(`M_MONUMENT`), a light cornice, a dark grey mansard.

## 4. Roof

Flat, grey `#8a8d90`, on both.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Office glass | #5c6f72 | M_SKIN S_GRID |
| Ground floor | #5c6f72 darkened | M_SKIN S_DARK |
| Piers, parapet | #e6e4de | M_STONE |
| Flats | #dcc6a3 | M_MONUMENT |
| Mansard | #5f6367 | M_STONE |

## 6. Ground and night

Car collision follows both outlines (the offices' full outline: the recess is not drivable).
Night: the ground floor and lit office floors (the skins).

## 7. Detail level and budget

L2, 488 triangles, budget 590. Shots: from Zajęcza (`--at=118,-494`), looking north and with
`--yaw=135 --pitch=-30` over the courtyard.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| lobby | prism | 0-4.5 m | outline pulled in 1.4 m | S_DARK | recessed ground floor |
| offices | prism | 4.5-20.8 m | mapped outline | S_GRID | glass in a white frame |
| parapet | prism | 0.6 m | mapped outline | M_STONE | |
| piers | 0.5 m square | 0-4.5 m | street sides every ~7.5 m, in the recess | M_STONE | |
| flats | prism | 17.9 m | Drewniana outline | M_MONUMENT | tenement look |
| cornice | prism | 0.55 m | flats + 0.35 m | M_STONE | |
| mansard | prism | 18.45-20.8 m | flats simplified 1 m, pulled in 1.2 m | M_STONE | |
