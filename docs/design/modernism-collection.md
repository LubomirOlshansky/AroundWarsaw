# Warsaw modernism and brutalism: the building plan and "Betonowy album"

F asked (2026-11-03): "add all the brutalist and the modern architecture of Warsaw, as good as we can
with photos; I love modernism: Karowa 18, Kozia 9, and the Hammer Building should look very nice; add
a story or quests, a collect-them-all to gather all the modernist buildings; put it in the backlog, the
roadmap and our building modelling plan with high priority."

This file is the plan only. Nothing is built in the PR that adds it. Every model below is a **photo
build** (CITY_INVENTORY "The new approach"): a Remote Control session on the Mac gathers
`refs/<slug>/` (Commons photos, the GUGiK orthophoto, SOURCES.md) and a REPORT in game coordinates
first, then an Opus spec, then the build. No cloud-only guesses (F's rule of 2026-11-02).

The Eastern Wall's other asks from the same message (Junior, Sawa and Wars's Marszałkowska fronts,
WACZEK, the Koka-Kolka sign, Sezam) belong to the Ściana Wschodnia thread, not to this plan. The
department stores and the Rotunda join the album below because they are already photo builds.

## 1. The buildings, ranked

Facts come from published sources (listed in section 5). The REPORT on the Mac confirms or corrects
each one before a spec is written. Where a year or an architect is marked *(confirm)*, it is from
general knowledge and has not been checked against a source yet.

Priority M1 is F's three, then the rest by how often a player sees them and how much they add to the
city. "On the map" means inside the map box (bake_osm.py `BBOX` / `BBOX_NORTH`).

### New photo builds (high priority, in this order)

| # | Building | Address | Built, architects | Why it matters | On the map | Today | Slug |
| --- | --- | --- | --- | --- | --- | --- | --- |
| M1 | **Młotek** ("the Hammer") | Smolna 8, on the escarpment opposite Muzeum Narodowe | 1976; Jan Bogusławski, Bohdan Gniewiewski. 19 storeys, about 66 m | The two top floors are wider and set apart by a deep recess, so the block reads as a hammer; plain raw surfaces, often called brutalist. Seen from Powiśle and the river, close to the start | yes: OSM outline "Młotek" at x 83, z 34, 66 m (LoD2) | ✗ plain block (CITY_INVENTORY #128) | `mlotek` |
| M2 | **Kozia 9** | Kozia 9, its back on Moliera | 1974-76; Jerzy Kuźmienko, Piotr Sembrat (brick: Andrzej Krawczyk) | Five sections stepping up one storey each, a cascade of brick terraces; barrel and side windows on Moliera, big windows and balconies on Kozia. Built for the elite of the day; thermal modernisation later erased the original texture | yes: south of the Old Town, between Krakowskie Przedmieście and Moliera (unnamed outline; the REPORT gives its x, z) | ✗ plain block | `kozia9` |
| M3 | **Karowa 18a** | Karowa 18a, on the Karowa bend down the escarpment | 1978; Henryk Dąbrowski, Jerzy Kuźmienko, Janusz Nowak, Piotr Sembrat (the Kozia 9 team) | Sculptural balconies that make the block read as a sculpture, and a car park in its base | yes: Karowa's bend between Krakowskie Przedmieście and Dobra (unnamed outline; the REPORT gives its x, z) | ✗ plain block | `karowa18a` |
| M4 | **Żyletkowiec** ("the razor blade") and the Ekspozytura next door | Świętej Barbary, the block of Wspólna / Poznańska / Św. Barbary | early 1950s; Marek Leykam. In the heritage register (with the Ekspozytura) | Minimal form, repeating facade modules that make bands of light and shadow, next to a monumental block with Italian Renaissance echoes: modernism and socialist realism side by side | yes | ✗ (#127) | `zyletkowiec` |
| M5 | **Dom Chłopa** | Plac Powstańców Warszawy | 1958-61 *(confirm architect)* | The thaw's first big modernist hotel, on the start area's south square next to Hotel Warszawa | yes | ✗ (#127) | `dom_chlopa` |
| M6 | **Narodowy Bank Polski** | Świętokrzyska 11/21 | post-war stone block *(confirm years and architects)* | A whole block of Świętokrzyska; the street's late-modern face next to Poczta Główna and PAST-a | yes | ✗ (#75) | `nbp` |
| M7 | **The Kopernika "skyscraper"** (the Helvetia hotel) | Kopernika 36/40, side on Sewerynów | 1923-28; Antoni Jawornicki; rebuilt 1946-48 under Roman Piotrowski | Pre-war Warsaw's second-tallest after the Prudential (11 storeys, the top cut after 1944); Art Deco detail, a tall central tower | yes | ✗ plain block | `kopernika_helvetia` |
| M8 | **Osiedle Za Żelazną Bramą** | Plac Mirowski / Grzybowska / Twarda | 1965-72; Jerzy Czyż, Jan Furman, Andrzej Skopiński, Jerzy Józefowicz | The centre's great slab estate, built on the site of the Warsaw Ghetto; tall slabs in a park | yes | ✗ plain blocks | `zelazna_brama` (one shared slab kit, one material) |
| M9 | **Torwar** | Łazienkowska | 1950s *(confirm)*, rebuilt 1999 | The arena's long low roof by the Trasa Łazienkowska | yes | ✗ (#130) | `torwar` |
| M10 | **Bank Gospodarstwa Krajowego** | Aleje Jerozolimskie 7 | about 1928-31 *(confirm)*; Rudolf Świerczyński *(confirm)* | Interwar stone modernism on the Aleje, next to Muzeum Narodowe and Rondo de Gaulle'a | yes | ✗ plain block | `bgk` |
| M11 | **Ministerstwo Komunikacji** (today the Ministry of Infrastructure) | Chałubińskiego 4/6 | about 1928-31 *(confirm)*; Rudolf Świerczyński *(confirm)* | Interwar ministry block by the Centralna; seen on every drive along Chałubińskiego | yes | ✗ plain block | `min_komunikacji` |
| M12 | **Dom Słowa Polskiego** | Miedziana | 1950s *(confirm)* | The printing house's long front, transitional between socialist realism and modernism | yes | ✗ (#127) | `dom_slowa` |

### Photo re-passes of models we already have (they join the album when re-passed)

| # | Building | CITY_INVENTORY | Today | The re-pass |
| --- | --- | --- | --- | --- |
| M13 | Sofitel Victoria (1976) | #104 | ◐ outline | the slab and its podium on Królewska from photos |
| M14 | Plac Defilad's pavilions: Cepelia, Zodiak, Scena Relax | #90 | ◐ outline | glazing, the roof slabs, the neon |
| M15 | Muzeum Narodowe (1927-38, Tadeusz Tołwiński *(confirm)*) | #47 | ◐ outline | the 1930s front |
| M16 | The Sejm's hemicycle (1928, Bohdan Pniewski *(confirm)*) | #42 | ◐ outline | the hall's columns and frieze, the office slabs |
| M17 | Warszawa Wschodnia (1969) | #73 | ◐ from the Mac report | F's look on the Mac or the phone |

### Already photo builds (in the album from day one)

Rotunda (#2), Domy Towarowe Centrum: Junior, Sawa, Wars (#3), Warszawa Centralna (#9), Hotel Warszawa,
the 1934 Prudential (#29), Cedet (#30), Warszawa Powiśle and Ochota stations (#71), Hotel Forum, today
Novotel, and Centrum LIM (#62).

### The lost ones (KASETA then cards, not models)

- **Pawilon Emilia** (1970; Marian Kuźniar, Czesław Węgner, Anna Lewicka), the furniture pavilion on
  Emilii Plater that later housed the Museum of Modern Art and was taken down in the 2010s *(confirm
  the year)*. A then card fits the 2010-onward rule (vision.md section 10): the dithered ghost of the
  glass box over today's site.
- **Supersam** (Plac Unii Lubelskiej) is south of the map box: out unless the map grows south.
- **Sezam**: the Ściana Wschodnia thread decides (F named it there).

### Off the map (noted, not planned)

Ruda and Bródno estates, Hotel Felix (Omulewska), Supersam, the Lachert and Szanajca villas
(Żoliborz, Saska Kępa), Ministerstwo Wyznań Religijnych on Aleja Szucha (just south of the box's edge
52.2183, to confirm).

## 2. "Betonowy album": the collect-them-all story

**The pitch.** Pani Wanda (fictional), a retired architect, has kept a box of 1970s colour slides of
the city's modern buildings all her life. The box fell off the back of her nephew's moving van on
Karowa's bend and the slides went everywhere. She asks you to bring each building "back into the
album": find it, and take a Fotka shot that matches the slide.

**Tone** (warsaw-tone): affectionate love of concrete, glass and terrazzo; Wanda's lines are dry and
fond ("Beton też ma uczucia. / Concrete has feelings too."). No mockery of real people; architects are
named with respect on the cards. No jokes about the war, the Ghetto (Za Żelazną Bramą's card states its
history plainly) or the Rotunda's 1979 explosion. Every line Polish with English, Polish at most 70
characters.

**How it plays** (reuses what exists; no new system):

1. **The start.** Not in the first ten minutes (the first-10 guide holds offers). Wanda appears at
   the Karowa bend by day after minute 10, or when the player first drives past Młotek, Kozia 9 or
   Karowa 18a after the guide ends. A call card (the phone, like the DESKA "Czwarty" call) gives the
   first slide.
2. **A slide is a Kadr spot.** Each album building is a Kadr entry (`data/kadr.json` format, Fotka's
   check: the subject in the frame's central 60 %, the camera within 300 m, the slide's `look`). The
   slide shows a dithered thumbnail of our own model from the slide's angle (rendered at build time,
   a still, never a real photo) and a hint line ("Tam, gdzie młotek wisi nad skarpą").
3. **Finding a slide.** Wanda hands out the slides in bundles of three as the player brings them
   back, so the hint arrow always points to at most three. A slide counts only once its building is
   a photo build (★): the album grows as the builds land, so the quest can ship with the nine ★
   buildings and fill up later.
4. **Five story slides** have a small twist on top of the shot:
   - **Młotek, "Głowa młotka":** the shot from the helicopter level with the hammer's head (55-66 m)
     at dusk. Wanda: her friend on the 19th floor waves a towel.
   - **Kozia 9, "Kaskada":** drive Kozia at walking pace (under 15 km/h for 100 m, like the E39
     follow check) to "find the terraces", then the shot from Moliera at night with the terraces lit.
   - **Karowa 18a, "Balkony-rzeźby":** the shot from the bend where the van lost the box; a stop on
     the bend finds the last slide in the gutter (a pickup like a Syrenka).
   - **Centralna, "Płyta":** the roof slab from straight above, from the helicopter.
   - **Rotunda, "Rondo o zmroku":** the shot at dusk with the neon on.
5. **The lost slide.** The Emilia slide plays on KASETA at its site: the then card shows the
   pavilion's ghost; Wanda's line is about the furniture she bought there.
6. **The reward.** Each slide: +20 respect and the photo on its notebook card (the KADR page gets a
   BETON tab). The whole album: +100 respect, the **"Betonowa"** car paint in the garage (raw concrete
   grey with board-formwork grain, the Syrenki's paint pattern), Wanda's last call, and a KEBAB FM
   news line ("Mieszkańcy Śródmieścia zakochani w betonie").
7. **On the maps.** Album slides are their own icon (a white slide frame), so the side quest stays
   visually distinct from the main line (F's rule); found slides turn grey; the district completion
   counts them like places.

**Add-ons check.** Wanda's talk is linear lines on a call card and bubbles: Dialogue Manager **not
used**, because there is no branching (the project default outside the police and authored branching
scenes). Beehave not used: Wanda does not move.

**Data and code** (for the build thread, Opus design, gameplay-dev build): a `data/album.json` (or a
`set: "beton"` field on `kadr.json` entries) listing slug, place, look, hint [pl, en], card line
[pl, en], architect and year; `fotka.gd` already scores shots; the call and the bundles in a small
`album.gd` (or `kadr` set logic in `fotka.gd`); a `check_album.gd` joining `tools/verify.sh` (every
entry's place exists, lines within 70 characters, every ★ entry has a thumbnail); flags `--album`,
`--album-log`, `--found-album=` in `main.gd` and the archive's flags table. Cost: 0 draw calls while
driving (the slides are UI), one icon layer on the map.

## 3. The modelling recipe for this set

- One thread per building (M1, M2, M3 first, in that order), Opus spec, Sonnet `object-modeler`,
  `art-director` side by side against the photos, F's look on the Mac or the phone.
- **Photos first:** the Mac's gather brief per slug: 15-25 Commons photos (every face, day and
  night), the GUGiK ortho for the roof, LoD2 heights, published facts; `refs/<slug>/REPORT.md` with
  the outline's x, z and the parts. A thread spawned without a message from F asks F for a one-word
  "go" before it starts Remote Control (memory: the gather needs F's own message in that thread).
- **What makes these read right at play zoom:** the silhouette first (Młotek's head and recess,
  Kozia's steps, Karowa's balconies), then the facade rhythm (one repeated bay module in the
  facade shader, not geometry per window), raw concrete and brick as shader materials (the roofs
  lane's RF approach), lit windows at night from the existing window seed.
- **Budgets:** each model inside its `check_mesh_quality.gd` BUDGET and one or two materials; the
  estate (M8) as one slab kit in a MultiMesh or a shared mesh, so it adds draw calls per sector, not
  per slab. Bench before and after every build (CLAUDE.md "Performance is a gate").
- Landmark models need `_collide_raw` and pocket rings (memory: landmark-pocket-rings).

## 4. Open questions (parked in docs/QUESTIONS.md with these defaults)

1. The quest giver: default Pani Wanda, a fictional retired architect.
2. The reward paint: default "Betonowa" (concrete grey with formwork grain).
3. Which slides need the helicopter: default two (Młotek, Centralna); the rest by car.
4. The Eastern Wall's 1960s towers on Marszałkowska: default they join the album when the Ściana
   Wschodnia thread builds them from photos.

## 5. Sources

- Kozia 9: [whitemad.pl, "Kozia 9 in Warsaw: socmodernism at its best"](https://www.whitemad.pl/en/kozia-9-in-warsaw-socmodernism-at-its-best/)
- Karowa 18a: [se.pl, "Dzieło sztuki w samym sercu stolicy"](https://www.se.pl/warszawa/dzielo-sztuki-w-samym-sercu-stolicy-prl-owski-blok-przypomina-rzezbe-aa-kWeQ-aTDV-AbUA.html);
  architects from [greyscape.com, "blok by blok"](https://www.greyscape.com/warsaw-packed-with-architectural-gems-lets-walk-and-talk-with-photographer-artur-bednarczy-blok-by-blok/)
- Młotek: [culture.pl, "Młotek na Smolnej"](https://culture.pl/pl/artykul/mlotek-na-smolnej)
- Żyletkowiec: [eska.pl, heritage register](https://www.eska.pl/news/ten-charakterystyczny-budynek-w-centrum-warszawy-wlasnie-trafil-do-rejestru-zabytkow-aa-q6hz-95qR-sTWn.html)
- Kopernika: [whitemad.pl, "Skyscraper from Kopernika Street"](https://www.whitemad.pl/en/skyscraper-from-kopernika-street-the-second-tallest-building-in-the-pre-war-capital/)
- Za Żelazną Bramą and Pawilon Emilia: greyscape.com (above)
