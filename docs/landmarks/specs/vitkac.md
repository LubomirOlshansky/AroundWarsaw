# Vipkac (Vitkac, Bracka 9): spec

Site key `vitkac` in `game/scripts/landmarks.gd` (`_build_vitkac`). Written 2026-11-03 from the Mac photo report `docs/landmarks/photo-reports/vitkac.md` (refs/vitkac/: one Commons photo, 2025, and the GUGiK ortho) and the OpenStreetMap outline "Vitkac" and its parts (26 m body, a 31 m top). The brand never appears: the card and the sign say VIPKAC (a VIP's hangover).

## 1. Identity

The luxury department store on Bracka by Al. Jerozolimskie, start area: a long dark stone block with rounded ends.

## 2. Massing

The mapped outline simplified (0.4 m): a 20 m wide, 90 m long sliver along Bracka, rounded at both ends. A 5 m shop storey, five storeys of 4.2 m to 26 m, then a glass storey set back 2.4 m to 30.4 m. The report's ortho box sits ~20 m south of the outline: the outline was trusted.

## 3. Facade, base to top

A fully glazed ground floor (warm shop windows every 4.2 m) on a darker base; a deep band over the shops; five storeys of big square windows (2.5 m) set nearly flush every 3.8 m; a proud band at every floor line; a 1 m parapet.

## 4. Roof

The terrace at 26 m in dark roofing; the glass top storey with its own parapet; small round trees on the terrace along the Bracka side every 7.5 m.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Stone and metal skin | #5a5b5c | M_STONE |
| Bands, parapets | #6d6e70 | M_STONE |
| Base | #3f4042 | M_STONE |
| Square windows | #2c3238 | M_GLASS |
| Shop windows | #c9b48c | M_GLASS |
| Top storey | #4a5a66 | M_GLASS |

No new material or draw call.

## 6. Ground and night

Car walls on the mapped outline, also handed to the pocket bridging. VIPKAC in warm white high on the Bracka front. Card "Vipkac". Open (photo check): the window pattern (the photo shows punched squares; storeys counted from one photo), the terrace planting, where the name sits.

## 7. Detail level and budget

L2, triangle budget 1400 (`check_mesh_quality.gd`; 1145 built).

Shot: `--at=-318,365 --yaw=90 --pitch=-45 --size=75 --nohud --no-ghost --time=dusk`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| base | ring prism | 5 m high | ground | M_STONE | 3 facade |
| body | ring prism | 21 m high | 5 m | M_STONE | 2 massing |
| bands | offset rings | 0.35-0.7 m high | each floor line | M_STONE | 3 facade |
| windows | bays | 2.5 m square, every 3.8 m | five storeys | M_GLASS | 3 facade |
| shops | bays | 3.6 m wide | ground floor | M_GLASS | 6 night |
| top | inset prism | 4.4 m high | 26 m | M_GLASS | 4 roof |
| trees | trunk and crown | 2.8 m | terrace, Bracka side | M_STONE | 4 roof |
