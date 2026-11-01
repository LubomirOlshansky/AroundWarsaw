# Kordegarda (the guardhouse of Pałac Potockich): spec

Site key `kordegarda` in `game/scripts/landmarks.gd` (`_build_kordegarda`). Written 2026-11-01 in a cloud thread (BACKLOG K4) from the OpenStreetMap outline in `centrum.json`; no photo, no LoD2 here. Values marked *(photo check)* wait for the Mac's `refs/`. OSM maps it 4.3 m tall, a shed; the model builds the whole building from the mapped outline instead of a skin.

## 1. Identity

The palace's old guardhouse in the court by the street (today Galeria Kordegarda): a low, formal building with a columned front.

## 2. Massing

Frame: origin (-626.3, -947.4) (the street face's south end), u north along it (axis (-0.239, -0.971), 16 m), +v east to the street. The mapped C-shaped outline (13 x 19 m) raised to 6.4 m with a 1.1 m plinth *(photo check: real height)*.

## 3. Facade

A plinth, a plaster window storey (M_MONUMENT), an eave band with a parapet; on the street face a portico: a stylobate, four columns (r 0.32 m) under an entablature and a triangular pediment, a dark door behind.

## 4. Roof

Flat roof under a parapet (the original hipped roof is not modelled); portico pediment grey (#6c6a66).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster | #e8dcb4 | M_MONUMENT |
| Trim, columns | #f4eedd | M_STONE |
| Plinth | #b3a994 | M_STONE |
| Roof | #6c6a66 | M_STONE |
| Door | #3a3d40 | M_GLASS |

No new material or draw call.

## 6. Ground and night

Collision on the outline. Card: "Kordegarda". The second, southern guardhouse of the court is not mapped and not built. Open *(photo check)*: height, roof, whether the portico is real.

## 7. Detail level and budget

L2; 466 triangles measured, budget 560 (`check_mesh_quality.gd`).

Shot: `--at=-632,-954 --yaw=245 --pitch=-25 --size=26 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | prism on the outline | 13 x 19 m, 1.6 m high | outline | M_STONE | 2 massing |
| body | prism on the outline | 13 x 19 m, 4.7 m high | 1.1..5.8 m | M_MONUMENT | 3 facade |
| eave, parapet | offset prism, walls | 0.35 m out, 0.6 and 0.5 m high | 5.8..6.9 m | M_STONE | 4 roof |
| stylobate | box | 8.8 x 3.2 m, 1.1 m high | u 7.9, v 1.6 | M_STONE | 3 portico |
| columns | 4 columns | r 0.32 m, 4.8 m high | u 4.3, 6.7, 9.1, 11.5 | M_STONE | 3 portico |
| entablature, pediment | box and gable | 8.4 x 3 m; rise 1.6 m | 5.4..7.8 m | M_STONE | 3 portico |
| door | dark pane | 2 x 3.8 m | u 7.9 | M_GLASS | 3 portico |
