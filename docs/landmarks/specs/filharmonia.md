# Filharmonia Narodowa: spec

Site key `filharmonia` in `game/scripts/landmarks.gd` (`_build_filharmonia`, `_fil_composer`).
Written 2026-11-02 in a cloud thread from the Mac's reference set (`refs/filharmonia/`, 3 Wikimedia
Commons photos and a GUGiK orthophoto; report `docs/landmarks/photo-reports/filharmonia.md`), the
OpenStreetMap outline and GUGiK LoD2. The mass stays LoD2's in a skin; the model is the Jasna front.

## 1. Identity

The National Philharmonic on Jasna (Karol Kozłowski, 1901; rebuilt 1955).

1. **A giant order of smooth cream-white columns** along the Jasna front, two to three storeys.
2. **A white stone composer on each window sill** between the columns, behind an iron balconette.
3. **The corner's green neon**: the FN roundel and SALA KONCERTOWA (the institution's own name).

## 2. Massing

Frame: origin (-860.7, -77.7), the mapped front's north end; u along it to (-837.6, -27.0) (55.7 m),
+v out of it to Jasna (east). Corner bays 4.8 m solid at both ends, eleven columns between them
(bay 4.6 m).

| Part | Where (u, v) | Heights over the ground |
| --- | --- | --- |
| Face | 0..55.7, -0.25..0.35 | 4.5 to 15.0 m |
| Base | -0.2..55.9, -0.25..0.75 | -0.6 to 4.5 m |
| Columns | u 4.8 + k 4.6, v 1.55, r 0.62 | 4.5 to 15.0 m |
| Entablature, cornice | v -0.55..2.6 | 15.0 to 16.65 m |
| Attic | v -0.25..0.45 | 16.65 to 18.0 m |

## 3. Facade, base to top

The rusticated base with ten ground-floor round-headed windows; a string course at 4.15-4.5 m; in
each bay a tall round-headed window (2 m wide, 5.7 to 13.4 m), a sill, a dark iron balconette and a
standing composer in white stone (2.6 m, a cloak to the ankles, a hand at the chest); the columns
in front; the entablature, the cornice and a plain attic.

## 4. Roof

LoD2's roof shapes in the skin's lead grey (#8e9392); the raised hall roof in the middle stays LoD2's.

## 5. Colour and material

Walls #e3ded2 (the report), columns #ede9de, base #c9c3b5, statues #f1efe9, windows #232a33,
iron #2b2c2e, lead #a2a7a8, neon green (0.2, 1.0, 0.45). M_STONE, M_GLASS; the skin M_MONUMENT.
The neon words FN, SALA and KONCERTOWA (two rows: as one the hall's name is wider than the atlas) join neon_signs.gd's LANDMARK_WORDS.

## 6. Ground and night

On the terrain at the front's ends; the base's line is the car's. At night the FN roundel and the
hall's name glow green on the Sienkiewicza corner, the windows take the city's glow.

## 7. Detail level and budget

L2, 1196 triangles, budget 1450 (check_mesh_quality). Shot: `--at=-838,-55 --yaw=75 --size=35
--pitch=-58`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| skin | LoD2 mass | the outline | Jasna 5 | M_MONUMENT #e3ded2 / #8e9392 | colour |
| face | box | 55.7 x 0.6 m, 10.5 m | the front | M_STONE #e3ded2 | facade |
| base | box | 56.1 x 1.0 m, 5.1 m | the front | M_STONE #c9c3b5 | facade base |
| columns | 11 columns | r 0.62 m, 10.5 m | v 1.55 | M_STONE #ede9de | 1 the colonnade |
| windows | 10 arches | 2.0 m wide | between the columns | M_GLASS #232a33 | facade |
| sills | 10 boxes | 2.3 x 0.7 m | under the windows | M_STONE #e3ded2 | 2 composers |
| balconettes | 10 boxes | 2.2 x 0.06 m, 0.95 m | on the sills | M_STONE #2b2c2e | 2 composers |
| composers | 10 figures | 2.6 m | on the sills | M_STONE #f1efe9 | 2 composers |
| entablature | 2 boxes | 56.1 x 3.2 m, 1.65 m | over the columns | M_STONE #ede9de | 1 the colonnade |
| attic | box | 55.9 x 0.7 m, 1.35 m | over the face | M_STONE #e3ded2 | facade |
| roundel | disc | r 1.5 m | the Sienkiewicza corner | M_STONE #232a33 | 3 the neon |
| neon | 3 words | FN, SALA / KONCERTOWA | the corner | neon sign | 3 the neon |
