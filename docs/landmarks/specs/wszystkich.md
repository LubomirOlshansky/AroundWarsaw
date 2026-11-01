# Kościół Wszystkich Świętych (All Saints): spec

Site key `wszystkich` in `game/scripts/landmarks.gd` (`_build_wszystkich`, `_wsz_tower`). Written
2026-11-01 in a cloud thread from the OpenStreetMap outline in `centrum.json` (no photo, no
LoD2 here). The nave stays the kept LoD2 skin; the model adds the south front on Plac Grzybowski
and the two towers. Values marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

Neo-Renaissance church (1861-1892) at Plac Grzybowski, the Jewish quarter's neighbour. Defining:

1. **Two tall square towers** at the ends of the front, belfry and copper dome with lantern and spire.
2. **A central screen** between them: three arched portals, a window storey, a pediment with an oculus.
3. **A warm cream plaster front** with lighter trim.

## 2. Massing

Frame: origin (-1393.3, -165.9) (the front's east end), u west along the front (axis
(-0.925, 0.38), 36.9 m), +v out of the front to the square. The outline says: front flat for
36.9 m; each end bulges back 7.7 m (towers, outer faces at u 0 and 36.9); nave walls at u 2.35
and 33.6. Towers 8.2 x 8.6 m at u 3.85 and 33.05. Heights: plinth 1.6 m, shaft 24 m, belfry
to 34 m, dome to 44.8 m, lantern to 48 m, spire to 52.5, cross tip 58 m *(photo check)*. Central
screen u 7.7..29.2: 19 m to the cornice, pediment apex 24.3 m, cross 27 m.

## 3. Facade

Pale stone plinth 1.4 m along the whole front; three dark portals (2.4 x 5.1 m) between four
pilasters, an entablature at 7.4..9 m, then a monument-shader window storey (9..19 m); two
steps in front. Towers: shaft with two window bands and string courses, double cornice at
24..25.5 m, belfry between four corner piers.

## 4. Roof

Cornice, pediment (4.4 m rise, copper-green) with a dark oculus (r 1 m) and a gilt cross. Tower
domes: octagonal swell to r 3.7 m, taper to a lantern (r 1 m, windows), a spire and a gilt cross.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster front, shafts | #ddcfaa | M_STONE, M_MONUMENT (windows, belfries) |
| Trim, pilasters, cornices, lanterns | #efe6cc | M_STONE |
| Plinth, steps | #b5aa8e | M_STONE |
| Domes, pediment slopes | #6e8f7e | M_STONE |
| Portals, tower windows, oculus | #3a3d40 | M_GLASS, M_STONE |
| Cross and ball | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

Car stopped by the steps (one ring) and the church's mapped walls. Card kept: "Kościół Wszystkich
Świętych", PL "Przy placu Grzybowskim.", EN "On Plac Grzybowski." Open *(photo check)*: the
real tower height and dome shape, portal count, nave eave height.

## 7. Detail level and budget

L3 for front and towers, L1 elsewhere; 788 triangles measured, budget 950
(`check_mesh_quality.gd`). Shot: `--at=-1410,-165 --yaw=180 --pitch=-25 --size=60 --nohud --no-ghost`.
