# Pomnik Powstania Warszawskiego: spec

Site key `pomnik_powstania` in `game/scripts/landmarks.gd` (`_find_pomnik_powstania`,
`_build_pomnik_powstania`). Written 2026-11-02 from the Mac's reference set (`refs/pomnik_powstania/`,
14 Wikimedia Commons photos, GUGiK orthophoto, OSM ways 1327606552 and 1449265995; REPORT.md there).
No aerial and no clean night photo exist on Commons: the layout is from the orthophoto, the night
from a dusk photo and a 1 August photo.

## 1. Identity

The Warsaw Uprising Monument (Wincenty Kućma, architect Jacek Budyn, 1989) on Plac Krasińskich,
at the foot of the Supreme Court's green colonnade. What makes it read:

1. **"Szturmujący"**: about eleven bronze insurgents running out of a broken brick wall toward the
   square, larger than life (~2.3 m).
2. **Two huge tilted light-granite slabs** leaning over them like falling walls, the short high one
   to the west, the long one to the east, the "rubble city" of dark bronze blocks between.
3. **"Przejście kanałami"**, 26 m south: a bareheaded priest and soldiers going down into a sewer
   manhole, on a low stone block, a broken bronze slab lying in front.

## 2. Massing

Frame: origin (-1235.0, -1700.0) (the OSM outline's centre), u along the court's wall, bearing 67
(0.9205, -0.3907), +v the groups' front, SSE, to the square.

| Part | Where (u, v) | Heights |
| --- | --- | --- |
| Landing | u -9..9, v -3.4..3.4 | ground - 0.6 .. ground + 0.6 (`PP_LANDING`) |
| Front treads | u -9..9, v 3.4..5.2, 4 treads | 0.17 m each down to the square |
| Wide flight | u -27..-9, v -8..4, 8 treads of 1.5 m | rising 0.19 m each to the landing, toward the colonnade |
| Brick wall | v -1.6 ± 0.55, six pieces between u -7.5 and 7.4 | 2.2 to 3.8 m over the landing |
| Rubble blocks | u -2.7..2.3, v -1.9..-0.1, five blocks | 4.1 to 5.6 m |
| West slab | base u -4.2, v -1.4, 1 m up | 9 x 4.8 x 1.2 m, leaning west ~27 deg |
| East slab | base u 4.4, v -1.5, 1.2 m up | 10.5 x 5.6 x 1.3 m, leaning east ~25 deg, top ~9.5 m |
| Small group | centre (-1234.5, -1674.0), facing (0.766, 0.643) | block 0.8 m, figures to ~3 m |

## 3. Facade, base to top

A sculpture, no facade: the granite landing and treads at the base, the bronze wall and rubble in
the middle, the slabs above. The fighters stand along the landing's front half (v 0.8 to 2.3), each
heading out of the wall and fanning to the sides at the ends (`PP_FIGHTERS`: running, kneeling with
a rifle, running with a rifle raised).

## 4. Roof

None. Seen from above the slabs' light top faces (#d6d8d3) and the landing read against the dark
bronze; the ortho shows exactly that.

## 5. Colour and material

All M_STONE (the shared building surface, no draw call of its own). Granite #c5c7ba lit, #9a9f9b
shaded faces, tops #d6d8d3; steps #cfd0ca; bronze #3b3628, wall and rubble #2a261f (the photos'
#242013..#6f685c, calmed); setts #8f8a8a; manhole #1f1d1a.

## 6. Ground and night

The landing sits on the terrain at the group (it rises ~1.2 m from the square to the court); the
wide flight leads up to the colonnade, the front treads down to the square; the small group stands
on a pad of setts. At night three warm up-lights (M_LAMP, #ffb066) glow at the landing's front edge
(photo 06). Collision: the landing and the wide flight, the small group's block.

## 7. Detail level and budget

L3 (a hero monument on the Old Town's edge), 1514 triangles, budget 1820 (check_mesh_quality
BUDGET "pomnik_powstania"). Shots: from the square looking NNW (`--at=-1236,-1690 --yaw=0
--size=22 --pitch=-35`).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| landing | box | 18 x 6.8 m | u 0, v 0 | M_STONE #9a9f9b, top #d6d8d3 | 2 the stage |
| treads | 4 boxes | 18 x 0.45 m | v 3.4..5.2 | M_STONE #cfd0ca | ground |
| flight | 8 boxes | 18 x 1.5 m | u -27..-9, v -8..4 | M_STONE #cfd0ca | ground, the court's steps |
| wall | 6 boxes | 1.6-1.8 x 1.1 m, 2.2-3.8 m tall | v -1.6 | M_STONE #2a261f | 1 the broken wall |
| rubble | 5 boxes | ~1 x 1.4 m, 4.1-5.6 m tall | u -2.2..1.8 | M_STONE #2a261f | 2 the rubble city |
| slab_w | tilted box | 9 x 4.8 x 1.2 m | base u -4.2 | M_STONE #c5c7ba | 2 falling wall |
| slab_e | tilted box | 10.5 x 5.6 x 1.3 m | base u 4.4 | M_STONE #c5c7ba | 2 falling wall |
| fighters | beams and prisms | 2.3 m | 11 along v 0.8..2.3 | M_STONE #3b3628 | 1 the insurgents |
| lamps | 3 boxes | 0.36 x 0.24 m | landing's front edge | M_LAMP #ffb066 | night |
| kanaly_block | box | 1.6 x 2.8 x 0.74 m | small group | M_STONE #c5c7ba | 3 the block |
| manhole | octagon | r 0.45 m | the block's front | M_STONE #1f1d1a | 3 the sewer |
| priest | frustums | 2.45 m | on the block | M_STONE #3b3628 | 3 the priest |
| soldiers | beams | 2.3 m | bent, kneeling, half in the manhole | M_STONE #3b3628 | 3 the descent |
| debris | 2 boxes | 2.4 x 1.6 m | in front | M_STONE #3b3628 | 3 the sewer cover |
