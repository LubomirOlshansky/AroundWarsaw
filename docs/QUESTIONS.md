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
| performance | The map textures (AO, lamp light and surface maps, ~96 MB of video memory on the phone), then the web build's first download (~59 MB) | cloud thread "Build landing and beta listings" | 2026-10-30 |

## Waiting

Newest first. One entry per question.

- **2026-10-30 · content · MW-6 (eggs, KASETA, Spacer, Fotka)** — Words written in this loop
  need a designer pass: egg lines vision doesn't quote, the English egg names, and the 15 Kadr
  photo spots (`game/data/eggs.json`, `kadr.json`). Default built: as written.
- **2026-10-30 · content · MW-6** — The KASETA ghost is faint (dithered, reusing the building
  shader) and dim at night. Brighter needs a visuals-lane shader uniform. Default built: faint.
- **2026-10-30 · content · MW-6** — E31's reward was track 2, which is free from the start: it
  opens the next locked track instead. The 5 old eggs now pay +10 respect each. Default built:
  as said.
- **2026-10-30 · content · MW-6** — Spacer (wander mode) is a row in Settings → JAZDA, offered
  once by a toast; FOTKA is a button in Settings → OBRAZ. Default built: there.

- **2026-10-30 · content · MW-5 (PÓŁNOC FM)** — Listen to the 7 new tracks (attached in the
  thread, or `--unlock=all --station=polnoc`): mood, balance, does the bass reach the phone's
  speaker? They're 22 kHz, 40 kbps to stay under 4 MB; raise it if you hear artifacts.
  Default built: as made.
- **2026-10-30 · content · MW-5** — Chapters 1–5 unlock tracks 3–7; chapters 6–9 unlock nothing
  yet (vision: a horn tune and the gold cover later). Default built: as said; BACKLOG.
- **2026-10-30 · content · MW-5** — Until you pick a station, the radio follows the clock:
  PÓŁNOC FM at night, KEBAB FM otherwise. Keep, or switch only at launch? Default built: follow.
- **2026-10-30 · content · MW-5** — New words for a designer pass: the day caption "powtórka ·
  rerun · the host is back at 22:00" and the unlock toast "Kuba ma nową płytę: „…”".
  Default built: as written.

- **2026-10-30 · content · 3g-2 (police, part two)** — Rescue escort: how often after the first
  rescue, and how fast? Default built: the first rescue always, then one in two; 45 km/h, 15–25 m
  ahead. Tell back after a phone run.
- **2026-10-30 · content · 3g-2** — The pedestrian-zone cap only cuts the gas: a car entering
  faster coasts down to 20 km/h. Brake it harder? Default built: coast down.
- **2026-10-30 · content · 3g-2** — Stopping by a guard ends in a caution in the joke notebook.
  The routine first contact takes no Podwózka star. Keep both? Default built: as said.
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
- **2026-10-30 · landmarks/models** — Hotel towers are named by address, not brand (rule:
  brands only as parodies): the InterContinental's card says "Emilii Plater 49", the Hilton's
  "Grzybowska 63", the Westin's "Jana Pawła II 21", the Novotel's "Marszałkowska 94/98".
  Default built: as said. Options: keep /
  parody names for the hotels.
- **2026-10-30 · web · deploy** — May I deploy the web build? It creates the Worker
  `aroundwarsaw-play` with the custom domain play.aroundwarsaw.app (a new DNS record in the
  aroundwarsaw.app zone) and uploads build/web (~141 MB), then redeploys the landing so the
  "Play online" button and the /play/ redirect go live. Both are public; `wrangler rollback` and
  deleting the Worker undo them. Default built: everything ready and tried locally; nothing
  deployed. Where: docs/DEVELOPMENT.md "The web build".
- **2026-10-30 · content · MW-1 (the notebook)** — The minimap shows "?" for undiscovered
  places within 400 m of the car, because districts don't exist yet. Switch to "in a discovered
  district" once DEMO 6.3's districts land? Default built: 400 m.
- **2026-10-30 · content · MW-1** — Venue cards hide the street address (a venue's real address
  can name the real club, e.g. "Jasna 1" is on the denylist). Add a designer-written "safe to
  show" address per place? Default built: no address on venue cards.
- **2026-10-30 · content · MW-1** — The settings tab is ZESZYT · notebook, and the card's title
  becomes MOJA WARSZAWA on that tab (the full name doesn't fit as a fifth tab on the iPhone SE).
  Keep? Default built: ZESZYT.
- **2026-10-30 · content · MW-1** — The chapter-complete card reads ROZDZIAŁ GOTOWY · CHAPTER
  DONE with "+50 zł, +30 ★". Wording for a game-designer pass? Default built: as written.
- **2026-10-30 · content · MW-1** — Stadion Narodowy (115 m from any road) and Most
  Śląsko-Dąbrowski (65 m) can't be found by car with today's anchors: wider radius, or wait for
  the map lane's bake resolution? Default built: nothing changed; BACKLOG "From loop MW-1".
- **2026-10-30 · store release · app IDs** — The iOS bundle ID is still
  `com.olshanskysoft.nocnawarszawa`. Change it to `com.olshanskysoft.aroundwarsaw` before the
  App Store Connect record exists, or keep it? Nobody ever sees it (the home-screen and store
  name is "Around Warsaw" on both platforms). The Android package can't change: Play has had
  version code 1 under `com.olshanskysoft.nocnawarszawa` since October, and a new package
  would be a new app. Options: keep (both platforms match) / change iOS only. Default built:
  keep, as the rename of 2026-10-30 decided. Where: `game/export_presets.cfg`, ROADMAP
  "rename + open source".

- **2026-10-30 · content · MW-0 (Moja Warszawa data)** — Where is the real "Apteka" bar you
  meant? Options: name the street / keep the default. Default built: APTECZKA in a Nowy Świat
  22/28 courtyard pavilion, marked `guess` in `game/data/places.json`. If the "Apteka" came from
  the song with "apteką" in its title, say so and it gets an invented name instead. Where: PR (MW-0).
- **2026-10-30 · content · MW-0** — The then-and-now cards start in 2010 (the demo's "time
  tape"), so vision.md's 2009 blue hall and the 1990s items wait for later. Allow the blue hall
  as an exception? Default built: 20 cards from 2010 to 2024 (`game/data/then_cards.json`).
- **2026-10-30 · content · MW-0** — Historic hall names "Hala Koszyki" and "Hala Gwardii" are
  kept as place names (they are also the halls' trade names); the new tower and museum are
  never named. Rename the halls descriptively ("Hala na Koszykowej")? Default built: kept.
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
- **YYYY-MM-DD · lane · item** — The question in one line? Options: A / B. Default built: A
  (or "nothing built: waits"). Where: PR #N, BACKLOG "section".
-->

## Answered

Move an entry here with the user's answer and the date; its item goes back to the top of the
backlog. Lasting decisions also go into BACKLOG's "Decided" sections, DEMO.md or ROADMAP.
