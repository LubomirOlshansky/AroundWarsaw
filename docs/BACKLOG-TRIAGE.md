# Backlog triage (snapshot, 2026-10-28)

`docs/BACKLOG.md` had 100 open entries (lines 1–269 at loop 10a's end): **33 fixes, 20
decisions, 47 notes**. Sorted by the scout (Haiku), corrected by the orchestrator (Opus). This
is the plan for the two backlog sweeps in ROADMAP ("Backlog sweeps"): each fix lands in the
loop named here; "sweep 1" runs after loop 3c, "sweep 2" before 3j. Line numbers refer to
BACKLOG.md at this snapshot; loops that change BACKLOG.md move them, so match by text.

## Fixes, by the loop they land in

| Loop | Item (BACKLOG line) |
| --- | --- |
| 3a roads-bake (running) | The shore is left open 6 m beside bridge decks in the bake; move the builder's fill into `bake_shore` (241) |
| 3b roads-builder | Kerbs, islands and medians are flat to the car (46); cramped turn arrows, roundabout arrows (50); Rondo Dmowskiego's spiral markings (52); chevrons point the wrong way (55); medians only between one-way pairs (56); deck pieces > 3 m apart show the river (58). **Done in loop 3b-2** (2026-10-28), except medians on two-way roads: none is mapped on today's map (counted 0; kept in BACKLOG for loop 3d) |
| 3d demo-bake | The Praga streets join only through an off-map link (42; the bigger box should connect them; else decide a link); the terrain stops 5–9 m short of the edges (48); Most Świętokrzyski ends in the air and its last lanes sit at water level at the rim (60, 255; the new box takes the whole bridge) |
| 3f landmarks | AO and lamp map use LoD2 footprints (Centralna's canopy, the stadium's skin) (91); the stadium's embankment (97); outlines on a cut building's inner faces (144) |
| 2d jokes and side jobs | Kebab kiosks drawn over benches and bins (38) |
| 3g police (traffic AI shared) | Cars overlap in busy junctions; an off-screen rival drives through traffic (7); trams nose to nose with crossing cars (9); AI drives through knocked barriers (33); AI ignores bus lanes (53) |
| 3h demo loop (tuning) | Only two race finishes from the spawn (11); rescue time limits untuned (19) |
| 3i juice, sound, night | Puddles under the lane markings (106); screen-space reflections, Poniatowski's pale slab lines by day (108); haptics fail on the phone (227) |
| 2e HUD (running) | The HUD in 720-line units (166); bubbles through the WIN/LOSE card (10) |
| sweep 1 | README's Mac measuring command (`--rendering-driver metal` without `--rendering-method mobile`) runs Forward+, not Mobile (graphics plan); `tools/shots.sh --out=` needs an absolute path (a relative one resolves under `game/`); `check_landmarks.gd` exits 0 on failure (220); README's two `bake_osm.py` commands (222); the helicopter's roof toast is English only (259); a car pinned between a wall and a waiting car (171); Point camera with a finger that never lifts, zoom not saved (169) |
| sweep 2 | Tapping picks the see-through tower in front (86); windowed `--prebuilt --shots` leak warning (267); Mac keyboard W on the diagonal start view (182; Mac only). **Done in sweep 2** (2026-10-29), with the first rescue call's hitch (loop G1's note; the haptic engine built at load, phone check pending) and the neon signs ghosted (loop 1's note); the W key was already fixed by the camera loop (the follow camera starts behind the car) |

## Decisions still open (for the user or the loop that meets them)

- Pay rates are first guesses (37) → 3h, from playtests.
- The Palace roof rescue lands on a 28 m annex; a designed terrace landing? (88) → 3f.
- The Poniatowski towers' heights are guesses (93) → 3b (re-seated with the deck profile).
- The beaches get the boulevards' granite edge; timber or riprap instead? (239) → decided
  (art review, the user's default): granite only on built banks, natural banks wet sand and a
  foam line; **done in loop 3b-2**.
- Night water may be too plain at the widest zoom (154) → 3i.
- Rain spray behind cars (114) → 3i, if the budget allows.
- Tow distance from a wide beach, the 2.5 m water threshold (249, 252) → leave unless the
  user's phone test says otherwise.

## To tidy in sweep 1 (stale or duplicated)

- Already fixed but not struck: 68–70, 73–75, 102–103, 132–133 (loop 1 / v0.9 fixes); 198–199
  and 217 describe changes already made.
- Out of date after loop 2a/2b: quality and weather "not saved" and QUALITY "on the hidden
  overlay until v1.0" (116–118, 125–126): quality is saved and in Settings now.
- Decided since: the Apple team ID (223) is in the public repo and fine; the river behaviour and
  the column posters were approved by the user.
- Duplicates: the iOS "Mouse is not supported" error (187, 230); autopilots can't test crashes
  (13, 35); the ghost's coarser dither on the phone (82, 139); sounds never heard on a phone
  (104, 235).

## Phone-only checks (for the device pass, 3j, or the user)

The ghost's dither size (82, 139); the sounds, including the river splash (104, 235); the steering
and camera feel, the 80 m view, the 44 pt controls (161); the phone's GPU headroom with a 120 Hz
diagnostic build (190).
