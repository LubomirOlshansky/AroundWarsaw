# Bazar Różyckiego (Targowa): spec

Site key `bazar` in `game/scripts/landmarks.gd` (`_find_bazar`, `_build_bazar`, `_bazar_*`).
Written 2026-11-02 in a cloud thread from the Mac's photo report
`docs/landmarks/photo-reports/bazar_rozyckiego.md` (one 2023 Commons photo and the GUGiK
orthophoto) and the 26 retail outlines OpenStreetMap maps in the market yard (4.3 m each). No
gate photo: the gate on Targowa is not built *(photo check)*.

## 1. Identity

Warsaw's oldest market (Julian Różycki, 1882), between Targowa and Brzeska. What makes it read:
a **dense patchwork of low old stalls** (tin and tarp roofs in grey, blue and rust, awnings,
crates) facing the **2023 rebuild's grid of dark green box kiosks with flat white-edged roofs**,
narrow paved lanes between them, tenements all round.

## 2. Massing

Found by position: every retail outline of at most 5 m whose centre lies in BAZAR_BOX
(x 1025..1135, z -2032..-1962). The 16 regular boxes (four corners at right angles, 45-75 m^2:
twelve 5.7 x 9.7 m in a grid, four 5.8 x 11.7 m by Targowa) are the new kiosks, 3.1 m tall with a
0.3 m roof slab. The other 10 outlines (strips up to 46 x 8 m, and the L-shaped 80 x 43 m mass)
are the old stalls: each cut along its longest edge into stalls 2.6-4.2 m wide, each cell
clipped to the outline, 2.5-3.3 m tall (seeded by position, the same on both city paths).

## 3. Facade, base to top

Kiosks: a dark plinth (0.45 m), dark green walls, on each long side two or three units (by
length), each a lit window (warm, M_PAVILION) or a grey roller shutter from 0.35 to 2.5 m; the
roof slab overhangs 0.35 m all round with a white fascia. Old stalls: a faded wall colour each;
on a whole (rectangular, under 14 m deep) stall an awning 1.3 m out over one long side, a dark
open front or a shutter under it, and on most open ones a crate stack before it.

## 4. Roof

Kiosks: flat, green #3b7a62, white edge. Old stalls: flat, each its own patch (tin grey, blue
tarp, rust, felt) so from above the north-west reads as the patchwork the orthophoto shows.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Kiosk walls | #2f6b55 | M_STONE |
| Kiosk roof, fascia | #3b7a62, #e9ece6 | M_STONE |
| Lit windows | warm (1.0, 0.84, 0.58) | M_PAVILION |
| Shutters | #9a9c98 | M_STONE |
| Stall walls | #b9b2a2 #8f9a9e #c7b98f #7f8f7a #a46d52 #d6d0c2 #6f7d8c | M_STONE |
| Stall roofs | #7d8084 #3f6fa8 #8a5638 #5e5d59 #9a9a94 #4f7fb0 #6e4a36 | M_STONE |
| Awnings | #c0392b #2e6da4 #e0b33a #3f8f5a #e7e2d6 | M_STONE |
| Crates | #a7814f | M_STONE |

No new material or draw call.

## 6. Ground and night

The lanes, the grass and the play area stay the map's. At night the lit kiosk windows glow.
Car collision on every kiosk and every stall cell. Card: "Bazar Różyckiego", PL "Najstarszy bazar
Warszawy, od 1882 roku. Stare budy obok nowych zielonych pawilonów. Kupisz tu wszystko.", EN
"Warsaw's oldest market, since 1882. Old sheds face the new green kiosks. Everything is for
sale." Open *(photo check)*: the gate on Targowa and its lettering, the kiosks' real unit count,
whether the four boxes by Targowa are new kiosks.

## 7. Detail level and budget

L2, triangle budget 2210 (1839 measured; `check_mesh_quality.gd`, `bazar`). Shot:
`--at=1060,-1960 --yaw=20 --pitch=-40 --size=90 --time=day --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| kiosk | box + plinth | the OSM box, 3.1 m | 16 outlines | M_STONE | 1 kiosks |
| kiosk roof | slab | box grown 0.35 m, 0.3 m | on each kiosk | M_STONE | 1 kiosks |
| kiosk fronts | panels | 2-3 per long side, 2.15 m high | long sides | M_PAVILION, M_STONE | 1 kiosks |
| stall | clipped prism | 2.6-4.2 m wide, 2.5-3.3 m | 10 outlines | M_STONE | 1 stalls |
| awning | sloped quad | stall width x 1.3 m | one long side | M_STONE | 1 stalls |
| stall front | panel | stall width - 0.8 m | under the awning | M_STONE | 1 stalls |
| crates | box | 0.7 x 0.56 x 0.55 m | before open stalls | M_STONE | 6 ground |
