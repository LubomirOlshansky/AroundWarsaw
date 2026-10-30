#!/bin/zsh
# The web (HTML5) build in build/web, for https://play.aroundwarsaw.app (docs/DEVELOPMENT.md "Web").
#
#   tools/export_web.sh            the derived map files when missing or stale, then the export
#   tools/export_web.sh --deploy   also upload build/web to the Cloudflare Worker (site/play)
#
# Godot's "Web" preset (threads on, so the sectors still load on a worker thread; the page needs
# the COOP/COEP headers in tools/web/_headers). Cloudflare serves files of at most 25 MiB and the
# pack is ~140 MB, the engine ~40 MB: tools/web/split_parts.py gzips both into 20 MiB parts and
# tools/web/split_loader.js (in the page's head) joins them in the browser.
emulate -L zsh
set -e
ROOT=${0:A:h:h}
GODOT=${GODOT:-godot}
cd $ROOT/game
[[ -d .godot/imported ]] || $GODOT --headless --path . --import
$ROOT/tools/setup_map.sh --if-needed
rm -rf $ROOT/build/web
mkdir -p $ROOT/build/web
$GODOT --headless --path . --export-release "Web" $ROOT/build/web/index.html > $ROOT/build/export_web.log 2>&1 \
	|| { tail -20 $ROOT/build/export_web.log; print -r -- "export_web: the export failed ($ROOT/build/export_web.log)"; exit 1 }
cp $ROOT/tools/web/split_loader.js $ROOT/tools/web/_headers $ROOT/build/web/
python3 -I $ROOT/tools/web/split_parts.py $ROOT/build/web/index.pck $ROOT/build/web/index.wasm
print -r -- "export_web: build/web ready (look at it: python3 -I tools/web/serve.py)"
if [[ $1 == --deploy ]]; then
	cd $ROOT/site/play
	npx wrangler@4 deploy
fi
