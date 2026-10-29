#!/bin/zsh
# Build Nocna Warszawa for a connected iPhone, install it, launch it with game flags, copy the
# engine log back to the Mac, then stop the app. Only when the user has allowed device runs
# (see .claude/skills/device-run/SKILL.md) and nobody else is using the phone.
#
#   tools/device_run.sh --device=ID [--label=NAME] [--wait=SECONDS] [--done=REGEX]
#                       [--skip-build] [--dry-run] [-- game flags...]
#
#   --device=ID   the phone's identifier (or set NW_DEVICE); find it with
#                 `xcrun devicectl list devices`. Never write it into a tracked file.
#   --label=NAME  names the log (user://NAME.log on the phone) and the work folder
#                 build/device/NAME/ (default: run)
#   --wait=S      how long to wait for the result before stopping the app (default 120)
#   --done=REGEX  the log line that means the run is over (default: the bench's last lines)
#   --skip-build  install the app built by the last run with this label
#   --dry-run     print the commands instead of running them
#   game flags    passed to the game after `--`; --nosave is added if missing
#
# The game's print() output never reaches `devicectl --console`, and `log collect --device`
# needs root, so the game writes its log with Godot's --log-file into the app's Documents
# folder and this script copies it back every few seconds (`devicectl device copy from`).
# Each run's copy is build/device/NAME/NAME_<date-time>.log (NAME.log: the latest), with the
# bench's bench_result.txt and the streaming soak's stream_soak_result.txt beside it; the exit
# status is 3 when the --done line never came.
# Run tools/export_ios.sh first: the build starts from a snapshot of build/ios, so a later
# export can't change the project under xcodebuild.

emulate -L zsh
zmodload zsh/datetime

ROOT=${0:A:h:h}
device=${NW_DEVICE:-}
label=run
wait_s=120
done_re='bench audio peaks|bench detail: memory|^OVER$'
skip_build=0
dry=0
flags=()
while (( $# )); do
	case $1 in
		--device=*) device=${1#--device=} ;;
		--label=*) label=${1#--label=} ;;
		--wait=*) wait_s=${1#--wait=} ;;
		--done=*) done_re=${1#--done=} ;;
		--skip-build) skip_build=1 ;;
		--dry-run) dry=1 ;;
		-h|--help) sed -n '2,28p' $0; exit 0 ;;
		--) shift; flags=("$@"); break ;;
		*) print -r -- "unknown option $1 (try --help)"; exit 2 ;;
	esac
	shift
done
if [[ -z $device ]]; then
	print -r -- "no device: pass --device=ID or set NW_DEVICE (find it with: xcrun devicectl list devices)"
	exit 2
fi
[[ $label =~ '^[A-Za-z0-9_-]+$' ]] || { print -r -- "--label: letters, digits, _ and - only"; exit 2; }
[[ $wait_s == <-> ]] || { print -r -- "--wait takes seconds"; exit 2; }
(( ${flags[(Ie)--nosave]} )) || flags+=(--nosave)

bundle=$(sed -n 's/^application\/bundle_identifier="\(.*\)"$/\1/p' $ROOT/game/export_presets.cfg)
[[ -n $bundle ]] || { print -r -- "can't read the bundle identifier from game/export_presets.cfg"; exit 1; }
work=$ROOT/build/device/$label
app=$work/dd/Build/Products/Debug-iphoneos/NocnaWarszawa.app

# run CMD...: run it (stopped after 120 s: macOS has no `timeout`), or print it for --dry-run.
run() {
	if (( dry )); then print -r -- "+ ${(q-)@}"; return 0; fi
	perl -e 'alarm shift; exec @ARGV or die "cannot run $ARGV[0]: $!\n"' 120 "$@"
}

if (( ! skip_build )); then
	[[ -d $ROOT/build/ios/NocnaWarszawa.xcodeproj ]] || { print -r -- "no build/ios: run tools/export_ios.sh first"; exit 1; }
	run rm -rf $work/ios
	run mkdir -p $work
	# APFS clone (-c): instant and takes no space until something changes.
	run cp -cR $ROOT/build/ios $work/ios
	print -r -- "building for the device (log: $work/xcodebuild.log)..."
	if (( dry )); then
		run xcodebuild -project $work/ios/NocnaWarszawa.xcodeproj -scheme NocnaWarszawa -configuration Debug \
			-destination "id=$device" -derivedDataPath $work/dd -allowProvisioningUpdates build
	else
		xcodebuild -project $work/ios/NocnaWarszawa.xcodeproj -scheme NocnaWarszawa -configuration Debug \
			-destination "id=$device" -derivedDataPath $work/dd -allowProvisioningUpdates build > $work/xcodebuild.log 2>&1
		grep -q 'BUILD SUCCEEDED' $work/xcodebuild.log || {
			print -r -- "BUILD FAILED: $(grep -m1 'error:' $work/xcodebuild.log)"; exit 1; }
	fi
fi
(( dry )) || [[ -d $app ]] || { print -r -- "no app at $app (build first)"; exit 1; }

# In a dry run the commands are printed, so nothing is sent to a file.
quiet=/dev/null
launch_out=$work/launch.txt
(( dry )) && { quiet=/dev/stdout; launch_out=/dev/stdout; }
run xcrun devicectl device install app --device $device $app > $quiet || { print -r -- "install failed"; exit 1; }
run xcrun devicectl device process launch --device $device --terminate-existing $bundle \
	--log-file user://$label.log -- $flags > $launch_out 2>&1 || {
	print -r -- "launch failed: $(tail -3 $work/launch.txt)"; exit 1; }
(( dry )) && { print -r -- "(dry run: would poll Documents/$label.log every 8 s for up to $wait_s s, then stop the app)"; exit 0; }

# Loop G0+: every run keeps its own log (a second run with the same label used to overwrite the
# first's); $label.log is a copy of the latest. Each poll copies to a temporary file and keeps it
# only when it is at least as long as the last copy (a copy taken mid-write can come back short).
stamp=$(strftime %Y%m%d-%H%M%S $EPOCHSECONDS)
log=$work/${label}_$stamp.log
tmp=$work/.copy.log
rm -f $tmp
t=0
finished=0
while (( t < wait_s )); do
	sleep 8
	(( t += 8 ))
	run xcrun devicectl device copy from --device $device --domain-type appDataContainer \
		--domain-identifier $bundle --source Documents/$label.log --destination $tmp > /dev/null 2>&1
	if [[ -f $tmp ]] && (( $(wc -c < $tmp) >= $( [[ -f $log ]] && wc -c < $log || print 0) )); then
		mv -f $tmp $log
	fi
	[[ -f $log ]] && grep -qE "$done_re" $log && { finished=1; break; }
done
# One more copy a few seconds after the done line (or the wait), so the lines printed with it
# are in too; a short copy never replaces a longer one.
sleep 3
run xcrun devicectl device copy from --device $device --domain-type appDataContainer \
	--domain-identifier $bundle --source Documents/$label.log --destination $tmp > /dev/null 2>&1
if [[ -f $tmp ]] && (( $(wc -c < $tmp) >= $( [[ -f $log ]] && wc -c < $log || print 0) )); then
	mv -f $tmp $log
fi
rm -f $tmp
[[ -f $log ]] && cp -f $log $work/$label.log
# The bench writes its card as text, the streaming soak its numbers (loop G0+): copy them when
# there are any (each run under its own name too).
for result in bench_result stream_soak_result; do
	rm -f $work/$result.txt
	run xcrun devicectl device copy from --device $device --domain-type appDataContainer \
		--domain-identifier $bundle --source Documents/$result.txt --destination $work/$result.txt > /dev/null 2>&1
	[[ -f $work/$result.txt ]] && cp -f $work/$result.txt $work/${result}_$stamp.txt
done
pid=$(run xcrun devicectl device info processes --device $device 2>/dev/null | grep 'NocnaWarszawa.app' | awk '{print $1}' | head -1)
[[ -n $pid ]] && run xcrun devicectl device process terminate --device $device --pid $pid > /dev/null 2>&1

print -r -- "== $label after ${t}s ($( (( finished )) && print "done line seen" || print "NO done line: /$done_re/")): $log"
if [[ -f $log ]]; then
	# Loop G1: also the quality Auto picked and the governor's changes; G0+: the soak's lines.
	grep -E 'Metal|city built|sectors:|settings:|quality:|save:|ERROR|SCRIPT|bench|governor:|stream soak' $log | grep -v 'audio peaks' | cut -c1-400 | head -40
	(( finished )) || exit 3
else
	print -r -- "no log came back (did the app start? see $work/launch.txt)"
	exit 1
fi
