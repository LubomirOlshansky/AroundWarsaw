# Warszawa Powiśle (site `powisle`)

Written 2026-11-01 for F's railway ask (docs/design/railway.md, S2). No reference photos in the
cloud; measured from the OpenStreetMap outlines in `centrum.json` ("Dworzec PKP Powiśle", a
24 x 20 m outline at (171, 89) over the tunnel's east mouth; the round roof outline of r 10.6 m
at (401, -6) with a r 8 m building under it; the two side platforms between them) and the facts
from published descriptions (whitemad.pl, archiweb.cz on the lower pavilion's 2013 refit,
Wikipedia). The Mac photo check (`refs/powisle/`) is open: the arches, the saucer's profile,
the canopies' length and the neon's letters.

## 1. Identity

Two little 1960s pavilions at either end of a station on an embankment: the upper one a glass
hall under a white roof stretched between two concrete arches and sagging between them ("a kite
floating in the air"), at the Aleje level by the Poniatowski Bridge, right over the cross-city
tunnel's mouth; the lower one a round glass drum under a white saucer with its rim turned up
(the "UFO"), the café-club "Warszawa Powiśle" with the station's name in red neon on the rim.
Romanowicz and Szymaniak, designed 1954-55, opened 1963.

## 2. Massing

- Upper pavilion: the OSM outline's frame (about 24 x 20 m), floor at the Aleje level (the
  highest ground under it), a 6 m plinth down the escarpment's falling side.
- Its glass hall set back 1.6 m under the roof's edges.
- Lower pavilion: a glass drum r 7.8 m, 3.4 m tall, at the street level by Kruczkowskiego.
- Platforms: the map's two side platforms on the embankment; a canopy 72 m long over the
  middle of each.

## 3. Facade, base to top

- Upper: glass (M_PAVILION, lit warm at night) up to the roof's underside in 1.8 m panels with
  dark mullions; the tops follow the roof.
- Lower: glass drum with dark mullions every 2 m.
- Canopies: X-shaped steel supports every 7.2 m (two dark beams crossing in the platform's
  cross-section), a thin white slab on top.

## 4. Roof

- Upper: a 10 x 10 grid; height over the floor 3.4 m at the side edges rising to 7.2 m along the
  middle (a parabola across), sagging 0.9 m between the two arches (the gutter). Two concrete
  arch ribs (0.45 m) along the ends, springing from the floor past the corners.
- Lower: an inverted dome, a shallow saucer of r 10.6 m: rim 4.5 m over the floor, the middle
  0.8 m lower, a 0.45 m rim face, a grey underside sloping up from the drum to the rim.

## 5. Colour and material

White #e6e4dd (roofs, arches, canopy slabs), grey #8d9095 (undersides, plinth), dark #2f3236
(mullions, X supports), glass #5d717c, neon red. Everything in the city's one building surface
(M_STONE, M_PAVILION) plus one neon word (`neon_signs.gd` LANDMARK_WORDS): no new draw calls
beyond the sign's.

## 6. Ground and night

The embankment, the rails, the platforms and the tunnel's mouth are the map's own (portals are
item L3). At night both halls glow warm, the neon WARSZAWA POWIŚLE burns red on the saucer's
rim on the side the game's camera sees. Car collision round the upper hall (from the plinth's
foot to 4 m over the floor) and round the drum.

## 7. Detail level and budget

L3, budget 1770 triangles (in `check_mesh_quality.gd`; built 1470).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | prism | the upper outline, 6 m | under the upper hall | grey | the escarpment's edge |
| upper_hall | glass panels | outline - 1.6 m | the upper outline | M_PAVILION | glass up to the roof |
| upper_roof | grid 10 x 10 | 3.4-7.2 m, sag 0.9 m | over the upper outline | white / grey | the kite between two arches |
| arches | beams | 0.45 m | the roof's two ends | concrete | the arches the roof hangs from |
| drum | glass prism | r 7.8 m, 3.4 m | (400.8, -6.3) | M_PAVILION | the round ticket hall, now a bar |
| saucer | rings | r 10.6 m, rim 4.5 m, dish 0.8 m | over the drum | white / grey | the inverted dome |
| neon | sign | WARSZAWA POWIŚLE | on the rim, camera side | red neon | the bar's letters |
| canopies | slab + X supports | 72 m x 4.8 m, 3.6 m high | each side platform's middle | white / dark steel | the X canopies |
