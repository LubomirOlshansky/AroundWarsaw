# POLIN Museum and the Ghetto Heroes Monument: spec

Site keys `polin` and `getto` in `game/scripts/landmarks.gd` (`_find_polin`, `_build_polin`,
`_polin_canyon`, `_polin_lip`, `_polin_lens`, `_polin_roof_kit`, `_build_getto`, `_menorah`).
Written 2026-11-02 from the reference set the Mac gathered in `refs/polin/` (gitignored): 25
Wikimedia Commons photos (c00-c26 the museum, d00-d12 the monument; authors and licences in
`refs/polin/SOURCES.md`), the GUGiK orthophoto (10 px/m, x -2210..-1990, z -1790..-1600) and
`REPORT.md` measured in game coordinates; plus the GUGiK LoD2 roof from the CI map pack (roof
26.0 m over terrain 8.0 m = 18 m, agreeing with the photos and the ortho's shadows).

## 1. Identity

POLIN, the Museum of the History of Polish Jews (Lahdelma & Mahlamäki, opened 2013), Muranów.
What makes it read:

1. **A plain 68 m square box of grey-green glass fins**, turned ~30 degrees, 18 m tall, a teal
   glass band round the roof edge.
2. **One curved cut through it**: on the east front the canyon, a tall wedge of warm sand concrete
   15 m wide at the foot and 3.5 m at the top (north wall curved and flaring, south wall straight
   and leaning back), deep-set dark glazing; across the roof the glazed slot with its south lip
   lifted; on the west front the big glazed lens.
3. Before it, **Pomnik Bohaterów Getta** (Natan Rapaport, 1948): a dark labradorite wall on a
   stepped platform, the fighters' bronze towards the museum, the deportation relief on the back,
   menorahs.

## 2. Massing

| Part | Where | Size / height above ground |
| --- | --- | --- |
| Box | the OSM outline (simplified 0.6 m) less the cut | -0.4 to 18 m |
| Canyon | frame origin (-2067.3, -1704.1) on the east front, u (0.508, 0.861) south along it, +v into the box | foot u -7.5..7.5 at the front to -2.5..2.5 at v 9; top -1.6..1.9 to -1.2..1.2 |
| Slot | (-2075, -1699.5), (-2089, -1698.7), (-2100, -1692), (-2111, -1684.4), (-2122, -1674.5) | 2.2 m wide, glass 1 m down |
| Lip | the slot's south-east side | 2.5 m over the roof at the slot, back to it over 11 m |
| Lens | west front, centre (-2132, -1680) | 37 m wide, 0.6 m to 14.1 m |
| Roof kit | plant room (-2105, -1728.5) 13 x 7 m, lift box (-2096, -1702) 7 m, skylights at (-2111.5, -1715) and (-2103.5, -1709.5) | 2.6, 3.0, 0.5 m |
| Monument | platform centre (-2031, -1741), long axis (0.457, 0.889) | platform 30 x 16 m, wall 9.5 x 3 x 11 m |

## 3. Facade, base to top

- Fins: the skin S_FINS in grey-green #8a9ba0 (photos: lit #adb3ad, shade #566466, blue under a
  blue sky); the real fins are 0.3 m laminated glass with a speckled frit of P O L I N letters
  that never reads as a word, so no lettering is drawn.
- West and north fronts: a 1.5 m board-marked concrete plinth #a9a7a0, the fins above it.
- Canyon: leaning walls #a39378 (alternate panels a shade darker), the glass at v 9 #4a3f33 (lit
  warm at night), a pale travertine floor #d6cfbf in its mouth flush with the plaza.
- Lens: glass #6f8590 (M_PAVILION, warm at night) 10 cm proud of the fins, a dark lip #2b2f33.
- Teal band #4f8584, 1.2 m above the roof edge all round.

## 4. Roof

Flat pale membrane #bcbcb6 at 18 m; the slot's glass at 17 m; the lip's grey wedge; the plant
room with six round fans, the lift box, two blue skylight groups. No hump: LoD2 shows one over
the west part but the ortho shows a flat membrane (a LoD2 artefact).

## 5. Colour and material

As above; existing materials only (M_SKIN + S_FINS, M_STONE, M_PAVILION, M_LAMP): no new draw
call. Monument: labradorite #5a5e5d, black granite #25272a, granite frames and paving #a8a8a2,
border #7c7d79, bronze #3a3a36, stone relief #8f8a80. Cards "POLIN Muzeum Historii Żydów
Polskich" and "Pomnik Bohaterów Getta"; no humour on either.

## 6. Ground and night

The plaza's setts, lawns and trees are the map's. The car stops at the outline and at the
monument's steps. At night the canyon's glass, the slot, the lens and the monument's flame glow.

## 7. Detail level and budget

L2, triangle budget 450 for `polin` (built 409) and 650 for `getto` (built 546)
(`check_mesh_quality.gd` BUDGET).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| box | walls + cap | outline less the cut, 18 m | the outline | S_FINS #8a9ba0 | glass-fin box |
| plinth | walls | 1.5 m | west and north fronts | M_STONE #a9a7a0 | concrete base |
| canyon | leaning quads | 15 m foot, 3.5 m top, 9 m deep | east front | M_STONE #a39378 | the wedge |
| glazing | quad | across at v 9 | canyon | M_PAVILION #4a3f33 | entrance |
| slot | cap + walls | 2.2 m wide | roof | M_PAVILION #6f8590 | skylight |
| lip | wedge | 2.5 m x 11 m | slot's south side | M_STONE #bcbcb6 | lifted roof |
| lens | fan of quads | 37 x 13.5 m | west front | M_PAVILION #6f8590 + #2b2f33 | the west window |
| band | parapet | 1.2 m | roof edge | M_STONE #4f8584 | teal crown |
| roof_kit | boxes, fans | plant 13 x 7, lift 7 x 7 | roof | M_STONE | plant |
| platform | box + cap | 30 x 16 m | (-2031, -1741) | #7c7d79, #a8a8a2 | paved platform |
| steps | 5 boxes | 15 m wide, 0.16 m risers | west face | #25272a | black steps |
| wall | frustum | 9.5 x 3 to 9 x 2.6, 11 m | platform | #5a5e5d | labradorite wall |
| fighters | frame + recess + 5 figures | 3.8 x 7.5 m | west face | #a8a8a2, #3a3a36 | bronze relief |
| deportation | frame + panel | 6.4 x 4 m | east face | #a8a8a2, #8f8a80 | stone relief |
| menorahs | blocks + beams | 1.5 m blocks, 2 m | steps' ends; one at the wall with a flame | #25272a, #3a3a36, M_LAMP | candlesticks |
