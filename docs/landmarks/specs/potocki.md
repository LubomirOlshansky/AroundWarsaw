# Pałac Potockich (Potocki palace): spec

Site key `potocki` in `game/scripts/landmarks.gd` (`_build_potocki`). Written 2026-11-01 in a cloud thread (BACKLOG K4) from the OpenStreetMap outline in `centrum.json`; no photo, no LoD2 here. Values marked *(photo check)* wait for the Mac's `refs/`. The mass stays the kept LoD2 skin (pale yellow plaster, grey roof); the model adds the court front of the main block.

## 1. Identity

Palace at Krakowskie Przedmieście 15 (baroque, rebuilt in the 18th century, today the Ministry of Culture), its main block closing a court open to the street.

## 2. Massing

Frame: origin (-683.3, -919.0) (the main block's court face, south end), u north along the front (axis (-0.2, -0.98), 50 m), +v east into the court. Eaves at 12.4 m, cornice to 13.2 m; central pavilion u 20..30, forward 1.2 m; pediment apex 15.4 m *(photo check)*.

## 3. Facade

A plinth, a string course at 5.6 m, corner pilasters and a cornice along 50 m. The pavilion: a stone ground floor to 6 m, a window storey, four pilasters, a door (2.4 x 4 m) with two steps, an upper window, a heavy cornice and a triangular pediment with a dark oculus.

## 4. Roof

Gable roof over the pavilion only, dark grey slopes (#7a6e68); the rest is the skin's roof.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster | #e8d9a8 | M_STONE, M_MONUMENT |
| Trim | #f4eedd | M_STONE |
| Plinth, steps | #b3a994 | M_STONE |
| Door, windows | #3a3d40 | M_GLASS |

No new material or draw call.

## 6. Ground and night

Car stopped by the steps. Card: "Pałac Potockich". Open *(photo check)*: the real colour, the pediment's sculpture, the street fence and gate.

## 7. Detail level and budget

L2; 166 triangles measured, budget 200 (`check_mesh_quality.gd`).

Shot: `--at=-690,-940 --yaw=245 --pitch=-22 --size=60 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | box | 50.4 x 0.6 m, 1.8 m high | u 25 | M_STONE | 3 facade |
| string course, cornice | 2 boxes | 50 x 0.4 m; 50.8 x 1.4 m | 5.6 m; 12.4..13.2 m | M_STONE | 3 facade |
| corner pilasters | 2 boxes | 1.2 x 0.6 m, 11.2 m high | u 0.6, 49.4 | M_STONE | 3 facade |
| pavilion | 2 boxes | 10 x 1.2 m, 4.8 and 6.4 m high | u 25, 1.2..12.4 m | M_STONE, M_MONUMENT | 3 pavilion |
| pavilion pilasters | 4 boxes | 0.8 x 0.6 m, 11.2 m high | u 20.4, 23.4, 26.6, 29.6 | M_STONE | 3 pavilion |
| door, window | 2 dark panes | 2.4 x 4 m; 1.8 x 3.4 m | u 25 | M_GLASS | 3 pavilion |
| steps | 2 boxes | 4.8 and 4 m wide | in front of the door | M_STONE | 3 pavilion |
| pediment | gable and oculus | 10.4 m wide, rise 2.2 m; oculus r 0.7 m | 13.2..15.4 m | M_STONE | 4 roof |
