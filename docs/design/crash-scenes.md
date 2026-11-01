# Crash scenes (stłuczki)

F's ask (2026-11-01): "collisions of cars where some cars get stuck, the police with lights and
the karetka, like an event in the map somewhere sometime". Built in `game/scripts/crash_scenes.gd`,
checked by `game/tools/check_crash_scenes.gd` (verify step `crashes`, in CI).

## What happens

- **When**: the first scene 80-150 s into a drive, then one 3-5.5 minutes after the last one
  clears (`FIRST`, `GAP`). One at a time. A normal launch only; test runs need `--crash=`.
- **Where**: 130-260 m ahead of the player, within ±46° of the way they are going (anywhere round a
  standing car), on a main or secondary road (class 0-1) with 2+ lanes, off bridges and tunnels,
  28 m clear of both ends of its edge, the kerb lane empty, out of sight.
- **What**: in the kerb lane, rear to front: the police car (light bar flashing), the car that ran
  into the other (turned 18°), the car it hit, the yellow ambulance (two blue lamps, a red band,
  AMBULANS on the sides). Seven people: the two drivers face to face by the kerb, the officer by
  the police car, the paramedic behind the ambulance, three onlookers on the footway.
- **Talk**: within 50 m the people take turns in speech bubbles every 2.6-4.2 s
  (`dialogue.json` `crash_scene`: `driver`, `officer`, `medic`, `gawker`). When the scene is placed,
  the tuned station's host reads it on the ticker (`radio_host` lines tagged `crash`, with the
  street's name).
- **Traffic**: a car stopped within 12 m behind a parked car in its lane changes lane after 1.6 s
  when the next lane has room (traffic.gd `PARKED_LOOK`, `PARKED_WAIT`): the queue squeezes past
  one by one. Bumping the scene's police car or ambulance is an offence like any bump (a ram calls
  the nearest other unit); the scene's cars never chase.
- **End**: after 150-240 s (`LIFE`), or once the player is 650 m away, as soon as the view can't
  see it: the cars go back to their pools, the people go.

## Cost

+0 draw calls by construction: the wrecks are two slots of the traffic's CAR MultiMesh, the police
car and the ambulance two slots of the POLICE MultiMesh (the ambulance is the police family's
shape 2: `models.gd police_mesh`, 1543 vertices for all three shapes), the people seven instances
appended to the pedestrians' MultiMesh (`pedestrians.gd SCENE`), the bubbles the HUD's. Script: a
2 Hz tick, and one more test per car per frame in traffic.gd `_drive`.

## Flags

`--crash=now` (a scene ahead at the start, maybe in view), `--crash=X,Z` (on the fitting road
nearest that point), `--crash=on` (the timer in a test run), `--crash=0` (none), `--crash-log`.

## Left

Built since: the ambulance's siren (`sfx.scene_siren`, the chase siren's stream at -20 dB on its own
voice, stops when the scene is over) and an amber dot on the minimap and the full map
(`hud.set_scene_mark`), both fed by `crash_scenes.gd` each tick.

See docs/BACKLOG.md "Crash scenes": the phone's look and check of the siren and dot, hazard lights
and glass, gestures, one-lane roads.
