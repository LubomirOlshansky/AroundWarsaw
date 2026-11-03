# Pałac Kazimierzowski: spec

Site key `kazimierzowski` (a kept skin with a model) in `game/scripts/landmarks.gd` (`_build_kazimierzowski`, skin in `SKINS`). Written 2026-11-02 in a cloud thread from the Mac's reference set `refs/krakowskie/` (29 Wikimedia Commons photos, three GUGiK orthophotos at 0.137 m/px; report `docs/landmarks/photo-reports/krakowskie.md`, authors and licences there) plus the GUGiK LoD2 heights from the CI map pack. It replaces the 2026-11-01 first pass, which had the OpenStreetMap outline only. Report section 2, photos 16-17 and 9.

## 1. Identity

The rector's palace at the far end of the University's lime avenue, closing the vista from the main gate: three storeys in ochre-yellow, a white Corinthian portico of four columns with a triangular pediment over the centre (the 2nd and 3rd storeys) on a rusticated ground floor with round-arched doors, a steep red tile roof with white chimneys. Front to the WSW, down the avenue.

## 2. Massing

The mass is the LoD2 model (kept skin: walls #e2c77a, roof #b5503a; the first pass had beige and grey). Frame: origin (-268, -730) 0.4 m in front of the centre risalit (OSM outline), +v out (-0.909, 0.416), u along the front. Porch block 12.8 x 1.8 m to 4.6 m; columns 7.6 m (4.6-12.6 m over the yard); entablature to 13.6 m; pediment 2.4 m. LoD2: ridge ~23 m over the yard.

## 3. Facade, base to top

Rusticated porch with four courses and three round-arched doors (dark wood); a white slab; four columns (r 0.42 m) at u ±1.5, ±4.5; entablature; pediment with red tile slopes back to the roof.

## 4. Roof

The LoD2 roof in the skin's red tile; the pediment's slopes in the same red.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls (skin) | #e2c77a | M_MONUMENT |
| Roof (skin), pediment slopes | #b5503a | M_STONE |
| Columns, entablature, pediment | #f3f1ea | M_STONE |
| Rusticated porch | #e2c77a lightened | M_STONE |
| Doors | #4a3328 | M_STONE |

## 6. Ground and night

The yard, lawns and trees are the map's. The car stops at the porch. Card "Pałac Kazimierzowski".

## 7. Detail level and budget

L2, triangle budget 280 (built 236).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| skin | LoD2 mass | the outline | the outline | M_MONUMENT #e2c77a | ochre palace |
| porch | box, 4 courses | 12.8 x 1.8 x 4.6 m | centre risalit | M_STONE | rusticated base |
| doors | 3 round-arched panels | 1.7 x 3.4 m | porch face | M_STONE #4a3328 | doors |
| columns | 4 columns | r 0.42 m, 7.6 m | u ±1.5, ±4.5 | M_STONE #f3f1ea | portico |
| entablature | box | 12 x 1.8 x 1 m | 12.6-13.6 m | M_STONE | entablature |
| pediment | gable | 12 m wide, 2.4 m | 13.6 m | M_STONE | pediment |
