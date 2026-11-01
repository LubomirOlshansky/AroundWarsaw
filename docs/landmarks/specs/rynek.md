# Rynek Starego Miasta and the Syrenka: spec

Sites `rynek` and `syrenka` in `game/scripts/landmarks.gd` (`_build_rynek`, `_umbrella`,
`_build_syrenka`, `_syrenka_figure`). Written 2026-11-01 in a cloud thread (F: "improve the Old
Town Market Square and the Mermaid"). No free photo is reachable from the cloud, so the square's
plan comes from the OpenStreetMap outlines in `centrum.json` and the figure from knowledge of
the monument; every value marked *(photo check)* waits for the Mac's `refs/`. The houses round
the square are not touched here (the historic tenement dress and stepped gables are
`map_builder._tenement_facades` and `OldTownRoofs`).

## 1. Identity

The Old Town Market Square (Rynek Starego Miasta): a closed cobbled square about 90 x 73 m,
rebuilt from rubble after the war, ringed by tall pastel tenements, with café gardens under
umbrellas on all four sides and, in its middle, the Syrenka: Warsaw's mermaid with a raised sword
and a round shield, bronze, on a stone pedestal in a round fountain.

## 2. Massing

Frame: world metres. The open square is the area more than 7 m from every mapped building
(flood fill from the fountain); its four corners are the edge lines' intersections: (-854.2,
-1756.1), (-811.2, -1796.6), (-758.2, -1735.9), (-799.7, -1695.4). The long axis runs about
41 degrees east of south. Paving: that quad grown 0.5 m (it stops 6.5 m off the facades, inside
the mapped footways' strip), a slab 0.3 m under the lowest ground to 3 cm over the highest.
Fountain: the mapped pond at (-806.5, -1745.5), r 3.5 m; the rim wall r 3.9..4.5 m, 0.5 m high.
Pedestal: footing r 1.9 m to 0.35 m, step r 1.45 m to 0.6 m, an octagonal shaft r 1.05 m to
2.4 m, a cap r 1.3 m to 2.6 m, the rock r 0.95 m tapering to 0.5 m at 2.95 m. The figure stands
on the rock: the tail coiled to 1.25 m, the torso to 1.8 m, the head to 2.2 m, the sword to
3.5 m (the statue's top 6.4 m over the ground: taller than life so it reads from the camera).

## 3. Facade, base to top

Not a facade: the square's furniture. Paving: a 1.3 m darker border band round the edge, a
lighter field, then a pale disc r 11 m (with a darker ring at r 11.5 m) round the fountain, each
a few millimetres over the last. Café gardens: along the 7 m line on all four sides, one set
every 4.6 m wherever a facade is within 5-10 m (58 sets; none in the street mouths): a table on
a pole, two chairs, a square umbrella 3.4 m across, its canopy one of nine colours, one colour to
each run of five (one restaurant). Fountain: the stone rim wall (inner and outer faces, an
annulus top), the pedestal as above. Syrenka: right arm up with the sword, left arm forward with
a three-layer disc shield (rim, face, boss), long hair down the back.

## 4. Roof

None. The umbrellas' canopies are low pyramids (rise 0.65 m) at 2.25..2.9 m; the only high
point is the sword at 6.4 m. Everything is built with `_no_roof` set: the roof grid (helicopter
landing, rescue, rain) does not see the paving, the umbrellas or the statue.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Paving field / border / disc | #d8d1bf / #bbb3a1 / #e8e2d1 | M_STONE |
| Rim, pedestal | #ddd5c1, #cfc8b5, #e0dac8 | M_STONE |
| Bronze (body, shade, deep, highlight) | #7ba892, #5a8873, #3f6656, #a8d0bb | M_STONE |
| Table, chairs, pole | #ece6d8, #5a3b26, #5a5649 | M_STONE |
| Umbrellas | #c8282a, #f2efe8, #2f6b4f, #d9a441, #24324a, #e07a5f, #3b7ea1, #efe3c0, #8c3a4a | M_STONE |

No new material or draw call: everything joins the city's one building surface. The bronze is
a lit patina green (a darker bronze read as black in the cloud's shots) *(photo check)*.

## 6. Ground and night

Cards: "Rynek Starego Miasta" (the square, taps on the paving) and "Syrenka" (her own, on the
fountain), PL and EN. The car meets the rim wall (a 16-sided collision ring, r 4.5 m) instead of
driving into the mapped pond; the umbrellas and chairs are drive-through like the map's benches.
No lights of their own at night (the mapped lamps stay).

## 7. Detail level and budget

L3 for the Syrenka, L2 for the square. Measured 2026-11-01: `rynek` 2562 triangles, budget
3100 (the paving, 58 sets of 44 triangles); `syrenka` 394 triangles, budget 480
(`check_mesh_quality.gd`). Shots: `--at=-799,-1738 --yaw=200 --pitch=-40 --size=60 --nohud
--no-ghost --time=day` (the square), `--at=-800,-1739 --pitch=-25 --size=18` (the statue).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| paving | slab, 3 caps | quad 90 x 73 m, 3 cm over the ground | the square | M_STONE | 3 paving |
| disc | disc with a hole | r 11 m | fountain | M_STONE | 3 paving |
| umbrellas | 58 sets | 3.4 m canopy, 2.9 m high | the 7 m line | M_STONE | 3 café gardens |
| rim wall | annulus wall | r 3.9..4.5 m, 0.5 m high | fountain | M_STONE | 3 fountain |
| footing and step | 2 octagons | r 1.9 and 1.45 m, to 0.6 m | fountain centre | M_STONE | 3 pedestal |
| shaft and cap | octagon prisms | r 1.05 m to 2.4 m, r 1.3 m to 2.6 m | fountain centre | M_STONE | 3 pedestal |
| rock | octagon frustum | r 0.95 to 0.5 m, 0.35 m | 2.6..2.95 m | M_STONE | 3 pedestal |
| tail | 4 beams, 2 flukes | 0.46..0.36 m thick, to 1.25 m | on the rock | M_STONE | 3 Syrenka |
| torso and head | 2 frustums, 3 prisms | 0.5 x 0.6 m, to 2.2 m | on the tail | M_STONE | 3 Syrenka |
| sword arm | 2 beams, guard, blade | blade 1.05 m, to 3.5 m | right side | M_STONE | 3 Syrenka |
| shield arm | 2 beams, 3 discs | shield r 0.52 m | left side, forward | M_STONE | 3 Syrenka |
