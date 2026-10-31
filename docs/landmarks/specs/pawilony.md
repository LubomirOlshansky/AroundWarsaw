# Pawilony (Nowy Świat 22/28)

Written 2026-10-31 for F's "add the pawilony warszawskie". No reference photos in the cloud
(no network to Commons); the plan is measured from the two OpenStreetMap outlines named
"Pawilony za Nowym Światem" in `centrum.json` and the passages mapped round them. What it
looks like is from what is widely known of the place: a maze of tiny one-storey bar
pavilions behind a gate on Nowy Świat, each a different colour, shutters, a dozen small lit
signs, string lights. The art-director check against real photos is open (Mac, `refs/pawilony/`).

## 1. Identity

What makes it the Pawilony: a cluster of very low (about 3 m) flat-roofed boxes, each a
different patched colour, packed shoulder to shoulder along narrow passages, so that from
above it reads as a strip of mismatched tiles between tall tenements; at night every front is
a small lit door or window with its own little neon word, and warm bulbs run along the eaves.
Seen from Nowy Świat: only a gate in a tenement front with a PAWILONY sign over it.

## 2. Massing

Two strips, each cut into pavilions along its long axis (the outline's longest edge):

- West strip: 51 m long, 12 m wide, running NNE behind the Nowy Świat tenements. Cut into two
  back-to-back rows (each about 6 m deep), one facing the passage to the west (the gate side),
  one facing east.
- South-east strip: 60 m long, 7 m wide, running east from the west strip towards Smolna; one
  row, fronts facing the footpath on its north side.
- Each pavilion: 3.4 to 5.6 m wide along the strip (seeded by its position, so it is the same
  every run), 2.7 to 3.6 m tall. Every pavilion stands on its own ground height.
- The unnamed 7.6 m building between the two strips is not part of the site and stays.

## 3. Facade, base to top

- Base: a 0.3 m dark plinth below the ground line (the terrain may dip).
- Walls: plain painted panels (M_STONE), one colour per pavilion from the palette below.
- Front (the passage side): a door, 1.0 x 2.2 m, dark; beside it either a lit shop window
  (warm, M_PAVILION, 1.4 to 2.4 m wide, 0.9 to 2.3 m up) or a closed roller shutter (grey).
- Over the front: a fascia board 0.45 m tall, a little proud of the wall, in a darker shade of
  the wall; on about two pavilions in three, a small neon word standing on the eave's front edge (under the eave the game's camera would not see it).
- String lights: three warm bulbs (0.16 m lamp boxes, M_LAMP) touching the underside of each
  front's eave, on about half the pavilions.

## 4. Roof

Flat roofs in tar paper, felt or sheet (five colours, section 5), each pavilion's own height; the roof slab overhangs the front
by 0.3 m (an eave), only on the front, so neighbours' slabs never overlap. No parapet.

## 5. Colour and material

Wall palette (sRGB): #b84a3a brick red, #d9a441 ochre, #3f6e8c blue, #5d8a5a green,
#e5ddcc cream, #7a5a8c violet, #c96f4a orange, #4a4f55 graphite. Roofs vary: #3b3a38 tar, #5f5d57 felt, #7a5f4c rusty sheet, #4f5c50 mossy, #6e6a64 grey. Doors #1f2124.
Shutters #8e9196. Window glass warm (M_PAVILION + 0). Every part is in the city's one building
surface (landmark material codes): no draw call of its own.

## 6. Ground and night

The courtyard keeps the map's own ground and footpaths. At night the lit windows, the bulbs and
the neon words carry the place. Neon words (the font of `neon_signs.gd`; no brands, Polish):
PIWO, BAR, SHOTY, KLUB, DISCO, KARAOKE, OTWARTE, in pink, cyan, violet, amber and green, scale
0.26 (about 0.57 m tall). Over the gate on Nowy Świat (the tenement's front at -285.0, 111.5),
PAWILONY in warm white, scale 0.45, 4 m up. APTECZKA (storefronts.gd venues) still finds its
own wall here.

## 7. Detail level and budget

L2, triangle budget 1800 (measured 1490 for 37 pavilions, plus about 20 % as the other sites);
`check_mesh_quality` BUDGET "pawilony" 1800, zero defects of any kind.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| box | prism | 3.4-5.6 x 6 (or 7) x 2.7-3.6 m | along each strip, back to back in the west strip | M_STONE, palette | the patched row of tiny bars |
| plinth | prism | box x 0.3 m | under each box, below ground | M_STONE #2c2c2c | hides the terrain's dips |
| eave | slab | box width x 0.3 m deep x 0.15 m | box top, front only | M_STONE, the roof darkened | the flat roof's overhang |
| roof | cap | box plan | box top | M_STONE, roof palette | a patchwork of roofs from the helicopter |
| fascia | board | width - 0.4 x 0.45 m | front, under the eave, 4 cm proud | M_STONE, wall darkened | where the neon word sits |
| door | panel | 1.0 x 2.2 m | front, one side | M_STONE #1f2124 | one door per bar |
| window | panel | 1.4-2.4 x 1.4 m | front, beside the door, 0.9 m up | M_PAVILION warm | lit bar at night |
| shutter | panel | 1.4-2.4 x 1.4 m | instead of the window on some | M_STONE #8e9196 | a closed bar |
| bulbs | 3 lamp boxes | 0.16 m | under the eave, front | M_LAMP warm | string lights |
| neon | sign quad | scale 0.26 | on the eave's front edge | neon_signs.gd (LandmarkSigns) | the dozen little signs |
| gate | sign quad | scale 0.45 | the tenement front on Nowy Świat, 4 m up | neon_signs.gd | PAWILONY over the gate |
