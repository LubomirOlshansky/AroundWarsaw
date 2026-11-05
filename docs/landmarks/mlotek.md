# Młotek (Smolna 8): log

Spec: [specs/mlotek.md](specs/mlotek.md). Site key `mlotek` (`landmarks.gd` `_find_mlotek`, `_build_mlotek`,
`_build_mlotek_head`, `_build_mlotek_foot`).

## 2026-11-05: plain block to model (Mac)

- Round 1 scores 3-4; fixes: the notch over the west balconies, deeper balcony edges, pale rims, taller windows.
- Round 2 (art-director, before the merge below): all 4, pass. It scored a roofline climbing east, which that
  model's height data then showed to be perspective.
- A model F sent, `mlotek-smolna-8.js` (origin and permission to confirm, QUESTIONS), was ported to the game as a test and compared with this build. Merged at F's word:
  flat roof, head to u 41.2, the sloping jaw, wider west balconies with yellow fronts. Kept from ours: the colour,
  19 window rows, the glass band on the east half only, the neck, the pergola.
- The merged build has not had an art-director pass: F's look is the check.
- `check_mesh_quality`: 1974 tris, budget 2400, 0 defects.
- Differs from the photos: the north face is mirrored from the south; the fence and low wall at the foot are missing.
