---
name: beehave-trees
description: Decide whether new or changed NPC/agent behaviour should use the Beehave add-on, and how to build it (hand-ticked tree, leaves in police/bt). Use before adding or reworking any AI that picks between several behaviours (police, guards, a new street character, a mugger, a warden).
---

# Beehave in Around Warsaw: decide, then build

## 1. Decide (write the answer in the PR: "Beehave: yes/no, because ...")

Use Beehave only when ALL hold:
- the agent chooses between **4 or more behaviours** by conditions (patrol, chase, search, give up ...), not a linear script;
- **few instances at once** (about 10 or fewer ticking); it must not be a crowd;
- it can tick at **5 Hz**, not every frame.

Do NOT use it for: traffic, buses, trams, pedestrians, crowds (data-oriented loops, the phone's
frame grows with node count); race and job flows (`rivals.gd`, `jobs.gd`: linear state
machines with tested gates); anything per frame. A 2 to 3 state machine stays an `enum` and
`match`. Rewriting working code to Beehave needs a player-visible reason; "cleaner" is not one.

## 2. Build (the pattern that exists)

- Tree root: `scripts/police/police_tree.gd` (lean `BeehaveTree`: no editor plugin, no
  autoloads, `set_physics_process(false)`). Copy it; never enable the add-on's plugin.
- Leaves: `scripts/police/bt/` (`is_phase`, `is_role`, `is_pull_over` conditions; `unit_action`
  action). Add a small leaf rather than a big one; conditions read the unit, actions move the
  unit's car through the traffic API.
- The owner (`police.gd`) ticks the trees by hand at 5 Hz, only for units near the player
  (guards: 6 nearest within 150 m). Escalation and game rules stay in the owner, not in leaves.
- No new draw calls, no per-frame work; add a `spent_usec` timer and report bench before/after.
- A check in `game/tools/check_*.gd` (see `check_police.gd`) and its line in `tools/verify.sh`.
- New add-on file edits: keep the single local line in `debug/debugger_messages.gd`;
  note the change in docs/ADDONS.md.

Reference: docs/ADDONS.md, archive "The add-ons" (grep `beehave`), `/mnt/project-files/addons/beehave-dialogue-manager.md` if present.
