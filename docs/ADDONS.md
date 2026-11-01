# Godot add-ons (moved out of CLAUDE.md, 2026-10-31)

Pre-approved (the user, 2026-10-30): install without asking, one at a time, free only, and
name it in the PR. Prefer GDScript-only
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
runtime by `police.gd`; editor plugin off, so no import plugin and no autoload). **Our own, not an add-on:**
`addons/nw_android_export/` (an editor plugin, on; it only marks Vulkan required in the Android
export's manifest; docs/archive/DEVELOPMENT-full.md "Android (Google Play)"). Candidates when a loop
needs them: Folder Import Rules, Lente photo mode, the In-app Review and Share plugins.

When to use Beehave and Dialogue Manager (decision rules and build patterns): skills `beehave-trees` and `dialogue-scenes` in `.claude/skills/`.
