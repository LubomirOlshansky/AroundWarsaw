# aroundwarsaw.app

The game's landing page: plain HTML and CSS in `public/`, no build step, no JavaScript, no
cookies, no analytics. Polish first with English under it, as in the game.

| File | What |
| --- | --- |
| `public/index.html` | the landing: hero, features, screenshots, the beta section |
| `public/privacy/index.html` | the privacy policy, generated from `docs/privacy.md` by `python3 -I tools/site_privacy.py` (never edit it by hand); the stores link here |
| `public/styles.css` | all styles; colours are tokens on `:root` |
| `public/img/` | screenshots (WebP, 1600 px wide, cropped from `shots/` without the HUD), `og.jpg` (1200×630 link preview), icons from `game/icon.svg` |
| `public/_headers` | security headers and image caching |
| `wrangler.jsonc` | the Cloudflare Worker that serves `public/` and owns the custom domains |

## Look at it locally

```zsh
cd site/public && python3 -m http.server 8765   # then open http://localhost:8765
```

## Deploy

The site is a Cloudflare Worker with static assets only (no script). `wrangler deploy` uploads
`public/` and attaches `aroundwarsaw.app` and `www.aroundwarsaw.app` as custom domains, which
works because the domain's zone is in the same Cloudflare account. Cloudflare creates the DNS
records and the certificate itself.

**By hand, from the Mac** (the first deploy):

```zsh
cd site
npx wrangler@4 login     # opens the browser once to sign in to Cloudflare
npx wrangler@4 deploy
```

If the deploy says a DNS record already exists for the domain (an old parking page or A
record), delete that record in Cloudflare → aroundwarsaw.app → DNS and deploy again.

**Automatically, from GitHub**: `.github/workflows/site.yml` deploys on every push to `main`
that touches the site, once the repository has two secrets (Settings → Secrets and variables →
Actions):

- `CLOUDFLARE_API_TOKEN`: Cloudflare → My Profile → API Tokens → Create Token → template
  "Edit Cloudflare Workers"; under Zone Resources include the `aroundwarsaw.app` zone.
- `CLOUDFLARE_ACCOUNT_ID`: shown on the Cloudflare dashboard's Workers & Pages overview.

Without them the workflow only checks that the privacy page matches `docs/privacy.md`.

## When the betas open

In `public/index.html` there are four beta links (`beta-ios`, `beta-ios-2`, `beta-android`,
`beta-android-2`). For each: set `href` to the public link, remove the `soon` class and change
"wkrótce · soon" to "Dołącz · Join".

- iPhone: the TestFlight **public link** (App Store Connect → TestFlight → External Testing →
  a group → Public Link), `https://testflight.apple.com/join/...`.
- Android: the closed test's opt-in link,
  `https://play.google.com/apps/testing/com.olshanskysoft.nocnawarszawa`. A Google Group as
  the testers list lets anyone join without you adding emails by hand; Play needs 12 testers
  for 14 days in a closed test before production (docs/store/play-console.md).

## Screenshots

The images come from the prototype's shot sets (loop 1, 2b, 3a, 10a). To refresh them, crop
new `tools/shots.sh` shots inside the HUD (about 15 % off each side), save as WebP at 1600 px
and quality 80, and keep the page under about 1.5 MB in total.
