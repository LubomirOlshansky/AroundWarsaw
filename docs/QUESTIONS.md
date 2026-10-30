# Parked questions and lanes in progress

The work doesn't stop for a question (docs/WORKFLOW.md "Backlog mode", the backlog-loop
skill): a question for the user is parked here with the default that was built, and the
session takes the next item. The user answers here, in a PR comment or in chat, in one batch.

## In progress

One session per lane. Add a row when you start an item, remove it when the item lands.

| Lane | Item | Session | Since |
| --- | --- | --- | --- |
| driving | The car's feel, traffic and the player, the roadworks (PR #5 landed, PR #8) | cloud thread "Make driving smoother" | 2026-10-30 |

## Waiting

Newest first. One entry per question.

- **2026-10-30 · store release · store listings** — Ship the iOS app for iPhone and iPad, or
  iPhone only? Once an iPad version is on the App Store, later versions can't drop iPad.
  Options: iPhone and iPad (needs an iPad device pass) / iPhone only. Default built: nothing
  changed (the preset still says iPhone and iPad, which is fine for TestFlight; iPad
  screenshots are rendered). Decide before the first App Store release. Where:
  docs/store/app-store-connect.md section 10.
- **2026-10-30 · store release · store listings** — Account steps only you can do: create the
  App Store Connect app record and the Play listing from docs/store/, pick the support email
  (not written in the public repo), upload the first builds, invite testers. And a yes to
  redeploy aroundwarsaw.app so `/support/` goes live (the store forms link to it). Default
  built: everything written; nothing submitted.

<!--
- **YYYY-MM-DD · lane · item** — The question in one line? Options: A / B. Default built: A
  (or "nothing built: waits"). Where: PR #N, BACKLOG "section".
-->

## Answered

Move an entry here with the user's answer and the date; its item goes back to the top of the
backlog. Lasting decisions also go into BACKLOG's "Decided" sections, DEMO.md or ROADMAP.
