# Pałac Czapskich (Academy of Fine Arts): spec

Site key `czapski` in `game/scripts/landmarks.gd` (`_build_czapski`). Written 2026-11-02 in a cloud thread from the Mac's reference set `refs/krakowskie/` (29 Wikimedia Commons photos, three GUGiK orthophotos at 0.137 m/px; report `docs/landmarks/photo-reports/krakowskie.md`, authors and licences there) plus the GUGiK LoD2 heights from the CI map pack. It replaces the 2026-11-01 first pass, which had the OpenStreetMap outline only. Report section 4, photos 18-19. Built whole: the first pass kept a skin because the front's direction was unknown.

## 1. Identity

The Krasiński-Czapski palace, Krakowskie Przedmieście 5, set back ~90 m west of the street and **facing east** over its forecourt (the two beige 4-storey street wings stay the map's): three storeys in brick-red plaster with white pilasters, quoins, string course and cornice, corner pavilions stepping forward, a centre risalit with a balcony over the door and a white pediment with a cartouche and a small statue, a red tile hipped roof with a row of white chimneys.

## 2. Massing

The OSM outline (simplified 0.5 m), 54 x 33 m. Frame: origin (-599.3, -600.5) on the centre risalit's face, +v east (0.964, -0.266), u north. Plinth to 1.2 m, walls to 15 m (LoD2: eaves ~17 m over the yard, ridge ~23 m), cornice 0.7 m; roofs: the main body u -14.3..15, v -19.4..-0.7 rising 6 m; the corner wings u -25..-14 and 15..25.7, v -28..4.9, rising 5 m.

## 3. Facade, base to top

Darker red plinth; walls with windows between piers (M_MONUMENT); a white string course at 5.2 m; white quoins on every corner of the outline; white pilasters at u ±10, -14, 14.6 and round the risalit (u -5.1, -1.8, 1.8, 5.5); a round-arched door in dark wood; the balcony slab and iron railing at 5.6 m; the white cornice.

## 4. Roof

Three red tile hips; the risalit's white pediment (11.6 m wide, 2.6 m) with a cartouche disc and a small statue on its apex; four white chimneys on the ridge.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls | #d3644e | M_MONUMENT |
| Plinth | #b5503f | M_STONE |
| Pilasters, quoins, cornice, pediment | #f2efe8 | M_STONE |
| Roof | #a8503c | M_STONE |
| Door | #4a3328 | M_STONE |
| Balcony railing | #25282a | M_STONE |

## 6. Ground and night

The forecourt and its trees are the map's; the zone is the outline grown 0.6 m. The car stops at the walls. Card "Pałac Czapskich".

## 7. Detail level and budget

L2, triangle budget 860 (built 778).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | outline, 1.2-15 m | the outline | M_MONUMENT #d3644e | brick-red palace |
| plinth | prism | outline, to 1.2 m | the outline | M_STONE #b5503f | base |
| string course, cornice | prisms | 0.4 m, 0.7 m | outline grown | M_STONE #f2efe8 | white bands |
| quoins | boxes | 0.9 m square | outline corners | M_STONE | quoins |
| pilasters | boxes | 0.7 m wide | east front | M_STONE | pilasters |
| door, balcony | arch panel, slab, railing | 2.2 m, 3.6 m | risalit | M_STONE | entrance |
| pediment | gable, disc, figure | 11.6 m, 2.6 m | risalit top | M_STONE | pediment |
| roofs | 3 hips | 6 m and 5 m rise | main body, wings | M_STONE #a8503c | red tile |
| chimneys | 4 boxes | 1 x 1.6 x 5.4 m | ridge | M_STONE | white chimneys |
