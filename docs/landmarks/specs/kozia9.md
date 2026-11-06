# Kozia 9: spec

Site key `kozia9` in `game/scripts/landmarks.gd` (`_build_kozia9`). Written 2026-11-05 from the Mac photo report `docs/landmarks/photo-reports/kozia9.md` (refs/kozia9/: only photos 1 and 2 show the block; the GUGiK ortho) and the unnamed OSM outline, found by `KZ_AT`, kept for the streamed path by `tools/bake_sectors.py` SITE_AREAS. Part of F's modernism set (`docs/design/modernism-collection.md`, M2).

The report's compass names are off: the slab runs north-west (low) to south-east (tall). Its "NW long side" is the south-west side on the car park, the one photo 1 shows; its "NE end" is the south-east end.

## 1. Identity

Jerzy Kuźmienko and Piotr Sembrat's block of 1974-76. Judged first:

1. Five sections climbing a storey at a time to the south-east.
2. The round stair tower at the tall end.
3. The saw-tooth long sides: flat plates of plain wall, every window turned sideways into a jog.
4. Cream-grey roughcast with no other ornament.

## 2. Massing

The mapped outline, teeth kept (simplified to 0.15 m), about 64 x 13 m. Five sections cut across the axis at u 16, 29, 42 and 53.5 (photo 1's bay counts against the ortho's roofs), roofs 14.4, 17.5, 20.6, 23.7 and 26.8 m over the ground (LoD2 tops 23.1 to 35.5 less the 8.7 m terrain). OSM's 14 m height is wrong. The tower is a 5 m radius drum at u 61.5, v -4.5, to 27.3 m, flush with the last parapet.

## 3. Facade, base to top

No separate base. Storeys of 3.1 m. Each jog of the saw-tooth (edges along `KZ_JOG`, 0.7 to 4 m long) holds one framed window per storey, up to 1.2 m wide (two on a jog over 2.6 m), with a white sill 50 cm proud and a shadowed head over it. The plates between them are blank. On the north-east side the jogs carry balcony boxes on alternating storeys, 2.4 x 2.1 m on the deep ones, 1.5 x 1.3 m on the short ones, pale tops, dark undersides (photo 2). A 0.45 m parapet with a pale cap tops each section.

## 4. Roof

Flat dark grey decks, stepping as the ortho shows, with the pale zigzag rim the ortho shows, four 4.4 m squares at u 10, 33, 44 and 51.5, two dishes (photo 1).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Roughcast | #b8b1a0 | M_STONE |
| Undersides | #8f897a | M_STONE |
| Parapet caps | #e0ded6 | M_STONE |
| Frames, sills, canopies | #eeeeea | M_STONE |
| Glass | #2e3640 | M_GLASS |
| Roofs | #70716f | M_STONE |
| Doors | #8c5a32 | M_STONE |
| Ramp walls | #8e8e8c | M_STONE |

No new material or draw call.

## 6. Ground and night

On the car park side two flat white canopies, wooden doors and steps; by the tower the garage ramp's two walls, its dark mouth and lintel. Rooms light through M_GLASS. Open: the Moliera face's real boxes, which needs street photos; Mapillary waits for the token on the Mac.

## 7. Detail level and budget

L3, triangle budget 7000 (`check_mesh_quality.gd`).

Shots: `--at=-806,-1172 --yaw=30 --pitch=-20 --size=80 --solo=kozia9 --solo-look=lit` (photo 1), `--at=-806,-1172 --yaw=15 --pitch=-40 --size=95` (play view).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| spine | five clipped prisms | 64 x 13 m, 14.4 to 26.8 m | the outline | M_STONE | 1 steps |
| stair_tower | drum, 14 sides | r 5 m, 27.3 m | u 61.5, v -4.5 | M_STONE | 2 tower |
| window_strips | framed windows, sills | up to 1.2 x 1.4 m | every jog, per storey | M_STONE, M_GLASS | 3 saw-tooth |
| balcony_boxes | hanging boxes | 2.4 x 2.1 x 1.3 m and 1.5 x 1.3 x 1.3 m | jogs, north-east side | M_STONE | 3 saw-tooth |
| terraces | parapets, pale caps | 0.45 m high, 0.4 m wide | each section's edge | M_STONE | 1 steps |
| entrance | canopy, door, steps | 4.8 x 2 m | u 27 and 53, v 1 to 4 | M_STONE | 4 walls |
| garage_ramp | two walls, mouth, lintel | 5.2 m wide, 11 m long | u 55.6 to 61.2 | M_STONE | 4 walls |
| roof_plant | boxes, dishes | 4.4 m square, 2.2 m high | u 10, 33, 44, 51.5 | M_STONE | 1 steps |
