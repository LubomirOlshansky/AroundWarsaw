# Kordegarda (Pałac Potockich's guardhouse): spec

Site key `kordegarda` in `game/scripts/landmarks.gd` (`_build_kordegarda`). Written 2026-11-02 in a cloud thread from the Mac's reference set `refs/krakowskie/` (29 Wikimedia Commons photos, three GUGiK orthophotos at 0.137 m/px; report `docs/landmarks/photo-reports/krakowskie.md`, authors and licences there) plus the GUGiK LoD2 heights from the CI map pack. It replaces the 2026-11-01 first pass, which had the OpenStreetMap outline only. Report section 5, photos 22-23. Built whole: OSM maps it 4.3 m tall.

## 1. Identity

The guardhouse in the mouth of Pałac Potockich's court, today the ministry's gallery: one storey of white stone; on the street face three tall round-arched windows either side of a round-arched door between shallow pilasters, and a balustraded attic with sculpture groups on its corners and over the door. The first pass's columned portico is gone (the photos show none).

## 2. Massing

The OSM outline (C-shaped, 13 x 19 m), plinth to 0.8 m, walls to 6 m (photo: ~6 m to the cornice; LoD2 ~7.5 m with the attic), cornice to 6.6 m, attic balustrade 0.9 m, sculpture groups to ~9.3 m. Frame: origin (-626.3, -947.4) the street face's south end, u north (-0.239, -0.971), +v east to the street.

## 3. Facade, base to top

Plinth; seven openings 2.2 m apart on the 15.6 m street face (windows 1.3 x 3.65 m, the door 1.6 x 4 m in dark wood); eight pilasters; cornice; balustrade (plinth, rail, dies every 1.6 m); three pedestals with two stone figures each.

## 4. Roof

A flat grey roof (#8d8b86) behind the attic.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls, cornice, attic | #efede6 | M_STONE |
| Plinth | #efede6 darkened | M_STONE |
| Sculptures | #c9c7c0 | M_STONE |
| Windows | #3a3d40 | M_STONE |
| Door | #4a3328 | M_STONE |
| Roof | #8d8b86 | M_STONE |

## 6. Ground and night

The car stops at the outline. Card "Kordegarda".

## 7. Detail level and budget

L2, triangle budget 950 (built 868).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | outline, 0.8-6 m | the outline | M_STONE #efede6 | white stone |
| cornice | prism | outline grown 0.35 m | 6-6.6 m | M_STONE | cornice |
| openings | 7 round-arched panels | 1.3-1.6 m wide | street face | M_STONE | windows, door |
| pilasters | 8 boxes | 0.44 m wide | street face | M_STONE | pilasters |
| balustrade | plinth, rail, dies | 15 m x 0.9 m | attic | M_STONE | balustrade |
| sculpture groups | 3 pedestals, 6 figures | 1.4-1.7 m | attic | M_STONE #c9c7c0 | sculptures |
