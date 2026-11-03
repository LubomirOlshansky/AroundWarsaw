# Towarowa 22: the Wola superblock, built as finished (site `towarowa22`)

F's ask (2026-11-03): "not a construction site, already built", from research into how the
planned buildings will look, with a playful "Warsaw of the future" angle.

## Sources

- F's attachments (2026-11-03, kept in the project files, `towarowa22/refs/`, never in the repo:
  they are the developers' renders and press photos): the labelled masterplan aerial (Towarowa,
  Srebrna, Nowa Zielona, Miedziana, Pańska, Wronia, Prosta, Nowa Wronia), the earlier aerial, the
  "warszawski superkwartał" plan (Park Słowa, Konstrukcja hali DSP, Pawilon DSP, Office House,
  Apartamenty Gutenberga, M7, Muzeum Woli), the hall-garden render (yellow steel truss over trees,
  conical glass skylights), the model aerial, and photos of the finished Office House with its
  round-holed pergola.
- towarowa22.pl: JEMS Architekci; partners AFI, Echo Investment, Archicom; Apartamenty Gutenberga,
  M7 (Miedziana 7, September 2026), Motion Tower, AFI Tower, AFI Duo, Office House; Ogrody
  Towarowa, 1.1 ha of gardens round the Dom Słowa Polskiego pavilion; Nowa Wronia a walking street.
- inwestycje.pl: a 150 m office tower with an 85 m part, 40 storeys, at Towarowa and Pańska.
- warsawinsider.pl: 6.5 ha, eight blocks, the towers step down to the south-east, the park at the
  centre, four high-rises over about ten years.

Brand rule: no developer's or tower's brand appears on screen. The signs say the address
(TOWAROWA 22) and the jokes.

## 1. Identity

The Wola superblock between Towarowa, Pańska, Miedziana and Srebrna, on the old Dom Słowa Polskiego
printing works: a row of towers stepping down to the south-east along Towarowa, a park at the
centre, and the printing hall's steel frame kept as a garden. Its readable mark from the street and
the air is the yellow truss over trees, and in the game the drone port on the 150 m tower.

## 2. Massing

`landmarks.gd` frame: origin T22_O (-2635.5, 470) on Towarowa's east carriageway, u along it
(south-south-east, T22_A), v across (east-north-east, T22_B). The map's own outlines in that frame:
the Office House u 22-99 v 111-182 (34 m, kept), its pergola u 72-102 v 162-208 (kept), Dom Słowa
Polskiego u 108-201 v 141-220 (replaced), M7 u 211-281 v 188-267 (kept), the octagon's pieces
u 41-122 v 220-300 (kept), Muzeum Woli u 296-331 v 155-176. The car park at the Srebrna end
(u 257-320, v 10-75, 31 parked cars and its service road) stays: the render's block there is left
for when the map has it. Heights: 150 / 124 / 112 / 96 m towers along Towarowa, an 85 m podium,
34-36 m low blocks, the Gutenberga podium at 20 m with 58 and 50 m towers, the hall frame 15 m.

## 3. Facade

Each block takes one landmark skin: the office tower and podium pale glass in a white grid
(S_GRID); the white and terracotta towers punched windows (S_PUNCHED); the dark tower glass with
fins (S_FINS); the teal office glass bands (S_BANDS); the tanks block and Gutenberga white loggia
slabs (S_SLAB / S_PUNCHED). The pavilion is one glazed storey.

## 4. Roof

Green roofs on most blocks (garden planters on top); the terracotta tower's crown is a wavy
scalloped parapet round a roof garden; four round glass tanks on the 28 m block; the pavilion's
green roof has four conical skylights; the 150 m tower carries the drone pad.

## 5. Colour and material

Office glass #9db3c3 / podium #a9bccb, white tower #ece8e0, terracotta #c97a70, dark tower
#3c444c, teal #5e9196 and #a7c2c2, tanks block #f0eee8, Gutenberga #e8e2d6 / #efeae0, roof green
#6f9a4a, hall steel yellow #e9c21c, Nowa Wronia paving #b9806a, the crane gold #d9ae3c, the signs
in mint neon.

## 6. Ground and night

The ground follows the terrain in 10 m cells: paving round the towers, brick-red Nowa Wronia, the
lawn and trees under the hall frame, Park Słowa's lawn, oval path, playground and pool. Laser-scan
trees are kept off the new blocks (`tree_free` plans). At night the skins light their windows and
the three neon signs (WARSZAWA 2050, DRONOPORT, TOWAROWA 22) and the plinth's OSTATNI ŻURAW WOLI glow.

## 7. Detail level and budget

L3, budget 4800 triangles (the build is 4597), the site's entry in `check_mesh_quality.gd`. The
drone's 8 floating faces are KNOWN there, since it hovers by design.

## 8. Parts table

| id | shape | size | position (u, v) | material | feature |
| --- | --- | --- | --- | --- | --- |
| afi | prism | 38 x 34 m, 150 m | 18-56, 16-50 | S_GRID pale glass | the tallest, drone port on top |
| podium | prism | 44 x 40 m, 85 m | 18-62, 52-92 | S_GRID, green roof | TOWAROWA 22 on the Pańska face |
| white | prism + 2 set-back boxes | 30 x 34 m, 124 m | 70-100, 20-54 | S_PUNCHED white | terraced top |
| pink | prism + wavy crown | 28 x 34 m, 112 m | 112-140, 20-54 | S_PUNCHED terracotta | scalloped crown garden |
| pink_low | prism | 38 x 32 m, 34 m | 108-146, 60-92 | S_SLAB, green roof | loggia bands |
| dark | prism | 28 x 34 m, 96 m | 156-184, 20-54 | S_FINS dark glass | fins |
| duo | 2 prisms | 54 x 76 m, 36 / 26 m | 196-250, 16-92 | S_BANDS teal | green roofs |
| tanks | prism + 4 cylinders | 66 x 28 m, 28 m | 106-172, 108-136 | S_SLAB white | round glass roof tanks |
| gutenberga | podium + 2 towers | 77 x 70 m, 20 + 58 / 50 m | 205-282, 108-178 | S_SLAB / S_PUNCHED | green roofs |
| hall | columns, chords, trusses | 80 x 54 m, 15 m | 118-198, 146-200 | yellow steel | the old printing hall as a garden |
| pavilion | prism + 4 frusta | 92 x 14 m, 6 m | 108-200, 204-218 | glass, green roof | round skylights |
| park | ground cells, path, pool | 83 x 52 m | 125-208, 224-276 | lawn, paving, water | Park Słowa |
| crane | mast, jib bars, plinth | 32 m tall, 22 m jib | park, u 198 v 233 | gold, stone | OSTATNI ŻURAW WOLI |
| drone | box + 4 discs | 4 m | 7 m over the pad | white, red light | the drone taxi |
| wronia | ground cells | 185 x 11 m | 97-282, 95-106 | brick paving | the walking street |

## The "Warsaw of the future" jokes

- **Dronoport**: a pad with an amber ring and a painted D on the 150 m tower, a white drone taxi
  hovering 7 m over it with four rotor discs and a red light; WARSZAWA 2050 on the crown's
  Towarowa face and DRONOPORT on its Pańska face.
- **Ostatni żuraw Woli**: Wola is the city's crane forest, so the park keeps the last one as a
  monument: a gilded tower crane on a stone plinth, its jib over the lawn and its hook hanging,
  with OSTATNI ŻURAW WOLI on the plinth.
- The info card: finished in the game, still being built in the real Warsaw.

## Open

- A Mac photo pass once the towers stand (the renders may change); the hall frame's real truss
  rhythm; the Srebrna-end block over the car park (needs the map's parked cars moved).
- Pocket rings: not needed. Every new block stands at least 8 m from the kept buildings (no party
  wall, no slit for the car), so plain `_collide` rings are enough.
