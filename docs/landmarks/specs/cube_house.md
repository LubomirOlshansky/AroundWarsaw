# Cube House: spec

Site key `cube_house` in `game/scripts/landmarks.gd` (`_find_cube_house`, `_build_cube_house`).
Written 2026-11-02 in a cloud thread from the OpenStreetMap outline and height; no photo and no
LoD2 here, so the bays and colours are estimates *(photo check)*. It replaces the plain block.

## 1. Identity

Cube House, a block of flats on Topiel by Leszczyńska in Powiśle. Card: "Cube House", PL "Biała
kostka przy Topieli, z wykuszami jak wysunięte szuflady."

## 2. Massing

The mapped outline is near square, about 14 by 17.5 m, with a 1.8 m full-height bay on one face;
one prism to 27.4 m (the OSM height), a plain parapet band 0.12 m proud from 26.9 to 28.0 m.

## 3. Facade, base to top

White cladding with punched windows (`S_PUNCHED`, 2.95 m floors). On every face a staircase of
boxed bays ("the cubes"), 2.8 m wide, 1.1 m proud, one per floor from the first to the seventh,
stepping between two spots a quarter of the face either side of its middle (on the jogged face,
0.15 so they stay on the bay's front) *(photo check: where the real bays or loggias are)*. The
bays are warm grey with the same punched windows.

## 4. Roof

Flat, grey `#86898c`, inside the parapet band.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Body, parapet | #e9e7e1 | M_SKIN S_PUNCHED / M_STONE |
| Bays | #b3aca0 | M_SKIN S_PUNCHED |
| Roof | #86898c | M_STONE |

## 6. Ground and night

Car collision follows the simplified outline. Night: warm windows from the skin.

## 7. Detail level and budget

L2, 324 triangles, budget 390. Shots: from Leszczyńska (default yaw), day and night, both paths.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | prism | 27.4 m | mapped outline | S_PUNCHED | punched windows |
| parapet | prism | 1.1 m | outline + 0.12 m | M_STONE | roof band |
| bay x28 | box | 2.8 x 1.6 x 2.65 m (0.5 m sunk) | four faces, floors 1-7 | S_PUNCHED | the cubes |
