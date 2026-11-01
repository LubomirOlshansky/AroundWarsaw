# Pałac Staszica (Staszic Palace): spec

Site key `staszic` in `game/scripts/landmarks.gd` (`_build_staszic`). Written 2026-11-01 in a
cloud thread from the OpenStreetMap outline in `centrum.json` and the palace's well-known
neoclassical front (no photo, no LoD2 here: heights are estimates). The mass stays the kept
LoD2 skin; the model adds the street front's dressing and Copernicus's statue. Values marked
*(photo check)* wait for the Mac's `refs/`.

## 1. Identity

Corazzi's neoclassical palace (1820-1823) for the Society of Friends of Learning, now the
Polish Academy of Sciences, on the east side of Krakowskie Przedmieście at the head of Nowy
Świat. Thorvaldsen's seated Copernicus (1830) stands before it.

1. **A long pale-ochre front** with a pale-stone plinth and a deep cornice.
2. **A central portico** of four columns under a pediment with an oculus.
3. **Copernicus** seated on a granite pedestal, an armillary sphere in his hand.

## 2. Massing

Plan frame: origin (-415.8, -405.5) on the outline's straight west front, u south along it
(axis (0.166, 0.986), the straight run is about 53 m), +v out of it to the street (west,
(-0.986, 0.166)). The portico is centred at u 14 *(photo check: the real centre)*, 15.8 m
wide and 5.6 m deep; the statue at u 14, v 15. Heights above the ground: plinth band 1.4 m,
columns 1.2..10.7 m, entablature to 12.2 m, pediment apex 14.6 m, cornice 15.2..16.0 m
*(estimate: the kept mass's eaves not read here)*; statue 5 m to the head.

## 3. Facade, base to top

- **Plinth**: stone band 1.4 m, 0.5 m proud, the whole front.
- **Portico**: a stylobate 1.2 m high with two steps in front; four columns (r 0.55 m, 9.5 m
  tall) at u 14 ± 1.8 and ± 5.4; stepped entablature; three dark doors (2.2 x 4.8 m) between
  the columns and the wall *(photo check: count)*.
- **Cornice**: a 0.8 m band, 1.2 m proud, along the whole front.

## 4. Roof

Pediment 2.4 m rise, slopes in the roof grey-green, a dark oculus (r 0.6 m). The rest of the
roof is the skin's.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Front (skin) | #e2d6b8 | M_MONUMENT |
| Columns, trim, cornice | #f0e9d6 | M_STONE |
| Plinth, stylobate | #b9ae96 | M_STONE |
| Doors, oculus | #3a3d40 | M_GLASS, M_STONE |
| Pedestal | #8f8b85 | M_STONE |
| Copernicus | #4a4f46 | M_STONE |
| Armillary sphere | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

The car is stopped by the stylobate (one ring, 15.8 x 6.6 m) and the statue's base (4 x 4 m).
Card (kept): "Pałac Staszica", PL "Przed nim stoi pomnik Kopernika.", EN "Copernicus's
statue stands in front of it." Open: the side pavilions' pilasters, the statue's exact spot
*(photo check)*.

## 7. Detail level and budget

L3 for the portico and statue, L1 for the rest, triangle budget 360 (324 measured, plus
about 18 %, in `check_mesh_quality.gd`). Shots: `--solo=staszic --solo-look=lit`, then in the
city from Krakowskie Przedmieście.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | box | 1.4 m tall | whole front | M_STONE | 3 plinth |
| cornice | box + 2 corner pilasters | 0.8 m tall | whole front | M_STONE | 3 cornice |
| stylobate | box + step | 15.8 x 6.6 m | u 14 | M_STONE | 2 portico |
| doors | 3 panels | 2.2 x 4.8 m | u 14, ±3.6 | M_GLASS | 2 portico |
| columns | 4 on 8-sided shafts | r 0.55, 9.5 m | u 14 ± 1.8, ± 5.4 | M_STONE | 2 portico |
| entablature | 2 boxes | 15 m wide | y 10.7..12.2 | M_STONE | 2 portico |
| pediment | gable + oculus | rise 2.4 m | y 12.2 | M_STONE | 4 roof |
| pedestal | 4 boxes | 4 x 4 m base, 5 m | u 14, v 15 | M_STONE | 3 Copernicus |
| figure | boxes + beam | 2 m seated | on the pedestal | M_STONE | 3 Copernicus |
