# Muzeum Powstania Warszawskiego: spec

Site key `mpw` in `game/scripts/landmarks.gd` (`_find_mpw`, `_build_mpw` and the `_mpw_*`
helpers). Written 2026-11-02 from F's Mac photo pass: `refs/mpw/` (gitignored) holds 25 Wikimedia
Commons photos (SOURCES.md: authors and licences), the GUGiK orthophoto (0.085 m/px) and
REPORT.md / PARTS.md in game coordinates. Heights from photos and LoD2 (the halls 12-20 m, the
tower's square at x -2905..-2898, z 191..199). It replaces LoD2's and OSM's blocks for the
museum, the office block, the gatehouse, the KASA pavilion, the Tobruk (mapped as a 14 m box)
and four 4 m "buildings" on the line of the Wall of Remembrance.

## 1. Identity

1. **The tram power station of 1904-1908** (OSM "Elektrownia Tramwajów Miejskich"), the Warsaw
   Rising Museum since 2004: orange-red Romanesque-revival brick on Przyokopowa, round arches,
   cream attics and frieze.
2. **The observation tower** at the halls' south-east corner: a concrete shaft whose east face
   leans out as a wedge carrying the white Kotwica, a black mesh platform and cabin at 28-31.5 m,
   the flag.
3. **The Wall of Remembrance** in Freedom Park: a long, gently curved black granite wall with
   the bell "Monter" in a recess.

Card: "Muzeum Powstania Warszawskiego", PL "Dawna elektrownia tramwajowa z 1908 roku. Wieża z
Kotwicą, a w Parku Wolności Mur Pamięci z nazwiskami poległych." No humour on this card.

## 2. Massing

Frame: u east, v south from the outline's NW corner (-2955.1, 160.4), turned 2.4 degrees with
the west wall (the east edge then sits at u 57.7 all along).

- West leg on Przyokopowa: W1 (north corner block, u -0.8..9.5, v 0..12, brick to 15 m, cream
  attic to 19 m), W2 (the arcade hall, u 0..18, v 12..63.5 plus its north end u 9.5..18,
  v 4.5..12, brick to 14 m, attic to 15.5 m), W3 (south corner block, u -0.8..18.3, v 63.5..73.5,
  to 15 / 17 m). The corner blocks stand 0.8 m forward of the hall.
- Low yard wing: u 9.5..52.3, v 0.3..4.5, 7 m.
- Halls in pale render: M1 (u 18..40.6, v 4.5..23, eaves 12, ridge 16.5), M2 (v 27..44.5,
  ridge 16), E1 (u 40.6..57.7, v 4.5..23, ridge 17), E2 (v 27..45, eaves 11, ridge 15), a cross
  gable between them (v 23..27, ridge 14).
- Tower: u 48.8..55.8, v 32.7..40.7.
- Office block: 22 x 13.2 m at (-2931, 130), turned 14.7 degrees, eaves 12.5 m, hip to 17 m.
- Gatehouse x -2959..-2949.6, z 142.3..148.4; KASA pavilion x -2911.5..-2904.5, z 139.5..151.

## 3. Facade, base to top

- W2 street front: brick piers every 4.6 m (0.6 x 0.3 m); in each of the 11 bays two small
  arched windows (0.84 m, sill 0.8, spring 2.3) under one brick archivolt, a small arch over them
  (sill 4.0, spring 4.8), a tall fan window (2.4 m wide, sill 6.2, spring 9.4); the 4th bay from
  the north blind (a cream arch, no glass); a cream frieze 12.2-13.6 m; the cream attic.
- W1: three floors (sills 1.0 / 5.4 / 9.6) of arched windows, a single and a pair to the street,
  one to the north; the city's arms (cream disc, red centre) at 12.4 m on the street face.
- W3: three narrow windows per floor to the street, two to the south.
- W2 yard side: four tall windows to the gravel court.
- Low wing: the museum's doors (three, under a cream arch) and nine small arched windows to the
  yard.
- Halls: the red steel grids (six posts, four rails) on E1's and E2's park gables, a door and
  three small windows in E1's gable, arched windows along the south wall of M2 and E2.
- Office block: brick with cream pilaster strips between window columns, four floors of windows.
- Gatehouse: brick, three stepped pinnacles. KASA: three cream blind arches round the door.

## 4. Roof

Flat dark grey `#8f9396` behind the attics on the west leg with a pale light strip on W2;
grey-blue standing-seam metal gables `#8394a0` on the halls; the low wing flat `#55585c`;
the office block's hip in orange tile `#b5683f` with two brick chimneys; the gatehouse's gable
dark metal, the KASA's grey metal.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Brick | #b4553f | M_STONE |
| Archivolts | #8a4a3c | M_STONE |
| Attics, frieze, blind arches | #d9cdb5 | M_STONE |
| Halls' render | #a09b94 | M_STONE |
| Glass | #3a4248 | M_GLASS |
| Gable grids | #9a2a25 | M_STONE |
| Tower concrete | #8a8a88 | M_STONE |
| Tower steel, mesh | #2a2523 | M_STONE |
| Kotwica | #f2f0ea | M_STONE |
| Light under the platform | #bfd8ff | M_LAMP |
| Wall of Remembrance | #3a3b3d | M_STONE |
| Office roof tile | #b5683f | M_STONE |

No new material or draw call (the city's one building surface).

## 6. Ground and night

Car collision: the museum's outline, the office block, the gatehouse, the KASA, the fence runs
and the Wall of Remembrance. The brick fence on Przyokopowa (1.2 m wall, cream coping, posts
every 6.5 m with tile caps, black railing to 2.35 m) runs 3 m out from the west wall from z 155
to 235 and from 114 to 142; the black steel gate between z 148 and 155. The Tobruk is a low
concrete shell at OSM's spot (-2926, 117) (*photo check*: the museum's own bunker may stand
elsewhere in the park). Night: the windows (M_GLASS), the blue-white light under the tower's
platform (M_LAMP).

## 7. Detail level and budget

L3, 2673 triangles, budget 3200. Shots: from Przyokopowa `--at=-2970,195 --yaw=90`, from
Towarowa over the park `--at=-2843,190 --yaw=270`; `--prebuilt` for the sector path.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| w1 | prism + attic | 10.3 x 12 m, 15 / 19 m | NW corner | M_STONE | 2 massing |
| w2 | prism + attic | 18 x 51.5 m, 14 / 15.5 m | Przyokopowa | M_STONE | 1 identity |
| w3 | prism + attic | 19.1 x 10 m, 15 / 17 m | SW corner | M_STONE | 2 massing |
| piers | 11 boxes | 0.6 x 0.3 x 14 m | W2 front, 4.6 m pitch | M_STONE | 3 facade |
| fan windows | arched panels | 2.4 m, sill 6.2 | W2 front, 10 + 1 blind | M_GLASS | 1 identity |
| small arches | arched panels | 0.84 m in pairs | W2 ground floor | M_GLASS | 3 facade |
| frieze | panel | 1.4 m | W2 front, 12.2 m | M_STONE | 3 facade |
| corner windows | arched panels | 1.1 / 0.9 m | W1, W3 | M_GLASS | 3 facade |
| arms | two discs | r 0.8 / 0.5 | W1 street face, 12.4 m | M_STONE | 3 facade |
| low wing | prism | 42.8 x 4.2 x 7 m | yard side | M_STONE | 2 massing |
| doors | arched panels | 3 x 1.4 m | low wing, u 12.4-16.6 | M_GLASS | 6 ground |
| halls | prisms + gables | eaves 11-12, ridges 14-17 | behind W2 | M_STONE | 4 roof |
| grids | beams | 6 posts + 4 rails | E1, E2 east gables | M_STONE | 3 facade |
| tower frame | 4 columns + braces | 0.4 m, to 14 m | tower corners | M_STONE | 1 identity |
| shaft | prism | 7 x 8 m, 14-27.5 m | halls' SE corner | M_STONE | 1 identity |
| wedge | frustum | 7 m wide, 0 to 1.5 m out | shaft's east face, 12-27.5 m | M_STONE | 1 identity |
| kotwica | 9 strokes | 5.5 x 3.9 m | on the wedge, 20 m | M_STONE | 1 identity |
| platform | slab + mesh rail | 9 x 9 m | 28 m | M_STONE | 1 identity |
| cabin | box | 5 x 5 x 3.5 m | on the platform | M_STONE | 1 identity |
| platform light | thin box | 7 x 7 m | under the platform | M_LAMP | 6 night |
| flag | pole + 2 quads | 4.5 m, 2.5 x 1.6 m | cabin roof | M_STONE | 1 identity |
| office | prism + hip | 22 x 13.2 m, 12.5 / 17 m | (-2931, 130) | M_STONE | 2 massing |
| office strips | panels | 1.2 m | between window columns | M_STONE | 3 facade |
| gatehouse | prism + gable + 3 pinnacles | 9.4 x 6.1 m, 6.5 m | at the gate | M_STONE | 6 ground |
| kasa | prism + gable + 3 arches | 7 x 11.5 m, 5.5 m | in the yard | M_STONE | 6 ground |
| fence | low wall, posts, railing | 1.2 / 2.5 m | 3 m off the west wall | M_STONE | 6 ground |
| gate | slab between posts | 6.3 x 2.5 m | z 148-155 | M_STONE | 6 ground |
| tobruk | frustum | r 1.8 m, 0.7 m | (-2926, 117) | M_STONE | 6 ground |
| wall of remembrance | mitred band | 0.6 x 4 m, about 125 m | (-2903, 141) to (-2848, 255) | M_STONE | 1 identity |
| bell | recess + frustum | 1.8 x 2.2 m, bell 0.9 m | (-2873, 204), west face | M_STONE | 1 identity |
