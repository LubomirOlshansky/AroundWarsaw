# Kaskada: spec

Site `kaskada` in `game/scripts/landmarks.gd` (`_build_kaskada`). Written 2026-11-01 in a cloud
thread (the Powiśle boulevards). OpenStreetMap maps "Kaskada" here (centre about 755, -521) as a
`boat` 46 x 10 m with rounded ends, moored along the boulevard; it is built as a river
vessel with a lounge. Everything beyond the outline is a guess *(photo check)*, including what
the Kaskada actually is (a floating restaurant? a club?).

## 1. Identity

A vessel moored along the Powiśle boulevard: a glazed lounge on a white hull with a sun deck
under a red awning. Replaces the mapped box.

## 2. Massing

Frame: the outline's long axis; `u` along it. Hull: the outline from 1.6 m under to 1.5 m over
the ground; lounge: the outline inset 3.1 m, 1.5 to 4.4 m; roof deck 0.5 m wider, to 4.7 m; the
awning 6.9 to 7.05 m over the stern half, a mast to 9 m at the bow end *(photo check: decks, size)*.

## 3. Facade, base to top

Hull: dark navy skirt under a white top strake. Deck: timber ring round the lounge. Lounge: glass
all round (M_PAVILION, lit at night). Roof deck: grey, a red awning on 6 timber posts.

## 4. Roof

The sun deck and awning; flat, no equipment modelled.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Hull skirt, strake | #2c3d4f, #e5e6e2 | M_STONE |
| Deck | #8e6b47 | M_STONE |
| Lounge glass | #9dc0cc | M_PAVILION |
| Roof deck, awning | #6a716f, #f0ede4 over #c8282a | M_STONE |

No new material or draw call.

## 6. Ground and night

Collision on the outline. Card "Kaskada". The lounge glows at night through M_PAVILION.

## 7. Detail level and budget

L2. Measured 2026-11-01: 216 triangles, budget 260 (`check_mesh_quality.gd`). Shot: `--at=755,-521
--size=40 --nohud --no-ghost --no-traffic`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| hull | 2 prisms on the outline | 46 x 10 m, 3.1 m | outline | M_STONE | 2 massing |
| lounge | prism, inset 3.1 m | to 4.4 m | amidships | M_PAVILION | 3 glass |
| roof deck | prism with cap | 0.3 m | 4.4..4.7 m | M_STONE | 4 roof |
| awning | box on 6 posts | 12.8 x 5 m | stern half | M_STONE | 4 roof |
| mast | box | 0.2 m, 4.3 m | bow end | M_STONE | 3 mast |
