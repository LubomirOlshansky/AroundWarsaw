# Plac Centralny (the new square before the Palace of Culture): spec

Site keys `plac_centralny` and `plac_centralny_lamps` (no cards) in `game/scripts/landmarks.gd` (`_find_plac_centralny`, `_build_plac_centralny`, `_build_plac_centralny_lamps`), the planting in `tools/plac_centralny.py` (map data: trees, beds, benches). Written 2026-11-05 in a cloud thread from F's three reference photos (a drone view of the redesign, an aerial render, a street-level view with the sign) and the mapped lawns, plazas and pool in `centrum.json`. No Mac photo gather yet: values marked *(photo check)* should be confirmed there. The square's ground slabs (tenement outlines, setts) stay `ground.gdshader`'s `centralny()` (R2).

## 1. Identity

The square laid in 2024-25 between Marszałkowska and the Palace: pale paved plazas, two big lawns either side of a wide axis, loose groves of young trees (locust, ash, ginkgo, magnolia), the pool by the north lawn, a long stone seat-wall with a planted top, wooden step seating with grass strips round a pale heart, the red WARSZAWA letters on two posts, green deckchairs, tall historic-style lamps.

## 2. Massing

Local frame: Marszałkowska's frame (s north, t east of the street's axis), origin s 64, t -130; u north, v east. Zone u -15..15, v -42..20.

| Volume | Plan (u, v) | Height | Source |
| --- | --- | --- | --- |
| Seat-wall | u -14..14, v -39.7..-36.3 (t -170..-166) | 1.1 m + bench 0.4 m | photo 2 *(photo check)* |
| Step wings | u 5.5..13 and -13..-5.5, v -30..8 | 12 rows rising west, 0.1 m each, to 1.2 m | photos 1-2 |
| Pale heart | u -5.2..5.2, v -13..5 | 0.07 m | photo 2 |
| Sign | u -3.8..3.8, v -14 | letters 1.9 m high, 13 m wide, on posts 1.3 m | photo 3 |

## 3. Facade, base to top

Not a building. Seat-wall: rough grey-green stone, gravel bed on top, larch benches on both long sides.

## 4. Roof

None: open sky, nothing above the furniture.

## 5. Colour and material

Stone #7d8077, larch #a98258, grass strips #6f9e42, pale granite #d3cbbf, letters red #c9242b, deckchairs green #58a85a, lamp posts #3d4146.

## 6. Ground and night

Lamp heads glow (M_LAMP). The sign is a landmark sign (lit day and night).

## 7. Detail level and budget

L2, triangle budget 1400 (`plac_centralny`), 700 (`plac_centralny_lamps`). Shots: `--at=-1070,235 --size=110` and a close one from the east with `--yaw=180`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| seat_wall | box | 28 x 3.4 x 1.4 m | u 0, v -38 | M_STONE #7d8077 | the stone seat-wall |
| wall_benches | 2 boxes | 26.4 x 0.6 x 0.4 m | u 0, v -39.2 and -36.8 | M_STONE #a98258 | larch benches |
| step_wings | 24 box pairs | 7.5 x 3.2 m rows | u +-9.25, v 8 to -30 | M_STONE grass and larch | wooden step seating |
| pale_heart | box | 10.4 x 18 x 0.07 m | u 0, v -4 | M_STONE #d3cbbf | the pale paved heart |
| sign_letters | landmark sign | 13 x 1.9 m | u 0, v -14 | neon sign #c9242b | WARSZAWA |
| sign_posts | 2 prisms | 0.16 x 1.3 m | u +-3.8, v -14.4 | M_STONE #8b8f93 | the posts |
| deckchairs | 12 box pairs | 0.56 x 0.5 m | on the heart's east end | M_STONE #58a85a | the deckchairs |
| lamps | 10 poles | 5.3 m | PCZ_LAMPS | M_STONE, M_LAMP head | the lamps |
