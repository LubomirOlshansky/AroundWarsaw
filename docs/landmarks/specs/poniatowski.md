# Most Poniatowskiego: spec

Site key `poniatowski` in `game/scripts/landmarks.gd` (`_find_towers`, `_build_towers`, `_pt_group`)
for the four tower groups, and `game/scripts/map_builder.gd` (`_build_poniatowski`, `_pn_pier`,
`_pn_edges`, `_poniatowski_skips`) for the river spans. Written 2026-11-02 from the reference set the
Mac gathered in `refs/poniatowski/` (gitignored): 30 Wikimedia Commons photos and four GUGiK
orthophotos, measured in game coordinates in `docs/landmarks/photo-reports/poniatowski.md` (authors
and licences there). The GUGiK LoD2 in the map pack has no part of the bridge or its towers, so every
height comes from the photos (±3 m).

## 1. Identity

The bridge of 1914 (Stefan Szyller; Mieczysław Marszewski and Wacław Paszkowski), 506 m of steel
deck arches over the Vistula between Powiśle and the Praga floodplain, carried on to Nowy Świat by
the concrete viaduct. What makes it read:

1. **Four cream tower groups** on the abutments, two at each end: a crenellated arcaded pavilion
   along the deck's edge and a square tower with a belfry and a merlon crown at its land end.
2. **Grey steel arch ribs under the deck** springing from **grey granite piers** with rounded
   cutwaters.
3. **A red fascia girder** along both edges under a **black cast-iron balustrade**, with a granite
   pedestal and a coat of arms standing out of the railing over each pier.

## 2. Massing

| Part | Where | Size / height over the deck walk |
| --- | --- | --- |
| Pavilion | the bake's seat (`towers`: centre, axis, half sizes ~7 x 1.6-2.4 m) | stone base from the boulevard (~9.6 m under the deck), cream to 5.6 m, merlons to 7.5 m |
| Shaft | centre 0.5 m past the pavilion's land end, 3.5 m out from its deck-side face, 7 x 7 m | cornice 15.3-16 m, belfry 6 x 6 m to 18 m, merlons to 19 m, corner balls to 20 m |
| Stair turret (south groups) | seat frame (3.5 along to the land, 9.5 out), r 2.5 m; the W-S one lands at (936, -114) as the ortho shows | to 2 m, merlons to 3 m; the flight from the pavilion out to it |
| Piers | on the axis at s 109.9, 183.9, 259.8, 335.7, 411.6 m from the west towers' line (report: (1036, -171), (1106, -195), (1178, -219) sure; (1250, -243), (1322, -267) estimated) | 9 m thick, straight sides to ±12 m, round cutwaters to ±16.5 m; up to 9.25 m under the deck |
| Arch ribs | four planes at ±4.6 and ±12.4 m, between the abutments' faces (s 6, 509.5) and the piers | 7.5 m deep at the springs, 1.6 m at the crown, 12 panels a span |
| Fascia, railing | the deck's outer edges (−14.7, +14.45) over the river part | fascia 1.35 m under to 0.5 m over the walk; railing to 1.2 m, a post every 2.4 m |
| Pedestals | over each pier, both edges | 2.6 x 1.4 m, to 1.75 m with a cap and a small turret top to 2.6 m |

## 3. Facade, base to top

- Under the deck: grey-cream stone blocks #b9b2a2, round-arched portals on the shaft's outer and land
  faces to the boulevard.
- Pavilion: cream render #e8dfc8, a string course #cfc4a8 at 4.5-4.9 m, the merlon parapet
  (M_ATTIC). Walk side: an open arcade of round arches 3.5 m high (dark), the river side and the
  ends: glazed arched windows (M_PAVILION, warm at night; the real ones are leaded diamond panes).
- Shaft: plain cream walls, two small arched windows a face (8-9.6 m and 11.6-12.6 m), the cornice,
  the belfry with three arched slits a face, merlons, four corner balls; an iron lantern on its
  walk-side face (M_LAMP).

## 4. Roof

Flat roofs #8f8a80 behind the merlons of the pavilion, the cornice, the belfry and the turret.

## 5. Colour and material

Existing materials only (M_STONE, M_ATTIC, M_PAVILION, M_LAMP; the spans in the walls surface): no
new draw call. Steel #7c8288, granite #9c9a94, fascia #b8484e, iron #1f1f22, cartouche #a8323a.

## 6. Ground and night

The car stops at the pavilion, the shaft and the turret on both levels (C10 in `check_roads.py`
mirrors the colliders); the piers are solid. At night the pavilion windows and the lanterns glow;
the deck's lamps are the bake's.

## 7. Detail level and budget

L2. Towers 1536 triangles, budget 1850 (`check_mesh_quality.gd`); the spans are map geometry
(about 11 k triangles in the walls surface, no draw call).

## 8. Not built (open)

- Whether a pier hides near the west bank in the deck's shadow (the west span is ~104 m, the record
  says eight spans): QUESTIONS.
- The north groups' curved ramp down to the lower road; the small 2-3 bay arcade beyond the shaft;
  the scrolls on the merlons and the triangular insets over the arches; the brick panels and
  balconies on the bases' Powiśle faces.
- The concrete arch viaduct over Powiśle (wide shallow arches, ribbed spandrels, #b8b6b0).
- The tram catenary masts every ~30 m are the bake's lamp posts, not the real masts.
