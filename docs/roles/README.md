# Role briefs

Eight craft roles for Around Warsaw, written 2026-11-03 at F's request ("make skills: art director,
game designer, environment artist and so on"). Each file is a self-contained brief with skill-style
front matter (`name`, `description`), so it can be:

- **added as a skill in claude.ai** (Settings → Capabilities → Skills: upload or paste the file as a
  skill's `SKILL.md`). Skills can't be created from a cloud thread, so F adds them by hand;
- **pasted into a chat** as the first message, for a one-off session in that role (for example with
  the Fable model);
- **read by an agent** in the repo. The agents in `.claude/agents/` are the repo's working versions
  (tools, models, report formats); these briefs describe the role and its judgement, and say which
  agent file is its counterpart.

Each brief starts with the same short "The project" block so it works without the repo. Where a
brief names a repo file, the session reads it if it can, and says so if it can't.

| Brief | Owns | Counterpart in `.claude/agents/` |
| --- | --- | --- |
| [art-director.md](art-director.md) | the look, acceptance of visible work, landmarks from photos | `art-director` |
| [game-designer.md](game-designer.md) | missions, the first hour, the main line, progression | `game-designer` |
| [economy-designer.md](economy-designer.md) | money, prices, the post-beta "Od słoika do Złotej" layer | `game-designer` (economy part) |
| [driving-designer.md](driving-designer.md) | handling, camera, assists, road drivability | `gameplay-dev` + `map-engineer` |
| [environment-artist.md](environment-artist.md) | streets, buildings, parks, props | `object-modeler` + `map-engineer` |
| [narrative-writer.md](narrative-writer.md) | Warsaw humour, parodies, lines in Polish and English | `game-designer` (writing part) |
| [sound-designer.md](sound-designer.md) | radio, city sound, feedback sounds, haptics | none yet |
| [playtest-lead.md](playtest-lead.md) | test plans, the PT bug log, Autopilot and phone runs | `qa-tester` |

Keep them short. When a rule changes in CLAUDE.md, the art bible or the warsaw-tone skill, those files
win; update the brief's line that repeats it.

The research behind the economy and driving briefs: `docs/design/city-economy.md` and
`docs/GAMEPLAY_PLAN.md`.
