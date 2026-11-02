# Playtest plan and bug log

How Around Warsaw is played for bugs: what each tool covers, the test plan (areas × kinds of
run), the bug log every finding goes into, and how a bug goes from a run to a fix thread. Started
2026-11-02 with Autopilot (F's ask: "make the test plan, start testing, add the places to a bug
log, then fix them one by one in separate threads").

## 1. What finds which bugs

| Layer | Tool | Finds | Runs where |
| --- | --- | --- | --- |
| Static | `tools/check_roads.py`, `check_map_data.py`, the `check_*.gd` scripts (`tools/verify.sh`) | road/deck rules, map counts, lane boxes overlapping colliders | cloud + Mac, every PR |
| Scripted drive | `game/tools/check_drive.gd`; the game's own `--autopilot` (missions, races, jobs) | fixed routes over bridges and tunnels, mission flows end to end | cloud + Mac |
| Looks | `tools/shots.sh`, screenshot-review skill, art-director | wrong-looking things at fixed spots | cloud (lavapipe) + Mac |
| **Free play** | **Autopilot** (`.claude/skills/autopilot-playtest`) | what a player meets off the scripted routes: stuck spots, dead stops, falling under the ground, clipping, menus and prompts that trap you | Mac only (Godot editor + Aura) |
| Feel and frame time | the iPhone (device-run skill), the user | touch feel, haptics, frame time, heat | the phone, with the user's yes |

Autopilot is the free-play layer: a decision model drives the real game in the editor inside a
harness that Claude writes from our code, like a curious player would. It doesn't replace the
checks; every bug it finds should end as a check or a fixed spot so it can't come back.

## 2. The test plan

A run is one row: an area, a kind and a time limit (10 minutes of game time unless the row says
otherwise). Areas follow the start outwards, the order a new player meets them (first 10 minutes
first, F's design goal). Mark the row's last run date and its result; re-run a row after each fix
in its area (the regression run).

Kinds (Autopilot's own): **explore** (drive/fly freely, report anything wrong), **test** (go
over one thing systematically: every kerb of a square, every ramp), **verify** (one claim, e.g.
"the unstuck button frees the car at X"), **goal** (reach a goal, e.g. finish the first mission).

| # | Area | Kind | What to look for | Last run | Result |
| --- | --- | --- | --- | --- | --- |
| P1 | Start: Plac Defilad, Marszałkowska, Świętokrzyska | explore | stuck spots, kerbs, tram islands, the Palace forecourt | 2026-11-02 (runs 1, 2) | PT-1 confirmed, PT-4 and PT-2 suspects, PT-3 closed; only Marszałkowska driven: next run forces the other streets |
| P2 | The first 10 minutes as a new player (title → language → guide stand → first job) | goal | prompts that trap, a step the guide never explains, a dead end | – | – |
| P3 | Śródmieście grid: Jerozolimskie, Nowy Świat, Chmielna, Krucza, Mokotowska | explore | stuck spots, invisible walls, parked cars that pin | 2026-11-02 (run 3) | partial: Jerozolimskie, Chmielna, part of Nowy Świat; the 4 framed stops were off the road (walls, a building corner: right to stop), PT-6 new; next: Krucza, Mokotowska, Świętokrzyska, Królewska one run each |
| P4 | Krakowskie Przedmieście, Plac Zamkowy, Old Town (the narrow streets) | test | every gate, bollard, the Castle Square slope | – | – |
| P5 | Bridges and ramps: Śląsko-Dąbrowski, Poniatowskiego, the W-Z tunnel, Wisłostrada | test | falling through decks, snapping heights, ramp ends | – | – |
| P6 | Powiśle and the river edge (boulevards, barges, the off-limits river) | explore | water tow, stuck at the embankment, under-deck entries (G6) | – | – |
| P7 | The map's edges (east yard, Gdańska, Wschodnia) | test | edge walls, falling off the map | – | – |
| P8 | The helicopter: take-off, landing on roofs, the rescue roofs | goal | landing on landmark roofs, clipping into towers | – | – |
| P9 | Menus: pause card, map, garage, settings, POMOC DROGOWA | test | a button that does nothing, a screen you can't leave | – | – |
| P10 | Police chase and the clamp; crash scenes | explore | a chase that pins the car, a scene that blocks a street for good | – | – |

**Budget.** The decision model bills to F's Aura account. One 10-minute row at a time; ask F
before more than three rows in one go or anything longer than 15 minutes.

## 3. The bug log

Every finding gets one row here, with an id that a fix thread, its PR and its branch use
(`PT-<n>`). A finding that isn't confirmed stays `suspect` and gets a `verify` run before anyone
fixes it.

Fields: **id** · **area row** · **place** (street or landmark, plus Godot world `--at=x,z` so
anyone can drive there: `godot --path game -- --nosave --at=X,Z --heading=H`) · **what happens**
· **severity** (S1 blocks progress or loses the car: stuck with no way out, falling under the
map, a crash; S2 costs the player time: a dead stop, a clip that needs the unstuck button; S3
looks wrong but plays) · **evidence** (the run id and trace/recording; Autopilot keeps runs in
`~/Library/Application Support/Autopilot/memory/Around Warsaw/runs/<run>/`; copy frames worth
keeping to `shots/autopilot/`, never into git) · **status** (suspect → confirmed → fixing (thread)
→ fixed (PR) → verified (the re-run)).

| id | Row | Place (`--at=`) | What happens | Sev | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| PT-1 | P1 | Marszałkowska, west kerb line just north of the start (`--at=-1019,-45 --heading=-20`; seen at x -1005..-1032, z -95..83) | 24-30 m/s to ~0 in under a second; the same line in 3 runs (run 1 once, run 2 three times); reversing frees it | S2 | runs 20261102-115157 trace1 t=19.8; 20261102-122308 `run2-events-all.jsonl` | confirmed (repeats); cause unknown: kerb, tram island or a traffic car |
| PT-2 | P1 | a block NE of Plac Defilad (run 1 kit x 360-430, y -280..380; Godot coords unknown) | ~10 near-stops in a minute; unsticks 1 → 23 over run 1 | S2 | run 20261102-115157 trace2 t=240-300 | suspect (run 2 never went there) |
| PT-3 | P1 | Dobra at the foot of the Powiśle escarpment (`--at=375,-396`) | the car 29 m below its start height | – | run 1 trace3 t=339; terrain there is -15.3 m, the car -14.6 m | closed (not a bug: low ground) |
| PT-4 | P1 | Marszałkowska by Rondo Dmowskiego (`--at=-807,494`; x -790..-860, z 406..494) | hard stops at 29, 20, 13, 15 m/s, then a full stop; reversing freed it | S2 | run 20261102-122308 episode 2 | suspect |
| PT-5 | P3 | side streets west of Marszałkowska (x -1690..-2960, z 30..415; worst `--at=-2447,205`) | 28 hard stops, 10 stucks freed in 1.6-8.6 s, while the agent wandered off its route | S3? | run 20261102-122308 `run2-events-ep1.jsonl` | suspect (low: off-route wandering) |
| PT-6 | P3 | the HUD, any street | the guide's speech bubble ("On your left! Left! ...") covers the minimap and the +/- buttons for ~4 s | S3 | run 20261102-125901 frames | confirmed (frames); check at phone size |
| R3 | P3 | Jerozolimskie by Plac Defilad (`-1053,235`, `-1117,248`), Szpitalna corner (`-584,154`), the excavation by Fangora (`-1141,27`) | hard stops at 108 km/h | – | run 20261102-125901 frames | closed (not bugs: 30 m off the road into a car park wall and a barrier, a building corner on a living street; at the pit the car follows the dug ground, the terrain grid doesn't) |

No run so far put the car under the ground (it stayed 0.7-1.0 m above the terrain at every
logged event in run 2).

## 4. From a run to a fix (the loop)

1. **Run** one plan row (Mac, autopilot-playtest skill). The harness logs every stop, clip and
   height jump with its position; frame-describer describes the frames at each.
2. **Log** each finding above as `suspect`, with its evidence.
3. **Confirm**: reproduce it once, cheapest first: drive there with `--at=`, or a `verify` run, or
   a check (`check_drive.gd --debug=X,Z`). Confirmed → S1/S2/S3. Not reproducible after two tries
   → `closed (no repro)` with the reason.
4. **Triage**: S1 first, then S2 by how early a player meets it (row order), then S3. Message the
   coordinator one confirmed bug at a time (or a batch of small ones on the same street); the
   coordinator starts **one fix thread per bug**, named after the place ("Fix the dead stop on
   Świętokrzyska").
5. **Fix thread**: prove the cause first (WORKFLOW "Prove the cause first"), fix, and add the
   spot to a check where one fits (`check_drive` routes, `check_roads` allow list, a new
   `--at=` shot), so the bug can't come back silently. The PR names the `PT-<n>` id and sets
   its status to `fixed`.
6. **Verify**: the next run of that row (or a `verify` run of that spot) sets `verified`, or
   reopens it.

Sources for the practice: bug triage (reproduce and enrich every report, severity by whether it
blocks progress, blockers first, triage after every phase: [HacknPlan, "The bug triage
process"](https://hacknplan.com/blog/the-bug-triage-process)); automated agents for coverage and
stuck/exploit spots in large maps (EA SEED, [curiosity-driven playtesting
agents](https://www.ea.com/seed/news/gameplay-testing-curiosity), [Augmenting automated game
testing with deep RL](https://arxiv.org/pdf/2103.15819)); exploratory test sessions with a charter
and a time box ([Exploratory testing strategies for video
games](https://sol.sbc.org.br/index.php/sbgames/article/view/27667)).
