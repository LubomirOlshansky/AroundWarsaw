# Cedet: log

Spec: [specs/cedet.md](specs/cedet.md). Site key `cedet` (`landmarks.gd` `_build_cedet`,
`_rounded_ring`, `_miter`, `_strip`).

## 2026-11-02: built from the Mac's photos (cloud thread, city inventory item 4)

- Before: the LoD2 and OSM lumps (a grey box with a beige roof storey and four round hoods).
- After (L3): ribbon glass between five cream rounded floor slabs, rounded corners at Krucza and
  the east end, bronze mullions every 7.2 m over granite piers, the open ground floor with shop glass
  set back 1.8 m, the cream cornice, the set-back glass pavilion with its swept-up roof wings, roof
  plant from the orthophoto, the steel loop with its arrow (blue at night).
- References: refs/cedet on F's Mac (Commons photos 3, 4, 5, 6, 8 after the rebuild, ortho.jpg),
  gathered by a Remote Control session; LoD2 heights from the map pack.
- Checks: `check_spec` OK; `check_mesh_quality` 1894 tris (budget 2300), 0 defects (the loop's coil
  leans 0.6 m in and out so its crossings don't z-fight); `bake_city` OK; shots day, night, corner, solo.
- Own look against the report (not an art-director pass): silhouette 4, colour 4, identity features
  all there, facade rhythm 4 (5 storeys, 7.2 m bays), roof 3, ground 3.
- Open (QUESTIONS): the Krucza corner's radius (the report reads 10-12 m from the photos, the OSM
  outline barely rounds it; 5 m built), the east end rounded or not, the pavilion's extent and the
  wings' size, storey height (LoD2 roof ~31 m vs the photos' ~3.7 m storeys), the loop's colour by day
  (built steel blue; photos patina green-grey).

## 2026-11-03: F's look check applied (cloud thread)

- F's answers (landmark look check): Krucza radius 10-12 m; the east end looks softened, radius unclear;
  3.7 m glazed storeys over a taller ground floor; a recessed roof pavilion; a muted metallic grey-bronze
  loop; "restore the two upswept roof wings and their underside shadows first".
- Before: the wings were flat 6.5 m quads rising 2.75 m, the same cream as the plate and with no shade
  under them, so from the game's camera the crown read as one flat cream lid.
- LoD2 read again: the eave is 26.7 m (not 31 m: that was the wings), the roof storey 29-30 m, the wings
  from 30.6 m at u +-20 to 31.5 m at u +-28, tips at u +-30, a 35.5 m box at the pavilion's back.
- After: 5 x 3.7 m storeys over a 6.7 m ground floor (meets the eave); the pavilion's glass 2 m back under
  its plate with a dark soffit; each wing 11 m long, curving up 2.4 m (t^1.7, four pieces) to u +-30, open
  underneath with a dark underside, shaded long edges and a shadow on the deck below; Krucza r 11 m (car
  collision follows the curve there); the plant screen from LoD2; the loop #7a7264 in M_LAMP + 0.5 (the
  shader's new neon variant: own colour by day, blue at night).
- Checks: `check_spec` OK; `check_mesh_quality` 1862 tris (budget 2300), 0 defects; shots day (front,
  Krucza corner, solo), night, prebuilt dusk.
- Open (BACKLOG): the east end's radius, the wings' exact rise, the plant screen's look.
