# Rondo Dmowskiego (the island, the underpass stairs, the Patelnia mural): spec

Site key `rondo` in `game/scripts/landmarks.gd` (`_build_rondo`, `_rondo_island`, `_rondo_tube`,
`_rondo_arch`, `_rondo_mural`). Written 2026-11-02 from F's four references (two aerials, a night
aerial looking north up Marszałkowska, the city's traffic-organisation plan "Rondo R. Dmowskiego,
koncepcja organizacji ruchu"), free press photos and articles on Metro Centrum's canopies
(whitemad.pl, kb.pl 9 July 2026), and the mapped geometry in `centrum.json`: the ring
(`Rondo Romana Dmowskiego`, centre line about 35 m from the middle), the tram cross (ballast),
four lawns (the island's quarters, 24.8-26.5 m out), and twelve walled stairwells (`steps` and
`lines` k wall). Street furniture round it: `tools/bake_street_details.py` RONDO.

## 1. Identity

Warsaw's central roundabout, where Marszałkowska crosses Aleje Jerozolimskie, over the underpass
to Metro Centrum and Warszawa Śródmieście. What makes a passer-by say "Rondo Dmowskiego":

1. **The tram cross**: both tram lines cross in the middle of the island, so it reads as four
   quarters.
2. **The four bent flower beds**: in every quarter one long crescent of flowers (red or purple in
   summer) in a yellow rim, and a shorter bed of clipped shrubs nearer the middle; grey granite
   paving in concentric bands round them; no trees.
3. **The blue tubes**: every underpass stair wears Metro Centrum's 1990s half-barrel canopy of
   milky polycarbonate on blue steel arches (still standing in 2026; ZTM's replacement for the
   northern ones is only on paper, the Patelnia's later).
4. **The Patelnia's mural**: a long wall of colour by the sunken square.

The Rotunda, the hotel towers and the banks round it are their own sites (parody names only).

## 2. Massing

| Volume | Plan | Heights above ground |
| --- | --- | --- |
| Island paving | each quarter between the tracks (4 m either side of the cross) and the island edge, 25.2 m on the tracks to 26.8 m on the diagonals (over the mapped lawns, 24.8-26.6 m) | cap at 0.18 m (over the mapped lawn) |
| Paving bands | four rings, 7.6-8.4, 13.4-14.0, 21.2-21.8, 23.6-24.2 m | cap at 0.21 m |
| Flower bed | a crescent between 15.0 and 19.6 m over the quarter, ends cut flat 5 m off the tracks | rim 0-0.38 m, flowers 0.38-0.46 m |
| Shrub bed | a crescent between 9.4 and 11.8 m, ends 5 m off the tracks | rim 0-0.30 m, shrubs 0.30-0.72 m |
| Tube | over each stairwell's walled outline (8.6-9.6 m long), a half barrel of radius half the well less 0.1 m (1.8-2.9 m) springing from 1.0 m | sills 0-1.0 m, crown 2.8-3.9 m |
| M post | 0.9 m past the mouth, beside it | pole to 2.72 m, red square 2.7-3.54 m |
| Mural | the first 50 m of the Patelnia's south wall (1.9 m), its north face | 0.15-1.82 m |

## 3. Facade, base to top

- **Tubes**: blue sills along both walls; a skin of seven flat strips round the half circle; a
  blue arch every ~1.5 m (an annular band 0.12 m proud, heavier at the mouth); the deep end closed
  by a skin half-disc; the mouth open.
- **M post**: a grey pole, a red square lit at night with a white M (our own five-stroke shape, not
  the operator's logo) on both faces.
- **Mural**: panels 0.8-2.4 m wide in bold colours, each with a black-outlined disc, a diamond or a
  zigzag band; an original pattern, not the real artwork.

## 4. Roof

The tubes' crowns (the polycarbonate skin, the cool pavilion glass, M_PAVILION + 0.5); the
island has no roof. The site's triangles stay out of the roof grid (`_no_roof`): no cassette or
helicopter landing on a canopy or a flower bed.

## 5. Colour and material

| Part | Colour | Material |
| --- | --- | --- |
| Paving | #b4b0a7 | M_STONE |
| Bands | #86827b | M_STONE |
| Bed rim | #e2b23c (yellow), #d97a2b (orange, shrub beds) | M_STONE |
| Flowers | #c42b3a red / #7a52b8 purple by quarter, lighter speckles | M_STONE |
| Shrubs | #3f6b2f | M_STONE |
| Tube skin | #d6e4ee | M_PAVILION + 0.5 (cool pavilion glass) |
| Tube steel | #2457a8 | M_STONE |
| M square | #c8171f, M #fbf7ee | M_LAMP (glows at night) |
| Mural | #f2c12e, #e8562a, #d6338a, #2fb3c9, #5bbf4a, #7a4fc2, #f08fb8, #2a62d1, white, #1d1d24 | M_STONE |

## 6. Ground and night

The island sits on the mapped lawn (the paving covers it); the laser scan's tree crowns on it go
(`tree_free`, 27.5 m). At night the tubes' skin is the cool pavilion glass (it reads blue under the
night light, not lit up: a phone look check decides if it should glow) and the M squares glow red. The street furniture (PRASA kiosk by the Patelnia stairs, an
ice-cream cart in the south-west, a tram shelter on the east Jerozolimskie island) is the street
details' (actors' material, one mesh per cell). The roundabout's lanes, crossings and stop lines
are the road bake's (no change).

## 7. Detail level and budget

L2, triangle budget 7000 (6272 measured 2026-11-02, `check_mesh_quality.gd` BUDGET): an exception
to the L2 range of 3000, because the site is a whole square: the island (~2300), twelve tubes with
their posts (~290 each) and a 50 m mural (~500).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| paving | cap per quarter | to the island edge | y 0.18 | M_STONE #b4b0a7 | 1 tram cross |
| bands | four ring strips per quarter | 0.6-0.8 m wide | y 0.21 | M_STONE #86827b | 2 beds |
| bed | crescent prism, rim and flowers | r 15.0-19.6 m | y 0-0.46 | M_STONE #e2b23c / #c42b3a / #7a52b8 | 2 beds |
| speckle | 0.44 m squares on a 1.3 m grid | on the flowers | y 0.50 | M_STONE lighter flowers | 2 beds |
| shrubs | crescent prism, rim and shrubs | r 9.4-11.8 m | y 0-0.72 | M_STONE #d97a2b / #3f6b2f | 2 beds |
| skin | 7 strips and a half-disc | well length x radius 1.8-2.9 m | over each stairwell, from y 1.0 | M_PAVILION + 0.5 #d6e4ee | 3 tubes |
| arches | annular bands | 0.12-0.2 m wide, 0.12 m proud | every ~1.5 m | M_STONE #2457a8 | 3 tubes |
| sills | two boxes | well length x 0.18 m | y 0-1.0 | M_STONE #2457a8 | 3 tubes |
| mpost | pole and red square with a white M | 0.84 m square | mouth + 0.9 m, beside | M_LAMP #c8171f | 3 tubes |
| mural | panels with discs, diamonds, zigzags | 0.8-2.4 m x 1.7 m | Patelnia south wall, north face | M_STONE palette | 4 mural |
