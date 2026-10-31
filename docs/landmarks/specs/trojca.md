# Kościół Ewangelicko-Augsburski Świętej Trójcy (Holy Trinity): spec

Site key `trojca` in `game/scripts/landmarks.gd` (`_find_trojca`, `_build_trojca`). Written
2026-10-31 in a cloud thread from the OpenStreetMap outline in `centrum.json` (a circle with four
arms), GUGiK's LoD2 heights and the user's photo of Zachęta, which shows the church's drum,
dome and lantern beside it. Values marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

Szymon Bogumił Zug's Lutheran church (1777-1781) on Plac Małachowskiego, beside Zachęta.

1. **A white round drum** on a Greek-cross plan, wider than it is tall.
2. **A low green copper dome** over it (verdigris), the city's widest after the Palace's hall.
3. **A tall columned lantern** on the dome: green, tall dark windows between piers, a small cap,
   a ball and a cross (58 m to the top).
4. **Four porticoes** of Tuscan columns under pediments, one on each arm of the cross.
5. **A ring of round windows** (oculi) in the drum's upper half.

## 2. Massing

Centre (-854.6, -508.6), a circle fitted to the outline's 28 drum points: radius 16.7 m. The four
arms turn -24.6° (towards the square, ENE), 65.4° (Kredytowa), 155.4° and 245.4°; each ~13 m wide,
their fronts 21.8, 24.1, 21.7 and 21.3 m from the centre (the outline's corners). Heights from
LoD2 over the ground (13 m): drum to 26.5 m, dome 26.5 to 36.7 m (28.6 m at r 14.5, 36 m at
r 8), lantern 36.6 to 46.7 m, its cap to 50.4 m, ball and cross to 55.6 m; the arms 15-16 m to
the pediment's apex.

## 3. Facade, base to top

- **Base**: a grey plinth 0.3 m proud, 1.7 m tall.
- **Lower drum** (1.2-15 m): white, tall windows between piers (M_MONUMENT).
- **Band** at 15-15.8 m, 0.35 m proud.
- **Upper drum** (15.8-24.5 m): plain white with 16 oculi, 1.1 m radius, at 20 m, on every
  other facet of the 32 *(photo check: count)*.
- **Cornice** 24.5-25.3 m, 0.45 m proud; **attic** 25.3-26.5 m.
- **Porticoes**: a vestibule 12 m wide behind each, the stylobate 4.4 m deep, four columns
  (r 0.55 m, 10.1 m tall, at 1 m behind the front, v ±1.55 and ±4.6), the entablature
  10.7-12.5 m, a pediment 3.4 m high roofed in dark copper.

## 4. Roof

The dome in five bands of 32 facets, lighter towards the top; the lantern's balustrade ring
(r 5.9 m), its columned drum (r 4.6 m, M_MONUMENT in copper), cornice, a cap in three bands, a
gilt ball and a cross (bar at 54 m). Nothing else on the roof.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Drum, porticoes, columns | #e9e7e1 | M_MONUMENT (lower drum, vestibules), M_STONE |
| Plinth, stylobates | #a9a59d | M_STONE |
| Dome, lantern | #6f9f8f lightening upwards; rings #4f7d70 | M_STONE, M_MONUMENT (lantern) |
| Oculi | #3c4a52 | M_STONE |
| Ball and cross | #c9a24a | M_STONE |

No new material or draw call: everything goes into the city's building surface.

## 6. Ground and night

The square's paving round it (the map's). The car is stopped by the drum and the porticoes
(one merged ring). At night the white drum takes the street light; the lantern's windows are
the monument shader's. Card: "Kościół Świętej Trójcy", PL "Luterańska rotunda Zuga z 1781
roku przy placu Małachowskiego.", EN "Zug's Lutheran rotunda of 1781 on Plac Małachowskiego."

## 7. Detail level and budget

L3, triangle budget 2300 (1901 measured, plus about 20 %, in `check_mesh_quality.gd`). Shots:
`--solo=trojca --solo-look=sil` and `flat`, then in the city by day from the square.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | 32-gon prism | r 17.0, 1.7 m | y -0.5..1.2 | M_STONE #a9a59d | 1 drum |
| drum_low | 32-gon prism | r 16.7, 13.8 m | y 1.2..15 | M_MONUMENT #e9e7e1 | 1 drum |
| band | 32-gon prism | r 17.05, 0.8 m | y 15..15.8 | M_STONE | 1 drum |
| drum_high | 32-gon prism | r 16.7, 8.7 m | y 15.8..24.5 | M_STONE #e9e7e1 | 1 drum |
| oculi | 16 octagon discs | r 1.1 m | y 20, on alternate facets | M_STONE #3c4a52 | 5 oculi |
| cornice | 32-gon prism | r 17.15, 0.8 m | y 24.5..25.3 | M_STONE | 1 drum |
| attic | 32-gon prism | r 16.7, 1.2 m | y 25.3..26.5 | M_STONE | 1 drum |
| dome | 5 frustum bands | r 16.4 to 5.7 | y 26.5..36.7 | M_STONE #6f9f8f | 2 dome |
| balustrade | 16-gon prism | r 5.9, 1 m | y 36.6..37.6 | M_STONE #4f7d70 | 3 lantern |
| lantern | 16-gon prism | r 4.6, 8.4 m | y 37.6..46 | M_MONUMENT #6f9f8f | 3 lantern |
| cap | cornice + 3 frustum bands | r 5.1 to 0.3 | y 46..50.4 | M_STONE | 3 lantern |
| cross | ball, upright, bar | 0.8 m ball, 4.5 m upright, 1.5 m bar | y 50.4..55.6 | M_STONE #c9a24a | 3 lantern |
| vestibule | box per arm | 12 x 2.7 m | behind each portico, y -0.5..12.5 | M_MONUMENT | 4 porticoes |
| stylobate | box per arm | 13.6 x 4.4 x 1.1 m | arm front | M_STONE #a9a59d | 4 porticoes |
| columns | 4 per arm (plinth, octagon, capital) | r 0.55, 10.1 m | 1 m behind the front, v ±1.55, ±4.6 | M_STONE | 4 porticoes |
| entablature | box per arm | 13.2 x 4.5 x 1.8 m | y 10.7..12.5 | M_STONE | 4 porticoes |
| pediment | gable per arm | 13.4 m wide, 3.4 m high | y 12.5..15.9, back into the drum | M_STONE, roof #4f7d70 | 4 porticoes |
