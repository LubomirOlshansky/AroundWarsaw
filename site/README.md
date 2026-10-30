# aroundwarsaw.app

The game's landing page. English at `/` (the default), Polish at `/pl/`, the privacy policy at
`/privacy/`, support (both languages, the stores' support URL) at `/support/`. Static files, self-hosted fonts, one small script for the form, no cookies, no
analytics.

| File | What |
| --- | --- |
| `src/index.html` | the landing's template, `{{key}}` placeholders |
| `src/strings.json` | all the copy in `en` and `pl`, the hero shot, the screenshot reel (image, size, caption, alt text), the list of things to do, the form's topics |
| `public/index.html`, `public/pl/index.html`, `public/privacy/index.html`, `public/support/index.html` | **built**, never edited by hand: `python3 -I tools/site_build.py` (the privacy page comes from `docs/privacy.md`, support from `docs/support.md`) |
| `public/styles.css` | all styles; colours and fonts are tokens on `:root` |
| `public/site.js` | the beta and feedback form: checks the fields, posts to Formspree in place, says how it went (without JavaScript the form still posts) |
| `public/img/game/` | screenshots, `<name>.webp` (1920 px wide) and `<name>-960.webp` for phones; `img/og.jpg` is the 1200×630 link preview |
| `public/fonts/` | Pixelify Sans (display) and Manrope (text), WOFF2, OFL licences beside them |
| `public/_headers` | security headers (a CSP that allows only this site and Formspree), caching |
| `wrangler.jsonc` | the Cloudflare Worker that serves `public/` and owns the custom domains |
| `public/_redirects` | `/play/` → https://play.aroundwarsaw.app, the game in the browser |
| `play/wrangler.jsonc` | that game's own Worker (`aroundwarsaw-play`), serving `build/web` from `tools/export_web.sh`; docs/DEVELOPMENT.md "The web build" |

Design notes: the world is the game's night city (sodium lamps, one pink neon, the car radio).
One moving part: the Kebab FM ticker, still under reduced motion. No eyebrow labels, no
icon-card grids. Changes went through the impeccable design skill's craft floor (contrast,
type measure, focus and selection colours, form states).

## Change the copy or the screenshots

1. Edit `src/strings.json` (both languages) or `src/index.html`.
2. `python3 -I tools/site_build.py`
3. Look at it: `cd site/public && python3 -m http.server 8765`, then http://localhost:8765 and
   http://localhost:8765/pl/ at phone and desktop width.

New screenshots: render them with `--nohud` at 2868×1320 (`tools/shots.sh`, README "flags"),
save each as WebP at 1920 px and 960 px wide (quality about 82), put them in
`public/img/game/` and list them in `strings.json` `reel` (or set `hero`).

## The form

It posts to Formspree form `mykaeqjp` (the same form as Stillplace's contact page), with the
subject `Around Warsaw: <topic>` and `source: aroundwarsaw.app (en|pl)`, so the messages are
easy to filter. Topics: beta invite (email required), feedback, something broke, an idea; the
phone type rides along. To give the site its own form, create one in Formspree and change the
`action` in `src/index.html`. If the Formspree form is restricted to certain domains, add
`aroundwarsaw.app`.

## Deploy

The site is a Cloudflare Worker with static assets only. `wrangler deploy` uploads `public/`
and attaches `aroundwarsaw.app` and `www.aroundwarsaw.app` as custom domains (the zone is in
the same Cloudflare account; Cloudflare makes the DNS records and the certificate).

**By hand, from the Mac:**

```zsh
cd site
npx wrangler@4 deploy        # npx wrangler@4 login first if it asks
npx wrangler@4 rollback      # back to the previous version if something is wrong
```

**Automatically, from GitHub**: `.github/workflows/site.yml` checks that the built pages match
`site/src`, `docs/privacy.md` and `docs/support.md`, and deploys on every push to `main` that touches the site,
once the repository has two secrets (Settings → Secrets and variables → Actions):

- `CLOUDFLARE_API_TOKEN`: Cloudflare → My Profile → API Tokens → Create Token → template
  "Edit Cloudflare Workers"; under Zone Resources include the `aroundwarsaw.app` zone.
- `CLOUDFLARE_ACCOUNT_ID`: shown on the Cloudflare dashboard's Workers & Pages overview.

## When the betas have public links

The page collects emails for invites, so it works without public links. When the TestFlight
public link or the Play closed test's opt-in link
(`https://play.google.com/apps/testing/com.olshanskysoft.nocnawarszawa`) should be on the page,
add them to the beta section in `src/index.html` and rebuild. Play needs 12 testers for 14 days
in a closed test before production (docs/store/play-console.md).

## The game in the browser

The "Play online" button goes to https://play.aroundwarsaw.app, a separate Worker so this
page's deploys never touch it: `tools/export_web.sh --deploy` builds and uploads it
(docs/DEVELOPMENT.md "The web build").
