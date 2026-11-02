# Moderna Powiśle: spec

Site key `moderna` in `game/scripts/landmarks.gd` (`_find_moderna`, `_build_moderna`). Written
2026-11-02 in a cloud thread from the OpenStreetMap outline and height and the developer's
listing (rynekpierwotny.pl); no photo reachable and no LoD2 here, so which part is old, the
heights of the parts and the colours are estimates *(photo check)*. It replaces the plain block.

## 1. Identity

Moderna Powiśle, Zajęcza 1A, 51 flats: the developer joined a restored pre-war tenement ("fine
plaster") to a new wing with large glass surfaces, ground floor plus six, two-level penthouses.
The card uses a parody of the developer's name: "Modernka Powiśle", PL "Od frontu odnowiona
przedwojenna kamienica, z tyłu nowe szkło i penthouse'y. Wisła trzysta kroków stąd."

## 2. Massing

The mapped outline (about 36 m on Zajęcza, 14.2 m high in OSM) is cut 13.9 m back from its
longest edge (the Zajęcza front; the outline's notch shows where the street block ends):
- front: the tenement, walls to 13.6 m, a cornice 0.3 m proud to 14.2 m;
- back: the new wing to 14.2 m, a penthouse floor pulled in 1.5 m to 17.4 m.

## 3. Facade, base to top

Tenement: cream plaster, tall windows between piers (`M_MONUMENT`), a lighter cornice. New
wing: glass in white floor bands (`S_RIBBON`), penthouse in dark glass (`S_DARK`).

## 4. Roof

Flat, grey `#8b8e90`.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Tenement | #e2d5ba | M_MONUMENT |
| Cornice | #e2d5ba lightened | M_STONE |
| New wing | #4c5966 | M_SKIN S_RIBBON |
| Penthouse | #4c5966 darkened | M_SKIN S_DARK |

## 6. Ground and night

Car collision follows the outline. Night: the new wing's lit floors and the penthouse (skins).

## 7. Detail level and budget

L2, 70 triangles, budget 90. Shots: from Zajęcza (`--at=306,-593`, size 50), looking north.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| tenement | prism | 13.6 m | outline within 13.9 m of the front | M_MONUMENT | |
| cornice | prism | 0.6 m | tenement + 0.3 m | M_STONE | |
| wing | prism | 14.2 m | the rest of the outline | S_RIBBON | |
| penthouse | prism | 14.2-17.4 m | wing pulled in 1.5 m | S_DARK | |
