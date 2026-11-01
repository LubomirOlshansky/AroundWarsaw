# The opening flyover and the first minute

F (2026-10-31): the first launch should open with a short camera flight over the city that
ends at the start, "not very long". First-scene plan item 2 (docs/design/first-scene.md). Built
in `game/scripts/camera_shots.gd` (`opening`) and `main.gd` (`_fly_in`, `_opening_due`).

## What good open-world games do in their first minute

Short notes from how well-known openings are built and talked about (sources at the end):

- **Show the world once, from above, then hand over.** Breath of the Wild's walk out of the cave
  ends on one wide swing over the plateau; Burnout Paradise opens with a flyover of the city and
  then the car; Forza Horizon 5 drops you in a car within a minute and the camera's showcase
  happens *while* you drive. The reveal is one shot, not a tour.
- **Short, then control.** The common rule in these talks is control inside the first 10 to 30
  seconds on a replay, and that every cinematic is skippable. Long intros are what players
  complain about most in reviews.
- **The reveal names the goal.** Disney's "weenie": the big landmark you can see from anywhere
  is where people walk to. In the opening it is shown first, so the player knows the city's
  centre without a map. For us that is the Palace of Culture, 250 m from the start.
- **No cut at the hand-off.** The best openings end the flight exactly on the gameplay camera,
  so the moment the stick works nothing jumps.
- **A title card over the view.** Forza's "MÉXICO", GTA's district names: one big word and the
  place, faded in over the flight, then gone before control.
- **Music starts with the reveal**, not after it.
- **First launch only.** Every later launch goes straight to the car (here: the short 2.6 s
  fly-in that was already there).

## The design

| Time | What happens |
| --- | --- |
| tap | The title screen goes ("tap to drive"). The radio's first song starts. |
| 0.0 s | The camera is high over the Palace of Culture (a 420 m view, turned 115° from the car's heading, steeper than play, -38°): the Palace in the middle, the towers behind. |
| 0.6 to 5.4 s | The caption fades in and out at the lower left: **WARSZAWA**, *Śródmieście · Plac Defilad*, *the centre of Warsaw*. |
| ~3.7 s | It passes over Plac Defilad between the Palace and the museum (a 230 m view, still turning). |
| 7.5 s | It lands on the car's follow view, behind the car facing north up Marszałkowska. No cut: the last key is the follow camera itself. The HUD comes in and the guide's clock starts (first10.gd), so its beats (the finger, the stand's arrow at 0:10) count from here. |

- One eased curve (smootherstep over the whole flight, Catmull-Rom through the keys, the size
  eased in log space), so it never stops halfway and the zoom feels even.
- **A tap skips** at any point (after a 0.25 s grace, so the title's own tap doesn't): a 0.3 s
  blend down to the car, the caption fades, and the HUD and the guide start then.
- **When it plays:** a normal launch on a fresh save (when the guide runs). Every other launch
  keeps the short fly-in. `--cinematic=opening` forces it in a test run (shots).
- **The keys are fixed points** (the Palace's centre and Plac Defilad), so if the start moves
  (`First10.START`), only the last leg changes. A start far from the Palace would need new keys.

## Performance

The flight's wide views are the same as the map's zoomed-out view: sectors outside the start's
3 × 3 show as proxies, the small things' shadows are off above WIDE_VIEW, and the far plane
follows the view's size. The title already waits for the start's sectors, so the landing is in
full detail. The flight costs no extra draw calls of its own (one caption layer, three labels,
freed when it ends) and the script work is one curve sample a frame.

**Only the phone can show** whether the 420 m view hitches as the proxies swap to sectors on
the way down, and how 7.5 s feels with the first song.

## Open for F (parked in docs/QUESTIONS.md)

- Length: 7.5 s by default. Shorter (5 s) or longer (10 s)?
- Should the stand's arrow come at once after the flight (the flight already showed the area)
  instead of 10 s later?

## Sources

- [Why the Forza Horizon 5 intro took six months (GamesRadar)](https://www.gamesradar.com/why-the-stunning-forza-horizon-5-intro-sequence-took-six-months-to-create)
- [How Playground crafted Forza Horizon 5's opening drive (The Loadout)](https://www.theloadout.com/forza-horizon-5/opening-drive)
- [Video game vista (TV Tropes)](https://TVTropes.org/pmwiki/pmwiki.php/Main/VideoGameVista)
- [Guiding the player in open-world games with visual elements (Berlin International)](https://repository.berlin-international.de/items/029343f1-11fd-4185-bbaa-191d6a2e6274/full)
- [Burnout Paradise retrospective (GamesRadar)](https://gamesradar.com/burnout-paradise-retrospective)
