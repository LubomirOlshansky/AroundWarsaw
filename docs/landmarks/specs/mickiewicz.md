# Pomnik Adama Mickiewicza (Mickiewicz's monument): spec

Site key `mickiewicz` in `game/scripts/landmarks.gd` (`_build_mickiewicz`, helpers `_kp_balustrade`, `_kp_candelabrum`, `_kp_figure`). Written 2026-11-02 in a cloud thread from the Mac's reference set `refs/krakowskie/` (29 Wikimedia Commons photos, three GUGiK orthophotos at 0.137 m/px; report `docs/landmarks/photo-reports/krakowskie.md`, authors and licences there) plus the GUGiK LoD2 heights from the CI map pack. It replaces the 2026-11-01 first pass, which had the OpenStreetMap outline only. Report section 1, photos 1-4.

## 1. Identity

Cyprian Godebski's monument of 1898 in its own fenced lawn square on the east side of Krakowskie Przedmieście, **facing the street (west)**: a raised granite terrace with a balustrade and four bronze candelabra with gilt flames, a stepped pedestal with a cartouche and a bronze wreath, a tall shaft with a medallion, the poet standing with his right hand on his chest.

## 2. Massing

Frame: origin the plinth's centre (-626, -1078) (ortho; OSM node (-626, -1075)), u south along the street (0.259, 0.966), +v west to the street. Terrace 16 x 10 m, 1.6 m high; a street flight of eight steps 6 m wide (v 5..7.8), a north flight of four 4 m wide. Pedestal steps 5.2 and 4.2 m square, die 3.4 m to 3.2 m over the terrace, shaft 2.1 m square to 9.4 m, cornice, statue 4.5 m: 16 m over the street in all (13.5 m from the terrace, the report's 13-14 m).

## 3. Facade, base to top

Balustrade 0.95 m (plinth, rail, a die every 2.2-3.9 m: single balusters are below a pixel from the camera) on the front either side of the flight, both sides (the north one open for its flight) and the back. Cartouche on the die's street face, the bronze wreath group at its foot, a bronze medallion (r 0.65 m) on the shaft.

## 4. Roof

No roof. The four candelabra (5 m: bronze base and stem, three lit globes, gilt flame) on the terrace's corners.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Granite terrace, pedestal | #cfcac0 | M_STONE |
| Balustrade | #d8d4cc | M_STONE |
| Statue, wreath, medallion (patina) | #4a5048 | M_STONE |
| Candelabra bronze | #3a3a32 | M_STONE |
| Gilt flames | #c9a13a | M_STONE |
| Globes | #f0dfae | M_LAMP |

No new material or draw call.

## 6. Ground and night

The lawn, rose beds and trees stay the map's; the zone (the terrace and flights) drops what stood on it. The car stops at the terrace. The globes glow at night. Card "Pomnik Adama Mickiewicza".

## 7. Detail level and budget

L2, triangle budget 1150 (built 1078; `check_mesh_quality.gd`).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| terrace | box | 16 x 10 x 1.6 m | centre | M_STONE #cfcac0 | raised terrace |
| flights | 8 + 4 boxes | 6 m and 4 m wide, 0.2 / 0.4 m risers | west, north | M_STONE | stairs |
| balustrade | plinth, rail, dies | 0.95 m | terrace edges | M_STONE #d8d4cc | balustrade |
| candelabra | prisms, frustums | 5 m | four corners | M_STONE, M_LAMP | gilt flames |
| pedestal | 3 boxes + cornice | 5.2 to 3.4 m square | centre | M_STONE | stepped pedestal |
| cartouche, wreath | boxes | 1.6 x 1.2, 2.8 x 0.8 m | street face | M_STONE | ornament |
| shaft | box + disc | 2.1 m square, 5.8 m | centre | M_STONE | medallion |
| poet | figure | 4.5 m | top | M_STONE #4a5048 | hand on chest |
