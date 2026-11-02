---
name: dialogue-scenes
description: Decide whether new or changed dialogue should use the Dialogue Manager add-on (.dialogue files) or the existing JSON line bags, and how to build a scene. Use before writing any conversation, call, card dialogue or story scene with player choices.
---

# Dialogue Manager in Around Warsaw: decide, then build

## 1. Decide (write the answer in the PR: "Dialogue Manager: yes/no, because ...")

Use Dialogue Manager when the text is an **authored scene**: several lines in order, with
**player replies that change what happens** (a caution, a fine-free outcome, a job accepted).
Examples: the police pull-over (done), Halina's first call, the final's set-piece.

Do NOT use it for: radio host, driver shouts, bubbles, signs, job and mission card text, crowd
barks. Those are random single lines from `data/dialogue.json` through `dialogue.gd line()`
(no-repeat bags, notes like `{"only": "roof"}`), which suit them better. A scene with one line and
no choice is just a `line()` call.

## 2. Build (the pattern that exists)

- **Flow only** in `game/dialogue/<scene>.dialogue` (titles `~ name`, `=> END`, `- reply => next`,
  `$> talk.done_x()` mutations). **Words** in `game/data/dialogue.json` (Polish + English, warsaw-tone
  skill), picked by `{{talk.say("group", "tag")}}`.
- A small state object like `scripts/police/police_talk.gd` (`RefCounted`, `say()` returns the Polish
  and keeps the English for the balloon; callbacks for outcomes) is passed as `extra_game_states`.
- Compile at runtime while the city builds, as `police.gd` does; the editor plugin stays off (no
  import plugin, no autoload); clear the resource's reference cycle at exit like `police.gd`.
- Keep files small (a 30-line file compiles in about 70 ms); several small files beat one big one.
- Every Polish line has its English; no brands except parodies (warsaw-tone).
- A check that walks the scene and the outcomes (see `check_police.gd`), added to `tools/verify.sh`.
  Note the change in docs/ADDONS.md.

Reference: docs/ADDONS.md, archive "The add-ons" (grep `Dialogue Manager`).
