# Poczta Główna (Świętokrzyska 31/33): spec

Site key `poczta` in `game/scripts/landmarks.gd` (SKINS entry, `_build_poczta`). Written 2026-11-03
in a cloud thread from the Mac photo report `docs/landmarks/photo-reports/poczta.md` (photo 1 the
building today, the GUGiK ortho; photos stay on F's Mac in `refs/poczta/`) and the LoD2 model.

## 1. Identity

1. **A pale salmon-pink eight-storey block** along Świętokrzyska, regular rows of plain windows,
   a cornice under the top storey.
2. **The round corner tower at Jasna** under a small grey-silver dome, a storey above the roof.
3. **The entrance**: six white columns two storeys high before a glazed recess, under a red band
   with the name (the game's parody: POCZTA, neon letters).
4. **The glazed central hall** behind the front.

## 2. Massing

Kept skin: LoD2's mass stays (roof ~29.8 m over the ground, the hall's hip 8-13.2 m, the rear
courtyard). Frame: u west along the Świętokrzyska face from (-906.2, -164.7), 54.4 m long, +v out
to the street. The corner tower's centre at (u, v) (-0.5, -4.5), ortho (-905, -159).

## 3. Facade

- Street level: three tall arched windows at u 4.2, 7.8, 11.4 (the corner's ground floor).
- The entrance at u 26.5 (the hall's axis): a podium, six columns r 0.42 at v 2.0 up to 8.2 m,
  dark glazing on the wall behind, a white entablature 8.2-9.0 m, the red band 9.0-10.4 m.
- A recessed white window strip at u 14.5 from the pavement to the cornice.
- A cornice band at 26.2-26.7 m along the face; above and between, LoD2's walls in M_MONUMENT.

## 4. Roof

LoD2's flat roof (#77706b). The corner drum (r 3.6) rises to 33 m with white ring cornices at 30
and 33 m, the dome (r 3.75) in four bands to ~37.6 m, a lantern and a point. The hall's roof: a
glass hip (M_GLASS_ROOF) from 8 to 13.5 m just over LoD2's.

## 5. Colour and material

Plaster #e5c8b4 (the report's #E3C3AE a step paler), columns and trim #f0ece4, band #c0262d,
dome #a7acb0, glazing #3a454e, hall glass #7a8d98, letters warm yellow.

## 6. Ground and night

The podium sits on the pavement; car walls round it. At night the POCZTA letters glow and the
hall's glass and windows light as the shader does.

## 7. Detail level and budget

L2, triangle budget 710 (588 measured plus 20 %, in `check_mesh_quality.gd`). Shots in project
files `poczta-pasta/`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | LoD2 kept skin | 54 x 55 m, 29.8 m | the outline | M_MONUMENT salmon | the block |
| drum | 14-gon prism | r 3.6, ground to 33 m | (-0.5, -4.5) | M_MONUMENT salmon | corner tower |
| dome | four frusta, lantern, point | r 3.75, to ~39.4 m | on the drum | M_STONE silver | corner dome |
| colonnade | six columns, podium, entablature | 18.4 x 3.2 m, 9 m | u 26.5, v 0-2.8 | M_STONE white | entrance |
| band | box and neon word | 18.4 x 3.0 x 1.4 m | over the entablature | M_STONE red | POCZTA |
| strip | box and glass | 2.2 x 27.7 m | u 14.5 | M_STONE white, M_GLASS | window strip |
| arches | three arched windows | 2.1 x 5.4 m | u 4.2-11.4 | M_GLASS | corner shop floor |
| cornice | box | 49.4 x 0.9 x 0.5 m | 26.2 m | M_STONE | top storey line |
| hall | hipped frustum | 31 x 16 m, 8-13.5 m | u 26.75, v -23.3 | M_GLASS_ROOF | glazed hall |

## 9. Open (photo check)

The colonnade's place and whether it is recessed; the dome's size against LoD2's corner lump; the
plaster's colour on the phone.
