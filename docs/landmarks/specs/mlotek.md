# Młotek (Smolna 8): spec

Site key `mlotek` in `game/scripts/landmarks.gd` (`_build_mlotek`). Written 2026-11-05 from the Mac photo report `docs/landmarks/photo-reports/mlotek.md` (refs/mlotek/: 17 Commons photos, the GUGiK ortho) and the OSM outline "Młotek", found by `ML_AT`. Part of F's modernism set (`docs/design/modernism-collection.md`, M1). F's own test model (`mlotek-smolna-8.js`, 2026-11-05) was ported into the game and merged at F's word: its flat roof and head extent (2025 height data), the sloping jaw, the wider west balconies with yellow fronts.

## 1. Identity

Jan Bogusławski and Bohdan Gniewiewski's 1976 block on the escarpment. What makes a passer-by say its name, judged first:

1. The hammer's head: two storeys wider and longer than the slab, jutting 5.7 m past the east end on a dark jaw that slopes up to its tip.
2. The dark neck between the head and the slab, a deep notch over the west balconies.
3. The balconies stacked up both ends, a yellow edge on every storey.
4. Strip windows in four groups and a column of single ones on grey-brown roughcast.
5. The concrete pergola at the east foot.

## 2. Massing

The slab is 35.5 x 17.1 m, its long axis 22 degrees north of east (`ML_O`, `ML_A`), from the OSM outline; the outline's 5.5 m west bay is 1 m narrower on each side. The ground storey is 3 m, then 19 storeys of 2.8 m to 56.2 m, the neck to 57 m (from 54.5 m over the west bay), the head's flat roof at 63.3 m over the low foot (F's height data: map height about 68.3), plant and masts to about 67 m. The jaw leaves the slab at 53.3 m and reaches 57.7 m at the tip. The head reaches u 41.2 (the height data; the leaning ortho read 43 m); it is flush at the west end and 0.6 m proud on the long sides.

## 3. Facade, base to top

Base: lobby glass on the south front at u 8 to 24 and 26 to 30, a grey plinth. Middle: per storey on both long faces, four strip windows (u 5.3 to 23.7) and one pair (u 25.7 to 28.1), white frames, 1.5 m high; plain wall from u 28 to the corner, as in photo 1. Ends: on the east a slab with a 0.5 m yellow edge per storey, a grey balustrade, glass doors behind; on the west balconies 1.25 m past the wall with 1 m yellow fronts, wrapping 5.5 m round both long faces. Top: the dark neck, a ledge, the glazed band from the middle of the long faces round the east end, slit vents on the west half, the plain head above it.

## 4. Roof

From the ortho: a flat grey deck with a pale rim, a raised middle 28 x 11 m with its own pale rim, five plant boxes and two masts. The hatch at the west end is left out.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Roughcast wall | #8f877a | M_STONE |
| Head | #8a857c | M_STONE |
| Soffit and neck | #4a4743 | M_STONE |
| Balcony edges | #d8bb45 | M_STONE |
| Balustrades | #6e6b65 | M_STONE |
| Roof rims | #c8c6bf | M_STONE |
| Window frames | #e8e8e4 | M_STONE |
| Glass | #2e3640 | M_GLASS |
| Plinth | #8c8a86 | M_STONE |
| Pergola | #7f7b74 | M_STONE |
| Roof | #6d6f72 | M_STONE |

No new material or draw call.

## 6. Ground and night

The pergola stands on six pilotis east of the slab, slats between its beams (photos 15, 16; the ortho). Rooms light through M_GLASS. Open: the north face's windows (no good photo: mirrored from the south), the retaining walls and fence at the foot, the entrance steps. No night photo.

## 7. Detail level and budget

L3, triangle budget 2400 (`check_mesh_quality.gd`).

Shots: `--at=95,25 --yaw=30 --pitch=-14 --size=125 --solo=mlotek --solo-look=lit` (photo 1), `--at=92,42 --yaw=25 --pitch=-34 --size=130` (play view), `--time=night`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shaft | boxes | 27.5 x 17.1 m and 2.7 x 12.7 m, to 56.2 m | u 2.8 to 33 | M_STONE | 4 walls |
| window_bands | framed strips | 4.2 x 1.5 m, 19 storeys | both long faces, ML_STRIPS | M_STONE, M_GLASS | 4 windows |
| stair_column | framed pair | 2.4 x 1.5 m, 19 storeys | u 25.7 to 28.1 | M_STONE, M_GLASS | 4 windows |
| balcony_strip | hanging slabs, yellow fronts, rails, doors | 19 storeys | both ends | M_STONE, M_GLASS | 3 balconies |
| base | lobby glass, plinth | 2 m high, 1.2 m plinth | south front | M_STONE, M_GLASS | 4 walls |
| neck | boxes | 0.8 m high, 2.5 m over the west bay | under the head | M_STONE | 2 neck |
| crown_slab | ledge, sloping jaw, head | 41.5 x 18.3 m | 53.3 to 63.3 m | M_STONE | 1 head |
| crown_glaze | framed band | 2.2 m high | u 19 to the east end, round it | M_STONE, M_GLASS | 1 head |
| roof_plant | boxes, masts | 2.6 m square, 3 m masts | on the deck | M_STONE | 1 head |
| canopy | 1.2 m beams, slats, 0.5 m pilotis | 14 x 14 m, 4.3 m high | u 36 to 50 | M_STONE | 5 pergola |
