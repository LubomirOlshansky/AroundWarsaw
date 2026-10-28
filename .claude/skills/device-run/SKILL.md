---
name: device-run
description: Builds Nocna Warszawa for the user's connected iPhone, installs and launches it with game flags (usually the bench), and copies the engine log back to the Mac with xcrun devicectl. Use only when the user has allowed device runs for this loop and nobody else is using the phone; for frame rate, Metal, thermal or touch questions that the Mac can't answer.
disable-model-invocation: true
argument-hint: "[label] [game flags, e.g. --bench --quality=high]"
---

# Run the game on the iPhone from the Mac

Real numbers come only from the phone: the iOS Simulator can't run Godot's Mobile renderer
(it lacks image cube arrays), so it shows layout and touch only, with the Compatibility
renderer.

## Gate (all must hold, or stop and say which doesn't)

- The user allowed device runs **for this loop** (in chat or in the loop brief). Permission
  from an earlier loop doesn't carry over.
- No other agent or session is using the phone right now (one device user at a time; a second
  launch with `--terminate-existing` kills the other run).
- The phone is unlocked and connected; find its identifier with `xcrun devicectl list devices`.
  Keep the identifier in the shell (`--device=` or `NW_DEVICE`), never in a tracked file.

## Steps

```zsh
tools/export_ios.sh                                   # after any change to game/
tools/device_run.sh --device=$NW_DEVICE --label=bench_day -- --bench --quality=high
tools/device_run.sh --device=$NW_DEVICE --label=bench_night --skip-build -- --bench --time=night
```

`tools/device_run.sh` snapshots `build/ios` into `build/device/<label>/` (an APFS clone),
builds with `-allowProvisioningUpdates` for that device, installs with
`xcrun devicectl device install app`, launches with
`devicectl device process launch --terminate-existing <bundle> --log-file user://<label>.log -- <flags>`,
copies `Documents/<label>.log` back every 8 s until the bench's last lines appear (or
`--wait=` seconds pass), copies `Documents/bench_result.txt` if there is one, stops the app,
and prints the key lines. `--dry-run` prints the commands without touching the phone.

- `--nosave` is added if missing. Without `--bench` (or another flag that ends the run), pass
  `--done=REGEX` for the line that means "finished", or the run lasts `--wait=` seconds.
- Godot's `print()` never reaches `devicectl --console`, and `log collect --device` needs root:
  the `--log-file` copy is the way.
- Launching from devicectl attaches no debugger, so frame times are honest. Xcode's Run button
  attaches one plus Metal API validation, which slows every draw call: never take numbers from it.
- The phone warms up: for before/after, alternate the builds (A, B, A, B) and compare medians;
  note the run order and how long the phone had been running.

## Report

The device model and iOS version, the flags, the bench lines (fps average, 1 % low, worst
frame, draw calls, objects, triangles, main/shadow pass split, script times, memory), the
log path under `build/device/`, and anything that differs from the Mac's numbers.
