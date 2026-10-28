#!/bin/zsh
# The Nocna Warszawa verification set in one run, ending in one PASS / WARN / FAIL table.
#
#   tools/verify.sh            map data, the check scripts and the headless runs (~1-2 min)
#   tools/verify.sh --quick    map data, the check scripts, the plain and prebuilt runs (~30 s)
#   tools/verify.sh --ios      also tools/export_ios.sh and the unsigned xcodebuild. Note:
#                              export_ios.sh rebuilds game/map/city.scn (with a renderer, so a
#                              window opens for a moment): only when the loop may change it.
#   tools/verify.sh --only=steering,plain   just those steps (--list prints the names)
#   tools/verify.sh --logs=DIR              keep the logs there (default build/verify/<time>)
#
# Every game run is headless, passes --nosave and quits by itself (--quit-after; Godot also
# gets --fixed-fps 60 so a run covers the same game time on any Mac and its outcome repeats).
# A run passes when Godot exits 0 and prints no ERROR / WARNING lines; autopilot runs also
# report their outcome (WARN if the job, race or rescue hadn't finished when the run ended).
# Nothing here downloads anything, writes the save or settings, or talks to a phone.
# What it can't check: screenshots (tools/shots.sh, then look), the bench, the phone.
#
# Exit code: 0 when nothing FAILED (WARN is allowed), 1 otherwise, 2 for a usage error.

emulate -L zsh
setopt pipe_fail
zmodload zsh/datetime

ROOT=${0:A:h:h}
GAME=$ROOT/game
GODOT=${GODOT:-godot}
STEPS_ALL=(map steering settings hud landmarks sfx radio water water-prebuilt plain heli race kebab splash rain prebuilt classic)
STEPS_QUICK=(map steering settings hud landmarks sfx radio plain prebuilt)
# Longest a single step may take, in seconds, before it is stopped (macOS has no `timeout`).
STEP_LIMIT=${NW_STEP_LIMIT:-900}

want=()
quick=0
ios=0
logs=""
for arg in "$@"; do
	case $arg in
		--quick) quick=1 ;;
		--ios) ios=1 ;;
		--logs=*) logs=${arg#--logs=} ;;
		--only=*) want=(${(s:,:)${arg#--only=}}) ;;
		--list) print -r -- "steps: ${STEPS_ALL[*]} ios"; exit 0 ;;
		-h|--help) sed -n '2,22p' $0; exit 0 ;;
		*) print -r -- "unknown option $arg (try --help)"; exit 2 ;;
	esac
done
if (( ${#want} == 0 )); then
	if (( quick )); then want=($STEPS_QUICK); else want=($STEPS_ALL); fi
	(( ios )) && want+=(ios)
fi
for s in $want; do
	if (( ! ${STEPS_ALL[(Ie)$s]} )) && [[ $s != ios ]]; then
		print -r -- "unknown step '$s' (try --list)"; exit 2
	fi
done

if ! command -v $GODOT > /dev/null; then
	print -r -- "FAIL: '$GODOT' not found (Godot 4.7.2; set GODOT=/path/to/godot)"; exit 1
fi
[[ -z $logs ]] && logs=$ROOT/build/verify/$(strftime %Y%m%d-%H%M%S $EPOCHSECONDS)
mkdir -p $logs || exit 1

# Another Godot running (a bench, screenshots, another agent) makes this run slower and
# disturbs its frame times: say so, don't wait. (pgrep -x matches the process name only,
# so it never matches this script's own command line.)
others=$(pgrep -x Godot | wc -l | tr -d ' ')

rows=()
fails=0
warns=0
passes=0

# row RESULT NAME SECONDS DETAIL
row() {
	local res=$1 name=$2 secs=$3 detail=$4
	case $res in
		PASS) (( passes++ )) ;;
		WARN) (( warns++ )) ;;
		*) (( fails++ )) ;;
	esac
	rows+=("$(printf '%-24s %-5s %5ss  %s' "$name" "$res" "$secs" "$detail")")
	printf '%-24s %-5s %5ss  %s\n' "$name" "$res" "$secs" "$detail"
}

# limited SECONDS CMD...: run CMD, stop it after SECONDS (exit code 142 = stopped).
limited() {
	local secs=$1; shift
	perl -e 'alarm shift; exec @ARGV or die "cannot run $ARGV[0]: $!\n"' $secs "$@"
}

# problems LOG: the ERROR / WARNING lines Godot printed (push_error, push_warning, script
# errors, engine errors), one per line.
problems() {
	grep -E '^(ERROR|WARNING|SCRIPT ERROR|SCRIPT WARNING|USER ERROR|USER WARNING|Parse Error)' $1
}

# check NAME OKLINE GODOTARGS...: a SceneTree check script that prints an OK line.
check() {
	local name=$1 okline=$2; shift 2
	local logf=$logs/$name.log t0=$EPOCHREALTIME code
	( cd $GAME && limited $STEP_LIMIT $GODOT --headless --path . "$@" ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	local np=$(problems $logf | wc -l | tr -d ' ')
	local last=$(grep -E "$okline" $logf | tail -1)
	if (( code == 142 )); then
		row FAIL $name $secs "stopped after ${STEP_LIMIT}s: $logf"
	elif [[ -n $last ]] && grep -qE "${okline}.*OK" <<< $last && (( code == 0 && np == 0 )); then
		row PASS $name $secs "$last"
	else
		local first=$(problems $logf | head -1)
		[[ -z $first ]] && first=${last:-"no result line"}
		row FAIL $name $secs "exit $code, $np error/warning lines: ${first[1,140]} ($logf)"
	fi
}

# game NAME FRAMES OUTCOME GAMEARGS...: a headless game run with --nosave that quits after
# FRAMES frames; OUTCOME is a regex for the line that says the activity finished ("" = none).
game() {
	local name=$1 frames=$2 outcome=$3; shift 3
	local logf=$logs/run_$name.log t0=$EPOCHREALTIME code
	( cd $GAME && limited $STEP_LIMIT $GODOT --headless --path . --fixed-fps 60 --quit-after $frames \
		-- --nosave --notitle "$@" ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	local np=$(problems $logf | wc -l | tr -d ' ')
	local built=$(grep -m1 '^city built in' $logf)
	local label="run: $name"
	if (( code == 142 )); then
		row FAIL "$label" $secs "stopped after ${STEP_LIMIT}s ($logf)"
	elif (( code != 0 || np > 0 )); then
		local first=$(problems $logf | head -1)
		row FAIL "$label" $secs "exit $code, $np error/warning lines: ${${first:-crash, see log}[1,140]} ($logf)"
	elif [[ -z $built ]]; then
		row FAIL "$label" $secs "no 'city built' line: the city never finished building ($logf)"
	elif [[ -n $outcome ]]; then
		local fin=$(grep -E -m1 "$outcome" $logf)
		if [[ -n $fin ]]; then
			row PASS "$label" $secs "0 errors · ${fin[1,110]}"
		else
			row WARN "$label" $secs "0 errors, but no '$outcome' line in $frames frames ($(( frames / 60 )) s of play)"
		fi
	else
		row PASS "$label" $secs "0 errors · ${built[1,110]}"
	fi
}

run_ios() {
	local t0=$EPOCHREALTIME logf=$logs/ios.log code
	( limited $STEP_LIMIT $ROOT/tools/export_ios.sh && cd $ROOT && limited $STEP_LIMIT xcodebuild \
		-project build/ios/NocnaWarszawa.xcodeproj -scheme NocnaWarszawa \
		-destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	if (( code == 0 )) && grep -q 'BUILD SUCCEEDED' $logf; then
		row PASS "ios export + build" $secs "BUILD SUCCEEDED (unsigned, generic iOS); city.scn rebuilt"
	else
		local first=$(grep -m1 -E 'error:|BUILD FAILED|ERROR' $logf)
		row FAIL "ios export + build" $secs "exit $code: ${${first:-see log}[1,140]} ($logf)"
	fi
}

print -r -- "Nocna Warszawa verify · $(strftime '%Y-%m-%d %H:%M' $EPOCHSECONDS) · $($GODOT --version 2>/dev/null | tail -1) · logs $logs"
(( others > 0 )) && print -r -- "note: $others other Godot process(es) running: timings here are slower, and a bench running beside this is disturbed"
print -r -- ""

for s in $want; do
	case $s in
		map)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_map_data.py > $logs/map.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			stale=$(grep '^WARN' $logs/map.log | head -1)
			if (( code != 0 )); then
				row FAIL "map data" $secs "$(grep -m1 '^FAIL' $logs/map.log) ($logs/map.log)"
			elif [[ -n $stale ]]; then
				row WARN "map data" $secs "counts OK; ${stale[1,150]}"
			else
				row PASS "map data" $secs "trees3d, pois, graph, palm as expected; city.scn up to date"
			fi ;;
		steering) check steering 'check_steering:' --fixed-fps 60 --script res://tools/check_steering.gd ;;
		settings) check settings '^settings:' --script res://tools/check_settings.gd ;;
		# Loop 2e: the HUD at phone size: 44 pt controls, 11 / 13 pt text, the safe area, no overlaps.
		hud) check hud '^check_hud:' --script res://tools/check_hud.gd ;;
		landmarks) check landmarks '^landmark check:' --script res://tools/check_landmarks.gd ;;
		sfx) check sfx '^sfx:' --script res://tools/check_sfx.gd ;;
		radio) check radio '^radio loops:' --script res://tools/check_radio_loops.gd ;;
		# Loop 10a: where a car can get into the water (whole map), and the game's tow decisions.
		water) check water '^check_water:' --script res://tools/check_water.gd ;;
		water-prebuilt) check water-prebuilt '^check_water:' --script res://tools/check_water.gd -- --prebuilt ;;
		plain) game plain 600 "" ;;
		heli) game heli 6000 '^rescue (done|failed):' --mission=1 --heli --autopilot ;;
		race) game race 8000 '^race (won|lost):' --race=0 --autopilot ;;
		kebab) game kebab 9000 '^kebab delivered:' --kebab=0 --autopilot ;;
		# Loop 10a: into the river from the boulevard by Most Poniatowskiego with a delivery on:
		# the splash, then the tow onto a lane on dry land within 2 s, the job still running.
		splash) game splash 420 '^water: towed after [01][.][0-9]+ s .* m from a lane, dry; job on' \
			--drive-into-water=1015,-85 --kebab=0 ;;
		rain) game rain-night 600 "" --weather=rain --time=night ;;
		prebuilt) game prebuilt-night 600 "" --prebuilt --time=night ;;
		classic) game classic 600 "" --controls=classic ;;
		ios) run_ios ;;
	esac
done

print -r -- ""
print -r -- "check                    result   time  detail"
print -r -l -- $rows
total=$(( passes + warns + fails ))
if (( fails > 0 )); then
	print -r -- "RESULT: FAIL ($fails failed, $warns warned, $passes passed of $total)"
else
	print -r -- "RESULT: PASS ($passes passed, $warns warned of $total)"
fi
missing="screenshots (tools/shots.sh, then look at them), the bench before/after"
(( ${want[(Ie)ios]} )) || missing+=", the iOS build (--ios)"
print -r -- "Not covered: $missing, the phone."
(( fails == 0 ))
