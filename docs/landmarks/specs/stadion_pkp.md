# Warszawa Stadion (site `stadion_pkp`)

Written 2026-11-01 for F's railway ask (docs/design/railway.md, S3a). No reference photos in the
cloud; measured from the OpenStreetMap outlines in `centrum.json` ("Dworzec PKP Warszawa
Stadion", a 19 x 36 m hall at (1391, -1328) with a concave curved end towards the platforms; the
two side platforms north of it, about 200 m long) and the facts from published descriptions (the
2012 renovation article in Przegląd Komunikacyjny / Bilfinger, Wikipedia). The Mac photo check
(`refs/stadion_pkp/`) is open: the sail's shape and height, the hall's glazing, the canopies'
length and the mosaic's pattern.

## 1. Identity

Romanowicz and Szymaniak's stop of 1955-58 for the old Stadion Dziesięciolecia, renovated for
Euro 2012: a low white ticket hall at street level south of the platforms, its platform-side end
a curved white form "like a sail in the wind", a passage under the tracks, and two long side
platforms whose glazed wind walls carry a red-and-white mosaic in the National Stadium's colours
under a perforated metal roof.

## 2. Massing

- Hall: the OSM outline, a 0.5 m plinth, glass walls to 3.9 m, a 0.5 m white roof slab with a
  0.8 m overhang that sweeps up 1.5 m towards the sail's end (after the Mac photo check, where
  the flat slab read as a plain white box).
- Sail: along the outline's curved end (STP_SAIL), a white wall from the ground to 8.2 m at the
  tips and 7.1 m in the middle (above the roof's raised end), its top leaning 0.8-1.4 m out
  towards the platforms.
- Platforms: the map's two side platforms; a canopy 96 m long from each platform's hall end.

## 3. Facade, base to top

- Hall: glass (M_PAVILION, lit at night) in 1.8 m bays with dark mullions over a grey plinth.
- Canopies: dark posts every 8 m along the outer edge; the wind wall just inside them, red and
  white 2 m panels in two chequered rows (both faces) to 2.4 m, glass above to the roof.
- A white stair head at each platform's hall end, its dark opening facing along the platform
  (the stairs down to the passage).

## 4. Roof

- Hall: one white slab rising along the hall towards the sail (a parabola, STP_RISE 1.5 m), in
  faint 3 m panels, a fascia round its edge, a glass clerestory from the walls' top up to it, its
  soffit grey.
- Canopies: a 0.25 m light metal slab over the platform's whole width plus 0.3 m.

## 5. Colour and material

White #ecebe6, glass #56707e, red #c4252b, metal #b3b7bb, dark #2d3034, neon red. Everything in
the city's one building surface (M_STONE, M_PAVILION) plus one neon word (STADION in
`neon_signs.gd` LANDMARK_WORDS): no new draw calls beyond the sign's.

## 6. Ground and night

The tracks, the platforms and the forecourt are the map's own. At night the hall glows, STADION
burns red standing on its roof, facing the game's camera. Car collision round the hall and the
stair heads.

## 7. Detail level and budget

L3, budget 1900 triangles (in `check_mesh_quality.gd`; built 1648).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | prism | the outline, 0.5 m | the hall | grey | the hall's base |
| hall | glass prism + mullions | the outline, 3.9 m | (1391, -1328) | M_PAVILION | the ticket hall |
| roof | swept slab | outline + 0.8 m, 0.5 m, rising 1.5 m | over the hall | white | the roof lifting into the sail |
| sail | curved wall | 8.2 m tips, 7.1 m middle, lean 1.4 m | the outline's curved end | white | the sail |
| neon | sign | STADION | on the roof, camera side | red neon | the station's letters |
| canopies | slab + posts | 96 m x platform width, 3.8 m high | each platform's hall end | metal / dark steel | the platform roofs |
| mosaic | panels | 2 m x 1.2 m, two rows | each canopy's outer edge | red / white | the stadium's colours |
| stair_heads | box + opening | 7 x 3.2 m, 2.6 m | each platform's hall end | white / dark | the way down to the passage |
