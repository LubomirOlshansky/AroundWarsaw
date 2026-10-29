#!/bin/zsh
# The Nocna Warszawa verification set in one run, ending in one PASS / WARN / FAIL table.
#
#   tools/verify.sh            map data, the check scripts and the headless runs (~1-2 min)
#   tools/verify.sh --quick    map data, the check scripts, the plain and prebuilt runs (~30 s)
#   tools/verify.sh --ios      also tools/export_ios.sh and the unsigned xcodebuild. Note:
#                              export_ios.sh splits the map into sectors and rebuilds the
#                              prebuilt city (game/map/sectors/*.scn, index.res, proxies.scn:
#                              with a renderer, so a window opens for a moment).
#   tools/verify.sh --only=steering,plain   just those steps (--list prints the names)
#   tools/verify.sh --logs=DIR              keep the logs there (default build/verify/<time>)
#
# `roads` runs tools/check_roads.py (loop 3a): the road and deck rules C1-C10 over the whole
# map; any finding not in tools/check_roads_allow.json FAILs (loop 3b; C4, C5, C9, C10 were a
# WARN before). `drive` runs game/tools/check_drive.gd (loop 3b): a car and a bus along every
# lane against the colliders, the autopilot over the bridges and tunnels. `drape` runs
# game/tools/check_drape.gd (loop 3b-2): the ground poking through the water, grass and plazas.
# `streets` runs tools/check_streets.py (map review B): poles on the asphalt, zebras off it,
# grass medians on tram tracks (S1, S2, S4 FAIL; S3, medians in a junction, is reported).
# `tiers` and `governor` (loop G1): the device tiers and the pixel image's size rule, and the
# frame governor's rules on scripted frames. `streaming` runs game/tools/check_streaming.gd
# (loop 3c) WITH a renderer (a window opens for a minute or two): every sector built from its
# file is the whole city, vertex for vertex; 10 spots rendered with --monolithic and with the
# prebuilt sectors streamed differ in at most 0.5 % of their pixels; a 3-minute soak over every
# sector misses no sector the car or the view needs (the 15-minute soak: README "Sectors and
# streaming").
# Loop 3g-1 (police, docs/design/police.md section 15): `police` runs game/tools/check_police.gd
# (P11 lines and flow, P12 the state machine with synthetic inputs); `police-runs` the scripted
# game runs P1-P7 on the prebuilt city (the lizak, the trap stop, an escape, caught, the three
# caps, the start grace, the cooldown), each judged by its `police:` lines, the złoty the same
# before and after; `police-soak` P13, the autopilot roaming Busy traffic with the police on at
# once (NW_SOAK_MINUTES of play, default 3; the full soak is 10: NW_SOAK_MINUTES=10
# tools/verify.sh --only=police-soak, ~70 s).
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
STEPS_ALL=(map roads streets drape drive drive-prebuilt steering settings tiers governor hud landmarks sfx radio water water-prebuilt streaming police plain heli race kebab splash rain prebuilt classic police-runs police-soak)
STEPS_QUICK=(map roads streets drape drive steering settings tiers governor hud landmarks sfx radio police plain prebuilt)
# Loop 3g-1: minutes of play in the police soak (P13; the full one is 10).
SOAK_MINUTES=${NW_SOAK_MINUTES:-3}
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

# shown NAME OKLINE GODOTARGS...: like check, with a renderer (loop 3c: pixels and meshes' data).
shown() {
	local name=$1 okline=$2; shift 2
	local logf=$logs/$name.log t0=$EPOCHREALTIME code
	( cd $GAME && limited $STEP_LIMIT $GODOT --path . --resolution 1280x720 "$@" ) > $logf 2>&1
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
		[[ -z $first ]] && first=$(grep -m1 'PROBLEM' $logf)
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

# Loop 3g-1: one police run (prebuilt city, --police-log); its log is $RUN_LOG and the caller
# judges its lines. P_FAIL collects what went wrong, P_NOTE what each run showed.
P_FAIL=()
P_NOTE=()
police_run() {
	local tag=$1 frames=$2; shift 2
	local logf=$logs/police_$tag.log code
	( cd $GAME && limited $STEP_LIMIT $GODOT --headless --path . --fixed-fps 60 --quit-after $frames \
		-- --nosave --notitle --prebuilt --police-log "$@" ) > $logf 2>&1
	code=$?
	local np=$(problems $logf | wc -l | tr -d ' ')
	if (( code != 0 || np > 0 )); then
		P_FAIL+=("$tag: exit $code, $np error/warning lines: $(problems $logf | head -1 | cut -c1-100)")
	fi
	# The złoty never change: every "wallet A zł → B zł" line has A = B.
	local bad=$(grep -E '^police: wallet [0-9]+ zł → [0-9]+ zł' $logf | awk '{ if ($3 != $6) print }' | head -1)
	[[ -n $bad ]] && P_FAIL+=("$tag: the złoty changed: $bad")
	RUN_LOG=$logf
}

# frame_of PATTERN LOG: the frame of the first `police:` line matching PATTERN (-1 if none).
frame_of() {
	local line=$(grep -E -m1 "$1" $2)
	[[ -z $line ]] && { print -- -1; return; }
	print -- ${${line##*\(frame }%%,*}
}

# expect TAG PATTERN LOG [NOTE]: the run printed a line matching PATTERN.
expect() {
	if grep -qE "$2" $3; then
		[[ -n $4 ]] && P_NOTE+=("$1 $4")
	else
		P_FAIL+=("$1: no line matching '$2' ($3)")
	fi
}

police_runs() {
	local t0=$EPOCHREALTIME f a b l
	P_FAIL=()
	P_NOTE=()
	# P1: the lizak within 0.4 s of the radar's 40 m (≥ 28 m before the officer at ~30 m/s), and
	# koguty 1 at most 1 s after passing the officer by 30 m (≤ 60 m past).
	police_run p1 900 --trap=2 --pedal=gas --police-now; f=$RUN_LOG
	expect P1 '^police: lizak \(trap 2, [0-9]+ km/h in 50, (2[89]|3[0-9]|40)\.[0-9] m before' $f "lizak"
	expect P1 '^police: L1 \(lizak ignored, [3-5][0-9]\.[0-9] m past' $f "L1"
	# P2: stopped by the officer: the pull-over (trap), the caution ≤ 10 s later, no chase.
	police_run p2 1500 --trap=2 --pedal=gas --police-auto=stop --police-now; f=$RUN_LOG
	expect P2 '^police: stopped 1?[0-9]\.[0-9] m from the officer' $f "stopped"
	a=$(frame_of '^police: pull-over trap' $f); b=$(frame_of '^police: caution n=1' $f)
	(( a > 0 && b > a && b - a <= 600 )) && P_NOTE+=("P2 caution $(printf '%.1f' $(( (b - a) / 60.0 )))s") || P_FAIL+=("P2: pull-over at frame $a, caution at $b ($f)")
	grep -qE '^police: L1' $f && P_FAIL+=("P2: a chase started ($f)")
	# P3: an escape ≤ 30 s after the start, +15 respect.
	police_run p3 2400 --police=1 --police-auto=escape; f=$RUN_LOG
	expect P3 '^police: escaped after ([0-9]|[12][0-9]|30)\.[0-9] s' $f "escaped"
	expect P3 '^wallet: \+15 respect' $f "+15"
	# P4: stopped by the chaser: the pull-over ≤ 2.5 s later, the caution ≤ 10 s after it.
	police_run p4 1300 --police=1 --police-auto=stop; f=$RUN_LOG
	a=$(frame_of '^police: stopped by unit' $f); b=$(frame_of '^police: pull-over' $f); l=$(frame_of '^police: caution' $f)
	(( a > 0 && b >= a && b - a <= 150 && l > b && l - b <= 600 )) && P_NOTE+=("P4 pull-over $(printf '%.1f' $(( (b - a) / 60.0 )))s, caution $(printf '%.1f' $(( (l - b) / 60.0 )))s") \
		|| P_FAIL+=("P4: stopped at frame $a, pull-over $b, caution $l ($f)")
	# P5: the caps, 30 / 40 / 45 s ± 0.5 s (no other traffic: no second unit raises the level).
	police_run p5_1 2100 --police=1 --police-auto=hold --traffic=empty; f=$RUN_LOG
	expect P5 '^police: end of shift after (29\.[5-9]|30\.[0-5]) s \(L1\)' $f "30s"
	police_run p5_2 2700 --police=2 --police-auto=hold --traffic=empty; f=$RUN_LOG
	expect P5 '^police: end of shift after (39\.[5-9]|40\.[0-5]) s \(L2\)' $f "40s"
	police_run p5_3 3000 --police=3 --police-auto=hold --traffic=empty; f=$RUN_LOG
	expect P5 '^police: end of shift after (44\.[5-9]|45\.[0-5]) s \(L3\)' $f "45s"
	# P6: the start grace: speeding through the trap gives nothing (before 60 s), never a chase.
	police_run p6 900 --trap=2 --pedal=gas; f=$RUN_LOG
	expect P6 '^police: trap 2: .*\(grace\)' $f "grace"
	grep -qE '^police: (L1|lizak)' $f && P_FAIL+=("P6: a lizak or a chase in the grace ($f)")
	# P7: after a chase (caught), two offences 60 s apart warn in the cooldown; a ram chases.
	police_run p7 7800 --police=1 --police-auto=stop --police-offence=4000:speed,7600:speed,7700:ram; f=$RUN_LOG
	a=$(grep -cE '^police: warn speed \(cooldown\)' $f)
	(( a == 2 )) && P_NOTE+=("P7 2 warnings") || P_FAIL+=("P7: $a 'warn speed (cooldown)' lines, want 2 ($f)")
	expect P7 '^police: L1 \(ram\)' $f "ram→L1"
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	if (( ${#P_FAIL} == 0 )); then
		row PASS "run: police P1-P7" $secs "0 errors · ${(j:, :)P_NOTE}"
	else
		row FAIL "run: police P1-P7" $secs "${P_FAIL[1][1,150]} (+$(( ${#P_FAIL} - 1 )) more)"
		print -rl -- "  ${^P_FAIL}"
	fi
}

# Loop 3g-1, P13: the autopilot roams Busy traffic with the police on from the start (runtime
# city). Passes with no errors, every chase that started ended (one may still run at the end),
# the złoty unchanged, the car never within 20 % of a screen edge in a chase (B4), the police
# cars within 1.5 m of a lane.
police_soak() {
	local t0=$EPOCHREALTIME frames=$(( SOAK_MINUTES * 3600 )) logf=$logs/run_police-soak.log code
	( cd $GAME && limited $STEP_LIMIT $GODOT --headless --path . --fixed-fps 60 --quit-after $frames \
		-- --nosave --notitle --autopilot --traffic=busy --police-now --police-log ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	local np=$(problems $logf | wc -l | tr -d ' ')
	local end=$(grep -m1 -E '^police: wallet [0-9]+ zł → [0-9]+ zł \(end' $logf)
	local label="run: police soak ${SOAK_MINUTES} min"
	if (( code != 0 || np > 0 )); then
		row FAIL "$label" $secs "exit $code, $np error/warning lines: $(problems $logf | head -1 | cut -c1-100) ($logf)"
		return
	fi
	if [[ -z $end ]]; then
		row FAIL "$label" $secs "no end line ($logf)"
		return
	fi
	local zl0=${${end#police: wallet }%% zł*} zl1=${${end#*→ }%% zł*}
	local started=${${end#*chases }%% started*} ended=${${end#*started, }%% ended*}
	local running=0
	[[ $end == *"1 running"* ]] && running=1
	local b4=${${end#*edge }%%;*} lanes=${${end#*lanes worst }%% m*}
	if (( zl0 != zl1 )); then
		row FAIL "$label" $secs "the złoty changed: $zl0 → $zl1 ($logf)"
	elif (( started != ended + running )); then
		row FAIL "$label" $secs "$started chases started, $ended ended ($logf)"
	elif (( b4 < 0.2 )); then
		row FAIL "$label" $secs "B4: the car came within $b4 of a screen edge in a chase ($logf)"
	elif (( lanes > 1.5 )); then
		row FAIL "$label" $secs "a police car $lanes m off its lane ($logf)"
	else
		row PASS "$label" $secs "0 errors · $started chases ($ended ended), wallet $zl0 zł → $zl1 zł, B4 ≥ $b4, lanes ≤ $lanes m"
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
		row PASS "ios export + build" $secs "BUILD SUCCEEDED (unsigned, generic iOS); sectors rebuilt"
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
				row PASS "map data" $secs "trees3d, pois, graph, palm as expected, over the sectors too; the prebuilt sectors up to date"
			fi ;;
		# Loop 3a: roads, decks, tunnels and the lane graph over the whole map (C1-C10, docs/DEMO.md 4.5).
		roads)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_roads.py --png=$logs/check_roads.png \
				--json=$logs/check_roads.json > $logs/roads.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_roads counts:' $logs/roads.log)
			counts=${counts#check_roads counts: }
			case $code in
				0) row PASS "roads" $secs "check_roads: OK · not allowed/found: $counts" ;;
				*) row FAIL "roads" $secs "$(grep -m1 '^check_roads:' $logs/roads.log) · $counts ($logs/roads.log)" ;;
			esac ;;
		# Map review B (2026-10-29): the streets at grade (poles on the asphalt, zebras off it,
		# grass medians on tram tracks; tools/check_streets.py S1-S4).
		streets)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_streets.py > $logs/streets.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_streets counts:' $logs/streets.log)
			counts=${counts#check_streets counts: }
			case $code in
				0) row PASS "streets" $secs "check_streets: OK · $counts" ;;
				*) row FAIL "streets" $secs "$(grep -m1 '^check_streets:' $logs/streets.log) · $counts ($logs/streets.log)" ;;
			esac ;;
		# Loop 3b-2: the bare ground poking through the areas laid on it (water, grass, plazas, sand).
		drape) check drape '^check_drape:' --script res://tools/check_drape.gd ;;
		# Loop 3b: every lane for a car and a bus against the colliders; the autopilot over the
		# bridges and tunnels (height jumps). The runtime city (the prebuilt one: --prebuilt).
		drive) check drive '^check_drive:' --script res://tools/check_drive.gd ;;
		drive-prebuilt) check drive-prebuilt '^check_drive:' --script res://tools/check_drive.gd -- --prebuilt ;;
		steering) check steering 'check_steering:' --fixed-fps 60 --script res://tools/check_steering.gd ;;
		settings) check settings '^settings:' --script res://tools/check_settings.gd ;;
		# Loop G1: model id -> tier, the pixel image at the phones' sizes; the governor's rules.
		tiers) check tiers '^check_tiers:' --script res://tools/check_tiers.gd ;;
		governor) check governor '^check_governor:' --script res://tools/check_governor.gd ;;
		# Loop 2e: the HUD at phone size: 44 pt controls, 11 / 13 pt text, the safe area, no overlaps.
		hud) check hud '^check_hud:' --script res://tools/check_hud.gd ;;
		landmarks) check landmarks '^landmark check:' --script res://tools/check_landmarks.gd ;;
		sfx) check sfx '^sfx:' --script res://tools/check_sfx.gd ;;
		radio) check radio '^radio loops:' --script res://tools/check_radio_loops.gd ;;
		# Loop 10a: where a car can get into the water (whole map), and the game's tow decisions.
		water) check water '^check_water:' --script res://tools/check_water.gd ;;
		water-prebuilt) check water-prebuilt '^check_water:' --script res://tools/check_water.gd -- --prebuilt ;;
		# Loop 3c: the sectors are the whole city (meshes, pixels at 10 spots), streaming misses nothing.
		streaming) shown streaming '^check_streaming:' --script res://tools/check_streaming.gd -- --keep=$logs/streaming ;;
		# Loop 3g-1: the police's lines, flow and state machine (P11, P12), the runs P1-P7, the soak P13.
		police) check police '^check_police:' --script res://tools/check_police.gd ;;
		police-runs) police_runs ;;
		police-soak) police_soak ;;
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
