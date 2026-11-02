# Warszawa Śródmieście (site `srodmiescie`)

Written 2026-11-01 for F's railway ask (docs/design/railway.md, S3b). No reference photos in the
cloud; measured from the two OpenStreetMap outlines in `centrum.json` ("PKP Warszawa
Śródmieście", two 7 m buildings of about 10 x 43 m at (-1152, 520) and (-1086, 495), between Aleje
Jerozolimskie and Pankiewicza) and the facts on Wikipedia (the station is underground; above
ground two rectangular buildings by Romanowicz and Szymaniak, "oversized shelters" for the stairs
down to the platforms). The Mac photo check (`refs/srodmiescie/`) is open: the glazing, the
fascia's height and material, the lettering.

## 1. Identity

The cross-city line's underground station of 1963 by the Palace of Culture. Above ground there
are only two long, low pavilions over the stairs: glass halls under a deep light fascia, the
station's name on them.

## 2. Massing

- Each pavilion: its OSM outline (simplified at 0.3 m), a dark plinth, glass walls to 4.4 m,
  the fascia 0.7 m proud of the glass from 4.4 m to 6.9 m (the OSM height is 7 m).

## 3. Facade, base to top

- Plinth: dark granite, 0.4 m over the ground.
- Glass (M_PAVILION, lit at night) in 1.6 m bays with dark mullions.
- Fascia: light stone panels, its soffit grey.

## 4. Roof

Flat, the fascia's top, a little darker than its sides.

## 5. Colour and material

Stone #dcd8cd, plinth #4a4b4d, glass #4f6a78, dark #2a2c2f, neon cool blue. Everything in the
city's one building surface (M_STONE, M_PAVILION) plus one neon word (ŚRÓDMIEŚCIE in
`neon_signs.gd` LANDMARK_WORDS): no new draw calls beyond the sign's.

## 6. Ground and night

The square, the streets and the underground station are the map's own. At night the halls glow
and ŚRÓDMIEŚCIE burns blue on each fascia's long side that the game's camera sees. Car collision
round both halls.

## 7. Detail level and budget

L2, budget 580 triangles (in `check_mesh_quality.gd`; built 476).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | prism | each outline, 0.4 m | both pavilions | dark granite | the base |
| halls | glass prism + mullions | each outline, 4.4 m | (-1152, 520), (-1086, 495) | M_PAVILION | the stair halls |
| fascia | prism | outline + 0.7 m, 4.4-6.9 m | over each hall | light stone | the deep band |
| neon | sign | ŚRÓDMIEŚCIE | each fascia, camera side | blue neon | the station's name |
