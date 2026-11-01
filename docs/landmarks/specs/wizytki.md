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

## 4. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster | #ecdfc0 | M_STONE, M_MONUMENT (windows) |
| Trim | #f6f0e0 | M_STONE |
| Plinth, steps | #b9ae96 | M_STONE |
| Copper (roof, pediment, cap) | #6d8f7f | M_STONE |
| Portal, oculus | #3a3d40 | M_GLASS, M_STONE |
| Cross | #c9a24a | M_STONE |

No new material or draw call.

## 5. Ground and night

Car stopped by the steps (one ring) and the church's mapped walls. Card: "Kościół Wizytek", PL
"Rokokowa fasada z 1761 roku, tuż przy Krakowskim Przedmieściu.", EN "A rococo facade of 1761,
right on Krakowskie Przedmieście." Open *(photo check)*: real gable shape, whether the
facade has towers, the turret's place and shape, roof colour.

## 6. Detail level and budget

L3 for the facade, L2 for the wings and turret; 566 triangles measured, budget 690
(`check_mesh_quality.gd`). Shot: `--at=-418,-800 --yaw=245 --pitch=-22 --size=45 --nohud --no-ghost`.
