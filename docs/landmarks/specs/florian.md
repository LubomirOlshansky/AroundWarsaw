# Katedra św. Michała Archanioła i św. Floriana (Praga): spec

Site key `florian` in `game/scripts/landmarks.gd` (`_build_florian`, `_fl_*`). Written 2026-11-02
in a cloud thread from the Mac's photo report `docs/landmarks/photo-reports/st_florian.md` (three
Commons photos: the west front by day, by night, the nave from afar; the GUGiK orthophoto) and the
OpenStreetMap outline "Bazylika Katedralna Świętego Michała Archanioła i Świętego Floriana
Męczennika" (towers mapped 75 m, the body 35 m). No LoD2 here (the GUGiK survey stops short of
Praga). Values not in the report are marked *(photo check)*.

## 1. Identity

Praga's neo-Gothic cathedral (Józef Pius Dziekoński, 1888-1904; blown up in 1944, rebuilt
1947-72). What makes a passer-by say its name: the **two square red-brick towers with tall green
copper spires** (75 m to the gilt crosses, seen across the river from the Old Town), the white
stone trim on red brick, the **gable between the towers with a rose window over a pointed
portal**, and the long slate nave with a flèche over the crossing.

## 2. Massing

Frame: origin (434.89, -1980.8), the front's middle between the towers' outlines; u across the
front (axis (-0.523, 0.852)), +v out of it. The outline puts the front to the **west-north-west**
(Plac Weteranów 1863 roku, Al. Solidarności beyond); the report says south-west *(photo check:
read off the ortho with north up; the outline wins)*.
- Towers: u ±10.95, v 0, 6.8 x 8.6 m (OSM outlines). Brick shaft to 33 m, belfry to 42 m, spire
  to 71 m, cross to 75 m.
- Nave (clerestory): u ±7.4, v +4.0..-60.6, eave 24 m, ridge 35 m (OSM).
- Aisles: u ±7.4..14.1 (v -4.3..-31) and ±7.4..18.6 (choir, v -43..-60.6), eave 13 m, lean-to
  roofs to 18 m.
- Transept: u ±19.2, v -31..-43, eave 24 m, ridge 35 m.
- Apse: a half octagon u ±7.4, v -60.6..-68.6 (from the outline), eave 24 m.
Heights other than the OSM 35/75 m are proportions from photos 4 and 6 *(photo check)*.

## 3. Facade, base to top

Front between the towers (photo 4): a stone plinth (to 1.2 m) and three steps; a brick porch
(6.4 x 1.2 m, to 9.5 m) with the pointed main portal (3.6 m wide, 7.4 m to the point) in a white
stone surround under a white wimperg (gable, 4.2 m) with two pinnacles; a white string course at
12.4 m; the rose window (r 3.4 m stone ring, r 2.9 m glass, 17.5 m up); five lancets in the gable
rising to the middle; pinnacles at the gable's feet, a stone cross on its apex. Three portals in
all: the main one and one in each tower's front (2.4 m wide). Towers: corner buttresses with
white pinnacles (to 29 m), white bands at 12.4, 24 and 33 m, a tall lancet on the front and the
outer face (14.5-22 m). Belfry: on each face a white pointed frame with twin dark lancets. Long
walls: M_GOTHIC brick (lancets and buttress strips in the shader), plus modelled buttresses
every 5.4 m on the aisles with white pinnacles.

## 4. Roof

- **Nave**: steep gable, 11 m rise over a 15.2 m span, dark slate.
- **Transept**: cross gable to the same ridge, brick gable ends.
- **Apse**: a half cone of seven slate faces to the ridge's end.
- **Aisles**: slate lean-tos.
- **Towers**: four brick gables round the spire's foot (4.2 m), four white corner pinnacles
  (6.4 m), the octagonal copper spire (r 3.2 m at 42.8 m to the tip at 71 m) with four lucarnes
  at 50.8 m, a gilt ball and a gilt cross to 75 m.
- **Flèche** over the crossing: a copper drum and spire to 49 m, a gilt cross.
- **Turrets**: four small round brick turrets with slate cones at the transept's corners (to 31 m).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Brick | #a4472e (buttresses #8e3c28) | M_GOTHIC (walls, shafts), M_STONE |
| Stone trim, pinnacles, bands, wimperg | #e9e3d3 | M_STONE |
| Plinth, steps | #a8a08e | M_STONE |
| Nave, apse, aisle roofs | #4a524f | M_STONE |
| Spires, flèche, lucarnes | #5e8e76 | M_STONE |
| Portals, lancets, rose glass | #2e3236 | M_GLASS |
| Ball and crosses | #c9a24a | M_STONE |
| St Michael | #eceae4 | M_STONE |

No new material or draw call.

## 6. Ground and night

Forecourt: St Michael, white, on a stone pedestal on the axis 12 m before the front (photo 5;
the spot *(photo check)*). Night (photo 5): eight warm floodlamps in the paving (M_LAMP), the
rose's stained glass lit, four cool cyan lamps on each belfry's parapet for the spires.
Car collision along the outline, each tower and the statue. Card: "Katedra św. Floriana", PL
"Neogotycka katedra na Pradze, 1888–1904. Dwie wieże po 75 m widać z drugiego brzegu Wisły.",
EN "Praga's neo-Gothic cathedral, 1888–1904. Its two 75 m spires are seen from across the
Vistula." Open *(photo check)*: the front's compass direction, the belfry's opening count, the
statue's spot, how far the white trim goes on the long walls.

## 7. Detail level and budget

L3 (skyline landmark), triangle budget 2480 (2059 measured; `check_mesh_quality.gd`, `florian`).
Shots: `--at=415,-1992 --yaw=235 --pitch=-28 --size=120 --lift=25 --time=day --no-ghost` (the
front), `--at=470,-1960 --yaw=60 --pitch=-35 --size=130 --lift=20` (the nave and apse).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | outline grown 0.3 m | to 1.2 m | outline | M_STONE | 3 facade |
| nave | box | 14.8 x 64.6 m, to 24 m | u 0, v -28.3 | M_GOTHIC | 2 massing |
| aisles | 4 boxes | 6.7 x 26.7 m, 11.2 x 17.6 m, to 13 m | u ±10.75 / ±13 | M_GOTHIC | 2 massing |
| transept | box | 38.4 x 12 m, to 24 m | v -37 | M_GOTHIC | 2 massing |
| apse | half octagon | 14.8 x 8 m, to 24 m | v -60.6..-68.6 | M_GOTHIC | 2 massing |
| cornices | 2 boxes | 0.7 m | at 24 m | M_STONE | 3 facade |
| nave roof | gable | 15.2 m span, rise 11 m | 24..35 m | M_STONE | 4 roof |
| transept roof | gable | 12 m span, rise 11 m | 24..35 m | M_STONE | 4 roof |
| apse roof | 6 triangles | to the ridge's end | v -60.6 | M_STONE | 4 roof |
| lean-tos | 4 quads | rise 5 m | 13..18 m | M_STONE | 4 roof |
| buttresses | 14 boxes + pinnacles | 0.7 x 0.9 m, to 11.5 m | aisle walls | M_STONE | 3 facade |
| turrets | 4 octagons + cones | r 1 m, to 31 m | transept corners | M_STONE | 4 roof |
| fleche | octagon + spire | r 1.5 m, to 49 m | v -37 | M_STONE | 4 roof |
| porch | box, lancet, wimperg | 6.4 x 1.2 m, to 13.7 m | u 0, v 4.6 | M_STONE, M_GLASS | 1 portal |
| rose | 2 discs | r 3.4 / 2.9 m | 17.5 m up | M_STONE, M_GLASS | 1 rose |
| gable lancets | 5 lancets | 1.1 m wide | 24.6..29 m | M_GLASS | 3 facade |
| towers | box shafts | 6.8 x 8.6 m, to 33 m | u ±10.95 | M_GOTHIC | 1 towers |
| belfry | box, 4 frames, 8 lancets | to 42 m | towers | M_STONE, M_GLASS | 1 towers |
| tower gables | 4 gables | 4.2 m | 42.8 m | M_STONE | 1 spires |
| spires | octagonal cones | r 3.2 m, 42.8..71 m | towers | M_STONE | 1 spires |
| lucarnes | 4 boxes + pyramids | 0.84 m | 50.8 m | M_STONE | 1 spires |
| crosses | ball, bars | to 75 m | towers | M_STONE | 1 spires |
| michael | pedestal, figure, wings, spear | 1.9 m base, to 5.9 m | u 0, v 12 | M_STONE | 6 ground |
| floods | 8 boxes | 0.6 m | the paving | M_LAMP | 6 night |
| spire lamps | 8 boxes | 0.32 m | belfry parapets | M_LAMP | 6 night |
