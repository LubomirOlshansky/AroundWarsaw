# Karowa 18a: spec

Site key `karowa18a` in `game/scripts/landmarks.gd` (`_build_karowa18a`). Written 2026-11-05 from the Mac photo report `docs/landmarks/photo-reports/karowa18a.md` (refs/karowa18a/: 12 Commons photos, the GUGiK ortho) and the unnamed OSM outline, found by `KR_AT`, kept for the streamed path by `tools/bake_sectors.py` SITE_AREAS. Part of F's modernism set (`docs/design/modernism-collection.md`, M3).

The report puts the street on the wrong side. Karowa's centre line runs 9 m south-east of the outline's straight side, and the ortho's sunlit tan wall is the rear, so the street front is the south-east side. Left in photo 1 is the uphill south-west end.

## 1. Identity

Dąbrowski, Kuźmienko, Nowak and Sembrat's block of 1978. Judged first:

1. Nine columns of splayed roughcast boxes, two storeys tall, hanging out of the wall.
2. Each column a storey off the next, like a brick bond.
3. Wide white windows in the wall between the columns.
4. The roofline dropping along the street, box tops standing over it.
5. The dark tiled ground floor under it all.

## 2. Massing

43.9 x 11.6 m behind the boxes, from the outline; the wall stands 1 m behind the outline's front, the boxes 1 m past it, 2 m deep (a little more than life, so they read on the phone). Floors run level (`KR_D`, map height 7.4) while the street falls from 4.5 to 2.8. Storeys of 2.95 m: eight window rows uphill, seven in the middle, six on the last bay, with plain wall above the top row. Box tops 26.7 m over the first floor for the uphill four columns (LoD2 34.3), 23.6 m for the next five, the last bay 19.5 m. The wall top is 1.2 m under the box tops.

## 3. Facade, base to top

Base: dark tiles to the first floor, ten shop windows with wooden frames, the passage at u 19.5 to 22.8, gates at u 2 to 5.6, 32.2 to 36 (wood) and 36.7 to 40.2, grey stone at the low end. Middle: columns at u 1.6, 5.9, 10.8, 15.3, 19.8, 24.3, 28.8, 33.3 and 37.7 (measured in photo 1); boxes 2.7 m wide at the wall, 1.9 m at the front, 5 m tall on a 5.9 m pitch, with the open balcony gap between them; 1.8 x 1.6 m white windows between the columns on every storey. The last bay comes forward, flat, two windows a storey. Rear: the same windows in plain wall. Top: flat box tops, no cornice.

## 4. Roof

Flat grey decks with pale rims at two heights and the last bay's, grey tops on the top row of boxes, three stair heads 6 m square at u 13, 25 and 36 (the ortho's three pale squares), a plant box at the tall end.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Boxes, last bay | #c4a07e | M_STONE |
| Wall between | #94745a | M_STONE |
| Roof rims | #cfccc4 | M_STONE |
| Undersides | #8a6144 | M_STONE |
| Frames | #f0eee8 | M_STONE |
| Glass | #2e3640 | M_GLASS |
| Shop glass | #8fa3ad | M_PAVILION |
| Tiles | #3f4448 | M_STONE |
| Base stone | #8c8a86 | M_STONE |
| Shop frames | #7a5534 | M_STONE |
| Roofs | #7a7873 | M_STONE |

No new material or draw call. The shop names in the photos (real) are left out.

## 6. Ground and night

The pavement, street lamps and bollards are the street's own. Rooms light through M_GLASS, the shops through M_PAVILION. Open: the rear's terraces (LoD2 shows 31.5 and 27.8 m levels behind), the windows in the boxes' sides, the balcony rails, and the block's own 1 m front setback against the map's outline.

## 7. Detail level and budget

L3, triangle budget 1500 (`check_mesh_quality.gd`).

Shots: `--at=-457,-932 --yaw=33 --pitch=-6 --size=44 --solo=karowa18a --solo-look=lit` (photo 1), `--at=-457,-932 --yaw=33 --pitch=-28 --size=70 --time=night`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| slab | three boxes | 43.9 x 11.6 m | v -1 to -12.6 | M_STONE | 4 roofline |
| balcony_boxes | hanging splayed prisms | 2.7 m wide, 2 m deep, 5 m tall | KR_COLS, a storey apart | M_STONE | 1 boxes |
| windows | framed windows | 1.8 x 1.6 m, 7 to 8 storeys | between the columns, front and rear | M_STONE, M_GLASS | 3 windows |
| terrace_steps | stepped tops | 26.7, 23.6, 19.5 m | u 0, 22, 39.7 | M_STONE | 4 roofline |
| garage_base | dark box, gates | 43.9 m long | to the first floor | M_STONE | 5 base |
| base_cladding | stone wall | 4.2 m long | u 39.7 to the end | M_STONE | 5 base |
| shop_windows | framed windows | 1.7 x 2.2 m, ten | KR ground floor | M_STONE, M_PAVILION | 5 base |
| roof_plant | three stair heads, a box | 6 m square, 1.8 m high | u 13, 25, 36 | M_STONE | 4 roofline |
