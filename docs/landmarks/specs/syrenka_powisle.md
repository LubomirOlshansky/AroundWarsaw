# Syrenka na Powiślu: spec

Site `syrenka_powisle` in `game/scripts/landmarks.gd` (`_build_syrenka_powisle`,
`_syrenka_powisle_figure`). Written 2026-11-01 in a cloud thread (the Powiśle boulevards).
No free photo is reachable from the cloud: the place comes from the baked `syrenka` point
(BACKLOG: "No Syrenka statue is mapped"), the figure from knowledge of the monument; every
value marked *(photo check)* waits for the Mac's `refs/`.

## 1. Identity

The riverside Syrenka (Ludwika Nitschowa, 1939, bronze) on the Powiśle boulevard at the foot of
Tamka and Karowa: a mermaid with a raised sword and a round shield, on a low stone plinth by the
embankment wall, facing the Vistula. The statue is the old egg's body: `eggs.gd` keeps only the
trigger and the night floodlight at its spot, the figure and plinth are this site's.

## 2. Massing

Frame: the site's own plan, origin (600, -697), `u` forward (towards the water, yaw -0.861 as
baked), `v` across. Footing slab 2.5 x 2.1 m, 0.52 m high (0.3 m sunk); block 1.7 x 1.4 m to
1.15 m; cap slab 2.0 x 1.7 m to 1.38 m *(photo check: plinth shape and height)*. The figure
stands on the cap, 1.6 times life size: tail coiled to 1.3 m, torso to 1.8 m, head to 2.25 m,
sword tip 3.75 m over the cap (5.1 m over the ground).

## 3. Facade, base to top

Plinth: three stepped blocks in warm grey stone, lighter cap faces. Figure: the tail a four-beam
coil with two flukes thrown up behind, torso and neck, a head with long hair down the back,
right arm bent up past the head with the sword (guard and a pale blade leaning back), left arm
bent up with the round shield (rim, face, boss) at the shoulder, turned out to the water. Not
the Old Town pose: there the shield is held low and forward *(photo check: which hand, how high)*.

## 4. Roof

None; built with `_no_roof` set, so the roof grid (helicopter, rain) does not see it.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plinth footing, block, cap | #aaa392, #b9b2a2, #d3ccbb | M_STONE |
| Bronze (body, shade, deep, highlight) | the Old Town set: #7ba892, #5a8873, #3f6656, #a8d0bb | M_STONE |

No new material or draw call: the bronze is a lit patina green, as the Old Town one.

## 6. Ground and night

Card "Syrenka na Powiślu" (PL and EN). The car meets a 2.5 x 2.1 m collision ring round the
plinth. The egg's cool floodlight (eggs.gd) lights her at night. The flood wall beside her is the
map's, not touched; on the real terrain the plinth may touch it *(photo check: spot)*.

## 7. Detail level and budget

L2. Measured 2026-11-01: 214 triangles, budget 260 (`check_mesh_quality.gd`). Shot: `--at=598,-699
--size=9 --pitch=-35 --yaw=0 --nohud --no-ghost --no-traffic`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| footing | box | 2.5 x 2.1 m, 0.52 m | origin | M_STONE | 2 plinth |
| block | box | 1.7 x 1.4 m, to 1.15 m | origin | M_STONE | 2 plinth |
| cap | box | 2.0 x 1.7 m, to 1.38 m | origin | M_STONE | 2 plinth |
| tail | 4 beams, 2 flukes | 0.5..0.36 m thick, to 1.3 m | on the cap | M_STONE | 3 figure |
| torso and head | 2 frustums, 3 prisms | 0.5 x 0.6 m, to 2.25 m | on the tail | M_STONE | 3 figure |
| sword arm | 2 beams, guard, blade | blade 1.15 m, to 3.75 m | v -0.5 | M_STONE | 3 figure |
| shield arm | 2 beams, 3 discs | shield r 0.5 m, at 2.15 m | v +0.5, forward | M_STONE | 3 figure |
