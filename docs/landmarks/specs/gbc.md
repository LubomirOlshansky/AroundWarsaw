# Gdański Business Center (site `gbc`): spec

Site key `gbc` (`landmarks.gd` `_find_gbc`, `_build_gbc`). Written 2026-11-02 from F's four
photos (the angled blue tower with the slanted crown; the two ten-storey glass blocks with white
floor bands, a dark top floor and logo boxes, round a landscaped plaza) and four unnamed
OpenStreetMap parts in `centrum.json` between Inflancka, Rondo Mackiewicza and Dworzec Gdański:
a 74 m tower at (-2017, -2487), 45 m blocks at (-1996, -2429) and (-2081, -2384), a 31 m
block at (-2105, -2428). The Mac photo check is open (QUESTIONS).

## 1. Identity

An office complex of 2007-2013 by the Gdański station: one tower and the blocks beside it, built
from their mapped outlines. The tenants' logos are parodies (AWIWA on the tower, NIELZEN on the
blocks).

## 2. Massing

Each mapped part lofted: tower to 74 m with its notched footprint, the blocks 45 m and 31 m.
The tower's crown is cut on a slant, high to the north, 7.5 m lower to the south.

## 3. Facade, base to top

Lit lobby 5 m; tower: blue glass in a fine grid (S_GRID); blocks: glass between white floor
bands (S_RIBBON), pale blue-green.

## 4. Roof

Blocks: a dark top floor 3.8 m tall, 0.5 m proud of the glass, a grey roof, the logo on its
long faces. Tower: a dark slanted crown 3 m deep at the low end, a grey roof.

## 5. Colour and material

Glass #5f86ae (tower), #7f9fa6 (blocks), dark #2a2d33, roof #9ba1a5. Existing M_SKIN, M_STONE and
M_PAVILION only; two neon words (AWIWA, NIELZEN in `neon_signs.gd` LANDMARK_WORDS).

## 6. Ground and night

The plaza, paths and trees are the map's own. Car stops at every outline. Windows glow at night;
lobbies are lit warm.

## 7. Detail level and budget

L2, triangle budget 750 (`check_mesh_quality.gd`; built 622).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| tower_lobby | prism | outline, 5 m | (-2017, -2487) | M_PAVILION | lit ground floor |
| tower_body | prism + grid skin | outline, to 74 m less crown | same | S_GRID #5f86ae | blue shaft |
| tower_crown | sloped prism | outline + 0.35 m, 7.5 m fall | top | dark #2a2d33 | slanted crown, AWIWA sign |
| block_lobby | prism | outline, 5 m | (-1996, -2429), (-2081, -2384), (-2105, -2428) | M_PAVILION | lit ground floor |
| block_body | prism + ribbon skin | outline | same | S_RIBBON #7f9fa6 | white floor bands |
| block_crown | prism | outline + 0.5 m, 3.8 m | top | dark #2a2d33 | dark top floor, NIELZEN sign |
