# Nocna Warszawa: project instructions

A free, open-source (MIT) fan game: an isometric small-car arcade drive (and a helicopter)
through the real centre of Warsaw, built in Godot 4.7.2 (Mobile renderer, iOS first, Metal)
from OpenStreetMap and GUGiK open data. The goal is a top indie game; the next milestone is
a high-quality demo of central Warsaw on the iPhone (docs/DEMO.md). The repo is public.

## Where things are

| Path | What |
| --- | --- |
| `game/` | the Godot project: `scripts/` (GDScript), `shaders/`, `tools/` (check scripts, `bake_city.gd`), `data/` (dialogue), `map/` (baked, generated), `audio/` |
| `tools/` | Python bakes and helpers; `verify.sh`, `shots.sh`, `device_run.sh`, `check_map_data.py`, `export_ios.sh`, `hooks/guard_godot.py` (the guard hook, on in `.claude/settings.json`: blocks game runs without `--nosave` or a quit flag, and a headless `bake_city.gd`) |
| `README.md` | how everything works: controls, every flag, map-data chain, bench, **Performance budgets** |
| `docs/WORKFLOW.md` | how the work is run: the loop, who owns what, definition of done, milestone gates |
| `docs/ROADMAP.md` | order of work and the progress log · `docs/BACKLOG.md` found issues and decisions |
| `docs/DEMO.md` | the demo plan: area, quality bar, road defects, police, milestones |
| `CREDITS.md`, `LICENSE` | data licences (ODbL, GUGiK, CC BY 4.0) and MIT |
| `data/raw/`, `build/`, `shots/`, `game_*/` | raw downloads, builds, screenshots, temp copies: gitignored, never committed |

## Your role: orchestrator

For anything bigger than a one-file fix: **plan, brief, delegate, verify, report** (the
loop-brief skill; the cycle in docs/WORKFLOW.md). Give each subagent a self-contained brief:
it has no memory of this conversation. Accept nothing on a report alone: run the checks and
look at the shots yourself. Subagents can't ask the user; relay their **Open Questions**,
then re-delegate with the answers. One agent writes in the project at a time.

## Agents (`.claude/agents/`)

| Agent | Lane | Writes | Default model |
| --- | --- | --- | --- |
| `gameplay-dev` | GDScript, shaders, HUD, driving, missions, jobs, police, traffic, landmarks in code | `game/scripts`, `game/shaders`, `game/tools` | opus (sonnet for spec-applying tasks) |
| `map-engineer` | bakes, roads, decks, ramps, lane graph, trees, POIs, the bigger map, city.scn | `tools/*.py`, `game/map` (by baking), `map_builder.gd` | opus |
| `perf-engineer` | measure and cut frame cost, budgets, device benches | code, for cost only, look unchanged | opus |
| `game-designer` | missions, loop, police, economy, jokes, text, 2D art specs and PixelLab assets | design docs, `game/data`, `game/art` | opus |
| `art-director` | judges screenshots and 2D art against the art bible | nothing (read-only) | opus |
| `qa-tester` | runs the verification set, shot sets, device runs; reports | nothing in the project | sonnet |
| `scout` | read-only lookups, counts, log crunching, parse checks | nothing | haiku |

## Skills (`.claude/skills/`)

| Skill | Use for |
| --- | --- |
| `verify-game` | `tools/verify.sh`: map data, check scripts, headless runs; what it can't prove |
| `screenshot-review` | `tools/shots.sh` at phone sizes and judging shots; `art-bible.md` lives here |
| `bake-map` | the OSM/GUGiK bake chain, its invariants, downloads, road and deck checks |
| `godot-mobile-perf` | performance rules for the phone and how to measure before/after |
| `warsaw-tone` | humour, parody and Polish/English rules; `dialogue.json` format |
| `loop-brief` | the brief template, delegation table, and how to verify a result |
| `device-run` | build, install, launch on the iPhone, copy the log back; the user starts it with `/device-run`, agents read the file only when the user allowed a run this loop |
| `pixellab` | 2D pixel art via the PixelLab MCP server: portraits, HUD/minimap icons, signs and posters, UI, store art; not for the 3D city |

**Tools note.** The PixelLab MCP server (`pixellab`, tools `mcp__pixellab__*`) is configured
in the user's own Claude Code settings. Its API key lives only there: never write a key into
any file, script, log or commit, never ask anyone to, and don't add a project `.mcp.json`.
Up to 50 generations per loop without asking; more needs the user's yes.

## Model routing (per delegation, by kind of work)

You, the orchestrator, always run on Opus. For each delegation pick the tier with the Agent
tool's `model` parameter (`"opus"`, `"sonnet"`, `"haiku"`); it overrides the agent file's
default. Route by the **kind** of work, not its size:

| Tier | Work |
| --- | --- |
| **Opus** (effort high) | deciding anything: design, game feel, tuning, police and mission design; root causes; performance analysis and budgets; the map pipeline's geometry (roads, decks, overpasses, lane graph); art direction and judging shots; anything device-gated (phone runs, haptics, iOS export); writing briefs and specs; reviewing another agent's work |
| **Sonnet** (effort medium) | applying a spec that already fixes the values; tests for behaviour already pinned; mechanical refactors, renames, flag strips; strings and translations against approved text; docs updates from a finished report; running `tools/verify.sh` and reporting; installing an approved add-on and its credits |
| **Haiku** (effort low) | read-only lookups ("where is X", "does Y exist", "how many"); grepping or summarising logs (bench output, device logs); counting and extracting from data files; checking files parse (frontmatter, JSON); listing files and diffs. No edits that need judgment, never device-gated, never the final verification |

- **Escalate, don't patch.** A Haiku or Sonnet run that returns Open Questions, fails its
  gates, overshoots its file scope, or gives a result you can't verify is re-run one tier up
  with the whole task. When unsure, go up a tier. Device-gated and performance work never
  goes below Opus.
- **One loop, several tiers**: Opus does the deciding, cheaper tiers do the applying and the
  counting (examples in docs/WORKFLOW.md). Put the tier and the reason in each brief.
- **Only you spawn.** Claude Code lets a subagent spawn its own (up to three levels) when its
  `tools` list `Agent`; ours don't, by design: routing, cost and the one-writer rule stay with
  you. An agent that wants a cheaper helper asks in its report ("Haiku could crunch X").
- The built-in Explore agent runs on your model (Opus); use `scout` for cheap lookups.
- Say which model each delegation used when you report it.

## Hard rules

- **Runs.** Every game run passes `--nosave` and quits (`--quit-after N` or `--shots=`);
  autopilot runs never quit by themselves. `check_steering.gd` runs with `--fixed-fps 60`.
  Engine flags go before `--`, game flags after; Godot ignores unknown flags silently.
  macOS has no `timeout` (`perl -e 'alarm shift; exec @ARGV' 600 cmd...`); never name a zsh loop variable
  `path`; `pgrep -f X` in a wait loop matches the loop itself (use `pgrep -x Godot`).
- **Both city paths** must work: the runtime build and the prebuilt `game/map/city.scn`.
  Rebuild city.scn WITH a renderer: `godot --path game --resolution 320x180 --script
  res://tools/bake_city.gd`, never `--headless`. Check looks on both (`--prebuilt`).
- **Map data.** After any centrum.json re-bake, run the whole chain and
  `python3 -I tools/check_map_data.py` (trees3d 75324 values, pois 1020, graph, palm; new
  counts only on purpose, recorded in that script and README together).
- **Performance is a gate.** The phone's frame grows with draw calls, not triangles. Keep
  README "Performance budgets"; report bench before/after for anything that runs per frame
  or adds geometry, materials or lights.
- **Downloads and installs** only with the user's approval: list source, size and time first.
  That includes data, tools and Godot add-ons (rules below).
- **Content.** Original art, music and writing. Real place names are fine; brands only as
  parodies (no real names or logos); affectionate humour, never about real private people;
  on-screen text in Polish with English (warsaw-tone skill).
- **Device runs** on the user's iPhone are allowed for test builds when the user said so for
  the current loop (device-run skill); one device user at a time. Find the phone's identifier
  with `xcrun devicectl list devices`; never write it into a tracked file.
- **Public repo.** No secrets, keys, device identifiers, email addresses or absolute home
  paths in tracked files; repo-relative paths.

## Godot add-ons

Installed only with the user's approval, one at a time, free only. Prefer GDScript-only
add-ons under MIT or CC0; a native GDExtension needs iOS binaries (most don't ship them), so
check it on the phone before relying on it. Each goes in `game/addons/<name>/` with its
licence file kept, gets a CREDITS.md line (name, author, licence, URL, version), and must keep
the performance budgets. **Installed:** Debug Draw (HardPixel, v1.1.0, loop 3a; GDScript only,
loaded only with `--debug-roads`); Phantom Camera (Ramokz, v0.11.0.3, the camera loop; it runs
the fly-in and target-look tweens only, the follow camera is `follow_camera.gd`; its editor plugin
is off); beehave (bitbrain, v2.9.3, loop 3g-1; the police units' behaviour trees, ticked by
hand at 5 Hz; editor plugin off, no autoloads: `police/police_tree.gd` has a lean `_ready`; one
local line in `debug/debugger_messages.gd`, no messages without a debugger); Dialogue Manager
(Nathan Hoad, v4.1.0, loop 3g-1; the pull-over's flow, `dialogue/police.dialogue` compiled at
runtime by `police.gd`; editor plugin off, so no import plugin and no autoload). Still need their
own yes: Folder Import Rules, Lente photo mode, the In-app Review and Share plugins.

## Commands

```zsh
tools/verify.sh [--quick|--ios|--only=a,b]   # the verification set, one PASS/FAIL table
tools/shots.sh [--set=core|quick|names] [--size=2532x1170]   # phone-size screenshots
cd game && godot --path . --disable-vsync -- --bench --nosave  # bench (+ --time=night, --weather=rain --time=night)
tools/export_ios.sh   # prebuilds city.scn, exports build/ios (verify.sh --ios also builds it)
```

## Code conventions

- GDScript: static types (`:=`, typed returns and arrays), tabs, `##` doc comments on classes
  and members saying what and why (and which loop added it); follow the file's existing order.
- New testing aids are game flags parsed in `main.gd` and documented in README's flags table.
- Checks are `game/tools/check_*.gd` SceneTree scripts printing `<name>: OK` and exiting 0/1;
  every new check joins `tools/verify.sh` in the same change.
- Python tools: `python3 -I`, standard library; a docstring with the usage line.
- When behaviour changes, README, ROADMAP (progress-log row) and BACKLOG change with it.

## Definition of done

`tools/verify.sh` PASS (and `--ios` at a loop's end) · screenshots at phone size looked at,
both city paths where the map builder changed · bench within budget · docs updated · scope
matches the brief · what only the phone can show is named, with what the user should try.
Details: docs/WORKFLOW.md.

## Git

The repo is public. Commit or push only when the user asks in the current conversation.
Never force-push, rewrite published history or delete a remote branch. Never commit
`data/raw/`, `build/`, `shots/`, `game_*/` copies, logs, keys, device identifiers or personal
data. Subagents don't touch git unless their brief says so.
