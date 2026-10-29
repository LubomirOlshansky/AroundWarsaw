#!/bin/zsh
# Loop 3d-1: make the derived map files a fresh clone doesn't have (they are not committed).
#
#   tools/setup_map.sh               the split, then the prebuilt sectors (~20 s; a window opens)
#   tools/setup_map.sh --if-needed   only when they are missing or don't match their inputs
#   tools/setup_map.sh --full        also the GUGiK part first (the terrain and the LoD2
#                                    buildings, from the raw downloads; ~2 min)
#
# Loop 3d-1 (the user's decision): game/map/lod2.bin, lod2.json and terrain.json come from
# GUGiK's data alone (the LoD2 sheets, the 1 m and 10 m terrain) and are derived too, not
# committed. They need the raw downloads (data/raw: tools/fetch_demo.py and the LoD2 package,
# README "Map data"); --full, or their absence, rebuilds them: tools/prepare_demo.py (terrain,
# sheets, ortho), tools/bake_terrain.py, tools/bake_gugik.py.
#
# The committed map is the bake chain's output (game/map/centrum.json, lod2.*, terrain.json,
# ao.bin, lights.bin, water.bin: the ODbL database). From it this makes:
#   1. python3 -I tools/bake_sectors.py → game/map/index.json, sectors/<i>_<j>.json, sectors/split.stamp
#   2. godot --path game --resolution 320x180 --script res://tools/bake_city.gd (WITH a renderer:
#      --headless drops MultiMesh and texture data) → sectors/s_<i>_<j>.scn, proxies.scn,
#      index.res, shared/*.res, sectors/city.stamp
# then checks them (tools/check_map_data.py). On a clone Godot has never opened, it imports the
# project first (.godot/ is missing; a minute or so). tools/verify.sh runs this with --if-needed
# when the files are missing; tools/export_ios.sh runs steps 1 and 2 every time.
emulate -L zsh
set -e
ROOT=${0:A:h:h}
GODOT=${GODOT:-godot}
full=0
if [[ $1 == --if-needed ]]; then
	if python3 -I $ROOT/tools/check_map_data.py --fresh; then
		exit 0
	fi
elif [[ $1 == --full ]]; then
	full=1
elif [[ -n $1 ]]; then
	print -r -- "usage: tools/setup_map.sh [--if-needed|--full]"; exit 2
fi
for f in lod2.bin lod2.json terrain.json; do
	[[ -f $ROOT/game/map/$f ]] || full=1
done
if (( full )); then
	if [[ ! -d $ROOT/data/raw/demo/gugik/nmt1_box || ! -d $ROOT/data/raw/gugik/sheets || ! -d $ROOT/data/raw/demo/gugik/sheets ]]; then
		print -r -- "setup_map: game/map/lod2.* and terrain.json are built from GUGiK's raw data, which isn't here:"
		print -r -- "  data/raw/demo (python3 -I tools/fetch_demo.py nmt10, ortho, sheets, nmt1box; see data/raw/demo/MANIFEST.md)"
		print -r -- "  data/raw/gugik/1465_gml.zip and sheets/ (README \"Map data\", step 2: the Warsaw LoD2 package)"
		exit 1
	fi
	mkdir -p $ROOT/build
	print -r -- "setup_map: the GUGiK part (terrain, LoD2)"
	( cd $ROOT && python3 tools/prepare_demo.py osm terrain sheets ortho && python3 -I tools/bake_terrain.py \
		&& python3 -I tools/bake_gugik.py data/work/demo game/map ) > $ROOT/build/setup_gugik.log 2>&1 \
		|| { tail -5 $ROOT/build/setup_gugik.log; print -r -- "setup_map: the GUGiK part failed ($ROOT/build/setup_gugik.log)"; exit 1 }
	grep -E '^(terrain|LoD2)' $ROOT/build/setup_gugik.log
fi
if ! command -v $GODOT > /dev/null; then
	print -r -- "setup_map: '$GODOT' not found (Godot 4.7.2; set GODOT=/path/to/godot)"; exit 1
fi
cd $ROOT/game
if [[ ! -d .godot/imported ]]; then
	print -r -- "setup_map: importing the project (first run on this clone)"
	$GODOT --headless --path . --import > /dev/null 2>&1 || true
fi
mkdir -p $ROOT/build
log=$ROOT/build/setup_map.log
python3 -I ../tools/bake_sectors.py map > $log
head -2 $log
# Not --headless (see above): this opens a small window for a few seconds.
if ! $GODOT --path . --resolution 320x180 --script res://tools/bake_city.gd >> $log 2>&1; then
	grep -E 'ERROR|error' $log | head -5
	print -r -- "setup_map: bake_city failed (log: $log)"; exit 1
fi
grep -E '^bake_city' $log
python3 -I ../tools/check_map_data.py --fresh
