# Plac Bankowy's palaces: spec

Site keys `ratusz` and `gielda` in `game/scripts/landmarks.gd` (`_build_ratusz`, `_bank_colonnades`,
`_bank_portico`, `_build_gielda`); the third palace, `wojewodzki`, stays a skin. Written 2026-11-02
in a cloud thread from the Mac's reference set (`refs/ratusz/`, 9 Wikimedia Commons photos and a
GUGiK orthophoto; report `docs/landmarks/photo-reports/ratusz.md`), OpenStreetMap's building parts
(the columns are mapped one by one, with heights) and GUGiK LoD2. The masses stay LoD2's in their
skins; the models add what LoD2 squashes into stubs.

## 1. Identity

Antonio Corazzi's palaces on the west side of Plac Bankowy (1825-1830), one long pale front.

1. **Pale ochre-cream walls under green copper roofs** (the old skins were a drab yellow under grey).
2. **The Ratusz's cour d'honneur** open to the square, both wings ending in **colonnades of
   free-standing white columns** two storeys tall, about a dozen each, under an entablature.
3. **The giant portico** of six Corinthian columns at the court's back, on an arcaded base, under
   an attic with no pediment.
4. **The Bank Polski's rounded corner** at Bielańska: the open arcade on piers, a tier of round
   arches over it, and the drum with its shallow green dome.

## 2. Massing

World frame for the colonnades (column centres are OSM's). Portico frame: origin (-1587.6, -995.69)
(the north-east front column), u along the row to (-1595.27, -1010.9) (17.05 m), +v into the court
(north-east). Rotunda: centre (-1479.7, -894.85), the drum r 12.05 m to 17.5 m, the corner's upper
face r 15.75 m.

| Part | Where | Heights over the ground |
| --- | --- | --- |
| Colonnades | 34 mapped columns (h 10.2 m over 1.6 m) in chains closer than 3.45 m | stylobate -0.5 to 1.6, columns to 10.2, entablature to 11.2, cornice to 11.6 |
| Giant portico | u 0..17.05, v -5.2..1.0 | base -0.6 to 6.6, columns to 16.8, entablature to 18.2, cornice to 18.7, attic to 21.2 |
| Arcade piers | 8 at the mapped piers round the corner, 2.4 m square | -0.5 to 7.1 |
| Upper tier | 7 arches between the piers, r 15.75 | 7.5 to 12.45 |
| Drum | r 12.17, 32 sides | -0.5 to 17.5, cornice to 18.1 |
| Dome | spherical cap, 4 rings | 18.1 to 22.1, a round light to 23.0 |

## 3. Facade, base to top

Colonnades: a stone stylobate under each chain, white columns (base, 8-sided shaft, capital), a
cream entablature and a cornice with a lead top. Portico: the rusticated base with a round arch
under each of its five bays and a string course; six columns r 0.74 m; the back wall a shade darker
with five tall round-headed windows; the entablature, cornice and plain attic. Rotunda corner: the
piers in wall colour, the cornice band at 7.1 m, an arched window with a cream surround over each
opening, the cornice at 13.6 m, then the drum with sixteen round-headed windows.

## 4. Roof

Green copper (#7da894) on all three palaces through the skins (LoD2's own roof shapes); the dome a
spherical cap in the same copper, rings slightly darker towards the top, a round light on top.

## 5. Colour and material

Walls #e6d6ae (the report's pale ochre-cream), columns #f2eee3, trim #ece4cc, base #cdbf98, roofs
#7da894, openings #27303a, lead #a3aaa8. M_STONE for the model, M_GLASS for the windows, the
skins M_MONUMENT. No new material.

## 6. Ground and night

Columns and piers stand on the terrain under them; the colonnades' stylobates and the portico's
base are the car's. At night the windows take the city's glow; no floodlights.

## 7. Detail level and budget

L2. `ratusz` 2054 triangles (budget 2500), `gielda` 874 (budget 1050) in check_mesh_quality.
Shots: the wings `--at=-1546,-1026 --yaw=90 --size=50`, the portico `--at=-1572,-996 --yaw=100
--size=35 --pitch=-30`, the corner `--at=-1460,-893 --yaw=90 --size=35`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| skins | LoD2 mass | the three outlines | Ratusz, Voivodeship, Bank | M_MONUMENT #e6d6ae / #7da894 | 1 colours |
| col_columns | 34 columns | r 0.68-0.73 m, 1.6-10.2 m | OSM's column parts | M_STONE #f2eee3 | 2 colonnades |
| col_stylobate | bands | 2.6 m wide | under each chain | M_STONE #cdbf98 | 2 colonnades |
| col_entablature | bands | 1.6 m wide, 1.0 m | over each chain | M_STONE #ece4cc | 2 colonnades |
| col_cornice | bands | 2.0 m wide, 0.4 m | over each chain | M_STONE #ece4cc, top #a3aaa8 | 2 colonnades |
| por_base | box | 19.1 x 6.2 m, 7.2 m | portico frame | M_STONE #cdbf98 | 3 portico |
| por_arches | 5 arches | 2.1 m wide | the base's front | M_STONE #27303a | 3 portico |
| por_columns | 6 columns | r 0.74 m, 10.2 m | the row | M_STONE #f2eee3 | 3 portico |
| por_windows | 5 arches | 1.7 m wide | the back wall | M_GLASS #27303a | 3 portico |
| por_attic | 4 boxes | 19.5 x 6.6 m | over the columns | M_STONE #e6d6ae / #ece4cc | 3 portico |
| rot_piers | 8 boxes | 2.4 x 2.4 m, 7.6 m | round the corner | M_STONE #e6d6ae | 4 rotunda |
| rot_arches | 7 arches | 2.5 m wide | the upper tier | M_STONE #ece4cc, M_GLASS #27303a | 4 rotunda |
| rot_bands | 2 curved bands | 1.75 m deep | 7.1 and 13.6 m | M_STONE #ece4cc | 4 rotunda |
| rot_drum | 32-sided prism | r 12.17 m | the centre | M_STONE #e6d6ae | 4 rotunda |
| rot_windows | 16 arches | 1.2 m wide | the drum | M_GLASS #27303a | 4 rotunda |
| rot_dome | 4 frustums | r 12.25 m, rise 4 m | over the drum | M_STONE #7da894 | 4 rotunda |
