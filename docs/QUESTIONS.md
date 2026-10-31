# Parked questions and lanes in progress

The work doesn't stop for a question (docs/WORKFLOW.md "Backlog mode", the backlog-loop
skill): a question for the user is parked here with the default that was built, and the
session takes the next item. The user answers here, in a PR comment or in chat, in one batch.

## In progress

One session per lane. Add a row when you start an item, remove it when the item lands.

| Lane | Item | Session | Since |
| --- | --- | --- | --- |
| driving | The car's feel, traffic and the player, the roadworks (PR #5 and #8 landed; the ram test) | cloud thread "Make driving smoother" | 2026-10-30 |
| visuals | Loop 3i items: rain and night looks (PR #7 puddles over markings, PR #11 night water), then reflections and the remaining 3i look items | cloud thread "Set up project and work through game backlog" | 2026-10-30 |
| landmarks | Landmark models, third pass: the low-rise landmarks (Teatr Wielki, Zamek, Barbakan, Kopernik, BUW, churches, Sejm), then street furniture | cloud thread "Improve landmark and skyscraper models" | 2026-10-30 |
| map | The loading fix (on-screen sectors first, proxies that look like the city), then the map north to Rondo Radosława, Arkadia and Forest (3d-1, 3d-2a, 3d-2b and 3e landed) | thread "Finish the demo map extension" | 2026-10-30 |

## Waiting

Newest first. One entry per question.

- **2026-10-31 · content · jobs-2 (courier race, round-up, payphone, armchair)** — The Leżak
  round-up follows parodies.md 5.3 (collect into the boot, unload at the depot), not pushing
  scooters with the car. Default built: the spec.
- **2026-10-31 · content · jobs-2** — Pędzik rides at 6.5 m/s and rarely beats a player; tune
  with `--courier-v=` on the phone. The race's gap reads high at the start when the order's
  lane is the far carriageway (jobs.gd's order picker, BACKLOG). Default built: 6.5 m/s.
- **2026-10-31 · content · jobs-2** — E40's card shows T17's line (+10) rather than adding a
  21st KASETA then card (that set is 2010–today). Default built: as said.
- **2026-10-31 · content · jobs-2** — The payphone (a small grey post by the bus shelter at Plac
  Konstytucji) and the armchair man (rust shirt, teal chair, Mokotowska, 1 day in 3, 08–20) are
  hard to spot in shots; art-director pass and a phone look. Default built: as made.

- **2026-10-30 · content · MW-2 (storefronts and parodies)** — The Frogs stamp card reaches 8 m
  from the door (parodies.md says 6 m), and 15 % of Podwózka passengers are `detour` (ask for a
  Frogs). Default built: 8 m, 15 %.
- **2026-10-30 · content · MW-2** — Pędzik couriers have their own MultiMesh (+1 draw call in view)
  rather than sharing the bikes'. The courier race and the Leżak round-up job aren't built (not
  cheap; BACKLOG). Default built: as said.
- **2026-10-30 · content · MW-2** — Billboards are text only until PixelLab pictograms can be
  made; the metro sign is a generic cream M on navy (no operator logo). Default built: as said.
- **2026-10-30 · content · MW-2** — `easter_lezak`'s English is trimmed to fit 70 characters: "A
  Leżak standing up. In its own zone. Someone should report this." Default built: trimmed.
- **2026-10-30 · map · MW-2's asks** — The bake should add `shop=convenience`,
  `railway=subway_entrance`, `amenity=bicycle_rental` and scooter-zone pois, and an address for
  Kruczkowskiego 3B; the shops find their walls at runtime today. Default: runtime placement.

- **2026-10-30 · content · F's asks** — LEVEL 26 costs +2 draw calls at night in view (the
  violet band and the crowd cell with the roof crowd and the door queue) against a +1 target.
  Default built: both kept; 0 by day and beyond 350 m.
- **2026-10-30 · content · F's asks** — With the pedestrian slow zones off (the new default),
  should the guards still whistle as flavour? Default built: no whistle, run or guards' car; the
  clamp stays.
- **2026-10-30 · content · F's asks** — The full map shows "?" marks only within 400 m of the
  car (the minimap's rule) so it doesn't spoil the notebook. Default built: 400 m.
- **2026-10-30 · content · F's asks** — The shop sign: "FROGS" with the blade disc keeping
  "24", or "Frogs 24" as the name? Default built: Frogs, the disc says 24.
- **2026-10-30 · store release · Android back** — `quit_on_go_back` is Godot's default (true):
  the back gesture may quit the app instead of closing the full map. Check on an Android phone.
  Default built: unchanged.
- **2026-10-30 · performance · full map** — The 3D city still renders under the open full map
  (paused). Stop it while the map is open? Default built: not done.

- **2026-10-30 · content · MW-4 (everyday life and trends)** — How often does a trend move
  without Live? Vision says every third session. Default built: every 4 sessions. Live counts
  8-day cycles from 2026-01-05 rather than the ISO week.
- **2026-10-30 · content · MW-4** — E28 is built as "follow a Rowerilo rider 400 m" (vision: "to
  a dock"). The "Na czasie" job pays 51 zł on time, 21 late, no tip on days 6–7; the offer shows
  within 60 m of a slot, then waits 240 s. Default built: as said.
- **2026-10-30 · content · MW-4** — Kolka and Hyrax show only in Live (or `--zajac`), plus Hyrax
  in the fixed Day look before noon. Dogs are drawn 1.35× so they read. Default built: as said.
- **2026-10-30 · content · MW-4** — The player has no horn signal (car.gd, driving lane), so the
  AI cars' horns make the dogs bark for now. Default built: AI horns.
- **2026-10-30 · content · MW-4** — Cost cut: movers within 15 m of the car step at full rate
  (was 30 m); off-screen ones at 3.75 Hz. Default built: as said.

- **2026-10-30 · content · Podwózka's name** — F is thinking of renaming Podwózka (the lift
  app) to something like "zUber". Take: a near-Uber name carries trademark risk (the rule is
  parodies that don't lean on a real name or logo), and Podwózka already reads as a joke in
  Polish. Options: keep Podwózka / **Hopka** ("hop in") / **Wiozę** ("I'm driving you") /
  **Szofer** / "zUber" anyway. Default built: Podwózka, nothing renamed until F picks.

- **2026-10-30 · content · MW-3 (night and river crowds)** — A real sitting pose? Sitters are
  squashed standing figures; a real pose needs `actor.gdshader` work (visuals lane) or a second
  mesh (+1 draw call). Default built: squashed.
- **2026-10-30 · content · MW-3** — Guessed curves: Plan C's hours, the dawn curve (20 at the
  window's edges, 40 at 06–07), weekday factors, the guitarist 16:00–01:00, rain 0.1. Tune by eye
  on the phone. Default built: as listed in DEVELOPMENT "The night and the river".
- **2026-10-30 · content · MW-6 (eggs, KASETA, Spacer, Fotka)** — Words written in this loop
  need a designer pass: egg lines vision doesn't quote, the English egg names, and the 15 Kadr
  photo spots (`game/data/eggs.json`, `kadr.json`). Default built: as written.
- **2026-10-30 · content · MW-6** — The KASETA ghost is faint (dithered, reusing the building
  shader) and dim at night. Brighter needs a visuals-lane shader uniform. Default built: faint.
- **2026-10-31 · map · 3e** — Ground under trenches: 1 m sub-cells only at tunnel portals and
  road cuttings (keeps the +1 % vertex budget), or a new builder feature that cuts the ground along
  a lowered corridor and draws the floor as one strip (would also fix the rail cutting and ~40 more
  findings for a few vertices per cell)? Default built: sub-cells; the strip is a follow-up loop.
- **2026-10-31 · map · 3e** — check_drive now drives all 98 structure routes (~2 s more), which
  surfaced allowlisted jumps at Poniatowski deck 13, Łazienkowski deck 20 and Towarowa. Default
  built: keep 98 routes (the alternative was back to 20, hiding them).
- **2026-10-31 · map · 3e** — Plac Na Rozdrożu's tube ends stop a few metres short of the street
  over them: extend a tunnel under any way crossing its open road within 15 m of the portal?
  Default built: OSM geometry kept, allowlisted with its cause.
- **2026-10-31 · map · 3e** — Portal headwalls are plain concrete; the new tall W-Z east headwall
  reads as a dark slab at night. An art pass on portal frames (lining, lamps)? Default: none
  until the art director picks it up.
- **2026-10-31 · map · 3e** — Parked cars at `PARKED_FILL` 0.27 (14,637 → 4,927) as asked. If
  it now looks too empty, it's one constant in `bake_osm.py`. Default built: 0.27.
- **2026-10-30 · map · 3d-2b** — A far level by zoom: draw the helicopter's highest views (above
  ~200 m) as painted proxies? Over the centre ~357 draw calls would drop to a few dozen, but those
  views lose their 3D detail. Default built: no far level, full detail everywhere (the orthographic
  camera shows no proxies today). Where: BACKLOG "From loop 3d-2b".
- **2026-10-30 · map · 3d-2b** — Map slots for the per-sector AO/light maps: keep 24 (32 MB) or
  raise to 28–32 for headroom (+5–11 MB)? The 3-minute soak reached 24 with no waits. Default: 24.
- **2026-10-30 · map · 3d-2b** — check_streaming's spot 8 limit (1 %): lower it now that it
  measures 0.015 %? Default: leave it until more runs agree.
- **2026-10-30 · map · 3d-2b** — Landmarks in the proxies need a LOD1 model from `landmarks.gd`
  (landmarks lane). Default: none until round 3f's landmark factory.
- **2026-10-30 · map · 3d-2a** — Clean the terrain at bake time (snap near-flat 20 m blocks within
  15 cm) so flat ground can merge into bigger quads? It would let ~47 % of cells merge but moves
  driving heights by up to 15 cm and needs a full re-bake. Options: snap / keep exact heights.
  Default built: keep exact heights. Where: BACKLOG "From loop 3d-2a".
- **2026-10-30 · map · 3d-2a** — Cut the ground along road edges (with skirts) rather than only
  dropping 10 m triangles fully under a cover? Default built: only whole covered triangles go;
  the full cut waits for a phone Metal trace showing ground fill under streets costs something.
- **2026-10-30 · map · 3d-2a** — Next flat-mesh target: footways (1.88 M vertices), grass (1.39 M),
  roads (1.21 M), kerbs (0.80 M). Default: footways first, after 3d-2b.

- **2026-10-30 · content · MW-5 (PÓŁNOC FM)** — Listen to the 7 new tracks (attached in the
  thread, or `--unlock=all --station=polnoc`): mood, balance, does the bass reach the phone's
  speaker? They're 22 kHz, 40 kbps to stay under 4 MB; raise it if you hear artifacts.
  Default built: as made.
- **2026-10-30 · content · MW-5** — New words for a designer pass: the day caption "powtórka ·
  rerun · the host is back at 22:00" and the unlock toast "Kuba ma nową płytę: „…”".
  Default built: as written.

- **2026-10-30 · content · 3g-2 (police, part two)** — Rescue escort: how often after the first
  rescue, and how fast? Default built: the first rescue always, then one in two; 45 km/h, 15–25 m
  ahead. Tell back after a phone run.
- **2026-10-30 · content · 3g-2** — The pedestrian-zone cap only cuts the gas: a car entering
  faster coasts down to 20 km/h. Brake it harder? Default built: coast down.
- **2026-10-30 · content · 3g-2** — The clamp card reads BLOKADA NA KOLE · ZDEJMUJĘ ZA 0:10 /
  WHEEL CLAMP ON · OFF IN 0:10. Wording for a game-designer pass? Default built: as written.

- **2026-10-30 · landing · beta form** — The aroundwarsaw.app sign-up form still posts to
  Stillplace's Formspree form (`mykaeqjp`), so beta sign-ups land in that inbox. Make a form
  for Around Warsaw on your Formspree account (free) and send its id, or keep the shared one?
  Default built: shared form, nothing changed. The id is one string in `site/src/index.html`
  (and the Polish page); then a redeploy. Where: BACKLOG "From the website".
- **2026-10-30 · performance · phone runs** — May I run the bench and a streaming soak on the
  iPhone 11 (a test build through Remote Control)? The Mac work is done (PR #27 memory −20 MB,
  #33 traffic, #35 bench result); what's left needs the phone: static memory on the iPhone 11
  (BENCH's memory line, before the beta), and whether a sector's load still makes a 25–65 ms
  frame there. Default built: nothing run on the phone. Where: BACKLOG "From the performance
  baseline", "From loop G0+".
- **2026-10-30 · landmarks/models · landmark models** — Do the towers now read as the real
  ones? Look at the before/after shots in the PR. Default built: 18 towers in their own skins
  and colours, Złote Tarasy golden, Muzeum Narodowe in stone, new bus shelters. Say which
  still look wrong and how. Where: PR (landmark models).
- **2026-10-30 · landmarks/models** — Złota 44's top is cut on a slope, high at its north end.
  Options: keep / high at the south end / flat. Default built: high at the north end.
- **2026-10-30 · web · deploy** — May I deploy the web build? It creates the Worker
  `aroundwarsaw-play` with the custom domain play.aroundwarsaw.app (a new DNS record in the
  aroundwarsaw.app zone) and uploads build/web (~141 MB), then redeploys the landing so the
  "Play online" button and the /play/ redirect go live. Both are public; `wrangler rollback` and
  deleting the Worker undo them. Default built: everything ready and tried locally; nothing
  deployed. Where: docs/DEVELOPMENT.md "The web build".
- **2026-10-30 · content · MW-1** — The chapter-complete card reads ROZDZIAŁ GOTOWY · CHAPTER
  DONE with "+50 zł, +30 ★". Wording for a game-designer pass? Default built: as written.
- **2026-10-30 · store release · app IDs** — The iOS bundle ID is still
  `com.olshanskysoft.nocnawarszawa`. Change it to `com.olshanskysoft.aroundwarsaw` before the
  App Store Connect record exists, or keep it? Nobody ever sees it (the home-screen and store
  name is "Around Warsaw" on both platforms). The Android package can't change: Play has had
  version code 1 under `com.olshanskysoft.nocnawarszawa` since October, and a new package
  would be a new app. Options: keep (both platforms match) / change iOS only. Default built:
  keep, as the rename of 2026-10-30 decided. Where: `game/export_presets.cfg`, ROADMAP
  "rename + open source".

- **2026-10-30 · store release · store listings** — Ship the iOS app for iPhone and iPad, or
  iPhone only? Once an iPad version is on the App Store, later versions can't drop iPad.
  Options: iPhone and iPad (needs an iPad device pass) / iPhone only. Default built: nothing
  changed (the preset still says iPhone and iPad, which is fine for TestFlight; iPad
  screenshots are rendered). Decide before the first App Store release. Where:
  docs/store/app-store-connect.md section 10.
- **2026-10-30 · store release · store listings** — Account steps only you can do: create the
  App Store Connect app record and the Play listing from docs/store/, pick the support email
  (not written in the public repo), upload the first builds, invite testers. And a yes to
  redeploy aroundwarsaw.app so `/support/` goes live (the store forms link to it). Default
  built: everything written; nothing submitted.
- **2026-10-30 · visuals · night water (PR #11)** — Is the river's new night sheen right on the
  phone's OLED: too faint, right, too strong? Options: keep / stronger / fainter. Default built: the
  faint version (`ground.gdshader`, the `0.16 * broad` and `0.1` shore terms).

<!--
- **2026-10-30 · HUD · radio skip** — On the phone, holding RADIO for 0.5 s skips to the
  station's next track; a tap changes the station as before. Nothing on screen tells the
  player about the hold. Options: A: leave it hidden / B: a one-time hint on the ticker
  ("przytrzymaj RADIO: następny utwór · hold RADIO: next track") / C: a separate ⏭ button.
  Default built: A (the ticker shows the new track's name, so a skip explains itself).
- **2026-10-30 · HUD · fallback toast** — The first launch at Auto's coarser picture (after a
  session that struggled at the sharp one) now shows once: "Obraz prostszy, żeby było płynnie ·
  A coarser picture for a smoother ride · Settings → Obraz". It doesn't mention heat, because
  the struggle is measured frame time, not temperature. Options: A: as built / B: the backlog's
  "Obraz prostszy, bo telefon się grzał · the phone was struggling" / C: no toast. Default built: A.
- **2026-10-30 · performance · compressed map textures** — May I run one bench on the iPhone
  with the AO and lamp-light maps VRAM-compressed (BACKLOG "Memory still on the table")? On the
  Mac they look the same and textures drop 42 MB, but video memory rises 23 MB from a one-time
  allocation; only the phone shows which way it goes there. Options: A: one device bench, before
  and after / B: drop it. Default built: nothing landed (the code waits on its branch).
- **YYYY-MM-DD · lane · item** — The question in one line? Options: A / B. Default built: A
  (or "nothing built: waits"). Where: PR #N, BACKLOG "section".
-->

## Answered

Move an entry here with the user's answer and the date; its item goes back to the top of the
backlog. Lasting decisions also go into BACKLOG's "Decided" sections, DEMO.md or ROADMAP.

- **2026-10-30 · content · MW-3** — Queues stand at the place's point and the nearest footway
  until MW-2's storefronts exist; Smoła's queue lands in a passage hidden by a block from
  `--club=smola`. Default built: as said.
  **Answered 2026-10-30 (F):** as said (kept).
- **2026-10-30 · content · MW-3** — Night buses (E23, E25) need a small bus API in `traffic.gd`
  (driving lane), e.g. `spawn_bus(route, sign)`. Default built: not built, BACKLOG.
  **Answered 2026-10-30 (F):** not built, BACKLOG (kept).
- **2026-10-30 · content · MW-3** — Dawn is the last entry of Settings → TIME (so saved settings
  keep their meaning); E15's "three different days" uses the real date without Live. Default
  built: as said.
  **Answered 2026-10-30 (F):** as said (kept).
- **2026-10-30 · content · MW-6** — E31's reward was track 2, which is free from the start: it
  opens the next locked track instead. The 5 old eggs now pay +10 respect each. Default built:
  as said.
  **Answered 2026-10-30 (F):** as said (kept).
- **2026-10-30 · content · MW-6** — Spacer (wander mode) is a row in Settings → JAZDA, offered
  once by a toast; FOTKA is a button in Settings → OBRAZ. Default built: there.
  **Answered 2026-10-30 (F):** there (kept).
- **2026-10-30 · content · MW-5** — Chapters 1–5 unlock tracks 3–7; chapters 6–9 unlock nothing
  yet (vision: a horn tune and the gold cover later). Default built: as said; BACKLOG.
  **Answered 2026-10-30 (F):** as said (kept).
- **2026-10-30 · content · MW-5** — Until you pick a station, the radio follows the clock:
  PÓŁNOC FM at night, KEBAB FM otherwise. Keep, or switch only at launch? Default built: follow.
  **Answered 2026-10-30 (F):** follow the clock (kept).
- **2026-10-30 · content · 3g-2** — Stopping by a guard ends in a caution in the joke notebook.
  The routine first contact takes no Podwózka star. Keep both? Default built: as said.
  **Answered 2026-10-30 (F):** kept. F is also thinking of renaming Podwózka (e.g. "zUber"): parked as its own question above.
- **2026-10-30 · landmarks/models** — Hotel towers are named by address, not brand (rule:
  brands only as parodies): the InterContinental's card says "Emilii Plater 49", the Hilton's
  "Grzybowska 63", the Westin's "Jana Pawła II 21", the Novotel's "Marszałkowska 94/98".
  Default built: as said. Options: keep /
  parody names for the hotels.
  **Answered 2026-10-30 (F):** **parody names** for the hotel towers, not addresses (changed; landmarks lane's item).
- **2026-10-30 · content · MW-1 (the notebook)** — The minimap shows "?" for undiscovered
  places within 400 m of the car, because districts don't exist yet. Switch to "in a discovered
  district" once DEMO 6.3's districts land? Default built: 400 m.
  **Answered 2026-10-30 (F):** 400 m kept. F also wants the minimap to open full screen: BACKLOG "From loop MW-1" (HUD item).
- **2026-10-30 · content · MW-1** — Venue cards hide the street address (a venue's real address
  can name the real club, e.g. "Jasna 1" is on the denylist). Add a designer-written "safe to
  show" address per place? Default built: no address on venue cards.
  **Answered 2026-10-30 (F):** no address (kept).
- **2026-10-30 · content · MW-1** — The settings tab is ZESZYT · notebook, and the card's title
  becomes MOJA WARSZAWA on that tab (the full name doesn't fit as a fifth tab on the iPhone SE).
  Keep? Default built: ZESZYT.
  **Answered 2026-10-30 (F):** ZESZYT kept (it means "notebook").
- **2026-10-30 · content · MW-1** — Stadion Narodowy (115 m from any road) and Most
  Śląsko-Dąbrowski (65 m) can't be found by car with today's anchors: wider radius, or wait for
  the map lane's bake resolution? Default built: nothing changed; BACKLOG "From loop MW-1".
  **Answered 2026-10-30 (F):** wait for the map lane's bake (kept).
- **2026-10-30 · content · MW-0 (Moja Warszawa data)** — Where is the real "Apteka" bar you
  meant? Options: name the street / keep the default. Default built: APTECZKA in a Nowy Świat
  22/28 courtyard pavilion, marked `guess` in `game/data/places.json`. If the "Apteka" came from
  the song with "apteką" in its title, say so and it gets an invented name instead. Where: PR (MW-0).
  **Answered 2026-10-30 (F):** APTECZKA in the Nowy Świat courtyard (kept).
- **2026-10-30 · content · MW-0** — The then-and-now cards start in 2010 (the demo's "time
  tape"), so vision.md's 2009 blue hall and the 1990s items wait for later. Allow the blue hall
  as an exception? Default built: 20 cards from 2010 to 2024 (`game/data/then_cards.json`).
  **Answered 2026-10-30 (F):** from 2010, no blue-hall exception (kept).
- **2026-10-30 · content · MW-0** — Historic hall names "Hala Koszyki" and "Hala Gwardii" are
  kept as place names (they are also the halls' trade names); the new tower and museum are
  never named. Rename the halls descriptively ("Hala na Koszykowej")? Default built: kept.
  **Answered 2026-10-30 (F):** kept.
