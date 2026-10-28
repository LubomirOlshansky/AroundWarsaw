---
name: godot-mobile-perf
description: Godot 4 Mobile-renderer performance rules for Nocna Warszawa on the iPhone (Metal, tile-based GPU) and how to measure and cut frame cost (bench, probe, the phone's BENCH card, draw calls, shadow pass, MultiMesh, culling, fill rate, script time). Use before adding anything to the city (props, vehicles, signs, lights, shaders, per-frame scripts), for any FPS or heat question, and when a change must stay inside README's "Performance budgets".
---

# Frame cost on the phone

The budgets live in README.md, **"Performance budgets"** (draw calls, triangles in the main
and shadow passes, script ms, frame ms, and what each loop may add). Read them first. If that
section is missing, use "Provisional budget P" in docs/DEMO.md "Milestones" and the latest
loop 2b row in docs/ROADMAP.md, and say so in your report.

## What this project has measured

- On the iPhone the frame grew with **draw calls** (about 10 µs each on an A18 Pro), not
  triangles: the first device run drew 6,700-7,700 calls and ran at 13-16 fps.
- The Mac (M4 Pro, ~3.3 ms a frame on Metal) says little about the phone: the phone's GPU is
  several times slower, tile-based, and throttles when warm; GDScript runs several times slower.
- Metal reports no GPU time in Godot. On the Mac, GPU times come from Vulkan:
  `--rendering-driver vulkan --rendering-method mobile` (add `--gpu-profile` for the passes).

## Measure first (Godot's own advice: profile, cut the biggest cost, profile again)

| Tool | Command (from `game/`; README lists every flag) |
| --- | --- |
| Bench route | `godot --path . --disable-vsync -- --bench --nosave` (+ `--time=night`, `--weather=rain --time=night`) |
| One view, standing still | `godot --path . --resolution 2532x1170 --fixed-fps 60 -- --probe --nosave --at=X,Z --heading=DEG` |
| Rank single costs | `--exp=a,b` switches named costs off (see `main.gd` / `bench.gd` for the names) |
| Frame cap | `--fps=0` uncapped, `--fps=60` / `--fps=30` |
| On the phone | the BENCH button (performance overlay or Settings) shows a card; COPY puts it on the clipboard; or the device-run skill |
| Vertices | `godot --path game --resolution 320x180 --script res://tools/count_vertices.gd` |

- Before/after: run the old code from a copy (`cp -cR game game_before`, gitignored, delete
  it after), interleave A B A B, at least 5 runs each, report medians.
- Compare like with like: the Mac sometimes runs capped at the display's 120 Hz and
  sometimes uncapped; say which. Another Godot running (`pgrep -lx Godot`) spoils the numbers.

## Rules (from Godot's optimisation docs and this project's measurements)

**Draw calls (the phone's biggest cost)**
- Every mesh surface × material × pass (main, shadow) is a draw call. Anything repeated
  (trees, parked cars, lamps, columns, props, traffic, people) is a **MultiMesh**; static
  geometry is merged per 128 m tile (`chunked_surface.gd`) with shared materials.
- Reuse materials and shaders; pack small 2D art into an atlas. A new material for one sign
  is a new draw call in every tile it appears in.
- Merging defeats culling (a merged batch draws whole when any part is on screen): keep the
  tiles; don't merge across them.

**Shadows**
- The shadow pass draws casters again. Small things don't cast (the budget names the size);
  the shadow camera's range should fit the view; the 4096 map is a cost too. Night has no sun
  shadows.

**Culling and distance**
- Frustum culling works per node/tile; use visibility ranges for small props so they vanish
  where they can't be resolved at 480-585 lines; scripts for far, off-screen actors run less
  often or not at all.

**Fill rate on a tile-based GPU**
- The 3D view renders at the pixel image's size (480 lines × the quality's scale), then
  scales up by whole pixels. Keep full-screen passes (post, VHS, glow) at the pixel image's
  size, not the screen's.
- Transparent layers each cost fill; keep them small and few. Passes that read back the
  screen (screen textures, mirror reflections) are expensive on tilers: test on the device.
- Fewer texture reads per pixel; simple shaders; avoid many vertices packed into a small
  part of the screen.

**Scripts**
- Static typing (`:=`, typed arrays, typed returns) gets GDScript's faster opcodes. No
  per-frame allocations in hot loops; cache node lookups; a distance check instead of a
  physics body where it will do; update far things less often.
- Per-system times show in the bench (traffic, trams, people, HUD and minimap, bubbles, ...):
  a new system adds its own line.

**Frame pacing and heat**
- 60 fps cap by default (ProMotion would run 120 Hz and heat up), 30 fps battery option;
  `window/ios/allow_high_refresh_rate=false`. Numbers from the phone come from a launch
  without a debugger (home screen or devicectl), never from Xcode's Run.

**Never**: remove a landmark, the occlusion ghost, the river or the night lights to save
time, or change the look at High without naming and defending the difference with shots.

## Report

A ranked cost table before (draw calls, objects, triangles main + shadow, script ms by
system, frame ms, memory), what you changed per cost, the same table after, the budget table
(used / allowed), and which savings should matter more on the phone than on the Mac, and why.

Further reading: docs.godotengine.org, Performance: "General optimization tips",
"GPU optimization", "Optimizing 3D performance", "Optimization using MultiMeshes".
