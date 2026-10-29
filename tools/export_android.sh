#!/bin/zsh
# Prebuild the city, then export the signed Android App Bundle for Google Play:
# build/android/nocnawarszawa-<version name>-<version code>.aab (the "Android" preset).
#
# usage: tools/export_android.sh [--skip-city] [--apk]
#   --skip-city  don't re-split the map or rebuild the prebuilt sectors (they are tracked;
#                use this when the map hasn't changed since the last bake)
#   --apk        a debug APK instead (build/android/nocnawarszawa-debug.apk, debug keystore),
#                for `adb install` on a test phone
#
# Needs (README, "Android (Google Play)"): Godot 4.7.2's Android export templates, the Android
# SDK and a JDK set in Godot's editor settings, and the upload key at
# ~/.android-keys/nocnawarszawa-upload.jks with its password in the login keychain
# (service nocnawarszawa-android-upload, account upload). No key, user or password is ever
# written to export_presets.cfg: Godot reads them from the environment below.
set -e
skip_city=0
apk=0
for arg in "$@"; do
	case $arg in
		--skip-city) skip_city=1 ;;
		--apk) apk=1 ;;
		*) echo "unknown option: $arg"; exit 2 ;;
	esac
done
cd "${0:A:h}/../game"

# The version comes from the preset, so the file name and Play's version code always agree.
opts=$(awk 'f&&/^\[preset\.[0-9]+\]/{exit} /^\[preset\.[0-9]+\]/{s=0} /^name="Android"/{s=1}
	s&&/^\[preset\.[0-9]+\.options\]/{f=1} f' export_presets.cfg)
[[ -n $opts ]] || { echo "no \"Android\" preset in game/export_presets.cfg"; exit 1; }
vname=$(print -r -- $opts | sed -n 's/^version\/name="\(.*\)"/\1/p')
vcode=$(print -r -- $opts | sed -n 's/^version\/code=\([0-9]*\)/\1/p')
package=$(print -r -- $opts | sed -n 's/^package\/unique_name="\(.*\)"/\1/p')

if (( ! skip_city )); then
	# The same two steps as tools/export_ios.sh: the map split into 512 m sectors, then each
	# sector's scene, the proxies and the index. Not --headless: the headless renderer discards
	# MultiMesh and texture data. This opens a window for a moment.
	python3 -I ../tools/bake_sectors.py map > /dev/null
	godot --path . --resolution 320x180 --script res://tools/bake_city.gd
fi

# Godot installs the Gradle build template (game/android/build, gitignored) on the first run.
template=()
[[ -f android/build/build.gradle ]] || template=(--install-android-build-template)
mkdir -p ../build/android

if (( apk )); then
	# A debug APK needs the Gradle build to write APK, not AAB: override the format for this run.
	out=../build/android/nocnawarszawa-debug.apk
	rm -f $out
	cp export_presets.cfg ../build/android/.export_presets.cfg.bak
	trap 'mv ../build/android/.export_presets.cfg.bak export_presets.cfg' EXIT
	perl -0pi -e 's/(name="Android".*?gradle_build\/export_format=)1/${1}0/s' export_presets.cfg
	godot --headless --path . $template --export-debug "Android" $out
else
	ks=$HOME/.android-keys/nocnawarszawa-upload.jks
	[[ -f $ks ]] || { echo "no upload key at $ks (README, \"Android (Google Play)\")"; exit 1; }
	export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$ks
	export GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload
	GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=$(security find-generic-password -a upload \
		-s nocnawarszawa-android-upload -w) || { echo "the upload key's password is not in the login keychain"; exit 1; }
	export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
	out=../build/android/nocnawarszawa-$vname-$vcode.aab
	rm -f $out
	godot --headless --path . $template --export-release "Android" $out
	unset GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
fi

[[ -f $out ]] || { echo "export failed: no $out"; exit 1; }
echo "built: build/android/${out:t}"
echo "size: $(( $(stat -f %z $out) / 1048576 )) MB ($(stat -f %z $out) bytes)"
echo "package: $package  version: $vname ($vcode)"
