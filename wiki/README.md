# The design wiki

A private website about everything in the game, for designing it without reading code: every
activity, landmark, place, secret, radio station, line, parody name, system and tuning number,
the pillars, and how far each part has come. **Spoilers and plans**: it lives at
https://wiki.aroundwarsaw.app, open to anyone with the link (no password, the user's call on
2026-10-31), is never linked from the landing, and tells search engines to stay away (`noindex` on every page and answer, `robots.txt` disallows all).

Nothing in it is written by hand. `tools/wiki_build.py` reads the game's data
(`game/data/*.json`), its scripts (each one's top comment and constants) and the docs
(`docs/`), and writes the pages to `build/wiki/` (gitignored). Change the game, rebuild, and the
wiki follows. Every item links to the file and line to edit on GitHub.

| File | What |
| --- | --- |
| `../tools/wiki_build.py` | the generator: `python3 -I tools/wiki_build.py` → `build/wiki/` |
| `static/wiki.css`, `static/wiki.js` | the look, the page filter and the search |
| `media.json`, `img/` | the pictures: which screenshot goes with which landmark, place or page (landing shots are shared with `site:`) |
| `worker.js` | the Worker: serves the pages with `noindex` (and asks for a password only if the secret `WIKI_PASSWORD` is set) |
| `wrangler.jsonc` | the Worker `aroundwarsaw-wiki` on its own subdomain (the landing's Worker is untouched) |

## Look at it locally

```sh
python3 -I tools/wiki_build.py
cd build/wiki && python3 -m http.server 8766   # http://localhost:8766
```

## Deploy (asks the user first)

Only to lock it again, set a password (any user name works at the prompt in the browser); to open it, `npx wrangler@4 secret delete WIKI_PASSWORD`:

```sh
cd wiki && npx wrangler@4 secret put WIKI_PASSWORD
```

Then each time:

```sh
python3 -I tools/wiki_build.py && cd wiki && npx wrangler@4 deploy
```

Or run the **wiki** workflow by hand on GitHub (Actions → wiki → Run workflow); it builds and
deploys with the same Cloudflare secrets as the landing (`CLOUDFLARE_API_TOKEN`,
`CLOUDFLARE_ACCOUNT_ID`). On every push to main (and every pull request) that touches the
data, scripts or docs it rebuilds the wiki, fails if the generator breaks, and keeps the built
site as a downloadable artifact for 7 days.

**Auto-deploy** (off): set the repository variable `WIKI_AUTO_DEPLOY` to `true` (Settings →
Secrets and variables → Actions → Variables) and every push to main also deploys, so the live
wiki always matches main. Turn it on only after the first deploy is approved.

Stronger lock, optional: put the subdomain behind Cloudflare Access (Zero Trust → Access →
Applications → Self-hosted, `wiki.aroundwarsaw.app`, allow your e-mail; free for up to 50
users). The password stays as a second lock.

## Add a picture

Save a `.webp` (960 px wide is plenty) in `img/` and list it in `media.json` under the
landmark's key (`landmarks.gd` INFO), a place or egg id, or a page topic, with a caption.
