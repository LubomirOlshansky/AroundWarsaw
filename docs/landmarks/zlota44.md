# Złota 44: log

Spec: [specs/zlota44.md](specs/zlota44.md). Site key `zlota44` (`landmarks.gd` `_zlota_sail`,
`_zlota_point`, `_zlota_flare`, `_zlota_garden`; skin `S_SAIL` in `building.gdshader`).

## 2026-11-02: rebuilt from F's photos (cloud thread)

- Before: a lofted blue-glass block with white diagonal "exoskeleton" lines (the real tower has
  none), its roof slope high at the north end (wrong: the tip is the south-east corner), no crown
  box, plain podium.
- After (L3): the south-east wing (a 2.6 m wedge at the foot, a waist at 64 m, 9 m out at the
  top), the roof cut on one plane from the 192 m tip to 150 m, the dark glazed crown box to
  184 m set back from the east face, white cassette bands with staggered glass, the podium's
  roof garden (Varso's terrace builder), a new card text.
- References: F's two photos (street view from the east by Lumen; aerial from the Palace, looking
  south-west). Commons and the Geoportal orthophoto are blocked from the cloud.
- Checks: `check_spec` OK; `check_mesh_quality` 1375 tris (budget 1800), 0 defects;
  `check_sites` OK; `bake_city` OK (prebuilt path); shots on both paths.
- Own look against the photos (not an art-director pass): silhouette 4 (the tip, slope and crown
  box read as in photo 2; the wing's lean is subtle from the driving camera), colour 4 (white with
  grey stripes), identity features all there, facade rhythm 4, ground 3 (garden yes, the base's
  glass wedge is hidden inside the podium on the east side).
- Still differs: the far skyline stand-in was not looked at (it takes the glass colour, now paler); crown box height
  and extent and the wing's lean wait for the Mac photo check (QUESTIONS).
