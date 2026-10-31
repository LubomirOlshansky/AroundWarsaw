# Biblioteka Uniwersytecka (BUW): log

Spec: [specs/buw.md](specs/buw.md). Site key `buw` (`landmarks.gd` `_find_buw`, `_buw_beds`,
`_build_buw`, `_buw_front`, `_buw_roof`).

## 2026-10-31: skin to model (cloud thread)

- Before: a skin (LoD2's massing in one green, `SKINS`), "no rooftop garden detail".
- After: L2 model from OpenStreetMap alone (no free photo, no network to Commons or GUGiK from
  the cloud): the glass block to the roof garden's mapped 10.9 m; on Dobra 12 copper plates
  with lines of text, the entrance under the middle two and the four philosophers on columns;
  a trellis post every 6 m on the other fronts; the roof garden from the 60 mapped lawns as
  beds on a pale deck (the paths between them); the long glass roof with its trusses, the
  second glass roof and the round lights as glass hips and cones (no flat top, so the cassette
  lands on the garden); three copper roof houses.
- Checks: `check_spec` OK; `check_mesh_quality` 0 defects, 1860 tris, budget 2250; the PR #115 cassette
  (`c01_buw`) placed on the garden (checked on that branch merged with this one).
- Scores: none yet (no photos in the cloud; art-director pass waits for the Mac).

## Still differs / photo check on the Mac

- The height: 10.9 m is OpenStreetMap's; LoD2 (on the Mac) may say more.
- Which front the philosophers stand at (built on Dobra, before the copper pages).
- The plates' count, width and how far they rise over the roof.
- The other fronts: how much is glass, how much trellis and greenery.
