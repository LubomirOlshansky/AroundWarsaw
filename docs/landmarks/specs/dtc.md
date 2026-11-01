# Domy Towarowe Centrum (the Eastern Wall's stores): spec

Site key `dtc` in `game/scripts/landmarks.gd` (`_find_dtc`, `_build_dtc`, `_dtc_sign`).
Written 2026-11-01 in a cloud thread (first scene item 3, docs/design/first-scene.md) from
the OpenStreetMap parts in `centrum.json`: each store is mapped in 3D (a glazed ground floor
0 to 5.5 m, the curtain-wall box 5.5 to 17.5 m whose outline is the named landmark, and top
parts to 20.5-23.5 m). The reference photos live on the Mac (`refs/`) and were not reachable
here: values marked *(photo check)* are the ones the side-by-side check should confirm.

## 1. Identity

Zbigniew Karpiński's three department stores of 1962-1970 on Marszałkowska's east side,
between Świętokrzyska and Aleje Jerozolimskie, opposite the Palace. Junior stands right of
the car at the game's start; Sawa and Wars follow south towards the Rotunda. What makes a
passer-by say "the Eastern Wall's stores":

1. **Long, low glass boxes** (17.5 m) against the Palace and the towers behind them.
2. **The box floats over a recessed glazed shop floor**: the upper floors cantilever over the
   pavement on all sides, an aluminium slab edge over the shop windows.
3. **Green-tinted curtain walls** with silver floor bands and fine mullions (the 1960s grid).
4. **Their names on the roof** in big lit letters, read from far down Marszałkowska.

## 2. Massing

Per store, all from its OSM parts (no frame of its own: the parts are in world plan).

| Volume | Plan | Heights above ground | Source |
| --- | --- | --- | --- |
| Shop floor | the largest part with mh 0 and h <= 6.5 inside the outline (its jogs are the mapped piers); else the outline drawn in 1.5 m | 0 (from -0.4) to 5.5 m | OSM part h 5.5, #B2E1C7 |
| Fascia | the landmark outline | 5.5 to 6.3 m | the slab edge |
| Curtain wall | the landmark outline | 6.3 to 17.0 m | OSM part h 17.5, mh 5.5, #78B3A1 |
| Cornice and roof | the landmark outline | 17.0 to 17.5 m | |
| Top storey | the outline drawn in 3 m *(photo check: the mapped top parts are partly odd, Sawa's runs on over Wars and starts at 20.5 m)* | 17.5 to 20.5 m | OSM parts h 20.5-23.5, #E4E5DE |

Ground: the lowest terrain under each outline. Junior: 25 x 100 m; Sawa: 27 x 107 m; Wars:
27 x 85 m.

## 3. Facade, base to top

- **Base (0-5.5 m)**: the shop windows all round, glass lit warm from inside at night
  (M_PAVILION), set back under the cantilever by the mapped amount (1-6 m).
- **Fascia (5.5-6.3 m)**: a plain aluminium band all round, the slab's edge.
- **Middle (6.3-17 m)**: the curtain wall in green glass, M_SKIN S_BANDS (silver floor bands
  every 3.8 m, mullions every 1.5 m), lit windows at night.
- **Cornice (17-17.5 m)**: aluminium, the roof's edge.
- **Top storey (17.5-20.5 m)**: pale panels in M_SKIN S_DARK (a fine dark grid), 3 m in from
  the edge on every side.
- **Sign**: the store's parody name (JUNIOREK, SAWKA, WARSIK: brands only as parodies) on a
  steel frame standing on the cornice over the south end, the face the game's camera sees
  from the street (down Marszałkowska); letters at most 3.2 m tall, the word over 75 % of the
  end; lit by day and night like the other landmark signs (`signs`, the neon atlas). Real
  stores carry their names on the street faces *(photo check)*: the south end is a game
  choice for the iso camera, which sees the stores' street faces only edge-on.

## 4. Roof

Flat at 17.5 m, a mid grey; the top storey's roof at 20.5 m a step paler, with a row of roof
lights down its middle (2.8 x 5.2 m, 0.45 m tall, every 7 m, lit at night: M_GLASS_ROOF) and
an air-handling unit (2.8 m square, 1.4 m tall) every third place, 4 m off the middle line.
The roof's plant is an estimate *(photo check: ortho.jpg)*.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Shop windows | #bcd8cf | M_PAVILION (+0, warm at night) |
| Fascia, cornice, sign frame, roof-light kerbs | #d3d7d5 (frame #949795) | M_STONE |
| Curtain wall | #6f9f93 | M_SKIN + S_BANDS / 16 |
| Soffit (the cantilever's underside) | #9ea19f | M_STONE |
| Top storey | #dfe1dc | M_SKIN + S_DARK / 16 |
| Roofs | #6c757a, top storey #737c81 | M_STONE |
| Roof lights | #cfd8dc | M_GLASS_ROOF |
| Air-handling units | #a3aaac, top #8d9497 | M_STONE |
| Sign | tube (1.0, 0.86, 0.55), warm white | neon atlas (LandmarkSigns) |

No new material: everything goes into the city's building surface (+0 draw calls) and the
landmark signs' MultiMesh (+0).

## 6. Ground and night

The car is stopped at the shop floor's outline (not under the cantilever: the pavement is the
footway there). At night the shop floor glows warm, the curtain wall shows lit windows, the
roof lights glow, the names stay lit. The pavement round the stores and the furniture on the
opposite pavement are first-scene items 4-5 (`first_scene.gd`), not this site. Card:
"Domy Towarowe Centrum", PL "Trzy szklane domy towarowe Ściany Wschodniej, 1962–1970. Nazwy
po Warsie i Sawie z legendy.", EN "The Eastern Wall's three glass department stores,
1962–1970, named after the legend's Wars and Sawa."

## 7. Detail level and budget

L2 (facade articulation from the mapped parts), triangle budget 1500 (1267 measured on
2026-11-01, `check_mesh_quality.gd` BUDGET).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shop | prism of the mapped ground part | per store, 5.9 m tall | y -0.4..5.5 | M_PAVILION #bcd8cf | 2 floating box |
| fascia | prism of the outline | 0.8 m tall | y 5.5..6.3 | M_STONE #d3d7d5 | 2 floating box |
| soffit | downward cap of the outline | per store | y 5.5 | M_STONE #9ea19f | 2 floating box |
| wall | prism of the outline | 10.7 m tall | y 6.3..17.0 | M_SKIN S_BANDS #6f9f93 | 1 glass box, 3 curtain wall |
| cornice | prism of the outline, roof | 0.5 m tall | y 17.0..17.5 | M_STONE #d3d7d5, roof #6c757a | 1 glass box |
| top | prism of the outline drawn in 3 m | 3 m tall | y 17.5..20.5 | M_SKIN S_DARK #dfe1dc, roof #737c81 | 1 glass box |
| lights | boxes on the top roof | 2.8 x 5.2 x 0.45 m, every 7 m | the top's middle line | M_STONE sides, M_GLASS_ROOF #cfd8dc | 4 roof |
| plant | boxes on the top roof | 2.8 x 2.8 x 1.4 m | every third place, 4 m off the line | M_STONE #a3aaac | 4 roof |
| frame | two posts and a rail | 0.3 m posts, word width + 0.6 m | the south end, 1 m in from the edge | M_STONE #949795 | 4 names |
| sign | neon word | letters up to 3.2 m | on the frame, facing south | neon atlas | 4 names |
