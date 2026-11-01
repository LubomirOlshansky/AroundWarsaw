# Kościół Świętego Aleksandra (St Alexander's church): spec

Site key `aleksander` in `game/scripts/landmarks.gd` (`_find_aleksander`, `_build_aleksander`).
Written 2026-11-01 in a cloud thread from the OpenStreetMap outline in `centrum.json` (a circle
with a rectangular porch at each end); no photo, no LoD2 here, so heights are estimates. Values
marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

Chrystian Piotr Aigner's church of 1818-1826, rebuilt by Kubicki in the form of the Pantheon, in
the middle of Plac Trzech Krzyży at the head of Nowy Świat.

1. **A round drum** under a low copper-green dome, with a small lantern and a cross.
2. **A portico of six columns under a pediment** on each end of the long axis.
3. **A cream-ochre wall** with tall windows round the drum.

## 2. Massing

Centre (-110.8, 541.7), a circle fitted to the outline's 30 arc points: radius 11.3 m. Long axis
(-0.232, -0.973), u to the north (Nowy Świat), +v east. The outline's porches are 12.8 m wide
and reach u = 18.0 (north) and -17.4 (south). Heights above the ground *(estimate)*: plinth to
1.0 m, drum to 13.5 m, cornice to 14.4 m, attic to 17.0 m, dome to 25.6 m, lantern to 30.6 m, its
cap and ball to 33.7 m, cross to 37 m. Porticoes: columns to 9.4 m, entablature to 10.9 m,
pediment apex 13.2 m.

## 3. Facade, base to top

- **Plinth**: a stone band 0.3 m proud, 1.5 m tall.
- **Drum**: a 24-sided wall; twelve tall windows (1.2 x 5.2 m) between the two porticoes.
- **Cornice and attic**: a 0.9 m cornice 0.45 m proud, then a set-back attic.
- **Porticoes**: a cella (a door 2.2 x 4.7 m) and a stylobate 4.4 m deep, six columns
  (r 0.42 m) at v ±1.2, ±3.6, ±5.8, an entablature and a pediment *(photo check: column count,
  whether both ends have a portico, the bell towers the outline does not map)*.

## 4. Roof

Dome in seven steps in the roof green-grey (#7f8f88), lighter toward the top; the lantern's drum
in the trim cream, a copper cap, a gold ball and a cross. Pediment slopes in the roof colour.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Drum, cella | #ebe4d2 | M_MONUMENT |
| Columns, cornice, lantern | #f3eee0 | M_STONE |
| Plinth, stylobate | #b5ab97 | M_STONE |
| Dome, cap, pediment slopes | #7f8f88 | M_STONE |
| Windows, doors | #3a3f42 | M_GLASS |
| Ball, cross | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

The car is stopped by one ring: the drum's circle joined with both porticoes. Card (kept):
"Kościół Świętego Aleksandra", PL "Rotunda na placu Trzech Krzyży.", EN "The rotunda on Plac
Trzech Krzyży." Windows are plain dark glass, not lit.

## 7. Detail level and budget

L2, triangle budget 1460 (1218 measured, plus about 20 %, in `check_mesh_quality.gd`). Shots:
`--solo=aleksander --solo-look=lit`, then in the city from Nowy Świat.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | 24-gon prism | r 11.6, 1.5 m | centre | M_STONE | 3 plinth |
| drum | 24-gon prism | r 11.3, 12.5 m | centre | M_MONUMENT | 3 drum |
| cornice | 24-gon prism | r 11.75, 0.9 m | y 13.5 | M_STONE | 3 cornice |
| attic | 24-gon prism | r 10.8, 2.6 m | y 14.4 | M_STONE | 3 cornice |
| windows | 12 panels | 1.2 x 5.2 m | drum, every 30° from 15° | M_GLASS | 3 drum |
| dome | 6 frustums | r 10.4 to 2.8 | y 17..25.6 | M_STONE | 4 roof |
| lantern | prisms + cap | r 2.3, to 33 m | centre | M_STONE | 4 roof |
| cross | 2 boxes | 3.3 m | y 33.7 | M_STONE | 4 roof |
| cella | box | 12 x 6.6 m | each end | M_MONUMENT | 3 porticoes |
| stylobate | box | 12.8 x 4.4 m | each end | M_STONE | 3 porticoes |
| columns | 6 on 8-sided shafts | r 0.42, 8.6 m | each end | M_STONE | 3 porticoes |
| entablature | box | 12.8 x 4.5 m | y 9.4..10.9 | M_STONE | 3 porticoes |
| pediment | gable | rise 2.3 m | y 10.9 | M_STONE | 4 roof |
| doors | panel | 2.2 x 4.7 m | each cella | M_GLASS | 3 porticoes |
