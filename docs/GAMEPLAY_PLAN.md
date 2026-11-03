# Gameplay plan: the best driving experience first

Written 2026-11-03 from F's playtest on the iPhone (13:22, nine screenshots and four photos of
Chmielna 89). F: "the map and buildings are good now; with priority, I want to make the driving
the best experience". This is research and a plan only: no game code changed with it.

What it covers, in F's order of priority:

1. [Driving](#1-driving-what-good-arcade-driving-does-and-where-we-stand): what arcade games do,
   where our car, camera and roads stand, an audit of the road network, an algorithm to improve the
   roads and the driving on them, and test cases for the Autopilot playtester and the headless checks.
2. [Dialog spam](#2-too-much-on-screen-the-chatter-budget): one shared budget for every bubble and toast.
3. [Visual bugs from the playtest](#3-the-playtests-visual-bugs-causes-and-fixes): likely cause and fix for each.
4. [Chmielna 89 "Piramida"](#4-chmielna-89-the-piramida) for the landmark backlog.
5. [The order of work](#5-the-order-of-work), with the tasks that suit Codex marked.
6. [Threads and PRs open today](#6-what-is-open-today-threads-and-prs) and what to finish first.

---

## 1. Driving: what good arcade driving does, and where we stand

### 1.1 What the reference games do

Top-down and isometric city drivers (GTA 2 and Chinatown Wars, Micro Machines, Art of Rally's
high camera) and arcade racers (Crazy Taxi, Burnout, Mario Kart) share a handful of rules. The
sources are at the end of the section; the rest is common practice in the genre.

| Rule | What it means for us |
| --- | --- |
| **The player sees the road ahead before they need it.** | Look-ahead in the direction of travel, wider at speed, and never a camera that hides the car (bridges, towers). Art of Rally's whole feel changed with a small change of camera angle: the camera *is* the handling on a small screen. |
| **Walls redirect, they don't stop.** | A glancing hit keeps most of the speed and turns the car along the wall; a head-on hit bounces back a little and never pins. Mario Kart and Burnout never leave you stuck against scenery. |
| **Assist the intention, not the input.** | Light steering assists: a small pull towards the lane's direction when the stick is near the middle, and steering that avoids a wall the car is about to brush. Strong at low skill (Mario Kart's smart steering), off for experts (a setting). |
| **Forgive the small stuff.** | Kerbs, posts, cones, corners of parked cars: the car slips past them. Only big, readable things block. |
| **Clear, wide, predictable roads.** | Track designers widen corners, round off kinks, and keep the racing line free. In a real city we can't move streets, but we can round collision corners, bevel pockets, close the dead ends you can't turn in, and keep the carriageway free of solid clutter. |
| **One message at a time.** | The screen talks only when it has something to say; reactions to the player's own mistakes are rare and short. |
| **Never a soft-lock.** | Every state has a way out within seconds: a tow, a reset, a respawn on the road. |

### 1.2 What we already have (and it is a lot)

The car and camera already follow most of those rules. Before planning new work, this is the base
(all on main, 2026-11-03):

- **Handling** (`car.gd`): Cruise (default) and Sport profiles (G4), speed-dependent steering
  limit (loop 2a), point-to-steer with yaw damping, a sensitivity slider.
- **Walls**: slide along keeps speed, glancing hits turn along, head-on push back, pinned 1.5 s is
  turned out, pinned twice is towed (loop 2a); front-corner slip past posts and car corners
  (driving-feel loop); PT-1 scrape scaled by how hard the car presses in.
- **Small props**: benches, bins, bike racks, columns have no colliders (easy-driving loop).
- **Traffic**: hit cars are shoved, not stopped dead; held against traffic 1.5 s the car ghosts
  through for 3 s; 8 s among cars and it is towed (G17).
- **Map pockets**: walls across slits, notches and facade bays (`_bridge_pockets`, PT-7, PT-17).
- **Ramps**: entering a ramp at an angle climbs on, not under (G6).
- **Stuck**: POMOC DROGOWA on the pause card, and offered on screen after 8 s stuck (G14).
- **Camera** (`follow_camera.gd`): critically damped turn capped at 64°/s, look-ahead along the
  way the car goes, dead zone, speed zoom, five zoom steps; the occlusion ghost dithers towers in
  front of the car; the tunnel x-ray shows the car through the ground in a tunnel.
- **Checks**: `check_roads.py` (C1-C11: grades, joints, clearance, piers, solids on lanes, deck
  ends, lane heights, landmark colliders), `check_drive.gd` (fixed routes, every ramp foot),
  `check_steering.gd`, `check_handling.gd`, `check_stuck_spots.gd` (every PT spot),
  `check_stuck_offer.gd`.

So the next gains are not in the car's physics alone. They are in four places nobody has measured
end to end yet: **(a)** how drivable each street is for the *player's* car (the checks measure
geometry and fixed routes, not every lane and every turn), **(b)** a steering assist that keeps
the car on the road without the player fighting it, **(c)** the camera in the hard places (under
decks, flying high), and **(d)** the noise on screen while it happens.

### 1.3 Road network audit (centrum.json, today's main)

Read with a small script over `game/map/centrum.json`'s lane graph (no game run):

| Measure | Value | What it means |
| --- | --- | --- |
| Directed edges / nodes | 4,710 / 2,902 | 337 km of directed lane centreline |
| Classes | residential 1,821, tertiary 1,311, secondary 853, living street 341, primary 115, links 206, unclassified 63 | no trunk or motorway class: Trasa Łazienkowska and Wisłostrada are `primary` |
| Nodes outside the main strongly connected part | **101** (59 unnamed, Widok 7, Śniadeckich 6, Warecka 6, Natolińska 4, Sempołowskiej 4) | traffic never goes there and a tow or teleport can land the car in a pocket it can't leave by road |
| Dead-end nodes | 365, **251 away from the map's edge** (edges: residential 260, living street 159, tertiary 19, secondary 7, primary 2) | each is a place a player drives into and has to turn round; most are courtyards and service ends |
| Junction nodes (3+ neighbours) | 1,242; 1,292 nodes are plain joins (2 neighbours) | |
| Edges under 6 m | 118 | very short pieces round junctions: where lane heights and kerbs tend to step |
| Kinks over 45° inside one edge (not service) | 15 (Smulikowskiego 91° at 514,-390; Trybunalska 90° at -1535,1640; Dowcip 89° at -698,-367; Kryniczna 86°; Chłodna 82°; Platynowa 77°; Olszowa 76°) | corners with no fillet: the car's line clips the kerb or wall at the corner |
| Lane widths | 1.5 m ×118 and 2.2 m ×182 (100 of those unnamed living streets; also Frascati, Hoża, Ordynacka, Aleja 3 Maja, Sienna) | narrower than the car's 1.8 m plus margin: these streets feel like threading a needle |
| Bridges and decks | 85 deck edges (Most Łazienkowski 18) | |
| Tunnels | 11 edges: Tunel Wisłostrady (2 × ~730 m), Aleja Armii Ludowej (under Trasa Łazienkowska's junction, 4), Solidarności (2 × 195 m), Karowa (2) | the teleport bug below lands on these |

What the existing checks don't measure: whether the player's car (1.8 × 4 m, the real `car.gd`)
can drive every lane and every turn at its street's speed without touching anything. `check_drive`
drives fixed routes and ramp feet; `check_stuck_spots` drives the spots a playtest found. Nothing
sweeps the whole network, so every stuck spot so far was found by a person or Autopilot first.

### 1.4 The algorithm: measure every lane and turn, fix by defect type, keep it fixed

A loop that runs the same way for every street, so road quality stops depending on who played where.

**Step 1: the drivability sweep** (new `game/tools/check_drivability.gd`, headless, the real car
script and the real colliders of each sector, no traffic, like `check_stuck_spots`):

1. **Lanes.** For every directed edge and every lane: place the car at the lane's start, heading
   along it, at the street's speed (`v`, capped at 50 km/h on residential), and drive the lane with
   a scripted driver that follows the lane centreline (pure pursuit, 0.6 s look-ahead, the car's
   own steering limit). Record per 2 m: contact (wall, kerb jolt, scrape), speed lost, pinned,
   unstick, tow.
2. **Turns.** For every junction and every allowed in-lane → out-lane pair (the graph's turn
   curves): the same driver along the turn curve at a turn speed (20 km/h right turn, 25 km/h left,
   35 km/h straight on). This catches corners with no fillet, island noses, bollards and kerb steps.
3. **Dead ends.** For every dead-end node: can the car turn round within 3 three-point turns? If
   not, it is a trap.
4. **Edges of the drivable area.** Along every lane, sample the free width (raycasts across the
   lane to the first solid each side, at bumper height): the corridor the player really has.

Output: one JSON row per lane and turn (`pass`, the first contact's point, speed kept, free width
min), a per-street **drivability score** (share of metres driven with no contact and no speed
loss over 10 %), and a ranked list of the worst 50 spots with `--at=` views. Runtime: the network
is ~4,700 edges and ~4,000 turns; at 60 fixed fps and ~4 s each, about 20 minutes headless, so
it runs as a nightly or on-demand job (a `--area=` filter for a PR's own streets).

**Step 2: classify each failure** by what the car touched and where:

| Defect | How the sweep sees it | Fix (most automatic first) |
| --- | --- | --- |
| **Pinch**: free width < car width + 1.2 m on a lane | free-width sample | a non-solid prop in the carriageway goes non-solid or moves to the kerb (snap_props); a mapped kerb or platform that pokes into the lane is cut back to the carriageway's edge |
| **Corner clip**: contact on a turn within 3 m of a building or wall corner | turn run, contact on a concave or convex corner | a **forgiveness bevel**: the collider's corner nearest the road gets a 45° chamfer (1-2 m) so the car slides off; drawn walls stay as they are |
| **Pocket**: the car slides into a recess and is turned back and forth | lateral oscillation with speed loss | `_bridge_pockets` covers slits, notches and bays up to 30 × 2.5 m; widen its limits where the sweep still finds pockets |
| **Kink**: a heading change > 45° inside an edge on a road above living-street class | geometry (this audit found 15) | fillet the lane centreline with a radius from the street's speed (r = v² / 4 m/s², at least 6 m) in the bake; traffic drives it too |
| **Kerb step**: a kerb line crosses a lane, jolting the car at 3 % each time | kerb jolts with no contact | move the kerb to the carriageway's edge or drop it where it crosses a lane (driveways, junction mouths) |
| **Height step**: the car jumps or catches on a lip | vertical speed spike | `check_roads` C2/C8 already catch most; add the sweep's spots to its allow list or fix the joint |
| **Trap dead end**: no turn-round in 3 tries | dead-end test | soft gate at the mouth (bollards, a closed-gate model, not drivable) for courtyards and service ends; for public dead ends a turning circle of open ground |
| **Narrow lane**: lane width < 2.5 m on a public street | graph data (300 lanes now) | widen the lane offset to the carriageway's real width (the ortho), or mark one-way streets as one wide lane |
| **Off-network pocket**: node outside the main strongly connected part | graph data (101 now) | connect it (a missing OSM turn or a one-way that should be two-way) or exclude it from tows, teleports and spawns |

**Step 3: fix in batches by street**, starting with what the player drives most: the first 10
minutes' streets (Marszałkowska, Świętokrzyska, Jerozolimskie, Nowy Świat, Powiśle), then the
main line's race routes (Trzy mosty), then the rest of Śródmieście. One PR per street group, each
with its before/after score in the PR.

**Step 4: keep it fixed.** Every fixed spot joins `check_stuck_spots.gd` (as today) and the
per-street scores join a baseline file; CI fails a PR that lowers any main street's score by more
than 2 points (the map jobs already run on every PR).

### 1.5 Driving on the roads: the assists

Measured on the phone, one at a time, each behind a setting so F can feel it on and off.

1. **Lane assist** ("Asysta pasa", on in Cruise, off in Sport). When the car is on a lane
   corridor, above 15 km/h, and the steering input is small (stick or finger within 15 % of
   centre, or Point's target within 20° of the lane), the car's yaw eases towards the lane's
   tangent: `yaw_rate += k · err · w`, with k ≈ 1.5/s, err the heading error to the lane (only
   below 20°), and w fading to 0 as the input grows. It holds the car straight on long avenues and
   follows gentle curves (Wisłostrada, Trasa Łazienkowska, the bridges) with no input. It never
   overrides a deliberate turn. Data: `lane_graph.snap` with a heading (exists).
2. **Wall look-ahead.** Each frame, cast the car's box 0.5 s ahead along its velocity; if it hits a
   solid at a shallow angle (under 35°), add a small steer away (as if the player corrected late).
   A head-on wall gets no help (that's the player's choice). Costs one `test_move` per frame, only
   above 10 km/h.
3. **Junction pick.** Crossing a junction with small input, the lane assist chooses the out-lane
   whose direction is nearest the car's heading, so going straight through a skewed junction
   doesn't drift into the island.
4. **Gentler wall exits.** The pinned timer (1.5 s) and the corner slip already exist; with the
   sweep's numbers, tune the head-on push back so the car always rolls back far enough to steer
   out (now at most 1.2 m/s).
5. **Camera at junctions.** Lead the look-ahead towards the out-lane the assist picked a second
   before the turn, so the player sees the road they turn into.

How we know it's better: `check_steering.gd` gets lane-keep cases (a 1 km avenue with no input:
the car stays within 0.5 m of the lane; a gentle 300 m curve; a skewed junction), the sweep score
goes up with the assist on, and F's phone run on Cruise.

### 1.6 Test cases

**Headless (cloud and Mac, every PR or nightly)**, new and extended:

| Id | Check | Case |
| --- | --- | --- |
| D1 | `check_drivability.gd` | every lane at its speed, every turn, every dead end (1.4 step 1); score baseline |
| D2 | `check_steering.gd` | lane keep on a straight avenue (Marszałkowska), a curve (Wisłostrada), a skewed junction (Rondo Dmowskiego's approaches), each with the assist on and off |
| D3 | new `check_teleport.gd` | 200 random teleport points over the map plus the known bad spots (tunnel portals, under Trasa Łazienkowska, the Wisłostrada tunnel's roof, bridge heads): the car lands on a ground or deck lane, never in a tunnel or on a roof, and drives 3 s forward without a pin |
| D4 | `check_stuck_spots.gd` | add each spot this plan's fixes touch (as the PT rows do) |
| D5 | new `check_chatter.gd` | a scripted 60 s of being pinned against a wall with traffic and pedestrians near: at most 2 bubbles and 1 toast; 0 bubbles above 40 km/h except quest and police |
| D6 | `check_drive.gd` | under-deck runs: Trasa Łazienkowska over Wisłostrada and Aleja Armii Ludowej's tunnel; the x-ray or deck fade is on while under |

**Autopilot rows (Mac, free play; each under 6 minutes because the Mac kills runs at ~6 min)**,
added to docs/PLAYTEST.md section 2 as P11-P16:

| # | Area | Kind | What to look for |
| --- | --- | --- | --- |
| P11 | Trasa Łazienkowska and Wisłostrada, both ways, under and over | test | the car hidden under the deck, the tunnel portals, ramps, the lane assist on long curves |
| P12 | Teleport from the full map: 10 holds on tunnels, bridges, courtyards, the river bank | test | where the car lands; stuck on a tunnel or roof; heading against traffic |
| P13 | Get stuck on purpose: 60 s pressing into walls, parked cars, a tram island | test | how many bubbles and toasts per 10 s; how long until the tow offer |
| P14 | Narrow streets: Frascati, Hoża, Ordynacka, Sienna, Aleja 3 Maja, the living streets | explore | pinches, kerbs that jolt, dead ends with no turn-round |
| P15 | The helicopter high: climb to the top over Varso, the Palace, the map edge | test | sky and void past the edge, floating buildings, where the heli sits on screen |
| P16 | Trzy mosty race route at full speed | goal | every contact at race speed, the camera's look-ahead on the bridges |

**On the phone (F, with his yes):** Cruise vs Sport with the lane assist on and off on
Marszałkowska and Trasa Łazienkowska; the under-deck fix; the chatter budget while stuck.

Sources for 1.1: [Implementing racing games: approaches and their design trade-offs](https://gamedeveloper.com/design/implementing-racing-games-an-intro-to-different-approaches-and-their-game-design-trade-offs),
[The fundamentals of arcade-style racing track design](https://gamedeveloper.com/design/feature-the-fundamentals-of-arcade-style-racing-track-design),
[A rational approach to racing game track design](https://gamedeveloper.com/design/a-rational-approach-to-racing-game-track-design),
[A top-down view camera system for a racing game](https://gamedeveloper.com/game-platforms/let-s-talk-about-top-down-view-camera-system-for-a-racing-game),
[How a small change in camera angle transforms Art of Rally](https://jalopnik.com/how-a-small-change-in-camera-angle-completely-transform-1849152549).

---

## 2. Too much on screen: the chatter budget

**F:** "when I'm driving and getting stuck, each second a few or more dialogs. Reduce it; not
every collision makes a comment."

**Why it happens.** About 25 scripts speak through `bubbles.gd` and `hud.toast`, each with its
own cooldown and nobody counting the total:

- `dialogue.gd` traffic shouts (9 s gap, on every bump and block), the radio host;
- `city_life.gd` (10 call sites: near-miss "pędzik" lines, dog walkers' horn and tiny-dog lines,
  cyclists' lane line, runners, Kolka), `crowds.gd` (club doors, queues, viral, office, police
  club), `packs.gd`, `fans.gd`, `storefronts.gd`, `buses.gd`, `loud_cars.gd`, `crash_scenes.gd`;
- quest scripts (`rides.gd` 10, `jobs.gd` 8): a passenger's "−½ ★ · stłuczka" toast on a bump
  (one per DRIVE_GAP), the słoiki jars;
- `police.gd` on a bump near a patrol.

The only global rule is G16's: **ambient** bubbles are muted **above 40 km/h**. Getting stuck is
exactly the slow case, so everything is allowed at once: the driver you hit shouts, the passenger
toast fires, a dog walker and a runner nearby comment on the horn and the near miss, and a crowd
line comes up, all inside a second or two. The screenshot at Marszałkowska shows a dog walker's
line at 0 km/h next to the job card.

**The fix: one budget in `bubbles.gd` (and the toast queue in `hud.gd`) that every speaker goes through.**

1. **Priorities.** Every line carries a class: `quest` (job, ride, rescue, rival, guide), `police`,
   `reaction` (someone reacting to the player: shouts, near misses, bumps, horns), `ambient` (city
   chatter, crowds, packs, the radio host's bubble).
2. **Rate cap.** At most **1 new bubble every 4 s** and **2 on screen**; `quest` and `police` may
   jump the cap but not the 2-on-screen limit (an ambient one makes room).
3. **Reactions are rare.** The first collision in a 20 s window may draw one `reaction`; the rest
   draw nothing. Collisions under 15 km/h draw nothing. A near miss draws a line at most once a minute.
4. **Quiet while stuck or struggling.** While the car is pinned, scraping, being turned out, or
   the stuck offer is up, and for 5 s after: `ambient` and `reaction` are dropped (not queued).
   `quest` lines that are about the stuck (the tow offer) still show.
5. **Quiet during cards.** While a job card, a ride card or the full map is up, `ambient` waits.
6. **Toasts.** The passenger's star toasts merge: one "−1 ★ · stłuczki" after the bumps stop for
   3 s, not one per bump.
7. **A setting.** Settings → Świat → "Gadatliwość miasta" (city chattiness): Mało / Średnio
   (default) / Dużo, scaling the gaps (8 s / 4 s / 2.5 s).

Check: D5 above (`check_chatter.gd`), plus `check_hud` for overlap. Small and self-contained: a
good first Codex task.

---

## 3. The playtest's visual bugs: causes and fixes

### 3.1 The helicopter high up: map edge, blue sky, floating buildings, heli at the top of the screen

**Seen:** at 236-360 m above the ground the far part of the view ends in flat blue; buildings
near the top edge stand on nothing ("floating"); the helicopter sits at the top of the screen.

**Causes (from `main.gd` `_update_camera`, `_camera_far`, `heli.gd`):**

- `Heli.MAX_HEIGHT` is 360 m above the ground (to clear Varso's spire). The camera aims halfway
  between the helicopter and its shadow (`focus.y -= heli.height_above * 0.5`) and widens 0.8 m
  per metre over cruise. At the camera's 30° pitch, the helicopter and its shadow are
  h·cos 30° ≈ 0.87·h apart on screen: at 300 m that's ~260 m of screen with the helicopter
  half of it above the centre, so it rides at the top edge.
- The far plane: an orthographic camera at a 30° pitch sees the ground at the top of the screen
  ~2× the view height further away than the centre. `_camera_far` adds `FAR_MARGIN` (130 m) plus
  the helicopter's height, but the top edge's ground is further than that at the widest heli views,
  so the ground there is clipped while the taller buildings' upper floors (nearer the camera) are
  not: **floating buildings over the sky colour**.
- Past the far plane and past the map's edge ring (`map_edge.gd`) there is only the clear colour.

**Fixes (in this order):**

1. Frame the helicopter, not the halfway point, when high: the aim's share of the height falls
   from 0.5 at cruise to ~0.15 at 150 m and up (the shadow leaves the view, which is fine that
   high). Keep the helicopter in the middle third of the screen.
2. Cap the view's widening (the 0.8 m per metre) at the widest view the far plane covers, and
   compute the far plane from the screen's top edge ray, not the centre's (the ground at the top
   edge is `distance + size / (2 tan 30°)` further).
3. Lower `MAX_HEIGHT` to the tallest roof under the helicopter plus 60 m (Varso's spire 310 m is
   the only one needing 360 m), so over most of the city the heli tops out at ~200 m.
4. A horizon haze: the sky colour fades in over the last 15 % of the far plane (in the ground and
   building shaders, the same way `edge_haze` fades the map edge ring), so whatever is cut fades
   instead of ending in a hard line.

Check: P15 on the Mac; a `--heli-height=` screenshot set at 100/200/300 m over the Palace, Varso
and the east edge.

### 3.2 The blue crowd near the rondo

**Seen:** a tight column of ~20 people in the same blue by the junction near the start.

**Most likely:** a running club from `packs.gd` (F's 2026-11-01 ask: TEMPO NA KAWĘ, KILOMETRY I
KRUASANY, NOGI Z MORDORU; each club runs in its own kit colour, `KIT` includes navy and pale
blue). From above, a club bunched at a crossing reads as a blob, not runners. To confirm: the
game log prints the packs' state (`packs:` lines) with the club's id at the time.

**Fix:** keep the clubs (F asked for them) but make them read: mixed kit with one club colour
(shirts or bibs, not head-to-toe), spread out in pairs along the pavement instead of a column,
a running gait at the camera's distance, and a small banner or the club name over the leader when
the car is near. Don't hold them at crossings in a block.

### 3.3 The Varso gap

**Seen:** at Varso the ground between the tower and the lower buildings is an empty grey plaza
where F knows there's building, and the stepped blue roofs look odd.

**Likely cause:** Varso 1 and 2 are still OSM extrusions (BACKLOG "Seen in screenshots"
2026-10-28: loop 1 lowered Varso 2's floating 80-90 m top to the ground; Varso 1's 71-81 m top
partly overhangs a 10 m part). The OSM building parts with a minimum height leave holes where
the LoD2 model was cut out, and K3 (Varso Place: terraces, sky garden) dressed the roofs, not
the masses. The result is a gap between the parts and blue glass all over.

**Fix:** a photo-based Varso Place pass (rule: landmarks only from the Mac's photos or F's): the
two lower buildings as solid masses down to the ground with their real stepped terraces, the
tower's podium, and the plaza only where the plaza is. Start with a Mac photo gather `refs/varso/`.

### 3.4 Plac Piłsudskiego's checkerboard paving

**Seen:** a hard, high-contrast chequer over the whole square, like a chess board.

**Cause:** the square's paving is drawn in `ground.gdshader` (`plac_at`, spec
`docs/landmarks/specs/plac_pilsudskiego.md`): 6 m panels alternating #b4b4b0 / #999995 with
0.27 m darker bands. From the photos the chequer is real, but it's subtle on the ground and seen
at a low angle; from the game's 30° camera over a 120 × 130 m field the step between panels reads
as a board game.

**Fix:** halve the contrast between panels (about #b0b0ac / #a3a39f), make the bands the main
read (thin, darker), add a fine granite speckle so a panel isn't flat, and fade the panel contrast
with the view's size (wide views see bands only). A ground shader tweak plus a look check from
the game's height and the helicopter.

### 3.5 The car is invisible under Trasa Łazienkowska

**Seen:** driving under the Trasa's deck, the car is hidden; you can't see where you're going.

**Cause:** the occlusion ghost only dithers *buildings* in front of the car (`building.gdshader`);
the decks are drawn by the ground material, which the ghost only lightens, never cuts. The tunnel
x-ray (`tunnel_xray.gd`) shows the car through the ground, but only when `map.in_tunnel` (more than
2 m under the terrain), not under a bridge deck.

**Options (recommended: 1 now, 2 next):**

1. **X-ray under decks too.** Show the existing warm silhouette whenever a deck is over the car
   (any deck in `map._decks_at(x, z)` more than 3 m above the car; a small public wrapper like `in_tunnel`). One call per frame, already built:
   the smallest change, and it also covers the other viaducts (Most Łazienkowski's land spans,
   Wiadukt Markiewicza, the Poniatowski viaduct over Powiśle).
2. **Cut the deck.** Let the ghost cut deck fragments that are above the car and inside the
   ghost's ellipse (the ground shader `discard`s them with the same dither the buildings use) when
   the car is under a deck. The player sees the road under it, not just the car.
3. **Lower the camera's cut-off for long decks:** while under a deck longer than 40 m, add the
   road under it to the minimap's highlight and keep the look-ahead arrow on screen. A fallback.

Check: D6 and a shot under the Trasa by day and night.

### 3.6 Map teleport left the car on a tunnel

**Seen:** after a teleport from the full map the car stood on (or in) a tunnel instead of the road.

**Cause (`main.gd` `_teleport_from_map` → `_lane_spot` → `_same_level`):** the teleport asks
for the nearest lane to a point on the terrain and accepts it if `_same_level` says so. For a
point on the ground that test is `h < terrain_height(q) + 1.0`, which is **true for a tunnel
lane** too (it is under the terrain), so the snap can pick a tunnel edge (Tunel Wisłostrady,
Armii Ludowej, Solidarności: 11 edges, ~2 km). The car is put at the tunnel's floor height or,
near a portal, between the floor and the ground. `graph.snap` already has a `ground_only` flag;
the teleport doesn't pass it. The same `_lane_spot` serves the tow (POMOC DROGOWA), so a tow near
a tunnel can do the same.

**Fix:** teleports and tows skip tunnel edges unless the asked point is inside a tunnel
(`ground_only` plus a tunnel test), require `|h − terrain| < 1 m` on the ground, prefer lanes in
the main strongly connected part (`node_scc`), then test the car's box at the spot before placing
it (step to the next candidate if it overlaps a solid). Check: D3.

---

## 4. Chmielna 89, the "Piramida"

F: "PKO Piramida looks bad". The building is **Chmielna 89** (2021-22, ~80 m), the bank's new
head office: a glass wedge whose sloped north-west face steps in a zigzag frame, on a ground floor
of V-shaped stainless steel legs, by the railway cutting next to Warta Tower. F attached four
photos (front, the V legs at street level, a dusk aerial with the skyline, the sloped roof from
above). In the game it is an OSM extrusion today.

Added to BACKLOG ("Landmarks from photos") and ROADMAP as a later photo-based landmark: a Mac
photo gather `refs/chmielna89/` plus F's four photos, then the model (the wedge, the zigzag
frame lines, the V legs, glass that reads blue-grey with the sky). No bank name or logo on it:
brands only as parodies (a parody sign only if F wants one).

---

## 5. The order of work

Phases run one after another; inside a phase, the items are independent threads. **[Codex]**
marks a task that is self-contained, has a clear spec and a headless check, so it suits Codex
(F has Codex); give it this file's section and `CLAUDE.md` (Codex reads `AGENTS.md`: a one-line
`AGENTS.md` that points to `CLAUDE.md` would help). The rest needs the map data on the Mac, a
look judgement, or the phone.

**Phase 0: quick fixes (this week, each a small PR)**

| # | Task | Section | Who |
| --- | --- | --- | --- |
| 0.1 | Teleport and tow never land in a tunnel; box test before placing; `check_teleport` | 3.6 | **[Codex]** |
| 0.2 | Chatter budget: priorities, rate cap, quiet while stuck, merged star toasts, setting; `check_chatter` | 2 | **[Codex]** |
| 0.3 | Car x-ray under decks | 3.5 option 1 | **[Codex]** |
| 0.4 | Helicopter framing and far plane, height cap, horizon haze | 3.1 | Opus (camera feel + shots) |
| 0.5 | Plac Piłsudskiego paving contrast | 3.4 | Sonnet + look check |

**Phase 1: measure the roads**

| # | Task | Section | Who |
| --- | --- | --- | --- |
| 1.1 | `check_drivability.gd`: lane, turn and dead-end sweep, free width, JSON + ranked list | 1.4 step 1 | **[Codex]** for the harness (copy `check_stuck_spots`' setup), Opus to read the results |
| 1.2 | Graph data fixes found by the audit: the 101 off-network nodes, the 15 kinks, the 300 narrow lanes | 1.3, 1.4 | Opus (bake changes, Mac re-bake) |
| 1.3 | Autopilot rows P11-P16 in PLAYTEST.md, run one at a time on the Mac with F's yes | 1.6 | Mac session |

**Phase 2: fix the roads by street** (one PR per street group, before/after score)

| # | Task | Who |
| --- | --- | --- |
| 2.1 | First-10-minute streets: Marszałkowska, Świętokrzyska, Jerozolimskie, Nowy Świat, Powiśle | Opus |
| 2.2 | Trzy mosty route and the bridges' approaches | Opus |
| 2.3 | Forgiveness bevels on collider corners within 3 m of a lane (bake rule) | Opus design, **[Codex]** for the bake code once specified |
| 2.4 | Trap dead ends closed with gates or bollards; public ones get turn space | Sonnet (props) |
| 2.5 | Score baseline in CI: fail a PR that lowers a main street's score by more than 2 | **[Codex]** |

**Phase 3: the assists and the camera** (each behind a setting, each felt on the phone)

| # | Task | Who |
| --- | --- | --- |
| 3.1 | Lane assist ("Asysta pasa") + `check_steering` lane-keep cases | Opus |
| 3.2 | Wall look-ahead steer | Opus |
| 3.3 | Junction pick and the camera leading into the turn | Opus |
| 3.4 | Deck cut in the ghost (under-deck option 2) | Opus (shader) |
| 3.5 | F's phone run: Cruise and Sport, assists on/off, stuck test | F + device run |

**Phase 4: the looks from this playtest**

| # | Task | Who |
| --- | --- | --- |
| 4.1 | Running clubs that read as runners | Sonnet |
| 4.2 | Varso Place masses from photos (Mac gather first) | Opus / landmark lane |
| 4.3 | Chmielna 89 from photos (Mac gather + F's four photos) | landmark lane, later |

**What not to do now:** new map areas, new side quests, new landmarks beyond 4.2-4.3. The
driving phases touch `car.gd`, `main.gd`, `follow_camera.gd`, `map_builder.gd` and the bake;
landmark PRs touch `landmarks.gd`, so the landmark lane can keep merging in parallel, but only
one driving thread at a time on `car.gd`/`main.gd` (they conflict).

---

## 6. What is open today (threads and PRs)

Checked 2026-11-03 13:30.

**Open PRs (12), waiting on the merge queue:** #385 merged at 12:43; next in the queue: #406
opening fly-over sound, #401 Cedet, #403 look-check answers, #400 Poniatowski viaduct, #407
Castle river front, #380 Supreme Court, #409 Eastern Wall docs, #410 modernism plan (docs), #411
Forest, #412 Arkadia; also older #383 Plac Bankowy and #371 monuments part 2 (both from
2026-11-02/03, not in the queue list: check if they still pass and merge or close them).

**Threads:** working: "Check Ściana Wschodnia photo build". Review-ready (waiting on a merge
slot or F's look): "Add opening fly-over sound", "Fix Royal Castle river front", "Plan Warsaw
modernism building collection", "Bring the city parks to life". Blocked on F: "Try the tryaura
autopilot" (PR #408, runs killed at ~6 min on the Mac), "Model Norblin, Browary, Koszyki and
Elektrownia".

**Recommendation:** finish the merge queue first (all of it is built; it only needs slots and
the green checks), then start Phase 0 with three threads in parallel (0.1, 0.2, 0.3 touch
different files except `main.gd` for 0.1 and 0.3, so run those two one after the other or give
0.3 to Codex after 0.1 merges). Keep the pause on new landmark work except 4.2-4.3 until Phase 2
is under way.
