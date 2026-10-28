#!/bin/zsh
# Prebuild the city, then export the Godot project as an Xcode project in build/ios.
set -e
cd "${0:A:h}/../game"
# Not --headless: the headless renderer discards MultiMesh and texture data, which would
# leave the prebuilt city without trees, cars or AO. This opens a window for a moment.
godot --path . --resolution 320x180 --script res://tools/bake_city.gd
mkdir -p ../build/ios
godot --headless --path . --export-debug "iOS" ../build/ios/NocnaWarszawa.ipa
# Loop 2b: Xcode's Run button attaches the debugger and, by default, Metal API validation and
# GPU frame capture, which make every draw call several times slower on the phone. Switch both
# off in the scheme Godot writes (Product > Scheme > Edit Scheme > Run > Diagnostics/Options).
scheme=../build/ios/NocnaWarszawa.xcodeproj/xcshareddata/xcschemes/NocnaWarszawa.xcscheme
if [[ -f $scheme ]] && ! grep -q enableGPUValidationMode $scheme; then
	perl -0pi -e 's/(<LaunchAction\s+buildConfiguration = "Debug")/$1\n      enableGPUFrameCaptureMode = "3"\n      enableGPUValidationMode = "1"/' $scheme
fi
echo "Open build/ios/NocnaWarszawa.xcodeproj in Xcode and press Run."
echo "For frame-rate numbers, start the game from the iPhone's home screen (no debugger attached)."
