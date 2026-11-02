# Arkadka (Westfield Arkadia) and the Forest's terrace: spec

Site keys `arkadia` and `forest` in `game/scripts/landmarks.gd` (`_build_arkadia`, `_build_forest`,
`_forest_terrace`, `_forest_bank_sign`). Redesigned 2026-11-01 in a cloud thread (F: "redesign Arkadia,
and on the Forest building a bank logo and a terrace"). From the OpenStreetMap outline (158 points,
about 300 x 330 m, 10.9 m in OSM, 21 m built) and public facts: Arkadia opened 2004 by Rondo
Radosława, the city's biggest mall, with a car park on its roof. There is no photo here: the colours
and the pyramid skylights are a first pass *(photo check)*. The real bank in the Forest tower is
never named: its parody is BANK PEPEO ("pepeo" is ash; F's spelling).

## 1. Identity

1. **A huge low block** with a lit glass shop-front storey, cream upper floors and a terracotta band.
2. **A roof car park** on the 21 m deck: rows of parked cars, three glass-pyramid skylights, floodlights.
3. **The entrance rotunda** on the north side: glass drum, white fins, a crown with ARKADKA on four faces.
4. **Forest**: a 120 m dark green glass tower with BANK PEPEO near its crown, and on its 27.4 m wing a
   planted roof terrace with parasols, tables and people.

## 2. Massing

Arkadia: the outline `_simplify`d to 1.5 m, 21 m high (ARKADIA_TOP), shop storey 5.6 m, deck parapet
1.1 m. Forest: the two OSM parts over 25 m: tower 120 m (52 x 37 m) and the wing 27.4 m (26 x 54 m).

## 3. Facade, base to top

- Arkadia: 0..5.6 m glass lit from inside (M_PAVILION); 5.6..17 m cream plaster #e6dccb with punched
  windows (M_SKIN S_PUNCHED); 17..20 m terracotta band #c47a55; 20..21 m pale cornice #e9e4d8.
- Three entrance canopies, 16 x 3.4 m at 4.7 m on two posts, midway on the three longest faces, each
  with a small ARKADKA board at 7.4 m.
- Rotunda: 12-sided glass drum r 9.9 m from 21 to 30 m, twelve fins 0.44 m, ring cornice, white crown
  30..37 m, ARKADKA on N, S, E, W at 31.4 m.
- Forest tower: unchanged skin (fins); BANK PEPEO 1.9 scale (about 23 m wide) on four faces 7 m under the
  crown, warm white (#ffb873, not the real bank's red).

## 4. Roof

Arkadia: deck #77797a with a 1.1 m parapet (cream, seen from both sides); three skylight strips
(glass, 10 m wide, each with 18 m glass pyramids 3.8 m high); four 8 m stair cores 3.6 m high;
floodlight masts 6.5 m on a 45 m grid (lit heads, max 40); up to 1500 parked cars (1.8 x 4.2 x 1.45 m,
seeded muted colours, back-to-back rows with 5.9 m aisles, a 55 % fill), straight into the mesh and not
into the roof grid. Forest wing: timber deck #a98457 at +0.1 m inside a 1.1 m glass balustrade,
planters with small trees every 7 m, round tables with three stools, parasols (4 colours) on a 7.5 m
grid, all outside the roof grid. People: crowds.gd DECKS `forest_terrace` (max 14, open 11-23 *guess*,
24 spots inside the planters).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Shop storey | #a9c6d2 | M_PAVILION |
| Upper walls | #e6dccb | M_SKIN S_PUNCHED |
| Band | #c47a55 | M_STONE |
| Cars | 8 muted paints, lid 25 % darker | default |
| Terrace deck | #a98457 | M_STONE |
| Balustrade | #c9dcdc | M_PAVILION + 0.5 |

## 6. Ground and night

Car stops at the outline (`_collide`). The shop storey glows at night; the car park's floodlights glow
(M_LAMP); BANK PEPEO and ARKADKA are neon signs. The terrace crowd is there from 11:00 to 23:00.

## 7. Detail level and budget

L2, triangle budget 20300 (an exception to the L2 limit: a 300 m mall with its car park; 16900 measured plus 20 %; the parked cars are 1500 x 10 of it, in the one landmark
mesh, no new draw call); Forest budget 1500 (1244 measured plus 20 %). Shots: `--at=-2780,-2480 --yaw=20 --pitch=-25 --size=90` and
`--at=-2945,-2405 --yaw=250 --pitch=-35 --size=45`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shop | prism of the outline | 5.6 m | ring | M_PAVILION | 1 block |
| upper | prism | 11.4 m | y 5.6..17 | M_SKIN S_PUNCHED | 1 block |
| band | prism | 3 m | y 17..20 | M_STONE | 1 block |
| deck | cap and parapet | 1.1 m | y 21 | M_STONE | 2 car park |
| skylights | 3 strips, pyramids | 10 m, 3.8 m | across ±70 m | M_GLASS_ROOF | 2 car park |
| cars | up to 1500 boxes | 1.8 x 4.2 m | bay grid | default | 2 car park |
| rotunda | 12-gon, fins, crown | r 9.9 m, 37 m | (-2778, -2470) | M_PAVILION, M_STONE | 3 rotunda |
| canopies | 3 slabs | 16 x 3.4 m | longest faces | M_STONE | 1 block |
| bank signs | 4 neon words | 23 m | tower, 113 m | neon | 4 Forest |
| terrace | deck, balustrade, planters, parasols | 26 x 54 m | wing, y 27.4 | M_STONE | 4 Forest |
