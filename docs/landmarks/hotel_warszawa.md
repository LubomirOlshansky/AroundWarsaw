# Hotel Warszawa (the Prudential): log

Spec: [specs/hotel_warszawa.md](specs/hotel_warszawa.md). Site key `hotel_warszawa`
(`landmarks.gd` `_build_hotel_warszawa`, `_hw_panes`, `_hw_back_panes`, `_hw_glow_strip`, `_hw_flag`).

## 2026-11-02: built from the Mac's photos (cloud thread, city inventory item 4)

- Before: the LoD2 and OSM lumps, the tower drawn as a blue-glass box with a flat top.
- After (L3): the cream stone shaft with eight front pilasters and 7 x 12 small windows, the heavy
  cornice, the set-back two-storey crown with its own cornice, masts and flag, the low base with the
  WARSZAWA portal and copper doors, the two six-storey wings, the 25 m U behind round a
  glass-roofed hall, flagpoles on the square, floodlit pilasters and cornices at night.
- References: refs/hotel_warszawa on F's Mac (Commons photos 1, 2, 7, 8 after the 2018 restoration,
  ortho.jpg), gathered by a Remote Control session; LoD2 heights from the map pack.
- Checks: `check_spec` OK; `check_mesh_quality` 1894 tris (budget 2300), 0 defects; `bake_city` OK
  (prebuilt path); shots day, night, crown and solo.
- Own look against the report (the cloud cannot open the photos; not an art-director pass):
  silhouette 4 (shaft, cornice step, crown and wings read), colour 4, identity features all there,
  facade rhythm 4 (8 pilasters, 7 x 12), roof 3 (masts and lift head placed by the report, not
  measured on the ortho), ground 3.
- Still differs / open: which way the front faces was read as east from the photos (fits the
  outline: the portal bump is on the square side); the U behind is one 25 m height (LoD2 shows
  some lower bits); the side pilasters' doubled corner strips are single. Mac photo check in QUESTIONS.
