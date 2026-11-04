# Developer console

One page for steering the game, generated from the repo: `python3 -I tools/console.py`
writes `build/console/index.html` (gitignored). Open it in a browser; it works offline.

- **Overview**: progress cards, stage bars, history over runs (`history.json` beside the page), the
  v1.0 checklist, recent merges.
- **City map**: every ranked place (colour by stage, tier, data used or district), the tier C outlines,
  street life, shops, transit, monuments, park details, trees, lamps, signals, parked cars, buildings,
  roads by class, trams, rails, cycle paths, bridges, tunnels and the game's content points. Sliders
  for marker and building filters, an area picker (whole map, a district, or a circle with a radius),
  and counts and km that follow the area.
- **Content**: the authored content as tables (activities, notebook places, eggs, Fotka spots, Syrenki,
  cassettes, speed traps, districts) with the file to edit.
- **Approvals**: what waits for F (docs/QUESTIONS.md Waiting, A/B mentions, ROADMAP checks still open).
- **Renders**: screenshots from `shots/`, `docs/media/` or any `--renders DIR`, matched to places by file name.

Keeping it current: `python3 -I tools/console.py --watch` rebuilds when the branch, the docs or the
game data change; tick "Auto-refresh" in the page to reload it every 20 s. The page keeps its filters
and view in the browser. Places, stages and counts come from docs/CITY_INVENTORY.md Part 1 (the wiki's
rules), so a thread that lands a place changes its mark there and the console follows.

## Deploying (rarely, F's call)

It is a static site like the wiki, but private by habit: it names plans and open questions, and the
renders are not copied unless you copy them. To publish:

```zsh
python3 -I tools/console.py --renders shots      # fresh build
cp -R shots build/console/shots                  # only if the renders should be public
cd console && npx wrangler@4 deploy              # the Mac's safety check may ask for a go-ahead
```

The route in `wrangler.jsonc` is a suggestion; `_headers` already sends `X-Robots-Tag: noindex`.
Add Cloudflare Access in front of it if it should not be open to anyone with the link.
