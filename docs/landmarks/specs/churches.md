# The church kit (22 parish churches): spec

Sites `church_<name>` in `game/scripts/landmarks.gd` (`CHURCHES`, `_find_churches`,
`_build_church`). Written 2026-11-01 in a cloud thread ("all the churches designed with best
practices", F) from the OpenStreetMap outlines in `centrum.json`; no photo, no LoD2 here. The rules
and the full inventory are in `docs/design/churches.md`. Every height, tower count, cap and colour
is an estimate; the Mac photo check of each church is parked in QUESTIONS.

## 1. Identity

One builder for the churches that had no model of their own: St Martin, the Capuchins' church,
the Immaculate Conception chapel, the Field Cathedral, the Holy Spirit, St Hyacinth, St Anthony
(Senatorska), St Brother Albert, the Reformed church, Our Lady of Jerusalem, the Pentecostal
church, the Child Jesus, the Nativity, St Charles Borromeo, St Augustine, Divine Mercy, Saints
Peter and Paul, Holy Trinity (Praga), Our Lady of Częstochowa, Our Lady the Victorious, the
Cerkiew and the Nożyk Synagogue. Each is a long box with a front end on a street, a gabled
nave, a facade, and towers by count. Before this each was an extruded outline at the mapped 14 m.

## 2. Massing

Per church: the mapped outline (simplified 0.6 m) as the body; a frame with its origin at the
front end's middle, `+v` out of the front, `u` across. Fields in `CHURCHES`: `o` and `out` (the
front), `L` and `W` (half length and half width of the outline's long box), `fill` (outline area
over box area). Eave height is `W` times the style's factor, clamped to 7.5-15 m. A tower is
`0.3 W` half-wide (2-3.6 m) at the front, proud of the facade by 0.2 m.

## 3. Facade, base to top

Plinth 1.2 m (outline grown 0.3 m), a windowed storey (`M_MONUMENT`) to the eave, a cornice 0.7 m.
Front: two corner pilasters, a string course, a dark portal (2.2 to 4 m wide) with jambs, a hood
and three steps, a dark window above, and in gothic and romanesque a round rose in the gable.
Long walls: lesenes (baroque, romanesque) or buttresses with a stepped cap (gothic) every
4.8 m, on edges within 20 degrees of the long axis.

## 4. Roof

A gable along the long axis over the box, front and back triangles in the wall colour, rise
`W` times the style's pitch (0.4 to 1.0); a cross plan (fill < 0.8) gets a nave 0.62 W wide over a
flat deck in a grey-brown. Towers: a belfry stage with dark louvres on all four faces, then a cap:
helm and dome (frustum profiles in `CHURCH_CAPS`), pyramid (four faces, 3 half-widths high),
spire (octagonal, 6.5 half-widths), onion (gold, on a drum on the Cerkiew's ridge), or a ridge
turret. A gilt cross on every cap and on the ridge of a towerless church.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Wall | per church: cream plaster #e2d3ae-#e9e0c8, brick #a44b38-#b0603f, modern #ddd6c8-#e8e2d4 | M_MONUMENT |
| Trim, pilasters | lightened wall or #ece4d2 | M_STONE |
| Plinth, steps | #a39b8a | M_STONE |
| Roof | per church: copper-green #6f8a7c, brown #7a5a48-#8a5a44, slate-brown #6e5d58-#725f58 | M_STONE |
| Portals, louvres, rose | #3a3d40 | M_GLASS, M_STONE |
| Crosses, onion | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

Car collision along the outline and each tower's footprint. Each church has a card (name and one
line, Polish and English, in `INFO`); the zone is the outline grown 3 m. No night lighting yet.
Open *(photo check)* for every church: which end is the front, the tower count and cap, colours.

## 7. Detail level and budget

L2. Measured 250-950 triangles per church, budgets measured plus 20 percent in
`check_mesh_quality.gd`. Shots: `--at=<church> --yaw=<front angle + 35> --pitch=-28 --time=day
--size=75 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | prism of the mapped outline | eave 7.5-15 m | outline | M_MONUMENT | 3 body |
| plinth, cornice | 2 prisms | outline grown 0.3 and 0.45 m | 0..1.2 m, at the eave | M_STONE | 3 body |
| nave roof | gable | 2L x 2W (0.62 W on a cross plan), rise 0.4-1.0 W | at the eave | M_STONE | 4 roof |
| portal | dark pane, jambs, hood, 3 steps | 2.2-4 m wide | u 0, v 0 | M_GLASS, M_STONE | 3 facade |
| pilasters | 2 boxes | 0.9 x 0.3 m, to the eave | u +-(W - 0.45) | M_STONE | 3 facade |
| lesenes, buttresses | boxes every 4.8 m | 0.4-0.6 m square | long walls | M_STONE | 3 walls |
| rose, window | disc, pane | r up to 2 m, 1.2 x 3 m | in the gable, over the portal | M_GLASS | 3 facade |
| towers | shaft, belfry, cornices | 0.6 W square, to 2-3 x the eave (max 34 m) | front, u 0 or +-(W - ts) | M_MONUMENT, M_STONE | 3 towers |
| caps | frustums | helm, dome, pyramid, spire | on the belfry | M_STONE | 4 roof |
| onion, drum | prism, 4 frustums | r 1.6-3 m | ridge middle (Cerkiew) | M_MONUMENT, M_STONE | 4 roof |
| crosses | 2 gilt boxes | 3 m tall | tops | M_STONE | 4 roof |
