# Pałac Potockich (Ministry of Culture): spec

Site key `potocki` (a kept skin with a model) in `game/scripts/landmarks.gd` (`_build_potocki`). Written 2026-11-02 in a cloud thread from the Mac's reference set `refs/krakowskie/` (29 Wikimedia Commons photos, three GUGiK orthophotos at 0.137 m/px; report `docs/landmarks/photo-reports/krakowskie.md`, authors and licences there) plus the GUGiK LoD2 heights from the CI map pack. It replaces the 2026-11-01 first pass, which had the OpenStreetMap outline only. Report section 5, photos 20-21.

## 1. Identity

Krakowskie Przedmieście 15, opposite the Presidential Palace: a U-shaped palace round its court of honour, the court opening east onto the street. On the street: the Kordegarda in the court's mouth (`kordegarda.md`), a stone-piered wrought-iron gate either side of it, and the two wings' ends (the photos' two-storey "guardhouses") with orange-red hipped mansard roofs.

## 2. Massing

The mass is the LoD2 model (kept skin: cream walls #ede8dc, orange-red roofs #c5502f; the first pass had ochre and grey-brown). Note: the report placed the front at z -800..-760 (x ~-545) in the ortho's censored block; the OSM outline (x -717..-622, z -985..-905) and the Kordegarda's place in its court put it here, which matches the photos (opposite the Presidential Palace), so the outline wins. Court front frame: origin (-683.3, -919) its south end, u north (-0.2, -0.98), +v east. Gates: north (-636.6, -974.4)-(-631.6, -963.6), south (-626.9, -946.6)-(-625.4, -935.2).

## 3. Facade, base to top

Court front (first pass, kept): plinth, string course at 5.6 m, cornice at 12.4 m, corner pilasters, a three-bay central pavilion with four pilasters, door and window, a pediment with an oculus. Gates: a cream pier at each end (1 x 1 x 3.4 m, cap, urn to 4.7 m) and an iron gate between them (two rails, bars rising in a shallow arch to 3.5 m).

## 4. Roof

The LoD2 roofs in the skin's orange-red; the court pediment's slopes the same.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls (skin), piers | #ede8dc | M_MONUMENT / M_STONE |
| Roofs (skin), pediment | #c5502f | M_STONE |
| Trim | #f7f4ec | M_STONE |
| Plinth, urns | #b3a994 | M_STONE |
| Iron | #25282a | M_STONE |

## 6. Ground and night

The court's paving is the map's. The car meets the closed gates and the court front's steps. Card "Pałac Potockich".

## 7. Detail level and budget

L2, triangle budget 760 (built 692).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| skin | LoD2 mass | the outline | the outline | M_MONUMENT #ede8dc | cream palace |
| court front | boxes | 50 m long, 13.2 m | west side of the court | M_STONE | string course, cornice |
| central pavilion | boxes, pilasters, gable | 10 x 1.2 m | court front u 25 | M_STONE, M_GLASS | pediment |
| gate piers | box, cap, urn | 1 x 1 x 4.7 m | gate ends | M_STONE #ede8dc | piers |
| gates | rails, bars | 9-10 m x 3.5 m | either side of the Kordegarda | M_STONE #25282a | iron gates |
