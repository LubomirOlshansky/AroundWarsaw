# The design wiki

A private website about everything in the game, for designing it without reading code: every
activity, landmark, place, secret, radio station, line, parody name, system and tuning number,
the pillars, and how far each part has come. **Spoilers and plans**: it lives at
https://wiki.aroundwarsaw.app behind a password, is never linked from the landing, and tells
search engines to stay away (`noindex` on every page and answer, `robots.txt` disallows all).

Nothing in it is written by hand. `tools/wiki_build.py` reads the game's data
(`game/data/*.json`), its scripts (each one's top comment and constants) and the docs
(`docs/`), and writes the pages to `build/wiki/` (gitignored). Change the game, rebuild, and the
wiki follows. Every item links to the file and line to edit on GitHub.

| File | What |
| --- | --- |
| `../tools/wiki_build.py` | the generator: `python3 -I tools/wiki_build.py` → `build/wiki/` |
| `static/wiki.css`, `static/wiki.js` | the look, the page filter and the search |
| `media.json`, `img/` | the pictures: which screenshot goes with which landmark, place or page (landing shots are shared with `site:`) |
| `worker.js` | the Worker: asks for the password, then serves the pages with `noindex` and `no-store` |
| `wrangler.jsonc` | the Worker `aroundwarsaw-wiki` on its own subdomain (the landing's Worker is untouched) |

## Look at it locally

```sh
python3 -I tools/wiki_build.py
cd build/wiki && python3 -m http.server 8766   # http://localhost:8766
```

## Deploy (asks the user first)

Once, set the password (any user name works at the prompt in the browser):

```sh
cd wiki && npx wrangler@4 secret put WIKI_PASSWORD
```

Then each time:

```sh
python3 -I tools/wiki_build.py && cd wiki && npx wrangler@4 deploy
```

Or run the **wiki** workflow by hand on GitHub (Actions → wiki → Run workflow); it builds and
deploys with the same Cloudflare secrets as the landing (`CLOUDFLARE_API_TOKEN`,
`CLOUDFLARE_ACCOUNT_ID`). On every push to main it only checks that the wiki still builds.

Stronger lock, optional: put the subdomain behind Cloudflare Access (Zero Trust → Access →
Applications → Self-hosted, `wiki.aroundwarsaw.app`, allow your e-mail; free for up to 50
users). The password stays as a second lock.

## Add a picture

Save a `.webp` (960 px wide is plenty) in `img/` and list it in `media.json` under the
landmark's key (`landmarks.gd` INFO), a place or egg id, or a page topic, with a caption.
