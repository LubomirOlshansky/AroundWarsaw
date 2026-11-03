# Brama Główna Uniwersytetu (the University's main gate): spec

Site key `brama_uw` in `game/scripts/landmarks.gd` (`_build_brama_uw`). Written 2026-11-02 in a cloud thread from the Mac's reference set `refs/krakowskie/` (29 Wikimedia Commons photos, three GUGiK orthophotos at 0.137 m/px; report `docs/landmarks/photo-reports/krakowskie.md`, authors and licences there) plus the GUGiK LoD2 heights from the CI map pack. It replaces the 2026-11-01 first pass, which had the OpenStreetMap outline only. Report section 2, photos 5-11.

## 1. Identity

Stefan Szyller's main gate of the University of Warsaw (1910), Krakowskie Przedmieście 26/28, facing the street (WSW): two white pavilions with statues in niches (Minerva, Apollo), curved gables with cartouches, lanterns and finials; the black wrought-iron gate with a crowned eagle between them; a narrow iron side gate and an urn pier outside each. The lime avenue behind it leads to Pałac Kazimierzowski (`kazimierzowski.md`).

## 2. Massing

Frame: origin (-462, -642) on the east building line (ortho, ±4 m; the first pass guessed (-494.5, -684)), u south along the street (0.37, 0.93), +v out to the street. Pavilions at u ±5.2, 4.4 x 4.4 m, 7 m to the cornice, gable steps to 10 m, lantern to 12.8 m, finial to 14 m. Central opening 6 m; side gates 3 m (u ±7.2..10.4); piers at u ±10.6 with urns to 5.1 m. 22 m in all: the report's 24 m does not fit between the mapped neighbours (the gap is ~19 m), so the piers stand 1 m inside. The mapped 4.3 m "guardhouse" at (-465, -646) (the north pavilion) is replaced.

## 3. Facade, base to top

Plinth, white body with corner pilasters on the street face, a round-headed niche with a standing statue, cornice, two stepped gable blocks with a cartouche disc, octagonal lantern, cone cap, gilt finial. Gate: two rails, nine bars, an overthrow at 4.6 m, the eagle (body and wings) with a gilt crown to 6 m.

## 4. Roof

No roof: the gable steps and lanterns crown the pavilions.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Pavilions, piers | #f2f0ea | M_STONE |
| Mouldings, plinth, urns | #dcd6c8 | M_STONE |
| Niches | #dcd6c8 darkened | M_STONE |
| Iron | #25282a | M_STONE |
| Finials, crown | #c9a24a | M_STONE |

## 6. Ground and night

The campus road, the avenue's limes and the street lamps are the map's. The car meets a wall across the gate (11 x 2.3 m). Card "Brama Główna Uniwersytetu".

## 7. Detail level and budget

L2, triangle budget 950 (built 868).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| pavilions | boxes | 4.4 x 4.4 x 7 m | u ±5.2 | M_STONE #f2f0ea | white pavilions |
| gables | 3 stepped boxes, disc | to 10 m | pavilion tops | M_STONE | curved gable, cartouche |
| lanterns | prism, cone, finial | to 14 m | pavilion tops | M_STONE | lantern |
| niches, statues | arch panel, figure | 1.6 x 3.8 m, 2.6 m | street faces | M_STONE | Minerva, Apollo |
| main gate | rails, bars, eagle | 6 x 4.6 m | centre | M_STONE #25282a | crowned eagle |
| side gates | rails, bars | 3.2 x 2.9 m | u ±8.8 | M_STONE | iron gates |
| piers | box, urn | 1 x 1 x 3.9 m | u ±10.6 | M_STONE | urns |
