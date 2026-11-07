# Centrum LIM's podium (Aleje Jerozolimskie 65/79): spec

Site key `lim` in `game/scripts/landmarks.gd` (a TOWERS entry; the podium in `_lim_parts`,
`_lim_podium`, `_lim_sign`, `_lim_screen`). Written 2026-11-06 from F's six night photos of the
street face, taken from the pavement and the tram stop opposite Warszawa Centralna (kept in the
project's shared files under `presidential-podium/refs/`, not in git), and the map's three
OpenStreetMap parts of the podium. The tower above (the hotel, 140 m) keeps its existing build.

## 1. Identity

The low block of Centrum LIM (1989) under the hotel tower, the long front on Aleje Jerozolimskie:

1. **Silver-white bands of vertical panels**, the whole length of the front.
2. A **glazed gallery floor set back** between two bands, lit from inside at night (restaurants:
   warm, a pink-lit stretch west of the tower, green-grey glass at the east end).
3. A **ground floor of shop glass behind an arcade** of round columns.
4. A **dark ribbon window** under the top band; the **top band carries the tenants' signs**.
5. A **black louvred plant screen** on the west half of the roof, **LED screens** on the roof
   and on the tower's north face.

## 2. Massing (the map's parts)

| Part | OSM | Heights above ground |
| --- | --- | --- |
| Ground floor (shop glass) | "Centrum LIM", 0-5 m | 0-4.6 |
| Upper floors (`outer`) | unnamed, 5-15 m, 5-9 m wider than the ground floor all round | 4.6-15 |
| Plant screen (`louvre`) | unnamed, 15-18 m, west half, black | 15-18 |

## 3. Facade, base to top (every face)

- 0-4.6 m: shop glass on the ground floor's outline (M_PAVILION, lit warm); round columns 0.9 m
  across about every 7.5 m, 1.1 m in from the bands' face, up to 10.6 m.
- 4.6-7.6 m: panel band (#d9d8d1, plain stone: the joints are too fine for the view).
- 7.6-10.6 m: the gallery, 2 m in (glass, lit warm); on the street face a pink-lit stretch
  (u 80-103) and green-grey glass (u 124-146).
- 10.6-12.2 m panel band, 12.2-13.1 m dark ribbon window 0.3 m in, 13.1-15 m the top band.
- Roof #9a9c9c; the plant screen #1b1d20 with fins, its top #5c5f62.

## 4. Signs (parodies, east to west on the street face; u from the west end)

| Real (in the photos) | In the game | Where |
| --- | --- | --- |
| The hotel's name with a crown | PREZYDENT (gold) + crown | top band, u 16 and 138; east face |
| Casinos Poland | KASYNOS (blue) + red chip | top band, u 119 |
| LOT Polskie Linie Lotnicze | LOD, LINIE LODOWE (white) | top band, u 104 / 93 |
| LUX MED | LUZMED (green) + plus | middle band, u 97 |
| Bank Pekao with its bison | PEPEO ŻUBR (white) + orange bison, red rule | top band, u 78 |
| Frosta | MROSTA (blue) | top band, u 57 |
| Wawa Casino | WAWKA (red on white) + KASYNKO (white on red) | top band, u 31 / 41 |
| Flying Tiger Copenhagen | TYGRYS / KOPENHAGA | first band, u 70 |
| Rossmann, Millennium | ROSZMAN, MILENIUSZ | over the shop glass, u 88 / 116 |
| Chery on the Oxford Tower behind | CZERY | Chałubińskiego 8's crown |

## 5. LED screens

| Where | Size | Advert (the game's own) |
| --- | --- | --- |
| On the plant screen, u 48, 7 m back | 12 × 7.5 m, legs | orange, PALUSZKI (the pretzel-stick ad) |
| On the roof west of the tower, u 90, 8 m back | 11 × 7.5 m, legs | violet, HYM (the fashion chain's) |
| On the tower's north face, east part, from 17.5 m | 11 × 8.5 m | red, LEKSUS (the car ad) |

## 6. Life

The arcade, the pavement and the Dworzec Centralny tram platforms are a busy place for the walkers
(main.gd `LIM_BUSY_*`, pedestrians.gd `add_busy`), and the two platforms get waiting crowds that
never drop under 40 % even at night (crowds.gd `STOP_CENTRALNY`).

## 7. Open

- The tower's own night look (PRESIDENTIAL and SAMSUNG on all four faces in the photos; the game
  has them on two) and its lit cells.
- No day photo: the panel colour and the signs by day are a guess from the night shots.
- A phone look check.
