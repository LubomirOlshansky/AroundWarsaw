# Wola's "19. Dzielnica": the Kolejowa estate, Asbud's towers and the drug works' building site (sites `noho`, `d19`, `asbud`)

F's ask (2026-11-07): "make the dzielnica 19 like real, and the construction work where Polfa was
and NOHO ONE in construction", with eleven photos.

## Sources

- F's eleven photos (2026-11-07, kept in the project files, never in the repo): three drone views of
  the estate (cream blocks with brown window frames; a plaza with dark grey frames and a grass mound),
  the courtyard with the glass footbridge, five photos of the Towarowa Towers (dark blue glass, gold
  and orange frames, white spine, orange base, the ASBUD mark on the crown), a satellite crop of
  Kolejowa, Przyokopowa and Kasprzaka, Street View of the estate's last stage as concrete frames, the
  drug works' plot as a site (a long concrete frame, a green tower crane, pallets of white, blue and
  pink insulation, cabins, cars, sand) and NOHO ONE's hoarding on a frame.
- whitemad.pl, architekturaibiznes.pl, eurobuildcee.com: NOHO ONE (BBGK Architekci) is on the former
  Polfa pharmaceutical works, about 5 ha by Prosta/Kasprzaka; precast concrete and stone, round
  columns, cornices; the "cascades" are terraces stepping down from penthouses; the first phase has
  its permit; Atlas Ward builds it.
- otodom/tabelaofert listings: "19. Dzielnica" is the estate on Kolejowa and Przyokopowa.
- OpenStreetMap: the plot is `landuse=construction`; the estate is 58 mapped parts (podiums 4.3 m,
  blocks 14-34 m, set-back top floors); the Towarowa Towers are two 96.7 m `apartments` outlines.

Brand rule: the site's name is the parody OHO ONE, the contractor's ATLAS WIATR, the developer's
ASBUDKA. The estate's name is a place name (like Osiedle Za Żelazną Bramą). The card does not name
the drug company: "medicines were made here".

## 1. `noho`: the building site

Frame D19_O/A/B: u along Kasprzaka (east), v into the plot (south). Zone: the OpenStreetMap
`construction` outline (NOHO_PLOT) and the strip south of it to the diagonal street's kerb
(NOHO_STRIP, the estate's last stage).

| Piece | Where (u, v) | What |
| --- | --- | --- |
| Long frame | 150-182, 22-118 | 9 storeys of 3.2 m, the lowest 4 glazed in dark glass, the top 3 stepping back 3.5 m a storey on the west (the cascade's terraces); columns every 8 m round the edge; 1 m safety screens with a yellow rail on the open floors |
| Kasprzaka frame | 70-138, 9-27 | 5 storeys, 2 glazed; two cores (6.4 m square) rising to 8 storeys ahead of it |
| Last stage | 70-120, 161-187 and 136-180, 149-172 | 8 storeys, 3 glazed, slabs running 1.4 m out as balconies on the long sides (Street View) |
| Foundation slab | 8-40, 116-156 | a raft, 30 starter columns with their bars |
| Cranes | (143, 72) green, (104, 38) red, (127, 167) white with a red jib | 46, 42 and 38 m masts, jibs 46, 40 and 36 m, red lamp on top |
| Yard | 55-145, 34-122 | pallet blocks (white EPS, blue XPS, pink, orange, grey), two storeys of cabins with a red band and ATLAS WIATR, a blue container, a silo, a skip, 3 sand heaps, a digger, 32 workers' cars |
| Hoarding | round both zones | 2.4 m navy boards with OHO ONE along Kasprzaka and the east street, galvanised panels elsewhere, three gates |

The car collides with the hoarding (both rings) and each frame. Trees from the laser scan on the
plot are dropped (tree_free).

## 2. `d19`: the estate

Zone D19_ESTATE (from the street north of the estate to Kolejowa, Przyokopowa to the green by the
roundabout); every mapped part inside is rebuilt from its outline (simplified 5 cm, as the parts
share fronts):

- podiums (5 m or less): dark shop glass, a pale fascia, a garden roof when bigger than 600 m²;
- `roof` parts: canopies (a 0.4 m slab at their height);
- blocks: a dark shop band 40 cm in on the ground floor, then look 0, cream (#e7dfcf) in S_PUNCHED
  with rust frames (#94573a, 4 cm proud, the pane 8 cm proud) round about a fifth of the windows,
  scattered; look 1 (the two blocks east of x -2880, south of z 735: the plaza photo) bronze glass
  (S_GOLD) behind a charcoal grid, a floor band every 3 m and a pier every 6 m, white short ends;
- a flat light roof, a plant room on roofs over 500 m².

Fronts shared by two parts (back to back, or one part a few cm proud of another) are dressed once
or not at all (`_d19_party`, `_d19_decorated`, `_d19_clash`), so nothing flickers.

## 3. `asbud`: the Towarowa Towers and their white blocks

Zone ASBUD_ZONE. The towers (parts over 60 m), simplified 1.5 m: dark glass on the ground floor,
an orange band (5.4-7.6 m), dark blue glass (S_DARK, #2f4d6c) to the roof; a white stone spine 4.4 m
wide a fifth of the way along the longest front; frames every 4.2 m in three-storey pieces (every
other one shifted a storey and a half), orange up to 40 % of the height, gold above, 0.3 m proud;
the frames run 4.5 m past the roof as an open crown; ASBUDKA in green neon on the crown. The white
blocks: S_PUNCHED white with orange balcony panels up one window column in six.

## Defaults until F's photos say otherwise

The list is /mnt/project-files/dzielnica19/PHOTOS-NEEDED.txt. Defaults built: storey counts of the
frames, where the long frame stands (the yard photo puts it on the east of the plot), which estate
blocks wear the dark grid (the two on the east green), the crane count and colours.
