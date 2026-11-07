# Boat race "Wiślana Szprotka"

F (2026-11-06, idea 8 of the coordinator's list): a friend phones and suggests a boat race on the
Vistula; the course is rings you must go through, miss three and you lose, then start again or
quit; look at games like it for mechanics; make the physics and the other boats' brains fun and
interactive. Then (same evening): work on the physics, design the start pier, make the models, test
with Autopilot.

Built in `game/scripts/boat_race.gd` (the quest, the course, the rivals, the river) and
`game/scripts/boat.gd` (the boats' motion and models); the course is baked by
`tools/boat_course.py` into `game/data/boat_race.json`; checked by `game/tools/check_boat_race.gd`
(verify step `boatrace`).

## 1. What the reference games do (no content copied)

| Game | Mechanic | What we take |
| --- | --- | --- |
| Wave Race 64 / Blue Storm | Buoys passed on the right side; miss five and you're disqualified; every buoy passed raises your top speed (a power meter), a miss resets it. Real swell, rivals' wakes throw you up. | The miss limit (F's three), the rhythm: rings in a row raise top speed, a miss resets it. Wakes you can jump. |
| Riptide GP (mobile) | Touch steering, tricks off waves fill a boost bar; short, readable courses. | Phone first: the car's own controls drive the boat, no new scheme to learn. |
| Hydro Thunder | Boost pickups on the line, shortcuts, heavy boats that bump each other. | Gold rings off the slalom: a boost, no penalty. Boats with mass that bump. |
| Splashdown | A momentum meter that drains on a miss. | Same as the rhythm. |
| GTA Vice City / San Andreas boat checkpoints | The next checkpoint and the one after are always visible. | The next ring bright, the two after it dim. |
| Superman 64's rings | (What not to do) rings with no flow between them, a timer that punishes. | Rings follow the river's own line in a slalom, no time limit, rivals instead of a clock. |

## 2. Rules

- **The call.** Szymek (a mate with a motorboat at the marina) phones by day (7:00-22:00) once the
  player has driven ~5 minutes, then every ~25 minutes; ODBIERZ, then "Ścigamy się?" PŁYNĘ! / NIE
  DZIŚ. The WYŚCIG ŁODZI pill also comes up by the start pontoon (a replay without the call).
- **The pontoon.** A floating start pontoon on the left bank at the mouth of Port Czerniakowski
  (gangway, bollards, blue and white flags, a banner arch). Stop the car by it: the car waits on
  the bank, the player takes the runabout "Szprotka" on the grid. (Port Czerniakowski's own entrance
  is an 8 m gut, too narrow to race through; the marina from PR #251 stays the backdrop.)
- **The course.** 3.2 km downstream from the harbour mouth under Most Poniatowskiego, the railway's
  Most Średnicowy, Most Świętokrzyski and Most Śląsko-Dąbrowski to the finish arch below the Old
  Town (the rings and the runs between them keep 6-7 m clear of every pier, `tools/boat_course.py`): 20 rings (16 m) in a
  slalom from bank side to bank side, 5 gold rings (9 m) on the fast line, the finish (60 m). About
  3 minutes.
- **Misses.** A ring passed outside its opening, or left behind, is a PUDŁO. The third is ODPADASZ!
  with JESZCZE RAZ (the grid again) or WYJDŹ (back to the car). Gold rings never count as misses.
- **Rhythm.** Every ring in a row +3 % top speed, up to +15 % (×5); a miss resets it. A gold ring:
  +18 % for 2.5 s.
- **Pay.** 1st 150 zł +40 respect, 2nd 60 +15, 3rd 25 +5, 4th nothing *guess*. REWANŻ any time.

## 3. Physics (boat.gd)

An arcade planing model on the water plane, the same code for the player and the rivals:
- Thrust along the heading fading to zero at the top speed (runabout 21 m/s = 76 km/h); brake to
  reverse.
- Grip across the heading grows as the boat gets up on the plane (1.1 → 3.2 /s): a turn at speed
  slides first, then bites. A hard turn bleeds speed.
- The rudder needs flow: no turn at rest, most at mid speed, ~30 % less flat out, almost none in
  the air.
- The current: 1 m/s downstream.
- Water height: a low chop (7 cm) plus wake rings. Every boat drops one every 0.32 s behind it
  (height by its speed and kind), the barge a big one (0.8 m). A crest met fast (climb rate over
  2.4 m/s) throws the boat up; landing hard (over 4 m/s) costs 14 % speed. Pitch and roll follow
  the water and the turn.
- Banks: map_builder's shore distance field pushes the boat back out along its slope, taking the
  speed into the bank. Solid things (bridge piers, moored barges, the marina) by one sphere test a
  boat a frame, and the piers in the water from the course file (circles, so they are solid even
  before their sector's colliders load); the moving barge is a capsule. Boats bump boats by mass.

| Kind | Top | Pull | Turn | Grip rest→plane | Mass | Who |
| --- | --- | --- | --- | --- | --- | --- |
| Runabout 5.4 m | 21.0 m/s | 6.5 | 1.55 rad/s | 1.1 → 3.2 | 1.0 | the player, Szymek |
| Tub 6.4 m "Złota Rybka" | 19.3 | 4.6 | 1.25 | 2.0 → 4.2 | 1.8 | Pan Zdzisiek |
| Jet ski 3.2 m | 22.6 | 8.0 | 2.1 | 0.9 → 2.6 | 0.55 | Kamil |

## 4. The rivals' brains

Each rival aims through every ring at its own fixed share of the opening, looks past the ring once
close (blending to the next one), plans its speed for the next turn (brakes when the turn at the
ring is sharp), keeps off a boat just ahead, and some block a player close behind. Temperaments:

| Rival | Boat | Line | Mistakes | Blocks | Says |
| --- | --- | --- | --- | --- | --- |
| Szymek (the caller) | red runabout | near the middle | 3 % a ring | a little | lody, his paint |
| Pan Zdzisiek | "Złota Rybka", cream and wood | dead centre | never | no | slow and steady, slows for the barge |
| Kamil | lime jet ski | wide | 5 % a ring | hard | films everything, "content" |

They play by the same rules (a rival can drop out on three misses). The rubber band only works off
screen (±7 % top speed past a 60 m gap), never where the player sees it. Headless race (all four
driven by the rivals' driver): Kamil ~172 s, the careful player ~179 s, Szymek ~181 s, Pan Zdzisiek
~192 s.

## 5. The barge

A 72 m sand barge pushed upstream by its tug at 2.4 m/s along the right-bank lane (round the bridge
piers, `tools/boat_course.py`), met about a minute in; the rings keep to the left half while it is
there. Its wake rings are the big jumps.

## 6. Cost

Idle: a timer and the pontoon (1 draw call, static). Racing: 4 boats + the barge (5), the next 3
rings and the finish (≤4), the foam (1): about +10 draw calls; four sphere tests a frame; the wave
sum ~1k terms a frame.

## 7. Flags

`--boat-race` / `--boat-race=call` (Szymek rings now), `=race` (the car at the pontoon and straight
onto the grid), `=auto` (that, with the player's boat driven by the rivals' driver), `=0` (none);
`--boat-log`.

## 8. Left

In docs/BACKLOG.md "Boat race".
