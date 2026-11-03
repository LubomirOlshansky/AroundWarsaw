# Most Poniatowskiego: spec

Site key `poniatowski` in `game/scripts/landmarks.gd` (`_find_towers`, `_build_towers`, `_pt_group`)
for the four tower groups, and `game/scripts/map_builder.gd` (`_build_poniatowski`, `_pn_pier`,
`_pn_edges`, `_poniatowski_skips`) for the river spans, `_build_powisle` (`_pv_*`, 2026-11-03) for the
Powiśle viaduct and `landmarks.gd` `_pt_ramp` for the north groups' stairs. Written 2026-11-02 from the reference set the
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
| Switchback stair (north groups, 2026-11-03) | seat frame: a flight u 0-2.65 from the pavilion's outer face out to v 8.2, a half-round turn round (3.0, 8.2) radii 0.3-2.95, a flight back to v 5.6 by the shaft; parapets 0.6 m on the mapped walls | treads stepping evenly from the walk down to the boulevard, parapets 1 m over them, a lantern at the turn and the foot |
| Stair turret (south groups) | seat frame (3.5 along to the land, 9.5 out), r 2.5 m; the W-S one lands at (936, -114) as the ortho shows | to 2 m, merlons to 3 m; the flight from the pavilion out to it |
| Piers | on the axis at s 109.9, 183.9, 259.8, 335.7, 411.6 m from the west towers' line (report: (1036, -171), (1106, -195), (1178, -219) sure; (1250, -243), (1322, -267) estimated) | 9 m thick, straight sides to ±12 m, round cutwaters to ±16.5 m; up to 9.25 m under the deck |
| Arch ribs | four planes at ±4.6 and ±12.4 m, between the abutments' faces (s 6, 509.5) and the piers | 7.5 m deep at the springs, 1.6 m at the crown, 12 panels a span |
| Fascia, railing | the deck's outer edges (−14.7, +14.45) over the river part | fascia 1.35 m under to 0.5 m over the walk; railing to 1.2 m, a post every 2.4 m |
| Pedestals | over each pier, both edges | 2.6 x 1.4 m, to 1.75 m with a cap and a small turret top to 2.6 m |
| Powiśle viaduct (2026-11-03) | both outer edges of the deck from s -272 to 426 in the frame from PV_A (449.1, 30.6) (the escarpment to Wybrzeże; the towers stand at s ~510); south from s 296 on t = 0 (Al. 3 Maja runs under the edge) | pilasters 2.4 x 2 m (0.4 m proud) every ~19 m from the ground to the slab, a 1.8 m plinth and an impost band; segmental arches (rise ≤ 0.3 span, springing ≥ 4.5 m over the ground) with a 0.7 m archivolt, the spandrel 1.6 m thick with ribs every 3.2 m and a cornice under the slab; the mapped pier buildings (s 4-18, 42-55, 217-231, 281-296) are the big piers |

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

L2. Towers (with the north stairs and the lanterns since 2026-11-03) budget 2700 (`check_mesh_quality.gd`);
the spans and the viaduct are map geometry (about 11 k + 14 k triangles in the walls surface, no draw call).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| pavilion | box + merlons | seat, to 7.5 m over the deck | each group's seat | M_STONE #e8dfc8, M_ATTIC | arcaded pavilion |
| arcade | arch panels | 3-5 bays, 3.5 m high | walk side (open), river side (glazed) | M_STONE #3a3640, M_PAVILION #4a5560 | round arches |
| shaft | box, cornice, belfry, merlons | 7 x 7 m to 20 m over the deck | the pavilion's land end | M_STONE #e8dfc8 | the tower |
| base | box | from the boulevard to the deck | under pavilion and shaft | M_STONE #b9b2a2 | stone base, portals |
| turret | 8-sided prism + merlons | r 2.5 m, to 3 m over the deck | south groups, (3.5, 9.5) in the seat frame | M_STONE #e8dfc8 | stair turret |
| pier | rounded block, courses, cap | 9 x 24 m + cutwaters | s 109.9-411.6 on the axis | walls #9c9a94 | granite pier |
| rib | struts | 7.5 m deep at the springs, 1.6 m at the crown | four planes under the deck | walls #7c8288 | steel arch |
| fascia, railing | quads, struts | 1.85 m; 1.2 m | both deck edges over the river | walls #b8484e, #1f1f22 | red girder, iron railing |
| pedestal | boxes | 2.6 x 1.4 m to 2.6 m | over each pier, both edges | walls #9c9a94, #a8323a | cartouche |

## 9. Not built (open)

- Whether a pier hides near the west bank in the deck's shadow (the west span is ~104 m, the record
  says eight spans): QUESTIONS.
- The small 2-3 bay arcade beyond the shaft;
  the scrolls on the merlons and the triangular insets over the arches; the brick panels and
  balconies on the bases' Powiśle faces.
- The viaduct's real arch count and spans, and which arches are filled in with shops (the report's text has
  no numbers; QUESTIONS 2026-11-03).
- The tram catenary masts every ~30 m are the bake's lamp posts, not the real masts.
