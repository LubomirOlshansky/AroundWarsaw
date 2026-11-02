#!/bin/zsh
# Turn the Autopilot playtest plugin (game/addons/autopilot, ramenvr/autopilot, Apache-2.0) on or
# off in this checkout's game/project.godot. It stays OFF in git: the plugin's game-side autoload
# (AutopilotPlaytest) must never ship in a store build, so the exports refuse to run while it is on.
#
#   tools/autopilot.sh on       enable the editor plugin and register its autoload (then open the editor)
#   tools/autopilot.sh off      take both out again (before committing project.godot or exporting)
#   tools/autopilot.sh status   print on or off
#
# Editor play always passes --nosave ([editor] run/main_run_args in project.godot), so an
# Autopilot run never touches the player's save. The workflow: .claude/skills/autopilot-playtest.
set -e
cfg="${0:A:h}/../game/project.godot"
plugin='res://addons/autopilot/plugin.cfg'
autoload='AutopilotPlaytest="*res://addons/autopilot/playtest.gd"'
case ${1:-status} in
	on)
		python3 -I - "$cfg" "$plugin" "$autoload" <<'PY'
import re, sys
path, plugin, autoload = sys.argv[1:4]
s = open(path, encoding="utf-8").read()
m = re.search(r'^enabled=PackedStringArray\((.*)\)$', s, re.M)
if m and plugin not in m.group(1):
    inner = m.group(1).strip()
    s = s[:m.start(1)] + (inner + ", " if inner else "") + '"' + plugin + '"' + s[m.end(1):]
if autoload not in s:
    s = re.sub(r'^\[autoload\]\n\n', '[autoload]\n\n' + autoload + '\n', s, count=1, flags=re.M)
open(path, "w", encoding="utf-8").write(s)
PY
		echo "autopilot: on (open the editor: godot --editor --path game)" ;;
	off)
		python3 -I - "$cfg" "$plugin" "$autoload" <<'PY'
import sys
path, plugin, autoload = sys.argv[1:4]
s = open(path, encoding="utf-8").read()
s = s.replace(', "' + plugin + '"', "").replace('"' + plugin + '", ', "").replace('"' + plugin + '"', "")
s = s.replace(autoload + "\n", "")
open(path, "w", encoding="utf-8").write(s)
PY
		echo "autopilot: off" ;;
	status)
		grep -q '^AutopilotPlaytest=' "$cfg" && echo "autopilot: on" || echo "autopilot: off" ;;
	*) echo "usage: tools/autopilot.sh on|off|status" >&2; exit 2 ;;
esac
