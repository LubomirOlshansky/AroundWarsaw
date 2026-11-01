# Zamek Królewski: spec

Site key `zamek` in `game/scripts/landmarks.gd` (`SKINS` row, `_build_zamek`). Written 2026-11-01
in a cloud thread from the OpenStreetMap outline and GUGiK's LoD2, checked against the earlier
pass-3 render (`landmark-models/pass3_zamek.png`). No photo here: colours are from memory of the
castle and stay a step paler than life. Values marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

The rebuilt Royal Castle (destroyed 1944, rebuilt 1971-1984) on Plac Zamkowy.

1. **A pentagon of ranges round one courtyard**, steep roofs, the Clock Tower (Wieża Zegarowa) on the
   square front, the Senate Tower and the big hipped roofs on the Vistula side.
2. **Salmon-pink plastered walls** with pale stone dressings.
3. **A pale stone plinth** under the walls, where the castle stands on its escarpment.

## 2. Massing

Unchanged: the kept LoD2 mass (tallest cell 45 m at (-672, -1520), the Clock Tower).

## 3. What this pass changed

- **Wall** #c87560 → #cf9580. The old colour read brick-red under the day sun, louder than the
  plaster in any photo of the castle.
- **Roof** #6e5a4e → #8d6350. The old one went near-black on shaded slopes (the west and north
  ranges); the new reddish-brown tile keeps its shape in shade.
- **Plinth** (`_build_zamek`): the mapped outline's 127 vertices, each edge cut into pieces of at most
  6 m, a stone wall 0.7 m proud of the outline (LoD2's walls stand up to ~0.6 m inside it), from 1 m
  under the terrain to 2.2 m over it, so it steps with the slope. 312 triangles.

## 4. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls (skin) | #cf9580 | M_MONUMENT |
| Roofs (skin) | #8d6350 | M_STONE |
| Plinth | #e2d8c4 | M_STONE |

## 5. Ground and night

Collision unchanged (LoD2's). Card (kept): "Zamek Królewski", PL "Zniszczony w 1944 roku, odbudowany
w latach 1971–1984."

## 6. Detail level and budget

L2, triangle budget 340 (312 measured, `check_mesh_quality.gd`). Shots: city, from Plac Zamkowy
(`--at=-640,-1480 --heading=0 --size=160 --no-ghost`).

## 7. Open *(photo check)*

- Whether the Clock Tower's roof is copper-green or tile.
- White stone quoins and window surrounds, a cornice band: not built (needs the eave height per
  range, which LoD2 does not give cleanly).
