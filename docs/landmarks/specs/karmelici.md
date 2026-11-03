# Kościół Karmelitów (Carmelite church): spec

Site key `karmelici` (a kept skin with a model) in `game/scripts/landmarks.gd` (`_build_karmelici`). Written 2026-11-02 in a cloud thread from the Mac's reference set `refs/krakowskie/` (29 Wikimedia Commons photos, three GUGiK orthophotos at 0.137 m/px; report `docs/landmarks/photo-reports/krakowskie.md`, authors and licences there) plus the GUGiK LoD2 heights from the CI map pack. It replaces the 2026-11-01 first pass, which had the OpenStreetMap outline only. Report section 6, photos 24-25.

## 1. Identity

Kościół Wniebowzięcia NMP i św. Józefa (Fontana and Szreger, 1761-1781): a two-storey sandstone front facing the street (west) over a paved forecourt. Below, two pairs of engaged Tuscan columns round the big door and pilasters at the ends, three doors; above, set back behind a balustraded balcony, a temple front of four free-standing Corinthian columns with a big arched window and two statues in niches, a straight entablature, an attic with sculpture groups, crowned by a green copper globe with a gilt finial; a lantern turret with round openings and a green cap either side.

## 2. Massing

The nave is the LoD2 model (kept skin: #d9cba6, teal copper roof #5e8f80 from the ortho). Frame: origin (-598.9, -1042.4), u south along the front (0.507, 0.862), +v west; the front stands 2.2 m out from the first pass's line, onto the outline's centre risalit (the LoD2 front had shown through it). Lower storey 26 x 2.8 m to 9.2 m, entablature to 10.3 m; upper storey 16.4 m wide to 18 m; attic to 19.6 m; globe to 22.4 m; finial to 24.6 m. Turrets 3.2 x 2 m at u ±10.6, caps to 17.5 m.

## 3. Facade, base to top

Ochre plinth and three steps; columns (r 0.42 m) at u ±2.4, ±3.9, pilasters at ±8.4, ±12.4; the door (3 x 5.4 m, round-headed, dark wood), side doors (1.7 m), windows over them; balcony balustrade; upper columns (r 0.4 m) at ±1.9, ±5.4; the arched window (2.6 x 4.3 m); niches with statues at ±3.65; four sculpture groups on the attic.

## 4. Roof

The LoD2 roof in the skin's teal copper; the globe in green copper (#5e9e8a); the turrets' green caps.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Front walls | #c9b78c | M_STONE |
| Plinth, steps, niches | #b39a62 | M_STONE |
| Columns, entablature, statues | #d8c9a2 | M_STONE |
| Globe, turret caps | #5e9e8a | M_STONE |
| Finial | #c9a24a | M_STONE |
| Doors | #4a3328 | M_STONE |

## 6. Ground and night

The forecourt's parking is the map's. The car stops at the steps. Card "Kościół Karmelitów".

## 7. Detail level and budget

L2, triangle budget 1300 (built 1202).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| lower storey | boxes | 26 x 2.8 x 8.2 m | u 0..26 | M_STONE #c9b78c | ground floor |
| columns | 4 columns, 4 pilasters | r 0.42 m, 8.2 m | round the door | M_STONE | Tuscan pairs |
| doors | 3 round-headed panels | 3 m and 1.7 m | v 0.35 | M_STONE #4a3328 | doors |
| upper storey | box, balustrade | 16.4 x 3 x 7.7 m | centre | M_STONE | temple front |
| upper columns | 4 columns | r 0.4 m, 6.7 m | v 0.4 | M_STONE | Corinthian |
| window, niches | arch panels, 2 figures | 2.6 x 4.3 m; 1.5 m | upper face | M_STONE | statues |
| attic | box, 4 groups | 12.8 x 1.6 m | 18-19.6 m | M_STONE | sculpture groups |
| globe | 3 frustums, finial | r 1.25 m | top | M_STONE #5e9e8a | copper globe |
| turrets | box, disc, cap | 3.2 x 2 x 4.8 m | u ±10.6 | M_STONE | lantern turrets |
