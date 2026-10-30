# Contributing

Thanks for wanting to help. This is a small fan project made by one person (with AI agents),
so small, focused changes are the easiest to take in.

## Set up

1. Install [Godot 4.7.2](https://godotengine.org/download/) and put `godot` on your `PATH`.
   Python 3 (standard library only) runs the map checks. The scripts in `tools/` are zsh and
   were written on macOS.
2. Clone the repo. The baked map is in `game/map/`, so the game runs straight away:
   `godot --path game`.
3. Before you open a pull request, run the verification set:

   ```zsh
   tools/verify.sh --quick   # map data, the check scripts, two short game runs (~30 s)
   tools/verify.sh           # everything except the iOS build (~1-2 min)
   ```

   It ends in one PASS / WARN / FAIL table with a log path per row. Please paste that table
   into your pull request.

How each part of the game works, every testing flag and the map-data chain are in
[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## The rules

- **Every game run you script passes `--nosave` and a way to quit** (`--quit-after N` or
  `--shots=`), so tests never touch a player's save and never hang. Engine flags go before
  `--`, game flags after it: `godot --path game --quit-after 600 -- --nosave`.
- **Parodies only, no real brands.** Shops, apps, drinks and banks in the game are invented
  near-misses; no real names or logos.
- **Polish with English.** Every on-screen line is written in Polish first, with its English
  beside or under it (`game/data/*.json` holds both).
- **Real people.** Real places and public landmarks are welcome. Real people are not: no jokes
  about, likenesses of or names of real private people, and nothing mean about anyone. The
  humour is affectionate, about the city and its habits.
- **The phone budget.** The game has to run at 60 fps on an iPhone 11. Anything that adds
  geometry, materials, lights or per-frame work shows its draw calls and frame time before and
  after (docs/DEVELOPMENT.md, "Performance budgets").
- **Your own work.** Code, art, music and text you add must be yours, or under a licence that
  allows it (say which in CREDITS.md). New map data comes only from the open sources listed
  there.
- **Nothing private.** No keys, passwords, device identifiers, email addresses, personal data
  or absolute home paths in any file, log or commit.

## Proposing a change

1. **Open an issue first** for anything bigger than a typo: what you want to change and why.
   A screenshot helps for anything you can see.
2. **Then a small pull request**, one thing per PR, with the verify table, screenshots for
   visible changes, and the bench numbers if it touches the frame.
3. GDScript follows the house style: static types, tabs, a `##` comment above each class and
   member saying what it does. New testing aids are game flags documented in
   docs/DEVELOPMENT.md; new behaviour that can be measured gets a `game/tools/check_*.gd`.

Bug reports are just as welcome as code: say what you did, what you saw, the device and the
build.
