# Graphics: headroom, upgrades and device tiers

Written 2026-10-28 by the perf-engineer, after the user reported that the game holds 60 fps on
an **iPhone 11** (A13, 1792×828, 60 Hz) as well as on their **iPhone 16 Pro Max** (A18 Pro,
2868×1320), and asked for the graphics to be "as good as it can be" with that headroom. The
iPhone 11 is now the minimum target (ROADMAP, DEMO.md).

This is a plan. It changes nothing by itself. The loops in section 5 do the work, after the
"first-minute look" and camera loops have merged. Numbers marked *est.* are estimates. Loop G0
replaces them with device measurements. Every other number comes from a log or a run named
beside it.

**Status.** **G1 is done (2026-10-28; README "Loop G1", ROADMAP row); G1b (2026-10-29, §4.5):
Auto draws the iPhone 11 (and the SE 2 / 3) sharp at ×1 with High's effects, with a ×2 fallback
for the next launches after a session that struggled.** What G1 changed from this plan:
- The pixel image is a **budget per level** (`tiers.gd`): High 0.96 MP, so the iPhone 11 at High
  draws 896×414 (×2), not ×1 (§6 Q1 answered by the loop's brief); Ultra's 1.6 MP keeps ×1 there
  for whoever picks it. Every phone that scaled by 2 or more is unchanged.
- Tiers as in §4.1 (Low `iPhone10,x` included); Ultra = High + 4096 + 16 reflection steps.
- The governor counts **missed refreshes** against the display's clock, not frames over 17.2 ms:
  on the iPhone 11, 1.6–16 % of frames come 1–8 ms late with the next as much early and every
  refresh drawn (a per-launch pacing mode), so §4.3's "late" would never let it raise. Its
  levels hold what exists today (GPU: reflection steps × 0.6, then small-caster shadows; CPU:
  traffic and people); no thermal input yet (§4.4's plugin).
- The view rule takes the small things' shadows off over 150 m and when flying.
- §1.2 item 2 and §1.4 checked on the phone with a Metal System Trace (G0's tool, used once): the
  A13 at the spawn by day is 88 % busy in its Medium GPU state at ×1 (14.5 ms a frame) and sits
  in its Minimum state at ×2. A cool iPhone 11 held 60 at ×1 too (no refresh missed in 3 min),
  so the orchestrator's 25 fps 1 % low was likely heat or the first rescue call's hitch.

---

## 0. In one screen

- **The iPhone 11 renders more pixels than the Pro Max.** Sharp's whole-pixel rule
  (`main.gd` `_apply_style`: `floor(screen lines / 480)`) gives the 828-line iPhone 11 a scale
  of ×1. Its pixel image at High is 1792×828 (1.48 MP), while the Pro Max's is 1434×660
  (0.95 MP). So the weakest phone draws 1.57× the pixels with about half the GPU, and its
  pixels are finer than any other phone's. Checked on the Mac today: `--resolution 1792x828`
  prints `image 1792x828`. The screenshot sets (2532×1170, 2868×1320) have never shown this
  look.
- **Today's numbers can't show headroom, and one of them is misread.** At a 60 Hz display the
  main thread's "draw" phase holds the wait for the display: 11.55 ms on one BENCH card and
  2.11 ms on another run at the same view (BACKLOG: "2–12 ms depending on the run"). It
  measures display wait, not the GPU (both readings are from the bench route at the default
  view). The best evidence for GPU room points the other way:
  loop 2b's "before" build ran at **120 fps** on the Pro Max zoomed out, with about 6 ms of
  Mac GPU work, almost 4× today's. Metal gives Godot no GPU timestamps, so G0 measures with
  Apple's tools (Metal System Trace, the Metal Performance HUD) plus a stress ladder.
- **The likely limit is the iPhone 11's main thread, not its GPU.** The Pro Max's main thread
  is busy ~5–6 ms a frame (process 3.96 + physics 0.49 + 3D render CPU 0.58 on the BENCH
  card). The A13 has about half the single-core speed, so it should be ~10–12 ms, *est.*.
  Its GPU should need ~3–5 ms at the default view and ~5–9 ms in the wide views, *est.*. The
  content loops (2c, 2d, police) will spend CPU. So the plan spends **GPU per-pixel work on
  every tier** and keeps **CPU-side extras on Ultra**.
- **Draw calls are cheaper than the skill says.** The "~10 µs a call on the A18 Pro" figure
  was measured under Xcode's Metal validation (47.6 ms for 6,771 calls, i.e. 7 µs each).
  Started from the home screen, the same 6,771-call build held 120 Hz, which caps the cost at
  **≤ 1.2 µs a call**. Keep the budget rules (they're cheap to keep), but a few dozen calls
  are not the risk; per-frame scripts are.
- **The ranked upgrades (section 3).** The best look per millisecond comes from shader work
  at the pixel image's size, with no draw calls and no CPU:
  1. Edge light: crease lines and sun-side highlights. This needs your yes, because the art
     bible allows one outline style.
  2. Facade "canyon" shade from the existing AO map (Mobile has no SSAO).
  3. Sun-dapple on the ground under trees.
  4. Sub-pixel smooth scrolling.
  5. Painted roof detail.
  6. Life in lit windows.

  Next come the effects in one sprite MultiMesh (rain spray, pigeons, leaves, steam), dusk
  glow and rain lamp cones. Ultra adds 4096 shadows, sharper reflections, roof clutter
  geometry and denser traffic.
- **Three tiers chosen at first launch** from `OS.get_model_name()` (section 4):
  - **Medium**: iPhone 8 to XS/XR (A11–A12), below the minimum target.
  - **High**: iPhone 11 to 15 (A13–A16), plus the 16e.
  - **Ultra**: iPhone 15 Pro and newer (A17 Pro, A18, A19).

  A governor drops the extras, never the look's pillars, when the view goes wide, frames run
  late or the phone gets hot.

---

## 1. What we know today

### 1.1 The two phones

| | iPhone 16 Pro Max (`iPhone17,2`) | iPhone 11 (`iPhone12,1`) |
| --- | --- | --- |
| Display | 2868×1320, 120 Hz (the game asks for 60) | 1792×828, 60 Hz LCD |
| Pixel image at High | 1434×660, scale ×2, 0.95 MP | **1792×828, scale ×1, 1.48 MP** |
| One image pixel on the glass | 0.11 mm (460 ppi ÷ 2) | 0.078 mm (326 ppi ÷ 1); ×2 would be 0.156 mm |
| Image at Medium (one step coarser) | 956×440 | 896×414 (0.37 MP) |
| GPU, 3DMark Wild Life Extreme (UL medians) | 4,264 | 2,068 (the A13 in the 11 Pro Max; stability 76 % in the stress test) |
| CPU single-core, Geekbench 6 | ~3,300–3,400 | ~1,730 |
| RAM | 8 GB | 4 GB |
| Measured | 60 fps at all four views; 1 % low 57–58 (loop 2b) | "holds 60" (the user; no BENCH card yet) |

Other A13 phones are lighter on the GPU. The 11 Pro and 11 Pro Max run ×2 (562 and 621
lines), and the SE 2 runs ×1 at 1334×750 (1.0 MP). So the iPhone 11 (and the XR) is the
worst fill case of its class, which is a good minimum target.

### 1.2 What the existing numbers already say

1. **Draw calls without the debugger** cost ≤ 1.2 µs each on the A18 Pro (6,771 calls held
   120 Hz; README, loop 2b) and roughly 2–2.5 µs on the A13 (*est.*, from single-core speed).
   So 50 more calls cost ~0.06 ms on the Pro Max and ~0.12 ms on the iPhone 11.
2. **The "draw" phase is not a GPU reading at 60 Hz.** It includes the wait for the next
   drawable (vsync), which moves with frame alignment: 2.11 ms in the `--bench` log and
   11.55 ms on the BENCH card at the same view. It shows GPU time only when the GPU is over
   budget, or on a 120 Hz build where the wait shrinks. README's "zoomed out the main thread
   already waits ~11 ms for the GPU" should read "waits for the display". Wide views still
   cost more per object (more casters, draws and cars), which is true and matters.
3. **The Pro Max has large GPU room.** The before-build's zoomed-out frame cost about 6 ms of
   Mac Vulkan GPU time (shadow 2.35 + opaque 2.6 + minimap ~1.0; README loop 2b) and still
   ran at 120 fps on the phone. So the phone's GPU time is at most ~1.4× the Mac's Vulkan
   time. Today's Mac numbers (1.04 ms at the spawn, 1.65 ms zoomed out at 2868×1320) put the
   Pro Max at **≤ ~1.5 ms and ≤ ~2.3 ms**. That is one data point, and G0 measures it
   properly.
4. **Scripts on the phone run ~5× their Mac time at 60 Hz clocks** (README loop 2b:
   0.6–0.9 ms on the Mac, 3.2–4.6 ms on the phone). The A13 is about half as fast again. iOS
   clocks the CPU down when a 60 Hz frame is easy, so these ms overstate the true cost. That
   is why G0 measures headroom by adding load, not by subtracting from 16.7.
5. **Mac runs with `--rendering-driver metal` render Forward+, not Mobile.** When a driver is
   given without `--rendering-method`, Godot picks Forward+. Today's probe printed
   `Metal 4.0 - Forward+`; a plain `godot --path game` prints `Forward Mobile`. README's
   "How to measure" command has this gap. Every frame time and look check on the Mac must
   add `--rendering-method mobile`, or a Forward+-only effect could look fine on the Mac and
   be missing on the phone.

### 1.3 Mac measurements for this plan

Mac M4 Pro, Vulkan + Mobile, `--gpu-profile`, `--probe` at the spawn, day, High, traffic
Normal, 300 frames. Four other agents were running Godot at the time, so the timings are
noisy (two runs each, interleaved). The draw-call counts are exact.

| Run | GPU (3D view) ms | Passes (one sample) |
| --- | --- | --- |
| Pro Max image 1434×660 | 1.03 / 1.04 | shadows 0.21 · opaque 0.65 · transparent 0.09 · tonemap 0.02 · 2D 0.18 |
| iPhone 11 image 1792×828 | 1.27 / 1.21 | shadows 0.21 · opaque 0.85 · transparent 0.14 · 2D 0.12 |
| iPhone 11 at Medium, 896×414 | 0.85 | |
| Pro Max image, `--exp=shadowsize=4096` | 1.26 / 1.19 | shadows **0.48** (from 0.21) |
| Pro Max image, `--exp=nopost` | 0.82 / 0.82 | opaque + transparent + tonemap merge into **one subpass** (0.57) |
| Draw calls, iPhone 11 image (Metal) | 154 (3D 53, shadow 35, 2D 66) | the same view as the Pro Max (2D +5) |

What this shows:
- The opaque pass grows ~0.35 ms per megapixel on the Mac. About 0.3 ms of it is fixed
  (vertices, draws).
- 4096 shadows add ~0.15–0.27 ms on the Mac.
- The post pass, together with the pass split it forces (its screen and depth reads stop
  Mobile from merging opaque, transparent and tonemap into one tile pass), costs ~0.2 ms.
  It is essential, but nothing else should force a second split: new image effects go
  inside the existing post pass (README budget rule 7).

### 1.4 The frame today on each phone (*est.* until G0)

| | Pro Max | iPhone 11 |
| --- | --- | --- |
| GPU, default view (spawn / river) | ≤ ~1.5 ms (§1.2 item 3) | ~3–5 ms: Mac 1.24 ms at its image × ≤ 1.4 × 2.1–2.7 (UL ratio) |
| GPU, zoomed out 220 m / helicopter 150 m | ≤ ~2.3 / ~2.5–3 ms | ~4–8 / ~5–9 ms |
| Main thread busy (process + physics + render CPU) | ~5–6 ms (BENCH card) | ~9–12 ms (×~2) |
| What runs out first | nothing soon; then CPU | **CPU**; then GPU in the wide views |

Loops 2c and 2d may spend +0.4–0.7 ms of Mac script time (README budgets). At the factors
above, that could be 4–7 ms on the iPhone 11 at 60 Hz clocks, which is more than its CPU
room. G0 must measure it before 2d starts. Two "headroom makers" in the perf lane would
help: Godot's separate render thread (`--render-thread separate`, or the project setting
`rendering/driver/threads/thread_model`), which takes draw submission off the main thread,
and the traffic script (1.53 ms on the Pro Max's card).

---

## 2. Measuring real headroom

### 2.1 Why we need instruments

- Metal gives Godot 4.7 no GPU timestamps (`GPU n/a (Metal)`).
- Both displays cap at 60 Hz in the game (the Pro Max can do 120 only if we allow it), so a
  fast frame looks the same as a barely-in-time one.
- The "draw" phase mixes CPU submission with display waits (§1.2 item 2).
- iOS clocks the CPU and GPU by load (DVFS), so "16.7 minus the ms used now" overstates the
  room, and heat lowers it after minutes.

So G0 measures headroom three ways that check each other:
1. **The stress ladder** is the ground truth. It adds known work in steps until frames run
   late.
2. **Apple's GPU tools** give real GPU ms: Metal System Trace on the Mac, or the Metal
   Performance HUD on the phone.
3. **A 120 Hz diagnostic build** (Pro Max only) is a quick sanity check.

### 2.2 Instruments to build (loop G0, perf-engineer)

| Instrument | What it is | Read where |
| --- | --- | --- |
| `--stress=gpu:N` | N full-image quads after the post pass (additive, output × a runtime-zero uniform, so nothing shows), each with 8 texture reads + 32 multiply-adds per pixel: a fixed per-pixel cost at the pixel image's size | BENCH / probe lines |
| `--stress=draws:N` | 25·N single-triangle meshes 2 m under the ground inside the view, casting shadows: +25·N draw calls in each of the main and shadow passes, no visible pixels | same |
| `--stress=cpu:N` | N × 0.5 ms busy loop in `_process` on the main thread | same |
| `--stress-ladder=gpu\|draws\|cpu` (with `--probe`) | Settle 8 s, then N = 0, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32 for 6 s each. Prints `stress: gpu 4 · fps 60.0 · 1% low 57.1 · late 2.1% · cpu busy 6.2 ms` per step. Stops after two failing steps (1 % low < 55 or > 5 % of frames late). Ends with `stress result: gpu headroom 12 steps`. About 2 minutes per ladder | the log copied back by `tools/device_run.sh` |
| `cpu busy` line on the BENCH card | process + physics + render CPU (3D + 2D); the rest of "draw" is waiting | the card |
| `tools/device_run.sh --env=K=V` and `--trace` | Launch with environment variables (`MTL_HUD_ENABLED=1`; loop 2b already used `MTL_DEBUG_LAYER=1` this way). Record 15 s of `xcrun xctrace record --template "Metal System Trace"` attached to the running game, then `xctrace export` (find the GPU-interval tables with `--toc`) to get GPU ms per frame and per pass | `build/device/<label>/` |
| `tools/export_ios.sh --diag120` | The exported project only gets `display/window/ios/allow_high_refresh_rate=true` (the plist already has `CADisableMinimumFrameDurationOnPhone`). Never in a release | `--probe --fps=0` reads fps up to 120 |
| SOAK in Settings → TEST | 20 min on the bench route at the current settings; fps per minute, 1 % low per minute and the governor's state go to `user://bench_result.txt` and the card | the card (COPY) |

All stress code is off by default, and the bench at N = 0 must match today's within noise.
An upgrade's device cost can then be read in the same units: run the ladder with the upgrade
on and off, and the cost is the number of steps lost. Calibrate one step in ms per phone
from the trace (N = 8 against N = 0, divided by 8).

### 2.3 The protocol (both phones, the iPhone 11 first, cool)

Each line is one launch through `tools/device_run.sh`, with `--probe` and `--quality` at
today's High.

| # | View (flags) | Time | Ladders |
| --- | --- | --- | --- |
| 1 | Spawn, default 80 m (no `--at`) | day | gpu, cpu, draws |
| 2 | River, default (`--at=1135.7,-198.1 --heading=72`) | day | gpu |
| 3 | Zoomed out (as 2 + `--size=220`) | day | gpu |
| 4 | Helicopter (`--at=1300,-420 --heading=60 --heli --size=150`) | day | gpu, cpu |
| 5 | Spawn | night, rain | gpu |
| 6 | Helicopter | night, rain | gpu |
| 7 | Views 1, 3, 4, 5 at N = 0 and N = 8 | | 15 s Metal System Trace each (GPU ms per pass; one step in ms) |
| 8 | Pro Max only: `--diag120` build, `--probe --fps=0`, views 1–4 | day | fps ≥ 118 means CPU and GPU are both under 8.3 ms |
| 9 | SOAK, 20 min, started from the home screen, unplugged | day, High | fps per minute, 1 % low, governor state |

Rules:
- One minute of rest between launches. If step 0 of a ladder reads under 60, the phone is
  warm: stop, let it cool for 10 minutes, and repeat that launch.
- Repeat ladder 1-gpu at the end. If it differs by more than one step from the first run,
  the session's numbers are unreliable.
- Write down the run order and the time.

Time: about 35–45 minutes per phone, plus the 20-minute soak.

### 2.4 What the user does

Before (once per phone):
- iPhone 11, the first time: turn on Developer Mode (Settings → Privacy & Security →
  Developer Mode, then restart). Connect it to the Mac by cable, unlock it and tap "Trust".
  If Xcode asks to prepare the device, open Xcode once (Window → Devices and Simulators).
  The first build registers the phone with the signing team automatically.
- Note the phone's **Settings → Battery → Battery Health** (maximum capacity, and whether
  "peak performance" management is on). A worn battery in a 2019 phone can make iOS throttle
  it, and the numbers mean nothing without this.

For the session:
- Turn Low Power Mode off and set Auto-Lock to Never.
- Set brightness to about half, take the phone out of its case and put it face up on a table
  in a room at about 20–25 °C. Close other apps.
- Let the phone sit idle for 10 minutes before the first run.
- Tell the orchestrator "the iPhone 11 is connected and free for device runs" (device runs
  need your yes for that loop). Then don't touch it while the game starts and quits itself,
  about 15 times.
- Optional cross-check: Settings → Developer → Graphics HUD → Show Graphics HUD, and send a
  screenshot of the HUD at the default view (it shows the GPU time per frame).

The soak:
- Unplug the phone (charging adds heat).
- Start the game from the home screen and open Settings → TEST → SOAK.
- Leave it on the table for 20 minutes, then press COPY and paste the card into the chat.

### 2.5 From headroom to budgets

For each phone and view, G0 writes a "Graphics headroom" table into README "Performance
budgets" and derives:

- **GPU budget for graphics** = 0.7 × (16.7 − GPU ms now) − the content reservation (2c + 2d +
  police: +20 % of today's GPU frame, *est.*).
- **CPU budget for graphics** = 0.75 × 16.7 − CPU busy now − the content reservation (2c + 2d
  scripts × the measured Mac→phone factor).
- **Draw calls**: the README ceilings stay. The stress-draws ladder shows how far above them
  the phone could go, which is a margin, not an allowance.

The 0.7 and 0.75 leave room for heat (the A13 keeps ~76 % in UL's 20-minute stress test) and
for frame-to-frame spread. An upgrade joins a tier only if its measured cost in ladder steps
fits that tier's weakest phone (the iPhone 11 for High, the iPhone 15 Pro for Ultra; until
one is measured, the Pro Max with a 30 % margin).

---

## 3. The upgrades, ranked by look per millisecond

### 3.1 What the Mobile renderer can't do (Godot 4.7 docs, "Overview of renderers")

Mobile has **no SSAO, SSIL, SSR, SDFGI, VoxelGI, volumetric fog, TAA, FSR2 or subsurface
scattering, and no soft PCSS shadows for directional lights**. Those are Forward+ only;
SSAO also exists in Compatibility.

Mobile **does** have:
- glow, depth and height fog, decals, depth of field and LightmapGI;
- reflection probes (8 per mesh) and MSAA/FXAA;
- PCSS for omni and spot lights;
- up to 8 positional lights per mesh (256 per view).

Moving the phone to Forward+ isn't worth it. It is a heavier clustered path with a depth
prepass, it gives up Mobile's merged tile passes, and the items below fake what we would
use it for at a fraction of the cost.

### 3.2 The ranked list

How to read the costs:
- GPU costs are *est.*: the Mac's cost at the Pro Max image × 1.0–1.4 for the Pro Max, and
  × 3.3–6.0 for the iPhone 11 (1.57× the pixels at 2.1–3.8× the time per pixel).
- "Per-pixel" items cost the same at every view, because the image size doesn't change.
  "Per-object" items grow with the view.
- Look: ★ 1–5 as judged against the art bible. Tier: where it is on by default.

| # | Upgrade | Look | GPU ms, Pro Max / iPhone 11 | CPU, draws, memory | Hurts | Tier |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | **Edge light**: 1-px crease lines on concave edges and a lighter sun-side line on convex roof and wall edges, in the post pass, which already reads 5 depths per pixel (**needs your yes**) | ★★★★★ | 0.03–0.07 / 0.12–0.3 | 0 · 0 · 0 | per-pixel, all equal | High (Medium too) |
| 2 | **Facade canyon shade**: walls sample the existing ground AO map a step out from the wall, so narrow streets and courtyards darken towards the ground in 3 dithered bands, plus a 1-px wall-foot contact line | ★★★★ | 0.02–0.05 / 0.08–0.2 | 0 · 0 · 0 | per-pixel | Medium+ |
| 3 | **Sun-dapple under trees**: in the trees' shade (the AO map's green channel), a two-tone pixel pattern of sun flecks drifting with the wind; by day only | ★★★★ | 0.01–0.04 / 0.05–0.15 | 0 · 0 · 0 | per-pixel (parks, avenues) | Medium+ |
| 4 | **Sub-pixel smooth scrolling**: render a 1-px margin and shift the scaled-up image by the snap remainder, so the camera glides while the city's pixel grid stays locked | ★★★★ (motion) | ~0 / not needed at ×1 | 0 · 0 · 0 | none | all |
| 5 | **Painted roof detail**: vents, skylights, HVAC blocks and membrane seams drawn in `building.gdshader` from the roof's position and style seed | ★★★ | 0.02–0.04 / 0.08–0.15 | 0 · 0 · 0 | per-pixel (biggest win from the helicopter) | Medium+ |
| 6 | **Life in windows** at night: silhouettes crossing lit windows and a few lights switching over minutes | ★★★ | ~0.01 / 0.02–0.05 | 0 · 0 · 0 | night | Medium+ |
| 7 | **Rain spray and splashes** behind moving cars (BACKLOG), in the shared FX sprite MultiMesh (item 8) | ★★★★ in rain | 0.02–0.05 / 0.08–0.2 | +0.05–0.1 / +0.1–0.25 ms · +1 draw, no shadow · < 1 MB | rain; more cars in wide views (capped) | High (16 cars), Ultra (48) |
| 8 | **Ambient life**: pigeons (flushing as you pass), falling leaves in the parks, steam from kebab stands and manholes on cold nights. Pixel sprites animated in the vertex shader from a seed and TIME | ★★★★ | 0.02–0.05 / 0.08–0.2 | ~0.05 / ~0.1 ms · shares item 7's draw · < 1 MB | per-object, capped by count | High (96 alive), Ultra (192) |
| 9 | **Dusk glow**: glow on at dusk alongside the shadows (off since v0.7, when shadows were 4× today's cost), with wider glow levels on Ultra | ★★★★ at dusk | 0.1–0.2 / 0.4–0.8 | 0 · 0 · 0 | dusk only | Ultra; High if the A13 measures it in |
| 10 | **Rain lamp cones**: dithered additive cones under street lamps at night in the rain, using the existing `glow.gdshader`. These are the cheap light shafts | ★★★★ in rain-night | 0.05–0.1 / 0.2–0.45 | 0 · +1 per 512 m tile in view (2–6) · 0 | rain-night, fill | Ultra; High if it fits |
| 11 | **Rooftop neon**: Warsaw's PRL-era rooftop signs as parodies, in the existing neon atlas and `neon.gdshader` | ★★★ at night | ~0.02 / ~0.08 | 0 · +2–6 at night · < 1 MB | night | High (1×), Ultra (2×) |
| 12 | **4096 sun shadow**: texels 0.37 → ~0.18 m, so shadow edges sit on the pixel grid (~0.75–1.5 image pixels per texel at 80 m instead of ~1.5–3) and lamp posts and signs cast readable shadows | ★★★ | 0.2–0.4 / not offered (bandwidth and heat) | 0 · 0 · +24 MB | per-pixel and shadow casters (wide views) | Ultra |
| 13 | **Surface tiles** (PixelLab `create_tiles_pro`, ≤ 50 generations): Warsaw pavement (trylinka hexagons, granite slabs, Old Town cobbles), facade patterns (tenement, MDM sandstone, panel blocks), roof membranes; one extra texture read in the existing shaders | ★★★★, art risk | 0.04–0.08 / 0.15–0.3 | 0 · 0 · +2–6 MB | per-pixel | High |
| 14 | **Sharper reflections**: a binary refinement on the hit (+3 steps); Ultra 16 steps | ★★–★★★ | 0.05–0.15 / 0.1–0.3 (refinement only) | 0 · 0 · 0 | river, wet streets | High (refinement), Ultra (16) |
| 15 | **Haze and river mist**: Godot's depth and height fog in the sky colour, stronger when zoomed out, with a dawn mist band at river level | ★★–★★★ | 0.02–0.04 / 0.08–0.15 | 0 · 0 · 0 | per-pixel (helps the wide views read) | High |
| 16 | **Wind gusts and flags**: one global wind field (direction, gusts travelling across the map) shared by trees, flags, leaves and the rain's slant; flags on public buildings and banners on the Royal Route | ★★–★★★ | ~0.02 / ~0.08 | 0 · +2–8 · 0 | per-object (small) | High |
| 17 | **Roof clutter geometry**: antennas, AC units, water tanks, chimneys; ≤ 3 kinds as MultiMeshes per 512 m tile, hidden in views over 160 m | ★★★ | 0.1–0.3 in wide views / not offered | +0.05 ms · +30–55 (wide) · tris +50–150 k | wide views, helicopter | Ultra |
| 18 | **Denser traffic and people**: +30 % cars and 90 people, only in views ≤ 120 m | ★★–★★★ | small | **+0.9–1.5 ms** / not offered · 0 · 0 | CPU everywhere; readability (C1) | Ultra |
| 19 | **Cloud sprites** seen from the helicopter and zoomed out, placed where the cloud shadows already are | ★★ | 0.05–0.15 (wide) / not offered | 0 · +1 · < 1 MB | wide views only | Ultra |
| 20 | **"Smooth" ×1 image** (an opt-in style on Ultra) | changes the style | +2–4 / n/a | 0 · 0 · +30–60 MB | everything | not recommended (§6 Q5) |

Together, items 1–6 cost about 0.15–0.3 ms on the Pro Max and about 0.4–1.0 ms on the
iPhone 11 (*est.*). They add no draw calls and no CPU, so they fit every High phone if G0's
numbers are anywhere near §1.4.

### 3.3 Notes on the top items

- **Edge light (1)** is what makes pixel-art 3D read as hand-drawn: a dark line where
  surfaces fold in and a pale one where an edge catches the sun. It is the signature of the
  best pixel-3D showcases (for example t3ssel8r's). The post pass already reconstructs
  normals from four neighbouring depths for the reflections, so this is mostly arithmetic.
  It is a second line style, which the art bible forbids, so G3 makes A/B shots first and
  ships only with your yes. The lines must skip the ghost's pixels, as the outlines do.
- **Canyon shade (2)** is the Mobile renderer's missing SSAO, done the pixel way. It gives
  courtyards and narrow streets depth, and the Palace's wings read as wings. Banded and
  dithered, never a smooth gradient.
- **Sun-dapple (3)** is the cheap form of "tree-dapple shadows". Alpha-tested holes in the
  crowns' shadow pass would defeat the GPU's hidden-surface removal for every tree in both
  passes. The look loop is doing the dapple on the crowns; this is the matching dapple on
  the ground, and the two should share one pattern scale.
- **Smooth scrolling (4)**: today the camera snaps to whole image pixels, which is 2 screen
  pixels on every ×2 phone, so slow pans step. This is a common pixel-3D technique. It
  belongs to the image scaling in `main.gd` and the camera snap, so it goes after the camera
  loop (Phantom Camera) merges. It does nothing on the iPhone 11 at ×1.
- **FX sprites (7, 8)**: one MultiMesh, one material, one PixelLab sprite atlas, no shadows,
  for every small effect (spray, splashes, pigeons, leaves, steam, and loop 3i's sparks and
  dust). That is 1–2 draw calls for all of it, which matches DEMO.md's "particles ≤ 1 draw
  call" for 3i. Idle sprites animate in the vertex shader. The CPU only places instances
  near the view, and spray rides on `traffic.gd`'s per-frame buffer pass.
- **Rules for every item:**
  - Tier switches are **uniforms, not shader defines**: a define makes a new pipeline, a
    first-sight hitch and a material that can't be shared.
  - Reuse the existing shaders (README budget rule 5).
  - Pixel light: 3–4 bands and a 1-px dither, never a smooth gradient.
  - Nothing new glows inside the ghost.
  - The protect list stays unchanged: Rondo in the rain, the Palace, the night river.

### 3.4 Considered and not recommended

| Idea | Why not | Instead |
| --- | --- | --- |
| Soft shadow filtering (PCF) | Penumbra gradients fight the pixel grid (art bible "Never") | Item 12's crisp 4096. "Very Low" filtering only if 4096 texels crawl, judged from shots |
| Tree-dapple *shadows* (alpha-tested crowns in the shadow pass) | Discard defeats hidden-surface removal for every tree draw | Item 3 |
| LightmapGI / baked probes | Mobile can render them, but `building.gdshader` uses UV2 for the style seed; the sun moves (Day, Dusk, Live); 6 km² today and 30 km² in the demo means hundreds of MB of lightmaps and hours of baking per map bake | Item 2 now; a per-vertex sky-visibility bake with sector streaming (loop 3c/3d) at zero runtime cost |
| Screen-space sun shafts | The sun is never on screen in a 30° orthographic view | Item 10 (lamp cones), long dusk shadows |
| Tilt-shift depth of field | Blur breaks "nothing blurrier than its neighbours" | Item 15 (haze) |
| Planar water reflections | A second render of the city doubles the draw calls and the shadow pass | Item 14 |
| Real lights for traffic headlights | Mobile allows 8 positional lights per mesh, and city meshes are 256 m tiles | The existing additive cones (the look loop strengthens the player's) |
| MSAA / FXAA | Smooths pixel art | none |

Other ideas, not in this plan's loops: a **snow** weather and **seasons** in Live (autumn
leaves, a winter city), and a **120 Hz** option on ProMotion phones (section 6).

---

## 4. Device tiers, Auto quality and the governor

### 4.1 Detection at first launch

`OS.get_model_name()` returns the hardware identifier (the BENCH card prints `iPhone17,2`).
The number before the comma is the family, not the marketing name: **`iPhone11,x` is the
XS/XR (A12); the iPhone 11 is `iPhone12,1`.** The export allows iOS 16 and iPads
(`export_presets.cfg`), so older phones can install it too.

| Identifier | Phones | Chip | Auto picks |
| --- | --- | --- | --- |
| `iPhone10,x` | 8, 8 Plus, X | A11 | Low |
| `iPhone11,x` | XS, XS Max, XR | A12 | Medium |
| `iPhone12,x` | 11, 11 Pro, 11 Pro Max, SE 2 | A13 | High |
| `iPhone13,x` – `iPhone15,x` | 12 to 14 Pro, 15, 15 Plus, SE 3 | A14–A16 | High |
| `iPhone16,x` | 15 Pro, 15 Pro Max | A17 Pro | **Ultra** |
| `iPhone17,1–4` | 16 Pro, 16 Pro Max, 16, 16 Plus | A18 Pro, A18 | **Ultra** |
| `iPhone17,5` | 16e (4-core GPU) | A18 | High |
| `iPhone18,x` and up | 2025 and later | A19… | **Ultra** |
| iPad, Mac, simulator, unknown | | | High, with the governor |

- Settings → Quality offers **Auto** (the default: the tier above plus the governor), Low,
  Medium, High and Ultra.
- A fixed choice wins, but the governor still guards the extras, never going below the
  chosen tier's base.
- Saves from before G1 that say "High" become Auto once, since they stored the default, not
  a choice.
- The BENCH card shows `quality Auto→High (iPhone12,1)`.

### 4.2 What each tier turns on

| | Low | Medium | **High** (A13–A16) | **Ultra** (A17 Pro+) |
| --- | --- | --- | --- | --- |
| Pixel image | one step coarser (budget 0.5 MP) | one step coarser (budget 0.5 MP) | Sharp, budget 0.96 MP: ×2 on the iPhone 11 (G1); under Auto ×1 there, ×2 as the fallback (G1b, §4.5) | Sharp, budget 1.6 MP: ×1 on the iPhone 11 |
| Sun shadows | off | 1024, buildings + trees | 2048, all over 1 m | **4096**, all over 1 m |
| Per-pixel pack (items 2, 3, 5, 6; 1 if approved) | off | on | on | on |
| Surface tiles (13), haze (15) | off | on | on | on |
| Reflections | off | 6 steps | 10 + refinement | **16** + refinement |
| Glow | off | night | night (+ dusk if it fits) | night + **dusk**, wider levels |
| FX sprites alive (7, 8) | 0 | 32, no spray | 96, spray on 16 cars | **192**, spray on 48 cars |
| Rain lamp cones (10) | off | off | if it fits | on |
| Rooftop neon (11) | off | off | 1× | 2× |
| Roof clutter (17), cloud sprites (19) | off | off | off | on (views ≤ 160 m; clouds only in wide views) |
| Traffic share / people | 55 % / 24 | 80 % / 40 | 100 % / 60 | **130 % / 90** (views ≤ 120 m) |
| `fine_detail` hidden beyond | 170 m | 170 m | 170 m | 240 m |
| Rain streaks | 40 % | 70 % | 100 % | 100 % |

Low and Medium keep their current meaning, so nobody's saved choice changes look. Medium
gets the per-pixel pack because its coarser image cuts the fill to between a quarter (×1 → ×2)
and under half (×2 → ×3).

### 4.3 The governor (G1)

It runs every 0.5 s, the overlay's cadence, always on and cheap. It reads:
- the share of frames that are **late** (over 17.2 ms, or 33.8 ms at the 30 fps cap) over
  3 s;
- **CPU busy** (§2.2);
- the view width and whether the player is flying;
- the thermal state, once item 4.4's plugin exists.

1. **The view rule is fixed, not adaptive.** In views over 150 m, or flying, Ultra's
   per-object extras step down (roof clutter by visibility range, FX count halved, traffic
   back to 100 %), and per-pixel items stay. Visibility ranges hide things whole, so
   nothing flickers or oscillates.
2. **The frame rule.** If more than 5 % of frames are late for 3 s, drop one level:
   - CPU extras if CPU busy is over 12.5 ms: traffic and people density, FX simulation,
     spray;
   - otherwise GPU extras, in order: cones, FX count, dusk glow, reflection steps,
     small-caster shadows (the last only at a view change).

   Raise one level after 30 s with under 0.5 % late, and not in a wide view. At most one
   change every 10 s. Counts fade over a second; nothing pops.
3. **Never touched:** the pixel size, the shadow map's size (reallocating it hitches), the
   landmarks, the ghost, the river, the night lights.
4. **Visible state:** an overlay line `gov: GPU 2/2 · CPU 2/2 · wide no · thermal n/a`, and
   the same on the BENCH and SOAK cards.

Tests:
- `check_tiers.gd` (identifier → tier, the table above, unknown → High) and
  `check_governor.gd` (the state machine with scripted inputs: no oscillation, the CPU/GPU
  split, the hold times).
- On the Mac, `--stress=gpu:N` and `--stress=cpu:N` force a drop and a recovery.

### 4.4 Heat and long sessions

- **The bar is DEMO H3**: 20 minutes without throttling. Read it as fps per minute staying
  at 60 with 1 % low ≥ 55 for 20 minutes at the tier's defaults, on both phones (the SOAK).
- **Design to the sustained phone.** Use 70 % of the frame for the GPU and 75 % for the CPU
  (§2.5). The UL stress test keeps ~76 % of the A13's peak; 4096 shadows and 120 Hz are the
  big heat sources, and neither is offered on the A13.
- **Thermal state.** Godot 4.7 has none. A small native iOS plugin can read
  `ProcessInfo.thermalState` and `isLowPowerModeEnabled`; build it with the haptics plugin
  already planned (ROADMAP: "a small iOS plugin with UIImpactFeedbackGenerator"),
  device-gated, Opus. Responses:
  - **serious**: both extras to level 0, silently;
  - **critical**: the 30 fps cap, with a toast "Telefon się grzeje · Phone is warm: 30 fps";
  - **Low Power Mode**: a one-time hint about 30 fps.

  Until the plugin exists, the late-frame rule and fps per minute do the job.
- **Record battery health** on every device run (§2.4). An old battery changes the result
  more than any shader.

### 4.5 Auto's sharp image and its fallback (loop G1b)

The user's call after the iPhone 11 before/after crops (2026-10-29): the iPhone 11 gets the
**sharp** picture by default, with a fallback. G1 had measured that a cool iPhone 11 holds ×1
at High (3 minutes, 0 missed refreshes) but with the A13 88 % busy in its Medium GPU state, so ×1
has little margin for heat or the content still coming, and the governor never changes the
pixel size live. So the pixel size is decided per launch, from the sessions before
(`tiers.gd` `SHARP_*`, `governor.gd` tally, `settings.gd` `[auto_image]`):

1. **Where.** Under Auto, where the level's budget makes the image coarser than the style's
   own scale (`Tiers.budget_binds`): on the phones only High with Sharp on the iPhone 11
   (`iPhone12,1`, 1792×828) and the SE 2 / 3 (`iPhone12,8`, `iPhone14,6`, 1334×750; the iPhone 8
   and the XR have the same screens but Low / Medium, whose own step already makes ×2); Mac
   windows under 960 lines over 0.96 MP (1366×768, 1440×900, 1792×828). Every other phone,
   style and level has one scale either way (`check_tiers.gd` walks all 40 iPhone ids × 4
   styles). Auto draws the style's own scale there with that level's effects ("High ×1": not
   Ultra's 4096 shadows or 16 reflection steps). Manual levels keep G1's rule.
2. **Struggled** (the session's tally, counted only at that image, past the governor's settle
   after a start, a load or a pause, and outside wide views and the helicopter, where no raise
   can come): the GPU's extras were dropped by a **GPU-bound** load for 60 s in all **and** a
   tenth of the counted play (one drop that a calm half minute undoes is 30 s: a passing load;
   a second, or one that didn't calm the frames, is the image; the tenth keeps two passing
   loads in a long drive from counting), or **3 counted minutes in a row** missed over 2 % of
   their refreshes GPU-bound (a steady loss under the governor's 5 % that never drops a level).
   CPU-bound misses and drops don't count (a coarser image doesn't help the CPU), nor a GPU drop
   a CPU-bound load made once the CPU's extras were gone. **Calm**: 3 minutes counted without
   that. The verdict is written the moment it is known (iOS kills a backgrounded app without
   notice), a struggle replacing an earlier calm verdict in the same session.
3. **Coming back.** After a struggle the next launches are the fallback; 2 calm sessions there
   bring the sharp image back **on trial**; a struggle before it has had as many calm sessions
   as the wait doubles the wait (2, 4, 8, 16, capped), and a passed trial puts it back to 2. A
   struggle at the fallback starts its count again. So a phone that struggled on one hot day is
   sharp again a day or two later, and one that can't hold ×1 spends one launch in 17 trying it
   once capped (the governor guarding that one): the governor's own raise-wait law, a level up.
4. **Never written** by `--nosave`, test runs (the bench, the probe, the autopilot, shots),
   `--last-session=struggled|calm` (which starts as if the last session struggled or was calm);
   the `quality:` lines say what Auto picked and why.
5. **Thermal state**: still not readable from Godot 4.7.2 (no OS / DisplayServer / Engine method
   for it); 4.4's plugin would add it to the struggle rule.

---

## 5. Loops, in order

The order starts after the first-minute look loop and the camera loop merge. Settings UI
changes wait for the HUD loop (2e). One writer at a time, as always. On top of `verify.sh`
PASS, docs and shots, every loop must pass:
- shots at **2868×1320, 2532×1170 and 1792×828** (the iPhone 11's own ×1 image), day, dusk
  and night, on both city paths, judged against the art bible;
- the BENCH card at the tier's default on **both phones** at the four views, with 1 % low
  ≥ 56;
- the ladder cost in steps, which must not exceed the item's budget from §2.5.

| Loop | Agent, model | Items | Acceptance on both phones |
| --- | --- | --- | --- |
| **G0 Headroom** (first) | perf-engineer, Opus; device-gated, both phones | §2.2 instruments. Fix README's Metal command (`--rendering-method mobile`). Update the skill's draw-call cost. Measure `--render-thread separate`. Run the §2.3 protocol | Stress off = bench unchanged. Ladders repeat within one step. The headroom table (4 views + 2 rain-night) and trace GPU ms for both phones in README. SOAK at High on both. Content budgets restated per phone (§1.4 warning) |
| **G1 Tiers and governor** — **done 2026-10-28** | perf-engineer, Opus (Settings row after 2e) | §4.1–4.3, with Ultra as High + 4096 shadows + 16 reflection steps; the image as a budget per level | `check_tiers` and `check_governor` OK (in verify.sh). Auto picks High on the iPhone 11 and Ultra on the Pro Max. A forced overload (`--stress=wait:40`) dropped within 0.8 s on the iPhone 11 and came back 30 s after it ended; `check_governor` runs 15 minutes of a pulsing load without swinging. BENCH at Auto 56.6 (iPhone 11) / 57.3 (Pro Max), 0 missed refreshes; the probes 52.9–58.8 |
| **G1b Sharp with a fallback** — **done 2026-10-29** | perf-engineer, Opus; the iPhone 11 | §4.5: Auto ×1 with High's effects where the budget binds, the ×2 fallback after a session that struggled, the doubling wait back | `check_tiers`, `check_governor`, `check_settings` OK. The iPhone 11's BENCH at Auto ×1 and a 15-minute drive (README "Loop G1b"; the first G0 soak data point) |
| **G2 Per-pixel pack** | gameplay-dev, Opus; art-director review | Items 2, 3, 5, 6 and item 4 (smooth scrolling) | +0 draw calls. Mac Vulkan GPU ≤ +0.15 ms at the Pro Max image (medians of 5, interleaved). The iPhone 11 loses ≤ its budget in steps. The protect list unchanged |
| **G3 Edge light** (only with your yes) | gameplay-dev, Opus | Item 1; A/B shots first | As G2. Art-bible line updated by you |
| **G4 FX sprites** | gameplay-dev, Opus; game-designer for the PixelLab atlas (≤ 50 generations) | Items 7, 8; the system 3i reuses | ≤ 2 draw calls for all effects, none in the shadow pass. Scripts ≤ +0.05 ms on the Mac. iPhone 11 rain-night BENCH ≥ 56. iPhone 11 SOAK in rain-night |
| **G5 Ultra pack** (after loop 3c, sector streaming) | perf-engineer measures, gameplay-dev builds, Opus | Items 9, 10, 11, 12, 14, 17, 18, 19; what fits the A13 moves into High | Pro Max BENCH ≥ 56 at the four views by day, dusk and rain-night. Pro Max SOAK at Ultra in rain-night. `--diag120` numbers recorded (answers §6 Q4). iPhone 11 numbers unchanged |
| **G6 Surfaces** | game-designer (PixelLab tiles), gameplay-dev (shaders), art-director gate; Opus | Item 13, after the look loop's palette is accepted | Day chroma rule (the ground quieter than what you drive or tap). C1 car-finding test still passes. ≤ 6 MB |
| **G7 Atmosphere** | gameplay-dev, Sonnet once the values are fixed by an Opus review | Items 15, 16, glow levels | As G2 |

G0 and G1 are small and protect everything after them, so they should go first. G2–G4 don't
depend on the map's structure. G5 waits for sector streaming, because roof clutter, traffic
density and the per-sector budget depend on it. A thermal plugin loop can join whenever the
haptics plugin is built.

---

## 6. Open questions (each with the default this plan uses)

1. **The iPhone 11's pixel size.** Keep ×1 (828 lines: today's look there, the smoothest of
   any phone, at 1.57× the Pro Max's pixels)? Or switch to ×2 (414 lines: coarser than Sharp's
   480, and about 60 % less fill)? *Default: keep ×1. It holds 60, and it is what you saw.*
   **G1:** ×2 at High (and so at Auto), as the loop's brief asked after the first iPhone 11
   bench; ×1 is Ultra on that phone. **G1b (the user, 2026-10-29):** Auto draws ×1 with High's
   effects, falling back to ×2 for the next launches after a session that struggled (§4.5);
   Wysoka stays ×2.
2. **Edge light** (crease and sun-side lines). Allow this second line style in the art
   bible? *Default: not until you've seen G3's A/B shots.*
3. **Ultra for everyone?** *Default: Auto picks Ultra on A17 Pro and newer; anyone can
   choose it in Settings, with a note that it may run warm.*
4. **120 Hz on ProMotion phones** (a Settings option on Ultra, falling back to 60 when warm)?
   *Default: not now. Decide after G5's `--diag120` numbers; at 120 the budget halves and
   the phone heats up.*
5. **A "Smooth" ×1 style on Ultra?** *Default: no. It trades the pixel identity for about
   4× the fill.*
6. **Snow and seasons** (Live picks autumn leaves and a winter city). *Default: a later look
   loop of its own, not in G0–G7.*
7. **Denser traffic on Ultra** works against finding the car in under a second (C1).
   *Default: +30 % only in views ≤ 120 m, and none during a race or chase.*
8. **The thermal plugin** (native iOS, built with the haptics plugin)? *Default: yes, in the
   haptics loop; the frame-based governor until then.*
9. **Saved "High" becomes Auto once?** *Default: yes.* **G1: done** (`settings.gd`, the
   `tiers` key).
10. **Minimum iOS.** The export allows iOS 16, which installs on A11 and A12 phones below the
    target. iOS 26 runs on the iPhone 11 and SE 2 and later. *Default: Auto handles old
    phones now (Low/Medium); raise the minimum to 26 at loop 3j (TestFlight).*
11. **Device time.** G0 needs the iPhone 11 for about an hour with Developer Mode, plus the
    battery-health reading. *Default: G0 waits for your yes and the phone.*

---

## Sources

- Godot 4.7 documentation, [Overview of renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
  (feature table: Mobile has no SSAO, SSIL, SSR, SDFGI, VoxelGI, volumetric fog, TAA; LightmapGI,
  glow, fog, decals, DOF and 8 lights per mesh are supported).
- UL Benchmarks, 3DMark Wild Life Extreme medians: [iPhone 16 Pro Max](https://benchmarks.ul.com/zh-hans/hardware/phone/Apple%2BiPhone%2B16%2BPro%2BMax%2Breview),
  [iPhone 16 Pro](https://benchmarks.ul.com/hardware/phone/Apple%2BiPhone%2B16%2BPro%2Breview),
  [iPhone 11 Pro Max (A13)](https://benchmarks.ul.com/hardware/phone/Apple+iPhone+11+Pro+Max+review).
- Geekbench 6 single-core: [EveryMac, iPhone Pro Max benchmarks](https://everymac.com/apple-benchmarks/all-iphone-pro-max-benchmarks.html),
  [Macworld, first A18 Pro results](https://www.macworld.com/article/2455063/the-first-a18-pro-benchmarks-are-out-and-it-is-fast.html).
- Apple, [Monitoring your Metal app's graphics performance](https://developer.apple.com/documentation/xcode/monitoring-your-metal-apps-graphics-performance)
  (the Metal Performance HUD and its GPU time); Apple Developer Forums, [enabling the HUD on
  iPhone](https://developer.apple.com/forums/thread/760649) (`MTL_HUD_ENABLED` through
  `devicectl`; the HUD works for apps installed from Xcode or TestFlight).
- This project: README.md (loop 2b, Performance budgets, Quality), docs/BACKLOG.md (loop 2b
  notes), loop 2b's `--bench` log from the phone, `game/scripts/main.gd` (`STYLES`, `QUALITY`,
  `_apply_style`), `game/export_presets.cfg`, and the Mac runs listed in §1.3.
