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

## 4. Roof, colour, material

As Mirowska (`MIROWSKA_*` colours, M_STONE walls, M_GLASS panes and lantern, M_GLASS_ROOF
lantern roof). No new material or draw call.

## 5. Ground and night

The car is stopped by the outline's ring. Card: "Hala Gwardii", PL "Ceglana hala przy Żelaznej
Bramie, bliźniaczka Mirowskiej.", EN "A brick market hall by Żelazna Brama, Mirowska's twin."
Map icon `hall`. The 2016 "boarded windows" then-card (`then_cards.json`) is a separate overlay.
Open *(photo check)*: the real brick colour, the door count on the long sides, whether the
lantern glows, the real state of the roof.

## 6. Detail level and budget

L2, 1212 triangles measured, budget 1450 in `check_mesh_quality.gd`; no zfight, degenerate,
bad-normal or floating parts. Shots: `--solo=gwardii --solo-look=lit`.
