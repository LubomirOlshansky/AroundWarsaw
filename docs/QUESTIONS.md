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
| landmarks/models | Landmark and skyscraper models (Złote Tarasy, Złota 44, Varso, PKiN, Spire, Q22, Muzeum Narodowe, Stadion Narodowy), bus stops: BACKLOG "High priority" | cloud thread "Improve landmark and skyscraper models" | 2026-10-30 |
| store release | The signed Android AAB for Play internal testing, on today's main | cloud thread "Prepare App Store and Play beta listings" | 2026-10-30 |
| performance | Profile the 108-sector map on mobile settings (frame time, draw calls, memory); cheap wins outside the map engine (3d-2 is the map lane's) | cloud thread "Prepare App Store and Play beta listings" | 2026-10-30 |

## Waiting

Newest first. One entry per question.

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
- **YYYY-MM-DD · lane · item** — The question in one line? Options: A / B. Default built: A
  (or "nothing built: waits"). Where: PR #N, BACKLOG "section".
-->

## Answered

Move an entry here with the user's answer and the date; its item goes back to the top of the
backlog. Lasting decisions also go into BACKLOG's "Decided" sections, DEMO.md or ROADMAP.
