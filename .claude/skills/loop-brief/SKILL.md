---
name: loop-brief
description: Writes the brief for one Around Warsaw work loop (goal, read-first list, prioritised items, budget, hard constraints, acceptance checks, report format with Open Questions), hands it to the right subagent and model, and verifies the result before accepting it. Use when starting any task bigger than a one-file fix, when delegating to a subagent, and when a subagent's report comes back.
---

# A loop: brief, delegate, verify, report

The cycle is in docs/WORKFLOW.md. This skill is the procedure.

## 1. Pick and size the loop

- Source: the priority order in the backlog-loop skill (the user's latest asks and answered
  questions, regressions, ROADMAP "The road to the 1.0 demo", BACKLOG-TRIAGE, BACKLOG), in
  a lane no other session holds.
- One theme per loop, 3-7 items in priority order. Road and performance work comes before
  new content. If an item needs a design call you can't make from the docs, don't stop:
  have the game-designer propose options, brief the safe, reversible default, and park the
  question in `docs/QUESTIONS.md`; with no such default, park it and take the next item.

## 2. Write the brief

Copy `template.md` (next to this file) into the session's scratch folder and fill it in.
Rules for a good brief:

- **Self-contained.** The agent has no memory of this conversation. Quote the user's words,
  give real file paths, coordinates, flags and numbers.
- **Read-first list** names exact docs, sections and files (with the functions or line areas
  to start from), so the agent doesn't rediscover the project.
- **Items** are concrete and checkable; for a suspected cause write "confirm it, don't take it
  on trust" and ask for the measurement that proves it before the change.
- **Budget** is the frame and vertex growth allowed (from DEVELOPMENT.md "Performance budgets"); a
  performance loop gets "no growth: the frame must get cheaper".
- **Constraints** are the block from `template.md`, pasted whole, plus the task's own.
- **Acceptance** lists the exact commands and outputs that prove each item, the screenshots
  wanted (names, sizes, both city paths), and the docs to update.
- **Object briefs** (landmarks, facades, props): the spec is written from the reference photos
  and names the detail level (L1-L3), the identity features and the triangle budget; the
  acceptance asks for matched shots beside the photos (the model-from-photos skill).
- **Model line**: "Model: <tier>, because <reason>" (e.g. "Model: sonnet, because the spec
  fixes every value; any decision it doesn't make goes to Open Questions").
- **Report format** always ends with **Open Questions** (each with the default the agent picked).

## 3. Delegate

| Work | Agent | Default tier (pass `model` to change it) |
| --- | --- | --- |
| GDScript, shaders, HUD, vehicles, jobs, traffic, landmarks in code | `gameplay-dev` | opus; sonnet when the spec fixes every value |
| Bakes, roads, decks, lane graph, map data, city.scn | `map-engineer` | opus (sonnet only to apply its own exact fix list) |
| Frame cost, budgets, bench, device numbers | `perf-engineer` | opus, always |
| Missions, loop, police, economy, jokes, 2D art specs and PixelLab assets | `game-designer` | opus; sonnet for translations against approved text |
| Judging screenshots and 2D art against the art bible (read-only) | `art-director` | opus, always |
| Running the verification set, shot sets; reporting only | `qa-tester` | sonnet; haiku only for "run verify.sh, paste the table"; opus for device runs |
| Lookups, counts, log crunching, parse checks (read-only) | `scout` | haiku |

Pick the tier by the kind of work (CLAUDE.md "Model routing"), write it into the brief's
**Model** line with the reason, and pass it as the Agent tool's `model`. A cheaper run that
returns Open Questions, fails a gate, overshoots scope or can't be verified is re-run one
tier up with the whole brief, never patched with corrections.

One agent writes in the project at a time (the folder is shared; benches disturb each other).
Read-only agents (art-director, a design proposal) can run beside a writer. Before
delegating, make a marker for the scope check: `touch <scratch>/loop_start`.

## 4. Verify before accepting (never accept on the report alone)

1. **Scope:** `find game tools docs README.md CREDITS.md -newer <scratch>/loop_start -type f`
   (once the repo is in git: `git status --short` and `git diff --stat`). Files outside the
   brief's scope: ask why, or reject.
2. **Checks:** run `tools/verify.sh` yourself (verify-game skill) and compare with the report.
3. **Look:** open the key screenshots yourself; for a visible change, have `art-director`
   review the set.
4. **Numbers:** bench before/after against the budget; device numbers if the loop had a run.
5. **Docs:** DEVELOPMENT.md (behaviour, flags), ROADMAP (item marked done, a progress-log row in the
   house style), BACKLOG (fixed items removed, found ones added) are updated.
6. A Sonnet run that fails its gates, overshoots scope or returns Open Questions: re-run the
   whole task on Opus with the answers, don't patch it.

## 5. Report to the user

What changed (per item, with the numbers), which agent and model did each part, what you
verified yourself and how, what only the
user can judge on the phone and exactly what to try, what was not done and why, and the Open
Questions (parked in `docs/QUESTIONS.md`, each with the default that was built). Then pick
the next item (backlog-loop skill); don't wait for an answer.
