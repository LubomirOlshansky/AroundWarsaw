#!/bin/zsh
# Loop 3d-1: the whole map-data chain for the demo box, from the raw downloads on disk
# (docs/DEVELOPMENT.md "Map data"; data/raw is only read). About 10 minutes, most of it the tree sheets.
#
#   tools/bake_all.sh            everything (prepare, terrain, trees, OSM, LoD2, OSM again, AO,
#                                lights, water, then tools/setup_map.sh: the split and the
#                                prebuilt sectors, with a renderer: a window opens)
#   tools/bake_all.sh --no-trees the same without re-reading the 30 tree sheets (~5 min of it)
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
step() { print -r -- "== $1"; }
step "prepare (data/raw -> data/work/demo)"
python3 tools/prepare_demo.py | tee build/bake/prepare.log
step "terrain"
python3 -I tools/bake_terrain.py | tee build/bake/terrain.log
if [[ $1 != --no-trees || ! -f data/work/demo/trees_area.json ]]; then
	step "trees (GUGiK sheets, ~5 min)"
	python3 -I tools/bake_trees_gugik.py data/work/demo/trees data/work/demo/trees_area.json | tee build/bake/trees.log
fi
step "OpenStreetMap, pass 1"
python3 -I tools/bake_osm.py $W $W game/map/centrum.json $W $W > build/bake/osm1.log
tail -1 build/bake/osm1.log
step "GUGiK LoD2"
python3 -I tools/bake_gugik.py data/work/demo game/map | tee build/bake/gugik.log
step "OpenStreetMap, pass 2 (structures over this LoD2)"
python3 -I tools/bake_osm.py $W $W game/map/centrum.json $W $W > build/bake/osm2.log
tail -1 build/bake/osm2.log
step "AO, lights, water"
python3 -I tools/bake_ao.py game/map | tee build/bake/ao.log | tail -1
python3 -I tools/bake_lights.py game/map | tee build/bake/lights.log | tail -1
python3 -I tools/bake_water.py game/map | tee build/bake/water.log | tail -1
step "split and prebuilt sectors"
tools/setup_map.sh
python3 -I tools/check_map_data.py
