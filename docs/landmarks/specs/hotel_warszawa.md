# Hotel Warszawa (the 1933 Prudential): spec

Site key `hotel_warszawa` in `game/scripts/landmarks.gd` (`_find_hotel_warszawa`,
`_build_hotel_warszawa`). Written 2026-11-02 from the Mac's reference set `refs/hotel_warszawa/`
(Wikimedia Commons, 12 photos, of which 1, 2, 7 and 8 are after the 2018 restoration, plus the GUGiK
orthophoto; SOURCES.md and REPORT.md there, not in git) and the GUGiK LoD2 heights in the map pack.

## 1. Identity

Marcin Weinfeld's Prudential (1931-33), Warsaw's first skyscraper, a hotel again since 2018:

1. A **stepped stone tower**: a wide shaft, one heavy projecting cornice, then a narrower
   **two-storey crown box** with a second cornice and masts and a flag on the roof.
2. **Eight full-height pilasters** on the front with **seven columns of small deep windows**
   between them: the shaft reads as vertical stripes, no horizontal bands but the two cornices.
3. Pale **sandstone cladding** (warm cream).
4. A **low two-storey base** with a **three-opening portal** under the cut word **WARSZAWA**, a
   **copper-red door** either side.
5. **Two six-storey wings** flush with the front either side of the shaft.

## 2. Massing

Frame: u along the front from south to north (towards Świętokrzyska), +v out of the front (east,
onto Plac Powstańców Warszawy); origin (-770.5, -190.0), u = (-0.330, -0.944). The OSM parts give
every rectangle (local u0, v0, width, depth); heights from LoD2 (ground ~13 m: the shaft's roof
68, the crown's 80-81, the back wings' 38-40) and the photos (storeys ~3.8 m).

| Part | Where (local) | Heights above ground |
| --- | --- | --- |
| Shaft (OSM 3482) | u -10.5..11.2, v -15.6..0 | -0.6 to 54.2 m: ground floor 5 m, base storey to 8.6 m, 12 storeys of 3.8 m |
| Cornice | the shaft grown 1 m | 54.2 to 55.8 m |
| Crown (OSM 3483) | u -8.0..9.2, v -14.4..-1.4 (set back ~1.4-2.5 m) | 55.8 to 66.2 m, top cornice (grown 0.8 m) to 67.4 m |
| Front wings (11860, 11865) | u 11.2..17.3 and -16.5..-10.5, v to +0.9 | to 24 m |
| Back U (11855/6/8/9) | round the hall, u -16.1..18.8, v -54.5..-5 | to 25 m |
| Hall (11857) | u -8.6..3.2, v -47.4..-15.6 | 7.5 m, glass ridge to 9.3 m |
| Portal porch | u -4.3..5.1, v 0..1.1 | to 5.2 m |

## 3. Facade

- Front (east): 8 pilasters 0.6 m wide, 0.3 m proud, pitch 3.1 m, from 5 m to the cornice; 7 window
  columns x 12 rows, windows 1.4 x 1.8 m, plus the base storey's row of 1.3 x 1.6 m at 5.7 m.
- Sides (north, south) and back: 6 and 7 columns of the same windows above the wings' roofs, seven
  pilasters a side (0.3 m proud) from 25 m up.
- String course at 8.6 m (the shaft grown 0.32 m); heavy cornice 1.6 m tall, 1 m out.
- Crown: 6 pilasters on the front, 5 bays x 2 rows on front and back, 4 on the sides; attic plain.
- Front wings: one column of tall narrow windows (1.1 x 2.6 m, five stacked) 1.6 m in from the outer
  edge, a shop-tall window at the foot.
- Back U: rows of small windows (1.3 x 1.8 m, every 3.2 m, six rows) on the edges facing the
  streets and the hall (over the hall from its roof up).
- Ground floor: the porch with three dark openings (centre 3.2 m wide, sides 1.6 m), copper-red
  doors (1.4 x 3.1 m) at u -6.6 and 7.6, tall ground-floor windows at u -8.9 and 9.7.

## 4. Roof

From the orthophoto and photos: the tower's small dark flat roof (#55504a) with a lift head
(4.4 x 3.6 m, 2.6 m tall), two white masts (8 m) and a flagpole (6.5 m) with the white-and-red flag;
the wings' and the U's pale membrane (#cfcbc4) behind 0.45-0.5 m parapets, four round plant hoods;
the hall's blue-green glass ridge roof (#7f9faf, M_GLASS_ROOF) with stone gables.

## 5. Colour and material

Stone #dccaa6 (the photos' #e3d6bc sunlit, calmed), pilasters #ebdfc4, spandrel/course shade
#cdbd9e, all M_STONE; windows #5f7079 (M_GLASS); portal dark #3c3733; copper #a5583f; roof #55504a;
membrane #cfcbc4. Lettering WARSZAWA in warm grey (0.45, 0.43, 0.40), 0.42 m tall.

## 6. Ground and night

A granite step (12 x 2.4 m) before the portal; three flagpoles (9 m) with white-and-red flags on the
square north of it. Night (photo 1): the pilasters are floodlit, so each front pilaster and each
crown pilaster carries a 0.3 m M_LAMP strip (#dcc59a) and both cornices a lit edge; the windows
take the city's night glow (M_GLASS). Car collision on the OSM outline.

## 7. Detail level and budget

L3 (the start area's south, a skyline tower), 1894 triangles, budget 2300 (check_mesh_quality
BUDGET "hotel_warszawa"). No new material, node or draw call. Shots: the front from the square
(`--at=-740,-170 --yaw=125 --lift=30`), the crown (`--at=-765,-188 --yaw=140 --lift=55`), night, solo.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shaft | prism | 21.7 x 15.6 x 54.8 m | u -10.5..11.2, v -15.6..0 | M_STONE #dccaa6 | 1 stepped tower |
| pilasters | boxes | 0.6 x 0.3 x 49.2 m, 8 | front, pitch 3.1 m | M_STONE #ebdfc4 | 2 vertical stripes |
| side_pilasters | boxes | 0.3 x 0.6 x 29.2 m, 14 | north and south faces from 25 m | M_STONE #ebdfc4 | 2 vertical stripes |
| windows | quads | 1.4 x 1.8 m | 7 x 12 front, 6 or 7 x 8 above the wings | M_GLASS #5f7079 | 2 small deep windows |
| glow_strips | quads | 0.3 m wide | every front and crown pilaster | M_LAMP #dcc59a | night floodlight |
| course | prism | shaft + 0.32 m, 0.45 m tall | 8.6 m | M_STONE #cdbd9e | 4 low base |
| cornice | prism | shaft + 1 m, 1.6 m tall | 54.2 m | M_STONE #ebdfc4 | 1 heavy cornice |
| crown | prism | 17.2 x 13 x 10.4 m | u -8..9.2, v -14.4..-1.4 | M_STONE #dccaa6 | 1 crown box |
| crown_cornice | prism | crown + 0.8 m, 1.2 m tall | 66.2 m | M_STONE #ebdfc4, top #55504a | 1 second cornice |
| masts | beams | 0.22 m, 8 m; flagpole 0.12 m, 6.5 m | roof | M_STONE #e6e6e2 | 1 masts and flag |
| lift_head | box | 4.4 x 3.6 x 2.6 m | u 2.5, v -9 | M_STONE #cdbd9e | roof |
| wings | prisms | 6.1 x 6.4 and 6 x 5.6 m, 24 m | either side of the shaft | M_STONE #dccaa6 | 5 flush wings |
| portal | box + quads | 9.4 x 1.1 x 5.8 m, 3 openings | u -4.3..5.1, v 0..1.1 | M_STONE #ebdfc4, #3c3733 | 4 portal |
| letters | sign | WARSZAWA, 0.42 m | over the portal, 4.55 m | sign (0.45, 0.43, 0.40) | 4 lettering |
| doors | quads | 1.4 x 3.1 m | u -6.6, 7.6 | M_STONE #a5583f | 4 copper doors |
| back_u | prism | 25 m, a U round the hall | u -16.1..18.8, v -54.5..-5 | M_STONE #dccaa6, roof #cfcbc4 | 2 massing |
| hall | prism + quads | 11.8 x 31.8 m, 7.5 m, ridge 9.3 m | u -8.6..3.2, v -47.4..-15.6 | M_STONE, M_GLASS_ROOF #7f9faf | roof |
| flagpoles | beams + quads | 9 m, flags 1.25 m | u 12.5-15.7, v 4 | M_STONE #e6e6e2 | ground |

F's look check (2026-11-03): front east confirmed, the tower reads as the hotel. Applied: one granite plinth, stone ground-floor face and string course across wings and shaft; wings to 25 m (the back U's height) under turned cornices; portal reveals and cornice slab; main and crown cornices 1.5 / 1.1 m proud over a shadow line.
