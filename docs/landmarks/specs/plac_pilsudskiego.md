# Plac Piłsudskiego (monuments, masts, paving): spec

Site keys `smolensk`, `pilsudski`, `kaczynski` and `plac_maszty` (no card) in `game/scripts/landmarks.gd` (`_find_plac_photos`, `_build_smolensk`, `_build_pilsudski`, `_build_kaczynski`, `_build_plac_masts`), and the paving's chequer in `game/shaders/ground.gdshader` (`plac_at`). Written 2026-11-02 in a cloud thread from the Mac's reference set `refs/pilsudskiego/` (6 Wikimedia Commons photos, the GUGiK ortho at 0.104 m/px; report `docs/landmarks/photo-reports/pilsudskiego.md`, authors and licences there). The three monuments were generic OSM pieces (`tools/bake_monuments.py` now skips them). No humour on any of them.

## 1. Identity

The city's ceremonial square: a wide field of grey granite in ~6 m squares, a chequer of lighter and darker panels outlined by darker bands (photos 1, 3), ringed by tall thin masts; on it the black stepped memorial to the victims of the 2010 Smolensk air crash (photos 5-6), Lech Kaczyński's bronze on its dark stepped pedestal, and across the east road Józef Piłsudski in a greatcoat, hands on his sabre, on a rough granite block (photo 4).

## 2. Massing

- Smolensk memorial at (-765, -737) (ortho; OSM (-761, -736)): 8 black steps, 6 m long (north-south), 4 m deep, 9.7 m tall, sheer to the west, stepping down to the east; on a 9 x 7.2 m base of dark glass with a water film.
- Kaczyński at (-677, -762.3): OSM maps his pedestal as two 2.5 m "buildings" (x -681.7..-672.3, z -768..-756.7) beside the statue node (-671.3, -762.7); the model replaces them with three dark granite tiers (9.6 x 10.8 m to 0.8 m, 6.8 x 7.8 m to 1.65 m, 4 x 4.6 m to 2.5 m) and a 3.6 m standing figure. The report read a statue's shadow at (-745, -823); that is the Papal Cross (OSM (-738, -817)), which stays the generic cross.
- Piłsudski at OSM's (-673.3, -817.8) (the ortho is censored there): a 3.2 m footing, the rough block 2.6 x 2.5 m tapering to 3.1 m, the figure 3.4 m: 6.5 m in all. Both statues face the square's centre (-780, -800).
- Masts: ten, five along each long side of the field (z ~-864 and ~-740), 14 m, with a lamp head.
- Paving: `PLAC_BOX` x -840..-718, z -868..-735 (the report's paved field), over bare ground, footpaths and plaza layers only.

## 3. Facade, base to top

Smolensk: polished black faces, the treads a shade lighter. Piłsudski: a pale lettering panel (JÓZEF PIŁSUDSKI / I MARSZAŁEK POLSKI is not drawn as text) and two bronze eagle badges on the front corners, the sabre before the figure. Kaczyński: plain dark tiers.

## 4. Roof

None (monuments and masts).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Smolensk stone | #1e1e22 | M_STONE |
| Smolensk base glass, water | #2b3a42, #4c6670 | M_STONE |
| Bronze | #4a4f46 | M_STONE |
| Piłsudski's granite | #8f8d88 | M_STONE |
| Kaczyński's granite | #2e3032 | M_STONE |
| Masts, lamp heads | #9a9c9e, #f4eedc | M_STONE, M_LAMP |
| Paving panels, bands | #b4b4b0 / #999995, #8e8f8c | ground shader |

No new material or draw call (the probe below).

## 6. Ground and night

The lawns stay the map's (the Saxon Palace's reconstruction site west of x -830 in the 2025-26 ortho is not shown: parked for F). Each monument and mast has a car wall. The mast heads glow at night. Cards: "Pomnik Ofiar Tragedii Smoleńskiej", "Pomnik Józefa Piłsudskiego", "Pomnik Lecha Kaczyńskiego"; the masts have none.

## 7. Detail level and budget

L2, triangle budgets: smolensk 120 (built 100), pilsudski 160 (134), kaczynski 100, plac_maszty 520 (480).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| smolensk_base | 2 boxes | 9 x 7.2 x 0.65 m | (-765, -737) | M_STONE #2b3a42 | glass and water |
| smolensk_steps | 8 boxes | 6 x 4 to 0.5 m, 9.7 m | on the base | M_STONE #1e1e22 | black stair |
| pilsudski_block | box, frustum, panel, badges | 2.6 x 2.5 x 3.1 m | (-673.3, -817.8) | M_STONE #8f8d88 | granite block |
| pilsudski_figure | figure, sabre | 3.4 m | on the block | M_STONE #4a4f46 | the Marshal |
| kaczynski_pedestal | 3 boxes | 9.6 x 10.8 to 4 x 4.6 m, 2.5 m | (-677, -762.3) | M_STONE #2e3032 | stepped pedestal |
| kaczynski_figure | figure | 3.6 m | on the pedestal | M_STONE #4a4f46 | the President |
| masts | footing, frustum, head | 14 m | PLAC_MASTS | M_STONE, M_LAMP | masts |
| paving | ground shader | 6 m panels, 0.27 m bands | PLAC_BOX | ground.gdshader | chequer |
