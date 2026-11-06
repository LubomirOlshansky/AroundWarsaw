#!/bin/zsh
# Loop 3d-1: the whole map-data chain for the demo box, from the raw downloads on disk
# (docs/DEVELOPMENT.md "Map data"; data/raw is only read). About 10 minutes, most of it the tree sheets.
#
#   tools/bake_all.sh            everything (prepare, terrain, trees, OSM, LoD2, OSM again, AO,
#                                lights, water, then tools/setup_map.sh: the split and the
#                                prebuilt sectors, with a renderer: a window opens)
#   tools/bake_all.sh --no-trees the same without re-reading the 30 tree sheets (~5 min of it)
#   tools/bake_all.sh --roads    a road or marking rule change (bake_roads.py, bake_osm.py): keeps
#                                the prepared data, terrain, trees and LoD2 on disk and runs only
#                                OpenStreetMap pass 2, AO/lights/water and the split (~half the time).
#                                Falls back to the full chain when an input is missing.
#   tools/bake_all.sh --resume   after a failed or interrupted run: skip the steps that already
#                                finished (their stamps are in build/bake/done/), run the rest.
#                                A run without --resume clears the stamps first. Changed raw data
#                                or a changed bake script: run without --resume.
#
# bake_osm.py runs twice: its structures (bake_structures.py) cut LoD2 buildings under decks, so
# they read lod2.*, and bake_gugik.py keeps LoD2 buildings by the OSM outlines in centrum.json.
# The second pass sees the LoD2 of this box (the outlines, and so lod2.*, don't change).
# Logs: build/bake/*.log.
emulate -L zsh
set -e
ROOT=${0:A:h:h}
cd $ROOT
mkdir -p build/bake
W=data/work/demo/osm_demo.json
RESUME=0
[[ $* == *--resume* ]] && RESUME=1
ROADS=0
if [[ $* == *--roads* ]]; then
	if [[ -f $W && -f game/map/terrain.json && -f game/map/lod2.json && -f data/work/demo/trees_area.json ]]; then
		ROADS=1
	else
		print -r -- "bake_all: --roads needs $W, terrain.json, lod2.json and trees_area.json on disk; running the whole chain"
	fi
fi
# The steps a roads-only bake keeps from the last full run.
ROADS_SKIP=("prepare (data/raw -> data/work/demo)" "terrain" "trees (GUGiK sheets, ~5 min)" "OpenStreetMap, pass 1" "GUGiK LoD2")
typeset -F T0 T_ALL
T_ALL=$SECONDS
(( RESUME )) || rm -rf build/bake/done
mkdir -p build/bake/done
# step NAME: prints the header; returns 1 (skip) when --resume and NAME already finished.
# Every step ends with `stamp NAME`, so an interruption costs at most the step it was in.
step() {
	if (( RESUME )) && [[ -e build/bake/done/${1//[^A-Za-z0-9]/_} ]]; then print -r -- "== $1 (done, skipped)"; return 1; fi
	if (( ROADS )) && (( ${ROADS_SKIP[(Ie)$1]} )); then print -r -- "== $1 (roads only, kept from the last run)"; return 1; fi
	print -r -- "== $1"
	T0=$SECONDS
}
# stamp NAME: marks the step done and prints how long it took (bake timings, for the street-pass loop).
stamp() {
	touch build/bake/done/${1//[^A-Za-z0-9]/_}
	printf '   %s: %.0f s\n' "$1" $(( SECONDS - T0 ))
}
if step "prepare (data/raw -> data/work/demo)"; then
	python3 tools/prepare_demo.py | tee build/bake/prepare.log
	stamp "prepare (data/raw -> data/work/demo)"
fi
if step "terrain"; then
	python3 -I tools/bake_terrain.py | tee build/bake/terrain.log
	stamp "terrain"
fi
if [[ $* != *--no-trees* || ! -f data/work/demo/trees_area.json ]]; then
	if step "trees (GUGiK sheets, ~5 min)"; then
		python3 -I tools/bake_trees_gugik.py data/work/demo/trees data/work/demo/trees_area.json | tee build/bake/trees.log
		stamp "trees (GUGiK sheets, ~5 min)"
	fi
fi
if step "OpenStreetMap, pass 1"; then
	python3 -I tools/bake_osm.py $W $W game/map/centrum.json $W $W > build/bake/osm1.log
	tail -1 build/bake/osm1.log
	stamp "OpenStreetMap, pass 1"
fi
if step "GUGiK LoD2"; then
	python3 -I tools/bake_gugik.py data/work/demo game/map | tee build/bake/gugik.log
	stamp "GUGiK LoD2"
fi
if step "OpenStreetMap, pass 2 (structures over this LoD2)"; then
	python3 -I tools/bake_osm.py $W $W game/map/centrum.json $W $W > build/bake/osm2.log
	tail -1 build/bake/osm2.log
	stamp "OpenStreetMap, pass 2 (structures over this LoD2)"
fi
if step "AO, lights, water"; then
	python3 -I tools/bake_ao.py game/map | tee build/bake/ao.log | tail -1
	python3 -I tools/bake_lights.py game/map | tee build/bake/lights.log | tail -1
	python3 -I tools/bake_water.py game/map | tee build/bake/water.log | tail -1
	stamp "AO, lights, water"
fi
if step "split and prebuilt sectors"; then
	tools/setup_map.sh
	stamp "split and prebuilt sectors"
fi
python3 -I tools/check_map_data.py
printf "bake_all: %.0f s in all\n" $(( SECONDS - T_ALL ))
