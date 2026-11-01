# Kościół Wizytek (Visitationists' church): spec

Site key `wizytki` in `game/scripts/landmarks.gd` (`_build_wizytki`, `_wiz_wing`). Written
2026-11-01 in a cloud thread from the OpenStreetMap outline in `centrum.json` (no photo, no
LoD2 here). The nave stays the kept LoD2 skin; the model adds the street facade, a stepped
wing and a turret. Values marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

Late-baroque church (Karol Bay, façade by Jakub Fontana, 1728-1761) on Krakowskie Przedmieście,
the convent's church. Defining: a cream two-storey facade with pilasters and a stepped, curved
gable with statues, copper-green roofs, a small turret over the crossing.

## 2. Massing

Frame: origin (-431.0, -804.7) (the front's north-east corner), u along the front (axis
(-0.527, -0.850), 14.2 m), +v out of the front to the street (ENE). The outline says: front
at v 0 from u 0 to 14.2; then it steps back to v -5.8 (u 0 to -6.6) and v -12.2 (u -6.6 to
-15.9), the stepped north wing; the nave is 22 m wide behind it, about 50 m long, with a
toothy outline on its far end. Heights *(photo check)*: central block 11 m ground floor,
18 m to the cornice, gable to 23.8 m, small pediment 25.3 m, cross 27.6 m; wings 14.1 m;
turret drum to 23 m, cap and lantern to 29.8 m, cross to 31.6 m.

## 3. Facade

Plinth 1.2 m; a dark portal (2.6 x 4.4 m) under a small cornice with three steps; four
pilasters per storey, an entablature at 11-11.8 m, a window storey (monument shader), cornice
at 18-18.9 m. Gable: three narrowing tiers with volutes, statue plinths and figures at the
ends, an oculus, a small copper pediment and a gilt cross. Wings: stone ground floor,
window storey, end pilasters, cornice.

## 4. Roof

- **Gable roof** over the gable: the top tier is a small pediment of 1.5 m rise at 23.8..25.3 m,
  copper-green (#6d8f7f) slopes, a dark oculus (r 0.8 m, 21.5 m up) below it and a gilt cross to
  27.6 m.
- **Wings**: flat, ending in the 0.9 m trim cornice at 13.2..14.1 m; the kept LoD2 skin carries
  their real roofs.
- **Turret**: a copper cap, a frustum from r 2.6 to 1.0 m (23.6..26.6 m) on a trim ring, a small
  lantern (r 0.9 m, 26.6..28.2 m), a copper spire (to 29.8 m) and a gilt cross to 31.6 m.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster | #ecdfc0 | M_STONE, M_MONUMENT (windows) |
| Trim | #f6f0e0 | M_STONE |
| Plinth, steps | #b9ae96 | M_STONE |
| Copper (roof, pediment, cap) | #6d8f7f | M_STONE |
| Portal, oculus | #3a3d40 | M_GLASS, M_STONE |
| Cross | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

Car stopped by the steps (one ring) and the church's mapped walls. Card: "Kościół Wizytek", PL
"Rokokowa fasada z 1761 roku, tuż przy Krakowskim Przedmieściu.", EN "A rococo facade of 1761,
right on Krakowskie Przedmieście." Open *(photo check)*: real gable shape, whether the
facade has towers, the turret's place and shape, roof colour.

## 7. Detail level and budget

L3 for the facade, L2 for the wings and turret; 566 triangles measured, budget 690
(`check_mesh_quality.gd`). Shot: `--at=-418,-800 --yaw=245 --pitch=-22 --size=45 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| ground floor | box | 14.2 x 1.4 m, 11.6 m high | u 7.1, v -0.7 | M_STONE | 3 facade |
| window storey | box | 13.8 x 1.2 m, 7 m high | 11..18 m | M_MONUMENT | 3 facade |
| plinth | box | 14.6 x 1.1 m, 1.8 m high | u 7.1, v 0 | M_STONE | 3 plinth |
| portal | dark pane plus cornice | 2.6 x 4.4 m; cornice 3.8 x 0.7 m | u 7.1, v 0.6, 1.2..6.3 m | M_GLASS, M_STONE | 3 portal |
| steps | 3 boxes | 3.4 to 2.4 m wide, 0.5 m deep each | in front of the portal | M_STONE | 3 portal |
| pilasters | 8 boxes | 0.9 x 0.6 m, 9.8 and 6.2 m high | u 0.9, 4.9, 9.3, 13.3 | M_STONE | 3 facade |
| entablature and cornice | 2 boxes | 14.8 x 1.4 m, 0.8 and 0.9 m high | 11..11.8 m, 18..18.9 m | M_STONE | 3 facade |
| gable tiers | 3 boxes | 11.2, 8.0, 5.0 m wide, 1.8, 1.7, 1.4 m high | 18.9..23.8 m | M_STONE | 3 gable |
| volutes and statues | 8 boxes | 1.4 x 1.1 m volutes; 0.6 m plinths, 1 m figures | tier steps | M_STONE | 3 gable |
| small pediment | gable plus oculus | 5 m wide, rise 1.5 m | 23.8..25.3 m | M_STONE | 4 roof |
| cross | 2 boxes | 0.3 x 2.3 m, arm 1.3 m | apex, 25.3..27.6 m | M_STONE | 4 roof |
| north wing | 2 stepped faces | 6.6 and 9.3 m wide, 14.1 m high | v -5.5 and -11.9 | M_STONE, M_MONUMENT | 2 massing |
| turret | octagon drum, cap, lantern | r 2.5 m, 23 m; cap to 29.8 m | u 3.3, v -24 | M_MONUMENT, M_STONE | 4 roof |
