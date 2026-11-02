# Stadion Leguminy (Legia's ground): spec

Site key `legia` in `game/scripts/landmarks.gd` (`_find_legia`, `_build_legia`). Written
2026-11-01 in a cloud thread from `centrum.json` alone (no photos, no LoD2): the ground on
ul. Łazienkowska is mapped as one 27 m outline (about 163 x 202 m, the bowl), a 20 m west part
and a 5.4 m footprint. The name is the parody "Stadion Leguminy" (the club name is a brand).

## 1. Identity
A roofed four-sided bowl with chamfered corners on the Warsaw escarpment's foot, long axis
about north-south, seen from the street as a pale panelled wall with a white roof edge.

## 2. Massing (heights over the lowest ground under the outline)
| Part | Plan | Height |
| --- | --- | --- |
| Apron | outline + 3.5 m | -1.5 to 0.25 m |
| Concourse | outline, dark glass (M_GLASS) | to 6.5 m |
| Facade | outline, 7 m bays in five greys, a graphite band 21.8-23, red line 23-23.4, green band 23.4-25 | 6.5 to 25 m |
| Roof rim | outline + 0.4 m, white | 25 to 28 m |
| Roof membrane | rim to a rounded rectangle 160 x 122 m (power 4) round the pitch; the last 5 m grey-blue | 28 m falling to 24 m |
| Upper tier | 162 x 128 m to 0.9 x the outline | 14 to 23.5 m over the pitch |
| Gangway and boxes | to 156 x 122 m, dark glass wall | 10 to 14 m |
| Lower tier | 116 x 82 m to 156 x 122 m | 1.2 to 10 m |
| Pitch | 105 x 68 m along the principal axis, 12 stripes, lines | 0.4 m |
| Masts | four, in the outline's corners at 0.97 x their radius | 46 m, lit head to 49 m |
| Signs | LEGUMINA, green neon, 13 m up, 0.55 of the front's width (max 60 m), on the longest south and east fronts | |

## 3. Facade
A pale panelled wall over a dark glass concourse: 7 m bays in five greys (#e9ebe8 to #8c9096) from
6.5 to 25 m, a graphite band at 21.8-23 m, a thin red line at 23-23.4 m and a green band at
23.4-25 m under the white roof rim. The concourse (0 to 6.5 m) is dark glass (M_GLASS) all round.

## 4. Roof
A white rim (outline + 0.4 m, 25-28 m) and a membrane (M_MEMBRANE) falling from 28 m at the rim to
24 m at a rounded rectangle about 160 x 122 m round the pitch; its last 5 m are grey-blue. The
bowl is open over the pitch.

## 5. Colour and material
| Part | Colour | Material code |
| --- | --- | --- |
| Facade bays | five greys, #e9ebe8 to #8c9096 | M_STONE |
| Bands | graphite #3a3d40, red, green #4f8a3a | M_STONE |
| Concourse, boxes | dark glass | M_GLASS |
| Roof rim | #f4f4f1 | M_STONE |
| Membrane | white, grey-blue inner edge | M_MEMBRANE |
| Pitch | stripes #5a9643 / #4f8a3a, white lines | M_STONE |
| Mast heads, sign | warm #fff1c9; green neon | M_LAMP |

## 6. Ground and night
An apron 3.5 m round the outline (-1.5 to 0.25 m) meets the street. Collision is the mapped
outline's (LoD2's mass). At night the four mast heads glow warm and the two LEGUMINA signs green.

## 7. Detail level and budget
L2, triangle budget 700 (`check_mesh_quality.gd` budget for `legia`).

## 8. Parts table
| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| apron | flat ring | outline + 3.5 m | round the outline | M_STONE | 6 ground |
| concourse | wall ring | 0 to 6.5 m | the outline | M_GLASS | 3 facade |
| facade | 7 m bays | 6.5 to 25 m | the outline | M_STONE | 3 facade |
| rim | wall ring | 25 to 28 m, outline + 0.4 m | on the facade | M_STONE | 4 roof |
| membrane | sloped ring | 28 to 24 m, to 160 x 122 m | inside the rim | M_MEMBRANE | 4 roof |
| tiers | stepped rings | 1.2 to 23.5 m | round the pitch | M_STONE | 2 massing |
| pitch | flat slab | 105 x 68 m | the centre, on the axis | M_STONE | 2 massing |
| masts | posts | 46 m, head to 49 m | four corners | M_STONE, M_LAMP | 6 ground |
| signs | neon word | 0.55 of the front, max 60 m | south and east fronts, 13 m up | M_LAMP | 6 ground |

## 9. Photo check (Mac, parked in QUESTIONS)
Facade colours and panel rhythm, the opening's size, seat colours, mast spots, sign legibility.
