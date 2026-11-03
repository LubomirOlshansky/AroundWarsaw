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

## Frame and massing

`landmarks.gd` frame: origin T22_O (-2635.5, 470) on Towarowa's east carriageway, u along it
(south-south-east, T22_A), v across (east-north-east, T22_B). The map's own outlines in that frame:
the Office House u 22-99 v 111-182 (34 m, kept), its pergola u 72-102 v 162-208 (kept), Dom Słowa
Polskiego u 108-201 v 141-220 (replaced), M7 u 211-281 v 188-267 (kept), the octagon's pieces
u 41-122 v 220-300 (kept), Muzeum Woli u 296-331 v 155-176. The car park at the Srebrna end
(u 257-320, v 10-75, 31 parked cars and its service road) stays: the render's block there is left
for when the map has it.

| Block | u | v | Height | Look |
| --- | --- | --- | --- | --- |
| Office tower at Pańska | 18-56 | 16-50 | 150 m | pale glass, white grid; drone port on top |
| Its podium | 18-62 | 52-92 | 85 m | the same skin, planted roof terrace; TOWAROWA 22 on the Pańska face |
| White terraced tower | 70-100 | 20-54 | 124 m + two set-back boxes | white cladding, punched windows |
| Terracotta tower | 112-140 | 20-54 | 112 m | terracotta cladding, a wavy scalloped crown round a roof garden |
| Low block behind it | 108-146 | 60-92 | 34 m | pale loggia bands, green roof |
| Dark tower | 156-184 | 20-54 | 96 m | dark glass with fins, green roof |
| Teal office and its wing | 196-250 | 16-92 | 36 / 26 m | teal glass bands, green roofs |
| Block with four tanks | 106-172 | 108-136 | 28 m | white loggia bands, four round glass tanks on the roof |
| Apartamenty Gutenberga | 205-282 | 108-178 | 20 m podium + 58 / 50 m towers | pale plaster, green roofs |
| Printing hall frame | 118-198 | 146-200 | 15 m | yellow steel columns, chords and trusses over a lawn with trees |
| Pawilon DSP | 108-200 | 204-218 | 6 m | glazed storey, green roof, four round skylights |
| Park Słowa | 125-208 | 224-276 | ground | lawn, an oval path, a playground and a pool, trees |
| Nowa Wronia | 97-282 | 95-106 | ground | brick-red paving, and a link to the pavilion |

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
