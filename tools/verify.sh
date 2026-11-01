#!/bin/zsh
# The Around Warsaw verification set in one run, ending in one PASS / WARN / FAIL table.
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
# `ground` runs game/tools/check_ground.gd (loop 3d-2a, ~2 min, not in --quick): no ground left
# under what covers it whole, no hole where it was left out, the ground on the height rule.
# `streets` runs tools/check_streets.py (map review B): poles on the asphalt, zebras off it,
# grass medians on tram tracks (S1, S2, S4 FAIL; S3, medians in a junction, is reported).
# `stopassist` runs game/tools/check_stop_assist.gd (2026-10-31): the car brakes itself into a
# quest's ring from 30-90 km/h and holds for the quest's hold, never touches a car passing or driving
# away, lets BRAKE reverse out; the quests share the ring and "stopped" (no map; CI too).
# `spec` runs tools/check_spec.py (LANDMARKS 0.4): the landmark specs are complete.
# `pois` runs tools/check_pois.py (content POIs, 2026-10-31): the baked corner shops, metro
# entrances, bike docks, Leżaks and zones (Q1-Q6: none on the carriageway, a crossing, a kerb ramp,
# in anything solid or off the map; the density, the egg zone, the odd shares).
# `tiers` and `governor` (loop G1): the device tiers and the pixel image's size rule, and the
# frame governor's rules on scripted frames.
# Loop MW-1: `places` runs game/tools/check_places.gd: MOJA WARSZAWA's 75 places (Polish +
# English, the 70 characters, the demo box, the brand denylist, reachability as a WARN) and the
# notebook's finding and reward rules on synthetic inputs; it reads only centrum.json (CI too).
# The L-shaped map loop: `edge` runs game/tools/check_edge.gd: the helicopter's clamp along the
# map's outline (random moves, four flights past the inner corner), the rescue spots inside the
# outline, the minimap's mesh over the corner left outside; centrum.json only (CI too).
# Loop MW-5: `radio` also checks PÓŁNOC FM (its 7 tracks and seams, the hours, reruns, the host,
# the unlocks); `sounds` runs game/tools/check_city_sounds.gd: the city's sounds at the notebook's
# places (the emitters, the hours, the cap of 8, the bells, the 02:00 beat); centrum.json only (CI too).
# Loop MW-6: `eggs` runs game/tools/check_eggs.gd: the 47 egg cards (words, places, rewards), each
# reachable egg's trigger on synthetic inputs (fires with its conditions, not without), the
# waiting ones listed; `tape` runs game/tools/check_tape.gd: KASETA's 20 then cards, the ghosts
# (one draw call, built only within 150 m), the button, the first-play reward and the dither;
# both read only centrum.json (CI too). Loop MW-3: `crowds` runs game/tools/check_crowds.gd: the
# city clock and the Dawn look, the queues, the door, the steps, Plan C, the police's hours, the
# dawn crowd's routes and walkers, the crowd eggs (E03 E04 E10 E14 E15); centrum.json only (CI too).
# Loop MW-2: `parodies` runs game/tools/check_parodies.gd: the stamp card, the detour, the couriers'
# counts, the Frogs' and venues' picks and walls (2D), the Leżaks and metro entrances off the
# lanes, no real brand, the lines and the font, the wall ray on a synthetic facade, the stamps,
# the knock and the two Frogs/Leżak eggs once, the cost; centrum.json only (CI too).
# Loop jobs-2: `jobs2` runs game/tools/check_side_jobs.gd: the courier race (night, 1 in 4, the
# 1.6 × detour rule, the rider's way and speed, a win's +30 zł +30 respect once), the Leżak round-up
# (the pay, the boot of 5, the depots, ten Leżaks on the real map, late, ✕, back by morning), the
# payphone by Plac Konstytucji and E40 once; centrum.json only (CI too).
# Loop couriers: `couriers` runs game/tools/check_couriers.gd: the Pędzik couriers waiting at the kebab
# stands at night (1 or 2, none by day, the race's take), the kerb riders on the real lane graph (the
# count in the band, on the kerb line, through the junctions), the swerve / hop on synthetic inputs and
# a car driven at one (never in its footprint), the near miss's line once per 30 s; centrum.json only (CI too).
# Loop MW-4: `life` runs game/tools/check_city_life.gd: the dogs' hours and caps, the horn's rate
# limits, the Wiralek cycle on synthetic dates, the "Na czasie" pay, the Zając, Fat Thursday, the
# life eggs, the meshes and the tick's cost; centrum.json only (CI too). `life-soak` (not in
# --quick, ~3 min) drives the car at the walkers and riders for 10 minutes of play: no overlaps.
# Loop night-buses: `buses` runs game/tools/check_buses.gd: the N sign's hours and mesh, the
# Centralny gatherings on a synthetic clock (rings of 5-8), the bays and stops, the stop figures'
# cap, the horn's rate limit, E23/E24/E25 once each; centrum.json only (CI too).
# The vintage-tram loop: `oldtram` runs game/tools/check_old_tram.gd: the old set's window (weekends
# 09-19, Live Jun-Sep) and one run an hour, the follow count and its reset, the look's draw-call
# budget (2 car meshes, no node added), a run on the real tracks finding E39 once; centrum.json only
# (CI too).
# The garage loop: `garage` runs game/tools/check_garage.gd: Warsztat u Mirka's paints and rules,
# buying and switching (10 seeded walks), the save, the car's paint, Mirek's lines, E01 and E21
# once; no map at all (CI too).
# Loop 3h slice 1: `save` runs game/tools/check_save.gd: save v2 (a version-1 fixture built in the
# check migrates keeping every section, a backup of the old file, the round trip, a newer file never
# overwritten, --nosave writes nothing, settings.cfg's version; save and resume: the [session] spot,
# NOWA GRA's wipe and its save.prev.cfg copy, the title's KONTYNUUJ / NOWA GRA / TAK / NIE); `districts` runs
# game/tools/check_districts.gd: the districts' data, coverage and ties, discovery, the "?" marks,
# completion and the full map's fog; neither needs a map (CI too). Loop 3h slice 2: `syrenki` runs
# game/tools/check_syrenki.gd: the 20 Syrenki's data and words, a find, the reward ladder (the paints
# "scale" at 5 and "silver" at 20, 150 zł at 10, once each), the save round trip and the districts'
# completion; no map (CI too). Loop 3h slice 3: `ladder` runs game/tools/check_ladder.gd: the rival
# ladder's order, thresholds and pace, the gating and the locked prompt's words, the refusal and
# final lines, the save (round trip, a v2/v1 file without [ladder], --nosave writes nothing,
# --ladder=N) and, from the committed centrum.json's lane graph, the final "Trzy mosty"'s three
# bridges (east, west, east), its legs and its start and finish (CI too). Loop 3h slice 4: `first10`
# runs game/tools/check_first10.gd: the guide's ten beats and windows, who gets the guide, three
# synthetic players through the director's rules (each beat in its window, the fallbacks, a beat
# waiting for a job), the first race's rubber band in a 1-D race, the words; `endcard` runs
# game/tools/check_end_card.gd: the end card's trigger on fixture wallets (final + 9 jobs no, + 10
# yes, seen no), the card and its button, the save's [intro]; neither needs a map (CI too).
# `first10-run` (not in --quick, ~12 min) is the headless replay: --first10 --autopilot plays the
# first 10 minutes on the real city (the stand, the guided order, Halina's race, the trap, the
# call, the helicopter, the tape, Powiśle, the garage) and passes on `first10: OK`.
# The main line (2026-10-31): `mainline` runs game/tools/check_main_line.gd: main_line.gd's step from
# the facts in each chapter (the guide, the ladder, the final, the jobs to the end card), its words
# and the ladder's pacing (the side quests' respect to the final); no map (CI too).
# `streaming` runs game/tools/check_streaming.gd
# (loop 3c) WITH a renderer (a window opens for a minute or two): every sector built from its
# file is the whole city, vertex for vertex; 10 spots rendered with --monolithic and with the
# prebuilt sectors streamed differ in at most 0.5 % of their pixels; a 3-minute soak over every
# sector misses no sector the car or the view needs (the 15-minute soak: README "Sectors and
# streaming"); loop 3d-2b: and two fast passes (the helicopter at its highest, the car at 45 m/s)
# miss none either; the loading fix (2026-10-31): five more (the helicopter low with turns, a car to
# helicopter switch, the start, looks at far targets, jumps): no proxy close up (~13 min in all).
# Loop 3g-1 (police, docs/design/police.md section 15): `police` runs game/tools/check_police.gd
# (P11 lines and flow, P12 the state machine with synthetic inputs); `police-runs` the scripted
# game runs P1-P7 on the prebuilt city (the lizak, the trap stop, an escape, caught, the three
# caps, the start grace, the cooldown), each judged by its `police:` lines, the złoty the same
# before and after, then (loop 3g-2) part two's runs: the escort, the guards, the clamp, the
# first contact, the kebab's frozen heat, a race's escape; `police-soak` P13, the autopilot roaming Busy traffic with the police on at
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
STEPS_ALL=(map roads streets outline pois spec lod2 drape ground drive drive-prebuilt steering stopassist settings tiers governor hud places edge eggs tape crowds life buses oldtram garage save districts syrenki ladder first10 mainline endcard parodies jobs2 couriers rides cost landmarks sites meshq sfx radio sounds water water-prebuilt streaming police plain ram heli race trzy-mosty first10-run kebab ride ride-police splash rain prebuilt classic police-runs police-soak life-soak)
STEPS_QUICK=(map roads streets outline pois spec drape drive steering stopassist settings tiers governor hud places edge eggs tape crowds life buses oldtram garage save districts syrenki ladder first10 mainline endcard parodies jobs2 couriers rides cost landmarks sites meshq sfx radio sounds police plain ram prebuilt)
# Loop 3g-1: minutes of play in the police soak (P13; the full one is 10).
SOAK_MINUTES=${NW_SOAK_MINUTES:-3}
# Longest a single step may take, in seconds, before it is stopped (macOS has no `timeout`).
STEP_LIMIT=${NW_STEP_LIMIT:-900}

# A fresh clone or worktree has no game/.godot class cache yet: every script step then fails
# with "Could not find type PhantomCameraHost" (or hangs). Import once first (~3 s).
if [[ ! -f $GAME/.godot/global_script_class_cache.cfg ]]; then
	print "verify: importing the project first (no game/.godot yet)"
	$GODOT --headless --path $GAME --import > /dev/null 2>&1
fi

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
		# Loop radio-playlists: a "<name>: WARN ..." line before the OK line makes the row a WARN.
		local warn=$(grep -m1 -E "^${name}: WARN" $logf)
		if [[ -n $warn ]]; then
			row WARN $name $secs "${warn[1,140]}"
		else
			row PASS $name $secs "$last"
		fi
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
	police_runs2
}

# Loop 3g-2 (police, part two): the escort on rescue 9 (joins +10 s, leads 12-26 m ahead), the
# guards (the whistle and the 3 s run, no chase; the talk on stopping by one), the clamp (on 10 s
# after the countdown, off 10 s later or at once on Przepraszam), the first contact (the routine
# check), the kebab's heat frozen on the card, a race's escape marked +20 %. Same judging as P1-P7.
police_runs2() {
	local t0=$EPOCHREALTIME f
	P_FAIL=()
	P_NOTE=()
	police_run e1 2400 --mission=9 --escort --police-auto=follow --traffic=empty; f=$RUN_LOG
	expect E1 '^police: escort joined \(unit [0-9]+, .*rescue clock \+10 s' $f "joined +10s"
	expect E1 '^police: escort status: lead, (1[2-9]|2[0-6]) m ahead' $f "leads"
	police_run g1 1500 --guards --zone-cap; f=$RUN_LOG
	expect G1 '^guard: whistle \(post ' $f "whistle"
	expect G1 '^guard: gave up ' $f "run 3s"
	grep -qE '^guard: guard car following' $f && P_NOTE+=("G1 car follows")
	grep -qE '^police: (L1|L2|L3|warn)' $f && P_FAIL+=("G1: the police reacted to the guards' zone ($f)")
	police_run g2 1500 --guards=talk; f=$RUN_LOG
	expect G2 '^police: guard talk done' $f "talk"
	police_run c1 1500 --clamp; f=$RUN_LOG
	expect C1 '^guard: clamp on \(10\.0 s' $f "on"
	expect C1 '^guard: clamp off \(10 s\)' $f "off 10s"
	police_run c2 900 --clamp=sorry; f=$RUN_LOG
	expect C2 '^guard: clamp off \(sorry' $f "sorry"
	police_run f1 1500 --first-contact --pedal=gas --police-auto=stop; f=$RUN_LOG
	expect F1 '^police: first contact done \(routine check\)' $f "routine"
	grep -qE '^police: L1' $f && P_FAIL+=("F1: a chase started ($f)")
	police_run k1 900 --kebab=1 --pullover=kebab --police-auto=stop; f=$RUN_LOG
	expect K1 '^police: kebab heat frozen' $f "frozen"
	expect K1 '^police: kebab heat runs again' $f "runs again"
	police_run r1 2400 --race=1 --police=1 --police-auto=escape; f=$RUN_LOG
	expect R1 '^police: race marked \+20 %' $f "+20%"
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	if (( ${#P_FAIL} == 0 )); then
		row PASS "run: police part two" $secs "0 errors · ${(j:, :)P_NOTE}"
	else
		row FAIL "run: police part two" $secs "${P_FAIL[1][1,150]} (+$(( ${#P_FAIL} - 1 )) more)"
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

# Loop MW-4 (vision 5's acceptance): the car driven at the dog walkers and riders for
# NW_LIFE_SOAK_MINUTES of play (default 10) on a Friday dusk; passes with no errors, some met and
# no dog, walker or rider ever inside the car's footprint (`life: soak done ... overlaps 0`).
life_soak() {
	local mins=${NW_LIFE_SOAK_MINUTES:-10}
	local t0=$EPOCHREALTIME frames=$(( mins * 3600 )) logf=$logs/run_life-soak.log code
	( cd $GAME && limited $STEP_LIMIT $GODOT --headless --path . --fixed-fps 60 --quit-after $frames \
		-- --nosave --notitle --life-soak ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	local np=$(problems $logf | wc -l | tr -d ' ')
	local end=$(grep -m1 '^life: soak done' $logf)
	local label="run: life soak $mins min"
	if (( code != 0 || np > 0 )); then
		row FAIL "$label" $secs "exit $code, $np error/warning lines: $(problems $logf | head -1 | cut -c1-100) ($logf)"
	elif [[ -z $end ]]; then
		row FAIL "$label" $secs "no 'life: soak done' line ($logf)"
	elif [[ $end != *"overlaps 0 "* ]]; then
		row FAIL "$label" $secs "${end[1,140]} ($logf)"
	elif [[ $end == *"dogs met 0 "* ]]; then
		row WARN "$label" $secs "met no dog: ${end[1,120]}"
	else
		row PASS "$label" $secs "0 errors · ${end[7,130]}"
	fi
}

# Loop 2d-1 x 3g-1: ride 8 with a pull-over at frame 1500; passes with no errors, exactly one
# `ride: stars 4.0 (police −1.0)` line and the pull-over done.
ride_police() {
	local logf=$logs/run_ride-police.log t0=$EPOCHREALTIME code
	( cd $GAME && limited $STEP_LIMIT $GODOT --headless --path . --fixed-fps 60 --quit-after 2400 \
		-- --nosave --notitle --prebuilt --ride=8 --passenger=believer --ride-quirk=river --autopilot --parody-log \
		--police-log --pullover=generic --pullover-frame=1500 ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	local np=$(problems $logf | wc -l | tr -d ' ')
	local stars=$(grep -c -- '(police −' $logf)
	local one=$(grep -m1 '^ride: stars 4\.0 (police −1\.0)' $logf)
	if (( code == 0 && np == 0 && stars == 1 )) && [[ -n $one ]] && grep -q '^police: pull-over done' $logf; then
		row PASS "run: ride-police" $secs "0 errors · $one, once"
	else
		row FAIL "run: ride-police" $secs "exit $code, $np error lines, $stars police star lines, '${one:-none}' ($logf)"
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

print -r -- "Around Warsaw verify · $(strftime '%Y-%m-%d %H:%M' $EPOCHSECONDS) · $($GODOT --version 2>/dev/null | tail -1) · logs $logs"
(( others > 0 )) && print -r -- "note: $others other Godot process(es) running: timings here are slower, and a bench running beside this is disturbed"
print -r -- ""

# Loop 3d-1: the sector split and the prebuilt sectors are derived and not committed (a fresh
# clone has none): make them first when they are missing (tools/setup_map.sh, ~20 s, a window
# opens). Stale ones (made from other inputs) stay a WARN of the map step, as before.
if ! python3 -I $ROOT/tools/check_map_data.py --fresh > $logs/setup_map.log 2>&1 && grep -q 'missing' $logs/setup_map.log; then
	print -r -- "note: $(head -1 $logs/setup_map.log); running tools/setup_map.sh (a window opens)"
	if ! $ROOT/tools/setup_map.sh >> $logs/setup_map.log 2>&1; then
		print -r -- "note: tools/setup_map.sh failed ($logs/setup_map.log): the game runs below will fail"
	fi
fi

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
		# Map north (2026-10-31): nothing of the map where the map isn't (its bounds without the
		# corner left `outside`), every sector on the map (tools/check_outline.py O1-O5; O6, dead
		# ends on the extension's edge, reported).
		outline)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_outline.py > $logs/outline.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_outline counts:' $logs/outline.log)
			counts=${counts#check_outline counts: }
			case $code in
				0) row PASS "outline" $secs "check_outline: OK · $counts" ;;
				*) row FAIL "outline" $secs "$(grep -m1 '^check_outline:' $logs/outline.log | tail -1) · $counts ($logs/outline.log)" ;;
			esac ;;
		# Content POIs (2026-10-31): the street pois of tools/bake_street_pois.py (corner shops, metro
		# entrances, bike docks, the Leżaks and their zones): Q1-Q6 of tools/check_pois.py over the whole
		# map (no scooter on a carriageway, crossing or kerb ramp, in anything solid, off the map; ~4 s).
		pois)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_pois.py > $logs/pois.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_pois counts:' $logs/pois.log)
			counts=${counts#check_pois counts: }
			case $code in
				0) row PASS "pois" $secs "check_pois: OK · $counts" ;;
				*) row FAIL "pois" $secs "$(grep '^check_pois: ' $logs/pois.log | tail -1) · $counts ($logs/pois.log)" ;;
			esac ;;
		# Landmark specs (LANDMARKS 0.4): every docs/landmarks/specs/*.md has all eight sections, a
		# detail level, a triangle budget and a filled parts table (tools/check_spec.py; ~0.1 s).
		spec)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_spec.py --selftest > $logs/spec.log 2>&1 && python3 -I $ROOT/tools/check_spec.py >> $logs/spec.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_spec counts:' $logs/spec.log)
			counts=${counts#check_spec counts: }
			case $code in
				0) row PASS "spec" $secs "check_spec: OK · $counts" ;;
				*) row FAIL "spec" $secs "$(grep '^check_spec: ' $logs/spec.log | tail -1) · $counts ($logs/spec.log)" ;;
			esac ;;
		# Map north: the LoD2 models and the OSM blocks never both (L1), never neither (L2), at most
		# the counts recorded in tools/check_lod2.py (not in --quick: ~35 s; needs lod2.json).
		lod2)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_lod2.py --quiet > $logs/lod2.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_lod2 counts:' $logs/lod2.log)
			counts=${counts#check_lod2 counts: }
			case $code in
				0) row PASS "lod2" $secs "$(grep -m1 -E '^check_lod2: (OK|no )' $logs/lod2.log) · $counts" ;;
				*) row FAIL "lod2" $secs "$(grep -m1 '^check_lod2: ' $logs/lod2.log | tail -1) · $counts ($logs/lod2.log)" ;;
			esac ;;
		# Loop 3b-2: the bare ground poking through the areas laid on it (water, grass, plazas, sand).
		drape) check drape '^check_drape:' --script res://tools/check_drape.gd ;;
		# Loop 3d-2a: the ground left out under the layers that cover it, no holes, on the heights.
		ground) check ground '^check_ground:' --script res://tools/check_ground.gd ;;
		# Loop 3b: every lane for a car and a bus against the colliders; the autopilot over the
		# bridges and tunnels (height jumps). The runtime city (the prebuilt one: --prebuilt).
		drive) check drive '^check_drive:' --script res://tools/check_drive.gd ;;
		drive-prebuilt) check drive-prebuilt '^check_drive:' --script res://tools/check_drive.gd -- --prebuilt ;;
		steering) check steering 'check_steering:' --fixed-fps 60 --script res://tools/check_steering.gd ;;
		# The quest stop assist: the car brakes itself into a quest's ring and holds for the hold.
		stopassist) check stopassist '^check_stop_assist:' --fixed-fps 60 --script res://tools/check_stop_assist.gd ;;
		settings) check settings '^settings:' --script res://tools/check_settings.gd ;;
		# Loop G1: model id -> tier, the pixel image at the phones' sizes; the governor's rules.
		tiers) check tiers '^check_tiers:' --script res://tools/check_tiers.gd ;;
		governor) check governor '^check_governor:' --script res://tools/check_governor.gd ;;
		# Loop 2e: the HUD at phone size: 44 pt controls, 11 / 13 pt text, the safe area, no overlaps.
		hud) check hud '^check_hud:' --script res://tools/check_hud.gd ;;
		places) check places '^check_places:' --script res://tools/check_places.gd ;;
		edge) check edge '^check_edge:' --script res://tools/check_edge.gd ;;
		# Loop MW-6: the egg cards and their triggers; KASETA's then cards and ghosts.
		eggs) check eggs '^check_eggs:' --script res://tools/check_eggs.gd ;;
		tape) check tape '^check_tape:' --script res://tools/check_tape.gd ;;
		# Loop MW-3: the night and the river's crowds, their rules on synthetic clocks, the crowd eggs.
		crowds) check crowds '^check_crowds:' --script res://tools/check_crowds.gd ;;
		# Loop MW-2: the storefronts and parodies (Frogs, venues, Leżaks, metro, stamps, eggs).
		parodies) check parodies '^check_parodies:' --script res://tools/check_parodies.gd ;;
		# Loop jobs-2: the courier race, the Leżak round-up, the payphone and E40.
		jobs2) check jobs2 '^check_side_jobs:' --script res://tools/check_side_jobs.gd ;;
		# Loop couriers: the waiting couriers, the kerb riders, the dodge, the near miss's line.
		couriers) check couriers '^check_couriers:' --script res://tools/check_couriers.gd ;;
		# Loop MW-4: everyday life and trends: dogs, riders, runners, Kolka, the Wiralek cycle, the
		# "Na czasie" pay, the Zając, Fat Thursday, the life eggs (E16 E18-E20 E27-E30).
		life) check life '^check_city_life:' --script res://tools/check_city_life.gd ;;
		buses) check buses '^check_buses:' --script res://tools/check_buses.gd ;;
		oldtram) check oldtram '^check_old_tram:' --script res://tools/check_old_tram.gd ;;
		garage) check garage '^check_garage:' --script res://tools/check_garage.gd ;;
		save) check save '^check_save:' --script res://tools/check_save.gd ;;
		districts) check districts '^check_districts:' --script res://tools/check_districts.gd ;;
		syrenki) check syrenki '^syrenki:' --script res://tools/check_syrenki.gd ;;
		ladder) check ladder '^ladder:' --script res://tools/check_ladder.gd ;;
		first10) check first10 '^first10:' --script res://tools/check_first10.gd ;;
		mainline) check mainline '^main_line:' --script res://tools/check_main_line.gd ;;
		endcard) check endcard '^end_card:' --script res://tools/check_end_card.gd ;;
		life-soak) life_soak ;;
		# Loop 2d-1: Podwózka's star and pay tables, the streak and the cancel rules, its lines.
		rides) check rides '^check_rides:' --script res://tools/check_rides.gd ;;
		cost) check cost '^check_cost_cuts:' --script res://tools/check_cost_cuts.gd ;;
		landmarks) check landmarks '^landmark check:' --script res://tools/check_landmarks.gd ;;
		# The museum and Plac loop: Muzeum Narodowe, Hotel Europejski and the Tomb from centrum.json
		# alone (found, what they replace, triangles, one material, cards; no terrain or sectors).
		sites) check sites '^check_sites:' --script res://tools/check_sites.gd ;;
		meshq) check meshq '^check_mesh_quality:' --script res://tools/check_mesh_quality.gd ;;
		sfx) check sfx '^sfx:' --script res://tools/check_sfx.gd ;;
		radio) check radio '^radio:' --script res://tools/check_radio.gd ;;
		sounds) check sounds '^city_sounds:' --script res://tools/check_city_sounds.gd ;;
		# Loop 10a: where a car can get into the water (whole map), and the game's tow decisions.
		water) check water '^check_water:' --script res://tools/check_water.gd ;;
		water-prebuilt) check water-prebuilt '^check_water:' --script res://tools/check_water.gd -- --prebuilt ;;
		# Loop 3c: the sectors are the whole city (meshes, pixels at 10 spots), streaming misses nothing.
		# The loading fix (2026-10-31): seven passes now, ~13 min: at least 25 min before it's stopped.
		streaming) STEP_LIMIT=$(( STEP_LIMIT > 1500 ? STEP_LIMIT : 1500 )) shown streaming '^check_streaming:' --script res://tools/check_streaming.gd -- --keep=$logs/streaming ;;
		# Loop 3g-1: the police's lines, flow and state machine (P11, P12), the runs P1-P7, the soak P13.
		police) check police '^check_police:' --script res://tools/check_police.gd ;;
		police-runs) police_runs ;;
		police-soak) police_soak ;;
		plain) game plain 600 "" ;;
		heli) game heli 6000 '^rescue (done|failed):' --mission=1 --heli --autopilot ;;
		race) game race 8000 '^race (won|lost):' --race=0 --autopilot ;;
		# Loop 3h slice 3: the final "Trzy mosty" from its last bridge (the whole race is ~14 min of play).
		trzy-mosty) game trzy-mosty 9000 '^trzy mosty (won|lost):' --trzy-mosty=3 --autopilot ;;
		# Loop 3h slice 4: the first 10 minutes replayed (the director quits after the garage, ~575 s).
		first10-run) STEP_LIMIT=$(( STEP_LIMIT > 1500 ? STEP_LIMIT : 1500 )) game first10-run 48000 '^first10: OK' --first10 --autopilot ;;
		# Loop 3d-1: 15000 frames: on the demo map order 0 goes 1,023 m by road (Oboźna 1) and is
		# delivered at 219.8 s of play (9000 frames = 150 s ended it on the way). Content POIs
		# (2026-10-31): 11 places' addresses joined the address list, so the order's shuffle picks
		# Emiliana Konopczyńskiego 3, 1,266 m by road: 21000 frames (350 s of play).
		kebab) game kebab 21000 '^kebab delivered:' --kebab=0 --autopilot ;;
		# Loop 2d-1: a Podwózka ride by the app's route: a passenger 34 m off the pin, a GPS believer,
		# the river quirk (its waypoint on dry land, the `ride: quirk river` line says how far from
		# the water), the stars and the pay (`ride: pay`, the wallet before and after).
		# Loop 3d-1: 30000 frames: on the demo map (east edge 21.056) the river quirk's legs run
		# 1.7-1.8 km by road and the pay came after 20000 frames (333 s of play).
		ride) game ride 30000 '^ride: pay' --ride=8 --passenger=believer --ride-quirk=river --autopilot --parody-log ;;
		# Loop 2d-1 x 3g-1: a pull-over 25 s into that ride takes exactly one star (police.gd calls
		# rides.on_pulled_over() when the conversation ends), on the prebuilt city.
		ride-police) ride_police ;;
		# Loop 10a: into the river from the boulevard by Most Poniatowskiego with a delivery on:
		# the splash, then the tow onto a lane on dry land within 2 s, the job still running.
		splash) game splash 420 '^water: towed after [01][.][0-9]+ s .* m from a lane, dry; job on' \
			--drive-into-water=1015,-85 --kebab=0 ;;
		# The driving-feel loop: the car rams the back of a traffic car in the real city and must
		# get past it within 10 s (the hit, the shove and the time are in the line).
		ram) game ram 1000 '^ram test: past it' --ram-test --no-police ;;
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
