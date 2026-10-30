---
name: backlog-loop
description: Runs Around Warsaw's autonomous backlog mode - keep picking the next item by priority, delegating, verifying and landing it until the backlog is empty; questions for the user are parked in docs/QUESTIONS.md instead of stopping the work, and each session stays in its own lane. Use when the user says to work the backlog, keep going, run autonomously or "copilot mode", and whenever a loop or a subagent's item finishes.
---

# Backlog mode: keep going until the backlog is empty

The user's standing rule (2026-10-30): **the work never stops for a question.** A question
that needs the user is parked and the next item starts at once; the user answers later, in
one batch. The work ends only when the backlog is empty (or the only items left wait on the
user). The cycle around it is in docs/WORKFLOW.md "Backlog mode"; each item is still a loop
run with the loop-brief skill, to the full definition of done.

## 1. Where the work comes from (priority order)

Take the first open item, top to bottom:

1. What the user just asked or reported from the phone, and answers to parked questions
   (`docs/QUESTIONS.md`, "Answered"): an answer unblocks its item, which goes first.
2. Regressions: a red `tools/verify.sh` or CI on main, a crash, a broken city path.
3. `docs/ROADMAP.md` "The road to the 1.0 demo": the rounds in their order, each round's
   loops as `docs/DEMO.md` section 7 lists them.
4. `docs/BACKLOG-TRIAGE.md`: fixes go with the loop named there; "sweep" items in the next sweep.
5. `docs/BACKLOG.md`: fixes not yet triaged (the oldest section first), then notes that turned
   out to be fixes. Decisions are parked questions, not work.

Skip an item when its lane is taken (section 3), when it waits on a parked question, or when
it needs something only the user can give (section 4). Skipping is not stopping: take the
next one.

## 2. The loop, item after item

```
pick (section 1) ─► claim the lane ─► brief + delegate (loop-brief) ─► verify yourself
      ▲                                                                     │
      └── park its questions, update the docs, land it, free the lane ◄────┘
```

- **After every finished item, pick again at once.** Don't end the turn with "done, what
  next?": the answer is in section 1. A report to the user goes out at the end of a round or
  when there is something to try on the phone, not after every item.
- **A subagent's Open Questions don't stop the item.** It built the safe, reversible default;
  verify that, land it, and park each question with that default (section 4).
- **A subagent that is blocked** stops that item and goes on to the next item in its brief;
  the orchestrator parks the block and picks the next item for that agent.
- **Escalate, don't patch** (CLAUDE.md "Model routing") still holds: a failed Sonnet run is
  re-run on Opus before the item counts as blocked.
- **Land it**: on the Mac, the orchestrator commits finished loops to main as before; a cloud
  session works on its branch and opens a PR per item or round (the user merges). Both only
  when the user allowed commits for this work; otherwise leave it verified and uncommitted
  and say so.

## 3. Lanes: never two sessions in one area

The project folder has one writer at a time (CLAUDE.md), and the Mac session and cloud
sessions can run side by side. So each session works in **one lane** and stays out of the
others:

| Lane | Covers | Usual agents |
| --- | --- | --- |
| driving | car and helicopter feel, controls, collisions, physics, the camera | `gameplay-dev` |
| map | bakes, roads, decks, structures, sectors and streaming, landmarks' geometry | `map-engineer` |
| visuals | materials, shaders, lighting, night, weather, HUD look, 2D art | `gameplay-dev`, `game-designer`, `art-director` |
| content | missions, jobs, police, Moja Warszawa, dialogue, radio | `game-designer`, `gameplay-dev` |
| performance | frame cost, budgets, device benches | `perf-engineer` |
| landing | the aroundwarsaw.app site | any, outside `game/` |
| store release | App Store / Play builds, store text and art, CI | any; submissions wait for the user |

Before claiming a lane, look for another session in it: the open PRs and their branches, the
last day of commits on main (`git log --since=1.day --stat origin/main`), and the
"In progress" table in `docs/QUESTIONS.md`. Taken: pick an item in a free lane. An item that
must touch a file in another lane (a shared script, `project.godot`, `main.gd`) keeps the
change small, names it in the PR, and leaves that lane's open work alone.

Write your claim in "In progress" (lane, item, session, date) when you start and remove it
when the item lands. A claim older than two days with no commit is stale: take it over and
say so.

## 4. Parking a question

Park instead of asking whenever a question needs the user. Always park:

- a design or taste call the docs don't settle (a feel, a joke, a layout, a mechanic);
- anything that can't be undone: a store submission, a release, a purchase, production
  (the landing's live site), deleting a remote branch or history;
- a download or install (CLAUDE.md: source, size and time first), a new data source, an add-on;
- a device run the user hasn't allowed for this loop, and phone-only checks;
- PixelLab generations beyond 50 in a loop.

Each parked question is one entry in `docs/QUESTIONS.md` "Waiting": the date, the lane and
item, the question in one line, the options, **the default that was built** (or "nothing
built: waits"), and where it lives (PR, BACKLOG line). Then:

- if a reversible default exists, build it and keep going on that item;
- if not, mark the item blocked on that entry and take the next item;
- tell the user in the next report as one batched list ("Parked: 3 questions"), not one
  message each.

When the user answers, move the entry to "Answered" with the answer, re-open its item at the
top of section 1, and record a lasting decision where the docs keep decisions (BACKLOG
"Decided" sections, DEMO.md, ROADMAP).

## 5. When it stops

Only when every item in section 1 is done, blocked on a parked question, or in a lane
another session holds. Then send one report: what landed (per item, agent and model), what
was verified and how, what to try on the phone, and the whole "Waiting" list. A pause for
the account's usage limits is not the end: say where the work stopped and pick up there.
