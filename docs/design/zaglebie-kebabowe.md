# Zagłębie Kebabowe: the kebab basin by Kino Femina

F's ask (2026-11-02): "Zagłębie Kebabowe" with a craft kebab near Kino Femina should be designed,
with quests to kebab delivery from it. The cluster is on Al. Solidarności, the south pavement
between Jana Pawła II and Femina; the delivery quests hook into the existing kebab order system
(`jobs.gd`). Every shop name is our parody; Kino Femina is a real place and keeps its name.

## 1. What is real

| Thing | Fact | Source |
| --- | --- | --- |
| Kino Femina | a cinema at Al. Solidarności 115, 00-120 Warszawa, pin 52.24205 N, 20.99459 E | aroundus.com place page; the cinema's own address |
| The building | already in the map as a building footprint (24 m, OSM); there is no named landmark, so no skin | `map/centrum.json` |
| The kebab shops there | the street is lined with kebab and bistro shops; their real names are not used | F |

The Mac photo check is parked (QUESTIONS): the real colour and shape of Femina's front, and whether
a marquee over the door should join the sign.

## 2. The parody names

| Ours (on screen) | Idea | Order twist (`zaglebie.gd`) |
| --- | --- | --- |
| **KEBAB KRÓL MAZOWSZA** | the king of the region, gold tube | Zestaw Królewski: only trips of 700 m or more, pays ×1.25 |
| **STAMBUŁ 24** | open all night, cyan tube | Nocna Porcja: ×1.25 more after dark (on top of the night ×1.5) |
| **DONER PASZA** | the king's rival, crimson | Szybki Pasza: the kebab cools 20 % faster (a shorter fair time), plain pay |
| **U WUJKA ERDALA** | the family one, green | Rodzinny: a hot kebab's tip doubles |
| **ZAKWAS I ROŻEN · CRAFT KEBAB** | the craft kebab: sourdough marinade, hand-carved, a queue and a hashtag | the card's two buttons are a choice: POCZEKAM (6 s: ×1.6 pay, cools 1.5× slower) or ZWYKŁY |

The signs ride `Storefronts.VENUES` (neon fascia on the wall the ray finds); Femina gets KINO /
FEMINA in red above them. The five stands wear name boards under KEBAB and the vendors' `zag_*`
line tags. Five stands within 76 m of Femina, at least 23 m apart, all on the real lane graph.

## 3. The quests

- **Delivery orders.** Pulling into any of the five stands starts an ordinary kebab order (same
  card, heat, beacon, courier race, night bonus, stop assist) with that shop's twist above.
- **Szlak Szpili (the Skewer Trail).** One delivery from each of the five shops pays +120 zł and
  +25 respect once (saved in `wallet.keep["zaglebie_trail"]`). A toast says so.
- **The welcome.** The first time the car comes within 80 m of Femina, a lore line (group
  `zaglebie`, 6 lines) shows once per save.
- **Lore.** Pasha and the King have not spoken since the garlic dispute; Uncle Erdal mediates over
  tea; nobody has eaten at all five in a day; Femina empties hungry; the craft kebab's sourdough.

## 4. Decisions

- Dialogue Manager: **not used**, because the only choice is the craft shop's two-button job card
  (the same shape as every job's GO / NOT NOW) and everything else is single vendor lines from the
  `line()` bags (dialogue-scenes skill, section 1). Beehave: not used (no NPC behaviour added).
- The stands are added at runtime by `jobs.gd` from `Zaglebie.extra_pois`, not baked: the map data
  and its counts do not change.
- Performance: five more kebab stands (one named mesh each, like U ZDZICHA), six neon signs in the
  sector's existing Neon MultiMesh (+0 draw calls); nothing per frame but one distance check while
  idle.

## 5. Left (BACKLOG)

Femina's front (marquee, colours) and the shops' real sizes after the Mac photo check; a queue
outside the craft shop (crowds.gd); a radio line for KEBAB FM.
