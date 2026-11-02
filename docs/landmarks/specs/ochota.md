# Warszawa Ochota (site `ochota`)

Written 2026-11-01 for F's railway ask (docs/design/railway.md, S1). No reference photos in the
cloud; the plan is measured from the OpenStreetMap outline "Warszawa Ochota" in `centrum.json`
(a 17.4 x 17.4 m square at (-2310, 928)) and the facts from published descriptions
(architekturaibiznes.pl "Ikony polskiej architektury: Warszawa Ochota"; Wikipedia). The Mac
photo check (`refs/ochota/`) is open: the stripes' direction, the supports, the stairs.

## 1. Identity

A thin white concrete saddle (a hyperbolic paraboloid) floating over a small glass box at the
edge of the railway cutting by Plac Zawiszy: two opposite corners lift high, two dip low, and
under it the shell is black-and-white stripes. Arseniusz Romanowicz and Piotr Szymaniak,
1962-63, on the monuments register. Seen from the isometric camera: the white saddle against the
dark cutting and the tracks under it.

## 2. Massing

- The hall: the OSM square, 17.25 m a side, its u axis across the tracks (the outline's longest
  edge), +u the street side (higher ground), v along the tracks.
- The deck: a 1.1 m slab at street level (the highest ground across the cutting) from the shell's
  far corner over the cutting to 15 m past the hall on the street side, as wide as the hall plus
  0.8 m; two piers down into the cutting under the hall's edges.
- The shell over a square of the hall's half size + 1.4 m (about 20 m a side).

## 3. Facade, base to top

- A black-and-white mosaic band, 0.6 m tall, 0.6 m tiles, round the hall at the floor.
- Glass (M_PAVILION, lit warm at night) from the band up to the shell's underside: each wall a
  trapezoid, because the shell's edges are straight lines.
- Dark steel mullions every ~1.7 m from the band to the shell.

## 4. Roof

A deep saddle (after the Mac photo check, 2026-11-01): a bilinear patch on 14 x 14 rulings,
its high corners at 10.6 m over the deck and its low corners at 3.0 m, with the middle sagging a
further 1.1 m (`OCH_SAG`), 0.16 m thick at its edges, which follow the shell. The high diagonal is
the one whose far corner lies away from the game's camera, so the whole top reads. Stripes along
one family of rulings: black and white underneath (the mosaic), white and light grey on top (the
game's camera never sees the underside). The blue WARSZAWA OCHOTA letters stand on a dark steel
frame (two posts and a bar, 4.2 m) by the entrance on the street side. Supports: the two low corners on raked concrete struts with footing blocks on the deck,
one high corner on a slim dark column (the sliding bearing), the other high corner free.

## 5. Colour and material

White #e9e7e1 (shell top, tiles), black #2b2c2e (stripes, tiles), concrete #b9b4aa (deck,
piers, struts, stairs), glass #6a7c86, frames #3a3f44, kiosk #d7d2c4. Everything in the city's
one building surface (landmark material codes M_STONE and M_PAVILION): no draw call of its own.

## 6. Ground and night

The cutting, the rails and the platforms are the map's own. Stairs fold down from the hall's
cutting side along the tracks (-v) to the island platform (the cutting's floor + 0.9 m), 3.2 m
wide between two concrete parapets. A small kiosk (once a newsagent's) stands by the entrance
on the street side. At night the hall glows warm under the dark shell. Car collision round the
hall only, from the cutting's floor to 4 m over the deck.

## 7. Detail level and budget

L3, budget 1420 triangles (in `check_mesh_quality.gd`; built 1178).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| deck | slab prism | hall + 15 m x hall + 1.6 m, 1.1 m deep | street level over the cutting | concrete | the hall on a bridge over the tracks |
| piers | two walls | 1 x (hall - 2) m | under the hall's u edges | concrete | the deck's supports in the cutting |
| band | tiles | 0.6 x 0.6 m | round the hall at the floor | black and white | the mosaic band |
| hall | glass trapezoids | 17.25 m square | the OSM outline | M_PAVILION | glass up to the shell |
| mullions | thin quads | 0.12 m, every 1.7 m | the hall's walls | steel | the glazing grid |
| shell | ruled grid | ~20 m square, 3.0-10.6 m, sag 1.1 m | over the hall | white / striped | the saddle |
| letters | frame + neon | WARSZAWA OCHOTA, 4.2 m | by the entrance | dark steel / blue neon | the station's name |
| struts | raked beams | 0.55 m | the two low corners | concrete | hinged supports |
| column | slim beam | 0.32 m | under one high corner | steel | the sliding bearing |
| stairs | step prisms | 3.2 m wide | from the hall down to the platform | concrete | the way down to the trains |
| kiosk | box | 2.6 x 2 x 2.5 m | by the street-side entrance | cream | the old newsagent's |
