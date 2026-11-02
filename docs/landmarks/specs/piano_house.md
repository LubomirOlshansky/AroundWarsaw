# Piano House: spec

Site key `piano_house` in `game/scripts/landmarks.gd` (`_find_piano_house`, `_build_piano_house`).
Written 2026-11-02 in a cloud thread from the OpenStreetMap outline and height; no photo and no
LoD2 here, so the facade pattern and colours are estimates *(photo check)*. It replaces the plain
block the map builder drew from the same outline.

## 1. Identity

Piano House, flats of the 2010s on Zajęcza by Topiel in Powiśle, just below the music university.
Card: "Piano House", PL "Dom na Zajęczej, tuż pod Akademią Muzyczną. Elewacja jak klawiatura:
białe klawisze, czarne okna."

## 2. Massing

The mapped outline is an L about 50 by 80 m with a saw-toothed west front (steps of 1-2 m every
5-6 m), kept at a 0.35 m simplification. The body rises to 17.8 m; the top floor (to 20.8 m, the
OSM height) is set back 1.6 m from a smoother outline, so the saw teeth fall away up there
*(photo check: is there a set-back top floor?)*. The L's centre lies in its open corner, so the
site's zone adds the outline's hull (nothing else stands in it).

## 3. Facade, base to top

New skin `S_KEYS` (building.gdshader): white plaster in 1.25 m "white keys" with a fine joint,
dark window strips full height over the joints after the 1st, 2nd, 4th, 5th and 6th key of every
seven (a keyboard's 2 and 3), a faint floor line every 3.1 m; a glazed ground floor (3.6 m) and a
plain band 0.7 m under the top. At night some strips glow warm, the ground floor glows.
Top floor: dark glass (`S_DARK`).

## 4. Roof

Flat, grey `#8d9094`, on the body and the top floor.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Body | #eeece6 | M_SKIN S_KEYS |
| Top floor | #3a4250 | M_SKIN S_DARK |
| Roofs | #8d9094 | M_STONE |

## 6. Ground and night

Car collision follows the simplified outline. Night: warm strips and lobby (the skin).

## 7. Detail level and budget

L2, 152 triangles, budget 180. Shots: from Zajęcza's east end (yaw 270), day and dusk, both paths.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | prism | 17.8 m | mapped outline | S_KEYS | keyboard strips |
| top | prism | 3 m | outline simplified 1.2 m, pulled in 1.6 m | S_DARK | set-back floor |
