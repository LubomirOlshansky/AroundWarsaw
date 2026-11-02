# Hala Gwardii (Gwardia Hall): spec

Site key `gwardii` in `game/scripts/landmarks.gd` (`_build_gwardii`, a model instead of a plain
extruded outline). Written 2026-11-01 in a cloud thread. Twin of Hala Mirowska
(`mirowska.md`): same architects (Szyller and Domaniewski, 1899-1901), same helpers, colours and
massing. Unlike Mirowska, OSM maps Gwardii as one outline only (no 3D parts, one part h 10.9 m),
but the outline is mapped down to the pilasters, so bay positions are measured from it. Values
marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

1. **Red brick walls** with cream pilasters and round-headed windows in every bay.
2. **A long nave roof** with a glazed lantern on the ridge.
3. **Tall thin gable ends** between four corner turrets with pyramid caps.
4. Different from the twin: **symmetric end to end**, a portal in the middle of both short ends,
   no annex.

## 2. Massing

Plan frame: origin (-1712.77, -537.24) at the south-west corner, u east along the long side
(axis (0.970, -0.242)), +v to the north. 96.8 x 44.1 m (outline). Walls 10 m, cornice 9..10 m
round all four sides; nave roof 10 to 14.5 m over v 8.75..35.35; lantern u 17.35..79.45, top
17.4 m; gable ends at u 7.7..9.1 and 87.7..89.1, apex 18 m, pinnacle each; turrets 5 x 5 m,
10..18.8 m, at u 10.1 / 86.7 and v 11.3 / 32.8.

## 3. Facade (measured from the outline's jogs)

- **Long sides**: 16 pilasters, centres u 1.0, 7.5, 11.1, 18.3, 24.95, 31.65, 38.25, 45.1 and
  their mirror about the middle (48.4); 11 windows (2.3 m wide, 2.4..6.6 m) in the regular bays,
  two narrower ones in the corner bays; the double pilasters at 7.5/11.1 and 85.7/89.3 carry the
  turrets.
- **Short ends** (both alike): pilasters at v 1.0, 7.4, 18.1 and the mirror about 22.05; a round
  portal (1.3..5.6 m, three steps) in the middle bay, a window each side, a small one in each
  corner bay; gable window (11..13.8 m) above.
- **Plinth** 1.7 m granite band.

## 4. Roof

As Mirowska: the walls end in a flat grey roof (#6d7470) with the nave standing on it, a gable
roof in pale zinc (#8b948f) of 4.5 m rise over the central 26.6 m (v 8.75..35.35, u 9.1..87.7),
two thin tall gables (rise 8 m, coping in trim) at u 7.7..9.1 and 87.7..89.1 with a pinnacle on
each apex (17.8..20 m), four corner turrets with pyramid caps in green-grey (#6f7f78, 15..18.8 m)
and a glass lantern along the ridge (12.4..16 m, glass roof to 17.4 m).

## 5. Colour and material

As Mirowska (`MIROWSKA_*` constants):

| Part | Colour | Material code |
| --- | --- | --- |
| Walls, turret bodies | #a85c40 | M_STONE |
| Pilasters, cornice, turret bands, gable coping | #d6ccb4 | M_STONE |
| Plinth, steps | #857e74 | M_STONE |
| Window panes | #323a40 | M_GLASS |
| Portal doors | #33271f | M_GLASS |
| Nave roof, turret caps | #8b948f, #6f7f78 | M_STONE |
| Lantern | #a9bcc4 | M_GLASS, M_GLASS_ROOF |

No new material or draw call.

## 6. Ground and night

The car is stopped by the outline's ring. Card: "Hala Gwardii", PL "Ceglana hala przy Żelaznej
Bramie, bliźniaczka Mirowskiej.", EN "A brick market hall by Żelazna Brama, Mirowska's twin."
Map icon `hall`. The 2016 "boarded windows" then-card (`then_cards.json`) is a separate overlay.
Open *(photo check)*: the real brick colour, the door count on the long sides, whether the
lantern glows, the real state of the roof.

## 7. Detail level and budget

L2, 1212 triangles measured, budget 1450 in `check_mesh_quality.gd`; no zfight, degenerate,
bad-normal or floating parts. Shots: `--solo=gwardii --solo-look=lit`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | extruded outline | 96.8 x 44.1 x 10.5 m | u 0..96.8, v 0..44.1 | M_STONE | 2 massing |
| plinth | 4 boxes | 1.7 m high, 0.2 m proud | the foot | M_STONE | 3 plinth |
| cornice | 4 boxes | 1 m high, 0.35 m proud | y 9..10, all four sides | M_STONE | 2 massing |
| long pilasters | 32 boxes | 0.6 x 0.15 m, 7.8 m high | both long sides, 16 per side | M_STONE | 3 long sides |
| end pilasters | 12 boxes | 0.6 x 0.15 m, 7.8 m high | both short ends, 6 per end | M_STONE | 3 short ends |
| long windows | 2 x 11 arches, 2 x 2 narrow | 2.3 m wide (1.8 m narrow), 2.4..6.6 m | both long sides | M_GLASS | 3 long sides |
| end windows | 2 x 4 arches | 2.6 m and 1.8 m wide, 2.4..6.6 m | both short ends | M_GLASS | 3 short ends |
| portals | 2 arches plus 3 steps each | 3.4 m wide, 1.3..5.6 m | both ends, v 22.05 | M_GLASS | 3 short ends |
| nave roof | gable | 26.6 m wide, rise 4.5 m | u 9.1..87.7, on 10 m | M_STONE | 4 roof |
| gable ends | 2 thin gables | rise 8 m, 1.4 m thick | u 7.7 and 87.7 | M_STONE | 4 roof |
| gable windows and pinnacles | 2 arches, 2 pinnacles | 3.6 m wide, 11..13.8 m; 2.2 m tall | gable centres | M_GLASS, M_STONE | 4 roof |
| turrets | 4 boxes plus bands and pyramids | 5 x 4.8 m, 10..18.8 m | u 10.1 / 86.7, v 11.3 / 32.8 | M_STONE | 2 massing |
| lantern | box plus glass roof | 62.1 x 11 m, 12.4..17.4 m | the ridge | M_GLASS, M_GLASS_ROOF | 4 roof |
