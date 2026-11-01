# The start area as real Warsaw (2025/26)

F's ask (2026-11-01): in the start area, improve every landmark that can be improved, add
details to the streets, make the shop signs (Ściana Wschodnia above all) like the real ones,
rework the ordinary buildings to look like the real ones, match the road and pavement
materials to the photos, and research the 2025/26 trends (Wykop and elsewhere) for trendy
places and jokes. This file is the research and the plan; the items are in docs/ROADMAP.md
("v1.0 checklist", the start of the game) and docs/BACKLOG.md ("The start area as real
Warsaw"). It extends docs/design/first-scene.md (items 4-7 there are folded in here).

**The box**: as first-scene.md, Plac Defilad's east half and Marszałkowska from Świętokrzyska
to Aleje Jerozolimskie (about 600 × 350 m), plus Złota and the Rondo Dmowskiego corners.

**Owners elsewhere** (don't touch): the street furniture along the main line's route outside
the box (another thread, docs/design/street-details.md), the trend spots and their jokes
(docs/design/trends-2025-26.md), the Cathedral and the Barbican (landmarks lane), the opening flyover
and the guided start (PR #155).

## 1. What the real place looks like now (research, 2026-11-01)

Sources: trade press and city news found by web search (links at the end). The cloud can't
read Wikimedia Commons, GUGiK or Wykop itself (403/login), so photos stay a Mac step
(model-from-photos skill) and the trends come from Google's 2025 year in search, the trade
press and the Warsaw city guides instead of Wykop's own pages.

### The Eastern Wall (Ściana Wschodnia)
- **Wars Sawa Junior is half empty.** H&M closed its Marszałkowska store, Poland's oldest, on
  3 October 2025 after 21 years; Zara and C&A left before it; Calzedonia left too. Shoe chains
  (CCC, eobuwie, Worldbox) took Zara's floor. In July 2026 the owner split the H&M corner and
  **a two-storey Żabka** is going in on the corner facing Pasaż Wiecha and Widok (Wars's south end in the game), the rest split into small units; Boardriders replaced C&A. So the real
  street faces today are a patchwork: shoe-chain fascias, a convenience-shop corner, and big
  "do wynajęcia" (to let) boards on the empty glass.
- **Pasaż Wiecha** (the old Pasaż Śródmiejski) runs behind the stores: low pavilions, canopies,
  the tall winged lamps of the 2006 rebuild, and the **Zodiak** pavilion (the Warsaw
  Architecture Pavilion and its café, reopened 2019).
- **Kino Relax** (Złota 8, behind Junior), Poland's first 70 mm cinema (1970), closed in 2006,
  was heritage-listed and refurbished in 2019 and is now **Scena Relax** (theatre, concerts,
  stand-up).
- **The Cepelia pavilion** (Marszałkowska × Aleje Jerozolimskie, 1966, Stępiński): the glass
  and steel pavilion restored and reopened on 13 December 2024 as a three-level book and music
  flagship store with a vinyl floor.
- The Forum hotel (now silver-clad, the NOWOTEL parody exists) and the Rotunda (rebuilt, the
  re-pass exists) close the wall at the south end.

### The ground
- **Plac Centralny** (the new square on Plac Defilad's Marszałkowska side, from the museum
  outwards; built 2024-25): six kinds of stone. The outlines of the pre-war tenements are
  drawn on the ground in large grey and red slabs, their old courtyards in reused granite
  setts from Plac Defilad, and the 1939 street lines in strips of granite setts. Lawns, more
  than 40 kinds of bulbs and perennials, 109 trees (locust, ash, ginkgo, magnolia...) and a
  shallow pond.
- **Marszałkowska** (2023-26): on the Plac Defilad side a cycle path, renewed pavement and
  marked parking; the old concrete entrance to the 1970 tunnel under Marszałkowska became a
  fountain (the tunnel is now a rain-water tank); three new at-grade crossings: Rondo
  Dmowskiego, one in line with Złota to Plac Centralny, one at Sienkiewicza/Fangora.
- **Złota** (2026): a green street, setts instead of concrete and asphalt, kerbs laid to the
  pre-war line, a mineral-surfaced middle alley with 81 elms, shrubs, benches; cars only for
  access and deliveries.
- Usual Warsaw materials to check on the orthophoto and photos: grey concrete pavement slabs
  and setts, granite kerbs, **red asphalt cycle paths**, the tram track in the middle of
  Marszałkowska.

### Trends 2025/26 (for places and jokes)
- **Labubu** (the toothy plush in blind boxes) was Poland's second rising Google search of
  2025: queues at the shops, "how much is it". Parody only: an original toothy plush, a
  blind-box shop with a queue.
- **Dubai chocolate** (pistachio and kataifi) was 2025's food search; pistachio everything.
- **Matcha**: Pyszne.pl matcha orders up 134 % in 2025 (Warsaw first by volume); hojicha and
  ube named next. Pastel matcha bars with queues of students.
- Bubble tea's long boom; smash burgers; "Italian brainrot" (the absurd AI creatures) and
  "6-7" with the kids; the Pope's conclave; the Chopin competition.
- Warsaw itself: the **empty department stores** and the Żabka that replaced H&M (above);
  Żabka on every corner (the game's Frogs); e-scooters everywhere (the game's Leżak); food
  couriers; the new green Złota and the tram/fountain works; Warsaw's clean transport zone
  (Strefa Czystego Transportu, from July 2024: old cars may not enter the centre).
- Never about real private people, no real brand names or logos (parodies), no politics of
  real politicians (the warsaw-tone skill).

## 2. The plan (one PR per item, in this order)

| # | Item | What | Lane / model |
| --- | --- | --- | --- |
| R1 | **The Eastern Wall's signs as they are now** | Polish letters in the pixel font (Ą Ć Ę Ł Ń Ó Ś Ź Ż); the stores' banners swapped for the real mix: DO WYNAJĘCIA boards on the empty glass, a two-storey Frogs on Wars's south corner (the old H&M, facing Widok and Pasaż Wiecha, which the start camera sees), a shoe chain parody; ORANŻADA and WYPRZEDAŻ with their real letters | content (this thread) |
| R2 | **Plac Centralny's ground** | The grey and red slabs of the tenements' outlines, the setts of the courtyards and the 1939 street lines, the lawns and the pond, in the ground layer in front of the museum (first-scene item 4) | map (Opus), ground bake |
| R3 | **Pavements, kerbs and cycle paths** | Grey slab pavements and granite kerbs, red asphalt cycle paths, Złota's setts and elm alley, the fountain at the old tunnel mouth, the new crossings; checked on the orthophoto on the Mac | map (Opus) |
| R4 | **Ordinary buildings by type** | The facade shader draws a type, not just a seed: pre-war tenement (tall floors, window surrounds, a heavy cornice, rusticated ground floor, ochre/cream/grey plaster), 1960s-70s slab (panel joints, loggia bands, pale grey), socialist-realist (stone, arcades), modern office (curtain wall, exists). Picked from height, footprint and OSM kind, with a hand list for the start box. Shader only: +0 draw calls | visuals (Opus) |
| R5 | **Scena Relax, Zodiak, Cepelia** | The old cinema's RELAX letters on Złota 8 (R1 puts the sign up), the Zodiak pavilion in Pasaż Wiecha, the Cepelia glass pavilion and its book-and-vinyl store (parody name) at Rondo Dmowskiego | landmarks (Sonnet with a spec) |
| R6 | **Trendy places 2025/26** | Mostly built by the trends thread the same day (docs/design/trends-2025-26.md: MACZA, PISTACJA DO KOŃCA, ZĘBUŚ and five more, posters, the Limitka drop). Left here: at least one of those spots inside the start box, plus the Eastern Wall jokes (the empty stores, Frogs XXL) in the radio and passenger lines | content (Sonnet), warsaw-tone |
| R7 | **Street details in the box** | Warsaw's street name plates on corners, a city bike dock, the tram stops' platforms and shelters on Marszałkowska, bollards, bins, the Plac Centralny benches (first-scene item 5) | content + object-modeler |
| R8 | **Landmark polish left in the box** | The museum's mid-height ribbon in stretches and the stepped roofline (BACKLOG MSN), the Palace's parked stone colour question, the Rotunda's teeth on the phone | landmarks |

Performance: R1, R4 add no draw calls (signs are instances in the existing Neon MultiMesh;
R4 is shader-only, the per-pixel cost is checked with the bench). R2, R3 change the ground
layer's vertex colours or splat, not its draw count. R5-R7 add geometry to existing meshes
(the landmark site mesh, the first-scene mesh). Each PR reports bench before/after.

What only the phone (or the Mac) shows: the signs' size at the default zoom, the ground's
patterns at the phone's resolution, the type shading at a distance, the photo checks.

## Sources
- fashionbiznes.pl, H&M closes Marszałkowska after 21 years; the H&M space becomes a
  two-storey Żabka; CCC, eobuwie and Worldbox replace Zara (2025-26)
- wiadomoscihandlowe.pl, Wars Sawa Junior changes (23 July 2026); matcha +134 % (May 2026)
- tvn24.pl, the Cepelia pavilion reopens on 13 December 2024
- rmf24.pl, Plac Centralny: six stones, tenement outlines, 109 trees, the pond (2024)
- se.pl, the green Złota and the new crossing on Marszałkowska (August 2026)
- architekturaibiznes.pl, the greening of Marszałkowska
- warsawinsider.pl, "Beast-ern Wall" (the Eastern Wall's buildings and history)
- telepolis.pl and blog.google, Poland's year in search 2025 (Labubu, Dubai chocolate)
