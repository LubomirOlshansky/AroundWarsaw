# Pałac Prezydencki (the Presidential Palace): spec

Site key `prezydencki` in `game/scripts/landmarks.gd` (`_find_prezydencki`,
`_build_prezydencki`). Written 2026-10-31 in a cloud thread from the OpenStreetMap outline (a U
round the forecourt, open to Krakowskie Przedmieście), GUGiK's LoD2 heights and the mapped lawn
in the forecourt; until now the palace was a skin (LoD2's massing in cream). No photo was
available here: the values marked *(photo check)* wait for the Mac's `refs/`, and the Geoportal
blurs parts round the palace, so the orthophoto helps less here than elsewhere.

## 1. Identity

The palace (rebuilt in classical form by Chrystian Piotr Aigner, 1818-1819) behind its
forecourt on Krakowskie Przedmieście, the President's seat.

1. **A U of cream wings round a forecourt**, open to the street, the main block across the back.
2. **A portico of four giant columns under a pediment** in the middle of the main block.
3. **Thorvaldsen's Prince Józef Poniatowski on horseback** in the forecourt, on a granite
   pedestal, facing the street.
4. **Four stone lions** on pedestals by the gate in the iron fence, and two small guardhouses.
5. **Pediments on the wings' street ends** and grey-green sheet roofs.

## 2. Massing

Plan frame: origin (-514.0, -1005.5), the middle of the main block's front; u towards the
street, axis (-0.9089, 0.4170) (WNW); v across (v < 0 north). From the outline: main block
u -25..0, v -41..42 (with a garden annex u -25..-14, v 42..50); north wing u 0..84, v -40.5..-25.5;
south wing u 0..88, v 23..40; street pavilions u 84..92 (north) and 88..96 (south). Heights from
LoD2 (ground 7.1 m): main block eaves 15.5 m, ridge ~21 m; wings eaves 10.5 m, ridge ~14 m;
pavilions 12 m to the cornice *(photo check: storeys)*. The forecourt between the wings is about
48 m wide and 90 m deep; the zone is the outline's hull so the LoD2 run (centred in the
forecourt) goes too.

## 3. Facade, base to top

- **Base**: rusticated, 4 m (the ground floor), a step darker.
- **Floors**: tall windows between pilasters (M_MONUMENT) to the eaves; a cornice 0.4 m proud.
- **Portico**: on a base 4 m deep and 19 m wide before the main block; four columns (r 0.6 m)
  from 4 m to 15.5 m at v ±2.3 and ±6.9; the entablature to 16.7 m; a pediment 3.8 m high
  *(photo check: column count, whether the columns stand free or engaged)*.
- **Street pavilions**: the wings' last 8-9 m, a storey taller, with a pediment 3.2 m high to the
  street.

## 4. Roof

Hipped over each block from the cornice: main block rise 5 m, wings 3.6 m, garden annex 3 m;
gable roofs on the pavilions; pyramid roofs on the guardhouses. Grey-green sheet.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls, columns, pediments | #efe9da | M_MONUMENT (floors), M_STONE |
| Base | #ddd6c4 | M_STONE |
| Roofs | #7d8a87 | M_STONE |
| Statue | #3f4a45 (patinated bronze) | M_STONE |
| Pedestal | #8d8a86 granite | M_STONE |
| Lions | #d8d2c4 | M_STONE |
| Fence | #2f3432 | M_STONE |

## 6. Ground and night

The forecourt's paving, drive and lawn are the map's. The statue at u 66, v -0.5: a granite
step 6 x 3.2 m, the pedestal to 3.6 m, a cornice, the horse stepping towards the street, the
rider with his sword forward *(photo check: place and pose)*. The fence at u 94 from v -25 to
22.5 with the gate open between v -6 and 6; the lions on pedestals at v ±6 and ±9.4, looking
out; guardhouses inside the gate at u 88.5, v -15.5 and 14 *(photo check)*. The car is stopped
by the outline, the fence, the pedestals and the statue. Card: "Pałac Prezydencki", PL "Przed nim
książę Józef Poniatowski na koniu i cztery kamienne lwy.", EN "Prince Józef Poniatowski on
horseback and four stone lions before it."

## 7. Detail level and budget

L2 for the wings, L3 for the portico, the statue and the gate: triangle budget 1050 (868
measured, plus about 20 %, in `check_mesh_quality.gd`). Shots: `--solo=prezydencki
--solo-look=sil` and `flat`, then in the city from the street at the gate.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| main | box, cornice, hip roof | 25 x 83 m | u -25..0, v -41..42, eaves 15.5 | M_STONE base, M_MONUMENT | 1 U |
| annex | box, cornice, hip roof | 11 x 8 m | u -25..-14, v 42..50, eaves 12 | M_MONUMENT | 1 U |
| wing_n | box, cornice, hip roof | 84 x 15 m | u 0..84, v -40.5..-25.5, eaves 10.5 | M_MONUMENT | 1 U |
| wing_s | box, cornice, hip roof | 88 x 17 m | u 0..88, v 23..40, eaves 10.5 | M_MONUMENT | 1 U |
| pavilions | box, cornice, gable | 9 x 16-18 m | u 84..92 and 88..96, to 12.7 m, apex 15.9 m | M_MONUMENT, M_STONE | 5 pediments |
| portico_base | box | 4 x 19 m | u 0..4, y to 4 m | M_STONE #ddd6c4 | 2 portico |
| columns | 4 (plinth, octagon, capital) | r 0.6, 11.5 m | u 3, v ±2.3, ±6.9 | M_STONE #efe9da | 2 portico |
| entablature | box | 4.2 x 19.2 x 1.2 m | y 15.5..16.7 | M_STONE | 2 portico |
| pediment | gable | 19.2 m wide, 3.8 m high | front u 4.2, back u -3 | M_STONE, roof #7d8a87 | 2 portico |
| statue_base | 3 boxes | 6 x 3.2 m, to 3.95 m | u 66, v -0.5 | M_STONE #8d8a86 | 3 statue |
| horse | body, 4 legs, neck, head | 2.3 x 0.8 x 1 m body | on the pedestal, head to +u | M_STONE #3f4a45 | 3 statue |
| rider | body, head, sword arm | 0.5 x 0.6 x 1.5 m | on the horse | M_STONE #3f4a45 | 3 statue |
| fence | 2 rails and posts per side | 19 and 16.5 m long, 2.1 m | u 94, v -25..-6 and 6..22.5 | M_STONE #2f3432 | 4 gate |
| lions | pedestal, body, head | 1.8 x 1.2 x 2.6 m pedestal | u 94, v ±6, ±9.4 | M_STONE #d8d2c4 | 4 lions |
| guardhouses | box, cornice, pyramid | 4.4 x 4.4 m, to 6.2 m | u 88.5, v -15.5 and 14 | M_MONUMENT, M_STONE | 4 gate |
