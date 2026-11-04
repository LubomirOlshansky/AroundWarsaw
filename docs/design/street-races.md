# Street races: rivals that race

**Status (2026-11-04):** F picked the plan and asked for "the racers and the police smarter, then
test it with Autopilot". R1, R2 and R4's driving numbers are built ([section 6](#6-built-2026-11-04));
R3, R5-R7 are open.

Written 2026-11-04 from F's note: "driving with racers in the city looks strange. When the race
starts, a racer like Pani Halina drives very slowly, and even where there is a shorter road they
drive by the rules all the time. It doesn't look competitive or fun." Research and a plan only:
no game code changed with it. Part of the driving-first work (docs/GAMEPLAY_PLAN.md); it does not
touch `car.gd` or the roads, so it can run beside GAMEPLAY_PLAN phases 1-3.

1. [What arcade racers do](#1-what-arcade-racers-do-to-make-rivals-feel-competitive)
2. [What our rivals do today](#2-what-our-rivals-do-today-the-code-audit) (the numbers)
3. [The plan](#3-the-plan-r1-r7): R1-R7
4. [First fixes to pick](#4-first-fixes-to-pick)
5. [Tests](#5-tests)

---

## 1. What arcade racers do to make rivals feel competitive

The sources are listed at the end of the section; the rest is common practice in the genre.

| Rule | What it means |
| --- | --- |
| **Race close, not fair.** The best races are decided in the last third. | Rubber banding (dynamic difficulty) keeps the pack within reach: rivals behind get a little faster, rivals far ahead ease off. Mario Kart, Burnout, Need for Speed and Midnight Club all do it; Black Rock (Pure, Split/Second) built theirs around "close racing" and argued against crude versions. |
| **Hide the band.** Players hate a rival who is visibly faster than physics allows. | Push the band hardest when the rival is off screen or far away; on screen, a rival never goes faster than the player's car could, and the boost reads as skill (a better line, a shortcut, a late brake), never as a rocket. Cap it, and let a really good drive win clearly. |
| **Rivals drive like racers, not like traffic.** | Full throttle, late braking, racing lines through corners, weaving round traffic, using the whole road, the pavement, the oncoming lane. In open-city racers (Midnight Club, NFS Most Wanted, Burnout Paradise) the AI runs reds, cuts corners and takes the alleys; traffic is an obstacle for everybody, not a rulebook. |
| **Rivals know shortcuts.** | Open-world races are about route choice. AI racers use authored shortcuts (alleys, car parks, plazas, ramps); in the best games some rivals know more of them than others, which makes the player want to learn them too. |
| **Personality.** | Each rival drives differently and readably: the aggressive one rams and blocks, the careful one brakes early, the show-off drifts, the pro takes the perfect line. Forza's Drivatars carry a driver's aggression and line; Burnout's rivals are told apart by how they fight. |
| **Mistakes make them human.** | A rival who sometimes overshoots a corner, clips a bin or spins after a bump gives the player a chance to pass and something to laugh about. Mistakes near the player are worth more than mistakes off screen. |
| **Show the race.** | The player always knows where the rival is and how far: an arrow or a marker, the gap in seconds, a line when the lead changes, a close finish shown as close. Without it, a good race feels like an empty drive. |
| **Lose gracefully, start fairly.** | Rivals never wait at the start for no reason, never stop for nothing, and never queue behind the player's bumper; they pass. |

Sources:
- [Black Rock Studio blasts "rubber banding" (MCV)](https://www.mcvuk.com/development-news/black-rock-studio-blasts-arubber-bandinga/)
- [The Pure Advantage: Advanced Racing Game AI (Game Developer)](https://www.gamedeveloper.com/design/the-pure-advantage-advanced-racing-game-ai)
- [Rubber banding as a design requirement (Game Developer)](https://www.gamedeveloper.com/design/rubber-banding-as-a-design-requirement)
- [AI Madness: using AI to bring open-city racing to life (Game Developer, Midnight Club)](https://gamedeveloper.com/programming/ai-madness-using-ai-to-bring-open-city-racing-to-life)
- [How to fix racing AI rubber banding feeling unfair (Bugnet)](https://bugnet.io/blog/how-to-fix-racing-ai-rubber-banding-feeling-unfair)
- [Forza Horizon 2: What's a Drivatar (Xbox Wire)](https://news.xbox.com/en-us/2014/09/30/games-forza-horizon-2-drivatars/)
- [Burnout Revenge designer diary #2 (GameSpot)](https://www.gamespot.com/articles/burnout-revenge-designer-diary-2/1100-6132331/)

---

## 2. What our rivals do today (the code audit)

A race rival is an ordinary traffic driver (`traffic.gd` Driver) with a route: `rivals.gd` calls
`traffic.race_to(d, finish, dist)` and raises its `speed_factor` and `accel_factor`. Everything
else is the town car's behaviour. Checked on main `ac51e1c`.

| What | Today | Effect on screen |
| --- | --- | --- |
| **Top speed** | road limit × pace (`traffic.gd _drive`: `v0 = e_speed × speed_factor`). Pace from `ladder.gd`: Halina 1.25, Słoik 1.3, Bartek 1.35, Seba 1.4, Zbyszek 1.45, Mike 1.5. Road limits are 9.7 m/s on residential streets and 13.9 m/s on main ones (`bake_osm.py TRAFFIC_SPEED`, or OSM's maxspeed). | Halina does 62 km/h on Marszałkowska and 44 km/h on a side street; Mike 75 km/h at best. The player's car tops 108 km/h (`car.gd max_speed` 30 m/s, more with tuning and nitro). |
| **Acceleration** | IDM, `ACCEL` 2.2 m/s² × accel 1.5-1.75 = 3.3-3.9 m/s². | The player's car pulls 15 m/s² (`car.gd accel`). After every corner and light the rival crawls back up to speed: 4-5 s to 60 km/h. |
| **Corners** | the town car's turn speed: `v_turn = lerp(16, 5.5, turn/1.6)` m/s, braking for it from DECEL 3.5 × 0.6. | A right angle at 20 km/h, braking from far before it, like a learner. |
| **Red lights** | `run_red` rolled per junction: 60 % runs it, 40 % stops and waits the whole cycle. | Races are lost to a light, at random, in plain view. |
| **Crossing cars, trams** | yields like traffic (`cross_gap`, `sees_tram`); gives up after 8 s stuck. | Stops in the junction for any car crossing its path. |
| **Traffic ahead** | follows it (IDM gap 1.1 s + 2.2 m); `_overtake` changes lane only on a multi-lane road with 10 m of room, not within 18 m of a junction. On a one-lane street it queues. | Stuck behind a bus on Nowy Świat. |
| **The player's car ahead** | treated as a car in the lane: it keeps a gap behind it and never goes round it while racing (the go-round is for town cars only). | The rival sits on your bumper instead of fighting for the lead. |
| **Route** | the shortest legal path by length over the lane graph (`lane_graph.distances_to`), one-way rules kept, chosen per junction. | Never the oncoming lane, never a plaza, a car park or a pavement, while the player cuts through all of them. Shortest by metres, not by time: it happily takes a slow residential street. |
| **The first race** (Halina to the Palm, `rivals.gd first_band`) | a band that holds her **25 m behind the player**: pace 1.15 ± 0.012 per metre off that gap, clamped 0.4-1.5; in the last 140 m she drops to 0.32 if the player is close. She also waits at the line until the player moves. | This is exactly F's "very slow": she is told to stay behind you, so she dawdles at 0.4-0.85 of the speed limit and never leads. There is nothing to chase. |
| **Later races** | no band at all: a fixed pace. | A player who knows the city wins by a minute; one who gets lost can't catch up. Neither is close. |
| **Personality** | none in the driving; the six rivals differ only in pace, car and lines. | Every rival drives the same, politely. |
| **Showing the race** | the status card: 1ST/2ND and "Halina 80 m behind"; a tag over the rival's car; rival dots on the minimap (`hud.gd`). | Fine, but no screen-edge arrow to the rival, no lead-change line, no gap in seconds. |

**In short:** the rivals are town cars with a slightly heavier foot. They are 40 % slower than
the player at the top, four times slower off the line, brake for every corner like traffic, stop
for 40 % of reds and for every crossing car, queue behind buses and the player, and take only
legal roads. The first race goes further and tells Halina to stay behind.

---

## 3. The plan: R1-R7

Each item is one PR. R1 and R2 are the feel; R3 and R4 the fun; R5 the drama; R6 and R7 polish.

### R1. Racer driving mode (the biggest change)

A new driver mode in `traffic.gd` for a driver with a race route (`d.racer`), so town cars are
untouched:

- **Speed by the car, not the sign.** Race top speed = the player's car top speed × the rival's
  `share` (R4: 0.72 Halina ... 0.9 Mike, 0.92 Seba in the final), capped by road class (main
  30 m/s, secondary 26, residential 18, living street 12) so they don't do 100 on Chmielna.
- **Pull like a sports car.** Race acceleration 7-10 m/s² (by rival), braking 9 m/s².
- **Corners by their shape.** Corner speed from the curve's radius: `v = sqrt(a_lat × r)` with
  a_lat about 7 m/s² (the connector bezier gives r), and braking late (full race brake, not 0.6 ×
  3.5). A right angle on a city junction then goes at ~30-35 km/h instead of 20.
- **Reds and crossings.** A racer goes through every red, slowing to `share × 60 %` only when a
  crossing car is really in its path in the next second (it swerves inside its lane, the `off`
  slide we already have for shoves). No waiting for crossing cars; trams still win (a racer
  brakes hard for a tram's body, and the miss is a good moment).
- **Traffic.** Overtake on any road: on one lane, into the oncoming lane when the next 40 m are
  free, or squeeze past on the kerb side (the `squeeze` mechanism, visible this time). Town cars
  honk at it.
- **The player.** A racer behind the player goes round (same overtake rules), never sits on the
  bumper. A racer ahead may block (R4 aggression).
- **No waiting.** The first race's start hold stays (it is the tutorial), but shorter (6 s, not
  12) and she rolls slowly off the line instead of standing.

Cost: one driver at a time in a race, a few more checks per frame for it; no new draw calls.
Check `check_race_ai.gd` (section 5).

### R2. A fair rubber band (the race is close)

- **The first race:** replace "stay 25 m behind" with "lead, then be caught": she starts ahead
  and keeps a target gap that moves from 30 m ahead (the first half) to level (the last third),
  so the player has someone to chase and passes her near the Palm. The last-stretch ease stays
  (a new player still wins), but from a lead, not from behind.
- **Every race:** a band with the rival's own strength (R4): behind the player by more than 60
  m, up to +12 % speed; ahead by more than 120 m, down to -15 %. Applied mostly when the rival is
  off screen (`d.visible` false); on screen at most ±5 %, and never above the player's top speed.
  Strength falls up the ladder (Halina strong, Mike weak, the final small), so the hard races
  are won by driving.
- Log the band's working (`--race-log`): time ahead/behind per second, for tuning.

### R3. Routes and shortcuts

- **Route by time, not length.** `distances_to` gets a cost option: edge length / the racer's
  speed on it + a junction turn penalty (seconds). Racers prefer main roads; a short slow
  side street is taken only when it really saves time. One more Dijkstra per race finish (cached
  as today).
- **Rule-bending links** by personality: racers with `wrong_way` may use one-way edges backwards
  for up to 150 m (a second cost table with those edges added at a 1.3 × cost), and bus lanes /
  tram tracks where the bake has them.
- **Authored shortcuts** (`game/data/race_links.json`, a bake-free list like the portals): a
  short polyline across a plaza, a car park, a petrol station, a pavement cut, each with its two
  lane-graph ends. A racer follows the polyline like a junction curve. Start with 10-15 in the
  race finishes' areas (Plac Defilad round the Palace, the Złote Tarasy forecourt, the Centralna
  bus bay, the Rondo ONZ car park, Powiśle's station forecourt, the Kopernik plaza). Each one is
  checked by `check_race_ai` (no collider in the polyline's corridor). Zbyszek knows all of them,
  Słoik none (he follows his satnav), the rest some.
- The finish line of a race shows the rival's shortcut once (a dashed line on the minimap after
  a loss: "Zbyszek pojechał przez parking"), so the player learns the city.

### R4. Personalities

One table in `rivals.gd` (per rival, read by R1-R3):

| Rival | share | accel | band | reds | wrong way | shortcuts | aggression | mistakes | Style |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Pani Halina | 0.72 | 7 | strong | all ("the bazaar!") | no | 2 | none | late brakes, wide corners | flat out on straights, terrible in corners: the player passes her on a bend |
| Słoik z Radomia | 0.75 | 7.5 | strong | stops for some | never | none | none | one wrong turn a race (satnav: "zawróć") | the legal route, carefully, then panics |
| Bulwar Bartek | 0.8 | 8 | medium | all | short | some | low | drifts, slides wide | the show-off: drifts every corner, bass you hear coming |
| Seba z Pragi | 0.85 | 8.5 | medium | all | yes | some | high: blocks, nudges | spins after a hard bump | blocks your line, rams once a race |
| Taksiarz Zbyszek | 0.88 | 8.5 | weak | all | yes | all | medium | none | bus lanes, tram tracks, every shortcut: the route master |
| Mordor Mike | 0.9 | 9.5 | weak | all | short | some | low | phone call: brakes for a second, once | the fastest car, the cleanest line |
| Seba (Trzy mosty) | 0.92 | 9 | small | all | yes | all on the route | high | rare | the final boss |

"Aggression" uses the existing shove code: a racer alongside the player with `aggression` steers
its `off` into the player's side (a nudge at most 3 m/s across, never a wreck), once per N
seconds. Mistakes are rolled per corner and only near the player's view, so they are seen.

### R5. Show the race

- A screen-edge arrow for the rival in its colour when it is off screen (the race already has
  one for the finish; the minimap dot exists).
- The gap in seconds (+2.4 s / -1.1 s) on the status card instead of metres.
- A lead-change moment: a short line from the rival ("Ej!") and a haptic tick, through the
  chatter budget's `quest` class.
- Slipstream: right behind the rival at speed for 1.5 s, the player gets a small pull (+5 %)
  and wind lines: a reason to stay close.
- A close finish shows as close: the result card says "o 0,8 s" (by 0.8 s).

### R6. The city reacts

Traffic honks and swerves (the existing near-miss) when a racer passes; a police unit on the
route may give chase to the rival, not only the player (police.gd target choice), once a race at
most; pedestrians jump back on crossings (crowds' existing scatter).

### R7. Race kinds (later, after R1-R5 feel right)

A sprint (as now), a checkpoint run through 3-4 places, and a "first to X, any route" with no
arrow for Zbyszek's rung. Not before R1-R5.

---

## 4. First fixes to pick

The recommendation for F, in order:

1. **R1 racer driving mode**: full race speed and acceleration, real cornering, through reds,
   past traffic and past the player. This alone answers "drives very slowly and by the rules".
2. **R2 fair band**: the first race with Halina in front to chase; every race close in the last
   third, the band hidden off screen.
3. **R3 part 1, route by time and wrong-way hops** for the rivals who would (no authored data
   yet); the authored shortcuts are part 2.
4. **R4 personalities**: the table above, cheap once R1 exists.

R5 (gap in seconds, the rival's arrow, slipstream) is small and could ride with R2. R6-R7 later.

Model: R1-R3 are gameplay feel and route code (Opus); R4's numbers and lines and R5 are Sonnet
once R1 is in. Each is a full definition of done (verify, shots of a race, bench, and the phone
feel on F's next device run).

---

## 5. Tests

- `game/tools/check_race_ai.gd` (new, joins `tools/verify.sh`): on the map pack, a racer from a
  fixed spot to each finish with no player: no stop longer than 1 s, mean speed at least 60 % of
  its race top, every red passed, no collider hit (the lane corridor), route time within the
  table's window per rival. Then the band: a scripted player ghost at 70 % and 100 % of the car's
  top; the race ends within ±6 s for Halina and the ghost at 100 % wins Mike's race by less than
  10 s.
- `check_first10.gd`: the first race keeps its rules (she leads in the first half, a 70 % ghost
  still wins).
- Autopilot row P17 in PLAYTEST.md: "race Halina and Zbyszek; did it feel close; did a rival get
  stuck or look silly" (with F's yes for a run).
- Bench before/after with a race running (one driver, so expected flat).

---

## 6. Built (2026-11-04)

**R1 racer mode** (`traffic.gd`, a driver with a race route and `race_accel` > 0; town cars are
untouched):
- top speed `race_top` (the player's car top × the rung's `share`) × the rubber band, capped by
  road class (`RACE_CLASS_TOP` 30 / 25 / 19 / 12 m/s for main, tertiary, residential, living);
- `race_accel` 7-10 m/s² (was 3.3-3.9), braking `RACE_DECEL` 8 m/s², headway 0.6 s;
- junction curves at `sqrt(race_lat × radius)` (`race_turn_speed`), at least 6 m/s;
- every red run (a little slower in the box, 75 % within 30 m of the line), crossing cars only
  within 7 m, and a wait for them cut from 8 s to 1.5 s;
- past traffic and the player: a free lane, even near the junction when standing in a queue;
  else out over the centre line when the oncoming lane is clear for 70 m (two-way roads only);
  stood 2.5 s behind a car with no way past (a knot in a junction box), it slips through.

**R2 rubber band** (`rivals.gd`):
- the first race: Halina paces off the player's own progress along the route
  (`first_speed`): 30 m in front for the first half, caught by 85 % of the way, lifts off for a
  close player on the last 140 m; `check_first10` models it (an ordinary 34 km/h driver: she
  leads at half way, he wins by 1.1 s);
- every other race (`band_mult`): a mix, by the rung's `band` weight, of her flat-out pace and
  the pace that holds her `aim` m behind the player; on screen never faster than her top or
  slower than half of it, off screen up to +30 % × weight faster or down to 0.3; never over 98 %
  of the player's top. The bottom rungs (band 0.5 and up: Halina, Słoik, Bartek) lift off on
  the last 140 m for a player less than 80 × band m behind.

**R4 numbers** (`ladder.gd` RUNGS, `racer()`):

| Rung | share | accel | corner grip | band | aim |
| --- | --- | --- | --- | --- | --- |
| Pani Halina | 0.72 | 7 | 5.5 (timid in corners) | 0.8 | 25 m behind |
| Słoik z Radomia | 0.75 | 7.5 | 6.5 | 0.65 | 15 m behind |
| Bulwar Bartek | 0.86 | 8 | 8 | 0.5 | 8 m behind |
| Seba z Pragi | 0.9 | 8.5 | 8 | 0.4 | level |
| Taksiarz Zbyszek | 0.92 | 9 | 8.5 | 0.3 | 5 m ahead |
| Mordor Mike | 0.94 | 10 | 8.5 | 0.25 | 10 m ahead |
| Seba, Trzy mosty | 0.95 | 10 | 8.5 | 0.15 | 10 m ahead |

Aggression, mistakes, wrong-way hops and authored shortcuts (the rest of R3/R4) are not built.

**Police** (`police_unit.gd` `_racer`): a chaser drives in racer mode with `CHASE_RACE_ACCEL` 6
m/s² (was 2.6) and `CHASE_LAT` 6.5, careful through reds instead of 30 km/h, round traffic that
doesn't give way, but never round the player (it keeps its 10 m gap and never rams) and its top
speed stays `chase_top` (0.8 of the player's), so a flat-out run still escapes.

**Measuring** (`tools/race_ai.sh`, `--ghost-pace`, `--race-debug`): every rival races the
autopilot as an average driver (`--ghost-pace=1.8`: the town car's corners, 1.8 × the limit)
and as a skilled one (`--ghost-pace=racer`: racer mode at the car's own top). Results in
section 7.

---

## 7. Results (2026-11-04)

Headless, `tools/race_ai.sh`, the same start spots and finishes (one run each; a gap > 0: the
player won by that many metres). Before: on main `ac51e1c` the average driver beat Halina,
Bartek and Mike (the only ones run).

| Rival | Average driver (`--ghost-pace=1.8`) | Skilled driver (`--ghost-pace=racer`) |
| --- | --- | --- |
| Pani Halina (884 m) | player by 22 m | player by 192 m |
| Słoik z Radomia | player by 13 m | player by 103 m |
| Bulwar Bartek | Bartek by 26 m | player by 185 m |
| Seba z Pragi | Seba by 43 m | player by 238 m |
| Taksiarz Zbyszek | Zbyszek by 687 m | player by 25 m |
| Mordor Mike | Mike by 334 m | player by 73 m |

(Bartek, Seba and the first two average rows are from the last tuning runs; Bartek and Seba got
a little faster after their average rows.) Rivals now stand still for 0.1-2.8 s a race (was up
to 31 s in the first version: queues at reds and knots in junction boxes, fixed by the lane change
near the junction, the curve's knot rule and RACE_KNOT).

**Autopilot on F's Mac** (P17, 2026-11-04, runs 20261104-115030, -120021, -120641): an AI
player beat Halina by 155 m in 44.9 s (she averaged 57 km/h, top 78 km/h, looked like racing,
nothing driven through) and Zbyszek by 151 m in 54.8 s (he averaged 62 km/h, top 99 km/h, led by
6-60 m until 38 s). Halina stood 3.5 s once at -827, 487 (the junction knot by Marszałkowska;
RACE_KNOT cut from 2.5 to 1.5 s after it). The police chase was not escaped, but the agent drove
at 2-18 km/h three times, so it says little; the chaser followed the player's turns one junction
inside, with no stops. The headless escape run (`verify.sh --only=police-runs`, P3) is the check.

**Open for the phone:** whether Halina and Słoik still feel too easy for F (the Autopilot player
won by 150 m), the mid-ladder for a skilled player (Bartek, Seba), and the chase's escape feel.
