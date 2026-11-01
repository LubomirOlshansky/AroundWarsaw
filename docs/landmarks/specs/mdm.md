# MDM: arcades, corner towers and reliefs (spec)

Site key `mdm` in `game/scripts/landmarks.gd` (`_find_mdm` for the skin, `_build_mdm` for the
model). Written 2026-11-01 in a cloud thread ("Marszałkowska pass 2") from the OpenStreetMap
outlines in `centrum.json` (no photo, no LoD2 there). Every height and bay is an estimate; the
Mac photo check is parked in QUESTIONS.

## 1. Identity

Marszałkowska Dzielnica Mieszkaniowa (1950-1952, socialist realism): long stone-faced blocks
round Plac Konstytucji and along Marszałkowska, a ground-floor arcade (podcienia) under the
upper storeys, a tower at each end of the square's blocks, terracotta reliefs. Before this the
blocks were LoD2 boxes in sandstone with tall windows and grey roofs (the kept skin).

## 2. Massing

The blocks stay LoD2's (kept skin, `_mark_zone`). The model adds, in the street's grid (u along
Marszałkowska, 0.349 / 0.937 in the game's x / z; v across): arcades along every long facade
(14 m or more) whose outward normal looks at the square or the Marszałkowska axis (dot > 0.55,
within 100 m, not into another block); four corner towers at the blocks' ends where the street
meets the square (east block's south end, west block's south end, the two south-gate blocks).

## 3. Facade, base to top

Arcade: square piers 1.1 m, every ~5.4 m, 0.6 m in front of a 2.9 m deep walk; an entablature
slab 5.6-6.3 m with a cornice on its front edge to 6.7 m; dark shopfronts in each bay between
the piers (0.3 m in front of the wall). Tower: a windowed shaft 10.5 m above the block's roof
with four corner pilasters, a cornice, a narrower windowed second stage (7 m), a cornice.

## 4. Roof

Tower: a hipped attic in grey sheet (6 m rise), a thin gilt spire 6 m higher with a gilt collar.
Block roofs stay LoD2's.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Tower shafts | #cdbfa3 | M_MONUMENT |
| Piers, pilasters, cornices | #d8ccb0 / #e6dcc4 | M_STONE |
| Shopfronts | #34383b | M_GLASS |
| Attic | #7f7b74 | M_STONE |
| Spire, collar | #c9a24a | M_STONE |
| Relief field, frame | #b0634a / #efe6d2 | M_STONE |

No new material or draw call.

## 6. Ground and night

Car collision on each arcade's rectangle. The card stays "MDM". Open *(photo check)*: the real
arcade rhythm and depth, whether the piers are square or round, the towers' real height and
crown, the reliefs' subjects and places.

## 7. Detail level and budget

L2, 2002 triangles measured, budget 2400 in `check_mesh_quality.gd`; no zfight, degenerate,
bad-normal or floating parts (each tower has a hidden core tying it to the ground).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| piers | boxes | 1.1 x 1.1 m, 6.1 m high | every ~5.4 m, 2.3 m out | M_STONE | 3 arcade |
| entablature | slab plus cornice | 2.9 m deep, 5.6-6.7 m | along each arcaded facade | M_STONE | 3 arcade |
| shopfronts | dark wall pieces | 4.3 m high, bay less 2 m | 0.3 m out of the wall | M_GLASS | 3 arcade |
| tower core | box | tower less 0.8 m, ground to roof | hidden in the block | M_STONE | 2 massing |
| tower stage 1 | windowed box, 4 pilasters | 11.6-15 m x 11.6-17 m, 10.5 m | on the block's end | M_MONUMENT, M_STONE | 3 tower |
| tower stage 2 | windowed box, cornices | 1.3 m narrower each side, 7 m | on stage 1 | M_MONUMENT, M_STONE | 3 tower |
| attic and spire | hipped frustum, thin box, collar | 6 m rise, spire 6 m | on stage 2 | M_STONE | 4 roof |
| relief | 5 thin boxes | frame 4.3 x 6 m, field 3.4 x 5.2 m | on the face to the square | M_STONE | 3 tower |
