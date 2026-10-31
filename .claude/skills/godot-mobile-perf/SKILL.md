---
name: godot-mobile-perf
description: Godot 4 Mobile-renderer performance rules for Around Warsaw on the iPhone (Metal, tile-based GPU) and how to measure and cut frame cost (bench, probe, the phone's BENCH card, draw calls, shadow pass, MultiMesh, culling, fill rate, script time). Use before adding anything to the city (props, vehicles, signs, lights, shaders, per-frame scripts), for any FPS or heat question, and when a change must stay inside DEVELOPMENT.md's "Performance budgets".
---

# Frame cost on the phone

The budgets live in docs/archive/DEVELOPMENT-full.md, **"Performance budgets"** (draw calls, triangles in the main
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
  On the phone (loop G1): `xcrun xctrace record --template 'Metal System Trace' --device ID
  --all-processes --time-limit 6s` while a `--probe` runs (attaching by name or pid fails), then
  `xctrace export --xpath` the `metal-gpu-intervals` and `gpu-performance-state-intervals`
  tables: GPU ms per frame and how high iOS had to clock the GPU (the iPhone 11 at ×1: 88 %
  busy in its Medium state; at ×2: its Minimum state). Starting the trace stalls the app ~11 s
  on iOS 27; measure after it.
- The draw-call cost above was Xcode's Metal validation; without it a call costs ≤ 1.2 µs on the
  A18 Pro (graphics.md §1.2).
- At the 60 fps cap the phone's frame times jitter (a launch either waits for the display inside
  "draw", 1–8 ms either way with every refresh drawn, or outside the frame): read **missed
  refreshes** on the BENCH card, not "late" frames, the 1 % low or "draw", for stutter (loop G1).
- **Physics interpolation is on project-wide; static nodes must turn it off**
  (`physics_interpolation_mode = OFF` on the node or a parent). Adding a MultiMesh node under an
  interpolated parent cost the iPhone 11's main thread 14 ms (37 at worst; the Mac 1.4); off,
  0.002 ms (loop G0+: the streamed sectors and proxies; the people, pigeons and police halos
  already had it off).
- A sector's GPU data (its meshes and MultiMeshes, ~1-1.6 MB) is created by the render server on
  the main thread (or the render thread with `--render-thread separate`) when the worker's load
  ends: a 25-60 ms frame on the iPhone 11 per load, outside the streamer's own time (loop G0+,
  `--stream-log`'s `worker` lines). The likely fix (untested): smaller sector resources, one loaded a frame.
- Quality levels and the pixel image's budget live in `tiers.gd`; the governor (`governor.gd`)
  takes extras away when refreshes are missed. Bench both phones at Auto (DEVELOPMENT.md "Loop G1").

## Measure first (Godot's own advice: profile, cut the biggest cost, profile again)

| Tool | Command (from `game/`; DEVELOPMENT.md lists every flag) |
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
