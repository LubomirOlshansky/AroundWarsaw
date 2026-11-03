# Dom Towarowy Braci Jabłkowskich (Bracka 25): spec

Site key `jablkowscy` in `game/scripts/landmarks.gd` (`_build_jablkowscy`). Written 2026-11-03 from the Mac photo report `docs/landmarks/photo-reports/jablkowskich.md` (refs/jablkowskich/: five Commons photos, the front, details, the entrance, the stained glass, and the GUGiK ortho) and the OpenStreetMap outline. The shop in it today is a real brand: the sign over the door says DOM MODY instead.

## 1. Identity

The 1914 Art Nouveau department store on Bracka, by the Chmielna square: ochre stone, arched shop windows, two white columns at the door.

## 2. Massing

The mapped outline simplified (0.4 m); the front is its 38.6 m edge on Bracka (found at runtime as the edge nearest (-579, 202)). A 8.4 m two-storey base, four storeys of 3.7 m to the cornice at 24.6 m, an attic storey set back 0.9 m to 28.2 m.

## 3. Facade, base to top

Nine bays on the front. The base: eight round-arched shop windows in stone frames between slim piers, the middle bay the entrance (a dark door and fanlight between two fat white Doric columns under a lintel). A balcony band over the base with a balustrade of 19 posts and a rail. Four storeys of paired tall windows per bay with a light relief panel under each pair. A cornice 0.5 m proud, a cartouche with a gilt roundel over the middle. The other fronts: plain rows of windows.

## 4. Roof

The attic storey's flat top in grey; the atrium's low glass hip roof in the middle of the block (the ortho's glazed roof).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Render | #d9c3a0 | M_STONE |
| Stone base | #7d6b5a | M_STONE |
| Trim, balustrade, panels | #e8dcc2 | M_STONE |
| Columns | #f0ece2 | M_STONE |
| Windows | #3a3f45 | M_GLASS |
| Shop windows | #d8c08a | M_GLASS |
| Atrium | #9fb3bd | M_STONE |

No new material or draw call.

## 6. Ground and night

Car walls on the mapped outline, handed to the pocket bridging so the slit by the glass block on the Chmielna square stays closed (PT-7, `check_stuck_spots`). The LoD2 block's 9 m entrance recess is gone with it. DOM MODY in warm white over the door. Card from INFO. Open (photo check): the stained-glass windows inside (not built), the cartouche's initials, the base's true height.

## 7. Detail level and budget

L2, triangle budget 1450 (`check_mesh_quality.gd`; 1205 built).

Shot: `--at=-548,195 --yaw=135 --pitch=-45 --size=75 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| base | ring prism | 8.4 m high | ground | M_STONE | 3 facade |
| body | ring prism | 16.2 m high | 8.4 m | M_STONE | 2 massing |
| cornice | offset prism | 0.8 m high | 24.6 m | M_STONE | 3 facade |
| attic | inset prism | 2.8 m high | 25.4 m | M_STONE | 4 roof |
| arches | arch panels | 3.3 m wide, 6 m to the spring | base, 8 bays | M_GLASS | 3 facade |
| piers | boxes | 0.56 m | between bays | M_STONE | 3 facade |
| balcony | slab, 19 posts, rail | 38.6 m | 8.4 m | M_STONE | 3 facade |
| windows | panes | 1.2 x 2.3 m | four storeys, pairs | M_GLASS | 3 facade |
| columns | Doric columns | r 0.45 m, 6.8 m | the door | M_STONE | 3 facade |
| cartouche | box and disc | 2.2 m | cornice middle | M_STONE | 3 facade |
| atrium | hip | 14 x 10 m | roof middle | M_STONE | 4 roof |
