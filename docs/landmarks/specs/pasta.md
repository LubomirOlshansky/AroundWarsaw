# PAST-a (Zielna 37/39): spec

Site key `pasta` in `game/scripts/landmarks.gd` (`_find_pasta`, `_build_pasta`). Written 2026-11-03
in a cloud thread from the Mac photo report `docs/landmarks/photo-reports/pasta.md` (photo 1 the
1910s tower, 2 today from the south-west, 3 the Uprising plaque, the GUGiK ortho; photos stay on
F's Mac in `refs/pasta/`). OSM maps the tower as one 54 m block ("PAST-a"); LoD2 has no model of it.

## 1. Identity

1. **A square tower ~51 m high** over Zielna, grey-brown render, vertical pilaster strips.
2. **The top storey: an open loggia of tall round arches**, five on the long faces, under a
   **crenellated parapet** like a castle's.
3. **A gilt anchor sign on the roof**; long white-and-red banners down the Zielna face.
4. **The plaque** on the grey base (20 August 1944, the Kiliński Battalion): a quiet card, no gags.

## 2. Massing

OSM's outline `_simplify`d (0.8 m), 21 x 26 m with a notch at the south-west, as the tower: a base
to 4.2 m (0.3 m out), the body to 43 m, a 0.6 m ledge, the loggia storey to 49.5 m, merlons 2 m.
The lower wings north and south stay LoD2's. Frame on the Zielna face: u south from
(-1201.5, -267.9), +v east to the street.

## 3. Facade

Pilaster strips and windows from M_MONUMENT on the body; the loggia: 1-5 arches per face by length
(a dark opening r up to 1.25 in a pale surround, 44.2-48.3 m). Zielna face: the door at u 10.6
(dark, in a pale frame), the plaque at u 14.6 (1.5 x 1 m), banners at u 4.5 and 16.7 from 12 to
36 m, white on the viewer's left as a flag hung down.

## 4. Roof

Flat, dark #5d5955, inside the merlons (`_attic`, 2 m). In its middle a low plinth and the gilt
anchor (~4.2 m of gold strokes), facing Zielna.

## 5. Colour and material

Render #9c8574 (the report's #8C7F72 warmed, so it does not read as plain grey), base #6e655d,
trim #b5a99b, openings #2b2826, plaque and banner white #ece7dc, banner red #c8303a, anchor KP_GOLD.

## 6. Ground and night

The base stands on the pavement; car walls round the outline. At night the windows light as the
shader does; the loggia stays dark.

## 7. Detail level and budget

L2, triangle budget 580 (476 measured plus 20 %, in `check_mesh_quality.gd`). Shots in project
files `poczta-pasta/`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| base | outline prism, 0.3 m out | 4.8 m | the outline | M_STONE grey | plinth |
| body | outline prism | 4.2-43 m | the outline | M_MONUMENT render | tower |
| ledge | outline prism, 0.35 m out | 0.6 m | 43 m | M_STONE trim | cornice |
| loggia | outline prism and arch panels | 43.6-49.5 m | the outline | M_STONE | arcade |
| merlons | crenellated parapet | 2 m | 49.5 m | M_ATTIC | castle top |
| anchor | gold beams on a plinth | 2.9 x 4.2 m | roof middle | M_STONE gold | Kotwica |
| door | two boxes | 3.6 x 4.2 m | u 10.6 | M_STONE | entrance |
| plaque | box | 1.5 x 1.0 m | u 14.6, 1.4 m up | M_STONE white | Uprising plaque |
| banners | two boxes each | 1.8 x 24 m | u 4.5, 16.7 | M_STONE white, red | banners |

## 9. Open (photo check)

The footprint (the ortho puts the roof ~8 m west of OSM's outline); the colour on the phone; the
flags on poles are not drawn.
