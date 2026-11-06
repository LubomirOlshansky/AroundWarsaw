# Teatr Polski: spec

Site key `teatr_polski` in `game/scripts/landmarks.gd` (`_build_teatr_polski`). Written 2026-11-02 in
a cloud thread from the Mac's reference set (`refs/teatr_polski/`, 4 Wikimedia Commons photos and a
GUGiK orthophoto; report `docs/landmarks/photo-reports/teatr_polski.md`), the OpenStreetMap outline
and GUGiK LoD2. The mass stays LoD2's in a skin; the model is the Karasia front.

## 1. Identity

Arnold Szyfman's theatre on Karasia (Czesław Przybylski, 1913).

1. **Two rounded corner bays (drums)** at the front's ends with balustraded tops.
2. **A row of oval windows (oculi)** along the top storey, a long iron balcony across the middle one.
3. **The green copper hall roof** rising behind a stone balustrade along the roof edge.

## 2. Massing

Frame: origin (-299.0, -482.1), the mapped front's north end; u along it to (-306.0, -499.6) (18.85 m),
+v out of it to Karasia (west). Drums at the outline's two bumps, (-297.6, -479.9) and (-306.6, -502.3),
r 2.4 m. Five bays of 3.77 m.

| Part | Where | Heights over the ground |
| --- | --- | --- |
| Face | u 0..18.85, v -0.25..0.35 | -0.5 to 16 m |
| Drums | r 2.4 m, 16 sides | -0.5 to 16 m, cornice ring to 16.6, balustrade to 17.5 |
| Balcony | v 0.35..1.55 | 5.2 m, iron rail to 6.4 m |
| Cornice, balustrade | v -0.2..1.2 | 16 to 17.5 m |

## 3. Facade, base to top

A stone plinth to 0.9 m; five round-arched doors on the ground floor; a string course at 4.6 m; five
tall round-headed windows over the long balcony; a string course at 10.4 m; five oculi (cream ring,
dark glass) at 12.6 m; the cornice and the stone balustrade. Each drum has a round-headed window on
both its faces and its own cornice and balustrade.

## 4. Roof

The skin's green copper (#76a08c) on LoD2's roofs: the hall's hipped roof reads green, as in the ortho.
*(Mac check: the low wings' flat roofs are probably not copper.)*

## 5. Colour and material

Walls #e2ddcd (the report), trim #ebe7dc, base #c8c2b1, openings #262c33, iron #2a2b2c, lead
#a0a5a5, kiosk #3f7d5a. M_STONE, M_GLASS; the skin M_MONUMENT.

## 6. Ground and night

On the terrain at the front's ends; the small green kiosk on the walk (2 x 1.5 m, 2.5 m) is the car's.
At night the windows take the city's glow.

## 7. Detail level and budget

L2, about 620 triangles, budget 760 (check_mesh_quality). Shot: `--at=-314,-495 --yaw=250 --size=32
--pitch=-58`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| skin | LoD2 mass | the outline | Karasia 2 | M_MONUMENT #e2ddcd / #76a08c | 3 the green roof |
| face | box | 18.85 x 0.6 m, 16.5 m | the front | M_STONE #e2ddcd | facade |
| plinth | box | 19 x 0.9 m, 1.4 m | the front | M_STONE #c8c2b1 | facade base |
| doors | 5 arches | 2.1 m wide | the ground floor | M_GLASS #262c33 | facade |
| windows | 5 arches | 1.7 m wide | the middle storey | M_GLASS #262c33 | facade |
| oculi | 10 discs | r 0.75 / 0.55 m | the top storey | M_STONE #ebe7dc, #262c33 | 2 the oculi |
| balcony | 2 boxes | 17.6 x 1.2 m | 5.2 m | M_STONE #ebe7dc, #2a2b2c | 2 the balcony |
| cornice | 2 boxes | 18.85 x 1.4 m | 16 m | M_STONE #ebe7dc | 3 the balustrade |
| drums | 2 prisms | r 2.4 m, 16.5 m | the front's ends | M_STONE #e2ddcd | 1 the drums |
| drum_tops | 2 rings, 2 parapets | r 2.7 m, 0.9 m | over the drums | M_STONE #ebe7dc | 1 the drums |
| drum_windows | 4 arches | 1.1 m wide | on the drums | M_GLASS #262c33 | 1 the drums |
| kiosk | box | 2 x 1.5 m, 2.5 m | on the walk | M_STONE #3f7d5a | ground |
