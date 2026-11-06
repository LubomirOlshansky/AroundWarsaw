# Foksal 13 and 15: spec

Site key `foksal` in `game/scripts/landmarks.gd` (`_build_foksal`, `_build_foksal13`, `_build_foksal15`). Written 2026-11-05 from F's photos (a straight-on street photo of both fronts with the "13" by the gate, a sunlit three-quarter photo, a close-up of Foksal 15's windows, two developer renders by day and night; kept with the trial in the project files, not in the repo), two 2019 Mapillary frames of the front and the back (`refs/foksal13/`, `refs/foksal13front/`, gitignored), the GUGiK LoD2 roofs and the two unnamed OSM outlines (`apartments`, 17.5 m, found by their address points Foksal 13 and Foksal 15; `tools/bake_sectors.py` SITE_AREAS keeps them for the streamed path). Asked for by F on 2026-11-05 after the Tiny Warsaw pack's model of Foksal 13 turned out wrong (its details on the courtyard side).

## 1. Identity

Two restored pre-war tenements side by side on Foksal. Foksal 13: salmon brick framed in white stone, a white rusticated ground floor round an arched dark gate with two atlantes, two crested gables over the end bays, stone balconies on the first floor and iron ones above. Foksal 15 (west of it): ochre brick, cream stone, red window frames, round-headed top-floor windows, and a forward bay at its east end with stacked iron balconies under a small gable.

## 2. Massing

The masses, courtyards and mansards are the GUGiK LoD2 models, kept in a skin (cream plaster walls behind, zinc roofs). The fronts are ours on the outlines' street edges: Foksal 13 from (-184.2, 27.8) to (-160.2, 18.6), 25.7 m, eaves 22.4 m (LoD2 22.6), the two 4.8 m end bays 0.25 m forward; Foksal 15 from (-206.5, 38.3) to (-188.6, 31.7), 19.1 m, eaves 20.6 m, and its bay from (-189.3, 29.8) to (-184.2, 27.8), 5.5 m, 2 m forward of the rest. LoD2's front walls stand 0.3 m behind the outline, so the fronts cover them.

## 3. Facade, base to top

Foksal 13: a white rusticated ground floor to 6.4 m in four courses with four windows each side of the gate (1.16 x 3 m); a white band; four storeys of 3.9 m with eleven windows each (1.24 x 2.6 m in white surrounds: two in each end bay, seven 2.3 m apart between), pediments over the first floor's; white string courses at each floor; a white frieze and a 0.9 m cornice at 22.4 m. Foksal 15: a cream rusticated ground floor to 5.6 m with six round-headed openings (3.1 m bays), four storeys of 3.7 m with framed windows (1.3 x 2.5 m, cream surround, red frame), the top floor's round-headed; cream bands and a cornice at 20.6 m. The bay: the same with two windows a floor and a round-headed door.

## 4. Roof

LoD2's zinc mansards with their dormers (skin roof #6f7882, slopes from n.y 0.3 count as roof). Over Foksal 13's end bays two crested gables (3.4 m face, a pointed crest, a finial, an arched attic window); over Foksal 15's bay a smaller one (2 m face). No ortho was used (the Mac gather was skipped): the roof is LoD2's as it stands.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Foksal 13 brick | #dc9c7a | M_STONE |
| White stone | #eeebe4 | M_STONE |
| Foksal 15 brick | #c39a72 | M_STONE |
| Cream stone | #e9dfc8 | M_STONE |
| Window frames (15) | #8c2b2b | M_STONE |
| Glass | #3d4652 | M_GLASS |
| Iron | #3f4247 | M_STONE |
| Gate | #2c2a2b | M_STONE |
| Skin walls / roofs | #e3d6bd / #6f7882 | ordinary style 0.37 |

No new material or draw call.

## 6. Ground and night

The car's walls stay the kept buildings' (map_builder). At night the glass windows light by the glass shader, each window its own column (about a third lit, warm or cool by floor). Not built yet: the warm uplights on the stone frames and the glowing ground floor of the night render (BACKLOG).

## 7. Detail level and budget

L2, triangle budget 3000 (`check_mesh_quality.gd`; about 2,550 built).

Shot: `--at=-178,8 --yaw=180 --lift=16 --size=40` (day, dusk, night).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| fk13_brick | wall + 2 boxes | 25.7 x 15.6 m | 13's front, 6.4-22 m | M_STONE | 1 brick and stone |
| fk13_ground | 4 boxes | 25.7 x 6.7 m | 13's front, ground | M_STONE | 1 rusticated ground floor |
| fk13_windows | surround + glass | 44 + 8 windows | 13's front | M_STONE, M_GLASS | 3 facade |
| fk13_gate | 2 arch panels, 2 atlantes | 3.5 m arch | 13's middle | M_STONE | 1 gate and atlantes |
| fk13_balconies | slab, rail, brackets | 3 stone, 5 iron | floors 1-3 | M_STONE | 1 balconies |
| fk13_gables | box, pyramid, finial, window | 4 x 3.4 m | over the end bays | M_STONE, M_GLASS | 1 crested gables |
| fk15_brick | wall | 19.1 x 14.6 m | 15's front | M_STONE | 1 ochre brick |
| fk15_windows | surround, red frame, glass | 24 + 6 arched | 15's front | M_STONE, M_GLASS | 1 red frames, arched top |
| fk15_bay | wall, windows, 3 iron balconies, gable | 5.5 m | 15's east end | M_STONE, M_GLASS | 1 forward bay |
| skin | kept LoD2 | the two outlines | masses and roofs | style 0.37 | 4 roof |
