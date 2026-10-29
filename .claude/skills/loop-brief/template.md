You are doing <LOOP NAME> on Around Warsaw, a free, open-source (MIT) fan game: an isometric
small-car arcade drive through the real centre of Warsaw, made in Godot 4.7.2, Mobile
renderer, iOS first (Metal). The project is the folder that holds this repo's CLAUDE.md (game
in `game/`, Python bake tools in `tools/`, docs in `docs/`, screenshots in `shots/`).

<WHY: what the user said or saw, in their words where possible, and what this loop is for.>

Model: <opus | sonnet | haiku>, because <reason>. <For sonnet or haiku: apply exactly what
this brief fixes; any decision it doesn't make goes under Open Questions, not into the work.>

Read first: CLAUDE.md, docs/WORKFLOW.md, <docs and sections>, <files, with the functions or
line areas to start from>. Skills that apply: <verify-game, screenshot-review, bake-map,
godot-mobile-perf, warsaw-tone, pixellab, ...>.

## Items, in priority order (finish one before starting the next; if time runs short, stop
## cleanly after a finished item)

1. **<Title>.** <What is wrong, with evidence (shot path, coordinates, numbers). The likely
   cause, marked "confirm it, don't take it on trust", and the measurement that proves it.
   What done looks like.>
2. ...

## Budget
Bench before and after: `cd game && godot --path . --disable-vsync -- --bench --nosave` (also
`--time=night` and `--weather=rain --time=night`), interleaved with a copy of the old code,
medians. Allowed growth: <from DEVELOPMENT.md "Performance budgets", or "none: this loop must make the
frame cheaper">.

## Constraints (hard)
- Work only inside this project folder. No downloads or installs of any kind without the
  user's approval (list source, size and time first); that includes Godot add-ons.
- <Git: the repo is public. Don't commit or push unless this brief says so; never force-push;
  never commit data/raw/, build/, shots/, game_*/ copies, keys, device identifiers or personal
  data.>
- Original art, music and writing; real place names are fine; brands only as parodies (no real
  names or logos); affectionate humour, never about real private people; on-screen text in
  Polish with English (Polish above English in the HUD; English glosses in the data).
- Every game run: `--nosave` and a way to quit (`--quit-after N` or `--shots=`); autopilot
  runs never quit by themselves. `check_steering.gd` runs with `--fixed-fps 60`. macOS has no
  `timeout`. `--size=` takes metres. Never name a zsh loop variable `path`. Inside a wait loop
  `pgrep -f X` matches the loop itself.
- Keep both city paths working (the runtime build and the prebuilt sectors, loop 3c); if
  you change what the map builder makes, run `python3 -I tools/bake_sectors.py` and rebuild the
  prebuilt sectors WITH a renderer (`godot --path game
  --resolution 320x180 --script res://tools/bake_city.gd`, never `--headless`) and check looks
  on both paths (`--prebuilt`). After any centrum.json re-bake run the whole chain and
  `python3 -I tools/check_map_data.py`.
- Keep the iOS export compiling (`tools/verify.sh --ios`).
- <Device runs on the user's iPhone: allowed / not allowed in this loop. If allowed, follow
  .claude/skills/device-run/SKILL.md; one device user at a time.>
- <Files other agents are editing right now: do not touch them.>
- <Task-specific: what must not change (e.g. driving feel, the settings loop 2a built).>

## Acceptance
- `tools/verify.sh` RESULT: PASS (paste the table); <task-specific checks and their outputs>.
- Screenshots you have looked at yourself, `shots/<loop>_*.png` at 2532x1170 (and 2868x1320
  where the HUD matters): <before/after pairs and spots; both city paths where the map builder
  changed>.
- Bench before/after (medians), vertices before/after, within the budget.
- docs/DEVELOPMENT.md (behaviour, flags), docs/ROADMAP.md (mark the item done, add a progress-log row in
  the same style as the others) and docs/BACKLOG.md (remove what you fixed, add what you found)
  updated.

## Report format
What you changed (per item), the root causes you confirmed (with numbers), files new/changed,
screenshots list, verification table, bench table, what the user should try on the phone and
what to tell back, known issues, and an **Open Questions** section (you cannot ask the user;
pick a sensible default, build it, and list it there).
