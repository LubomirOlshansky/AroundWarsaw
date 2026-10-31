# Around Warsaw art bible (short and living)

Written from what the game already decided (docs/DEVELOPMENT.md, docs/ROADMAP.md, the shaders and the
HUD code). It changes only when the user agrees: propose changes in a report, with shots.

**The one rule:** *a toy-sized, real Warsaw you can read at a glance on a phone, by day bright
and friendly, by night a neon cassette.* When two choices conflict, pick the one that reads
better at the default view on a 1170-line phone.

## Pillars, each with a test

1. **It is Warsaw.** Real streets, real footprints, landmarks built from their real shapes.
   *Test:* someone from Warsaw names the place in the shot.
2. **Readable first.** The player's car, the road ahead, the goal and anything tappable stand
   out from the city. *Test:* at the default 80 m view (the car ~58 px long on 1170 lines),
   squint: the car, the target and the route still show.
3. **One pixel world.** Everything goes through the same pixel image and outlines.
   *Test:* nothing looks sharper, blurrier, smoother or more photographic than its neighbours.
4. **Night is the show.** Night is dark and calm, lit by its lamps, windows and neon.
   *Test:* at night the brightest things are lights, never the ground or the water.

## The image

- The 3D city renders into a low-resolution pixel image, scaled up by **whole pixels** only.
  Styles: Sharp (480 lines, default), Fine (360), Clean (240), Chunky (170, fewer colours).
- Depth outlines from the post pass; posterized colour. Don't add a second outline style.
- Geometry is low-poly and built in code (box-built vehicles and people, procedural
  landmarks from real footprints and part heights). No photo textures; textures are small,
  pixel-scale, nearest-filtered.
- Walls between the camera and the car become the thin dithered **occlusion ghost**; the
  street seen through it keeps its own brightness.
- Inside the ghost nothing glows: ghosted windows and signs go dark, and the inner faces of
  a cut building are unlit, a step darker than the street. In the ghost's core the car is
  the brightest thing.
- Every building face wider than a few metres has its window grid; no blank slabs.
- **Pixel size on phones (the user, 2026-10-28):** keep today's smoother look (Sharp scales
  by 2 whole pixels on both iPhones: 585 / 660 lines). A stronger retro / pixel vibe is a
  later loop of its own, not part of any other loop.

## Light and colour

| Look | Character | Notes |
| --- | --- | --- |
| Day (the default) | bright, stylised, friendly; soft cloud shadows; sky `#a8cde6` | the original look; changes to it need before/after shots |
| Dusk | the dusk loop (2026-10-31, the user's 16:20 photos): overcast blue hour, slate-blue sky, flat cool light with no sun shadows, most windows and every lamp on, the Palace floodlit gold, lit names on the towers | cool blue shadows, warm lights |
| Night | deep navy-violet ambient, cold moon, stars, light bloom | water dark and calm; lamps' reflections carry it |
| Rain | overcast, wet asphalt and paving with a sky sheen, mirrored lights | streaks are screen-space |

- Neon: pink `#ff1a8c`, cyan `#1ae6ff`, violet `#9e40ff`; word colours for pharmacy green,
  exchange amber, hotel red. Street lamps: warm sodium, cold white LED in parks.
- The river is a slow lowland river: low contrast, few small glints, never an open sea.
- **Value ladder at night**, brightest first: lamp heads and neon > lit windows > lit ground
  > the player's car > roads > roofs and walls > water. A lamp pool's brightest pixel stays
  under ~80 % of a lit window's luma on every surface, pale paving included. Test: no 24-px
  area of ground is brighter than the lit windows in the same shot.
- **Lamp pools are pixel light**: 3–4 hard bands with a 1-px dither between them, never a
  smooth radial gradient. Sodium on grass reads warm olive, never chartreuse.
- **Day chroma** (the user agreed, 2026-10-28): the ground (grass, paving, bike lanes, water,
  sand) is quieter than what you drive or tap; the player's car, job beacons and police are
  the most saturated things in their neighbourhood. Bike lanes are Warsaw brick red, not
  coral. The overcast rain-day look is the guide.
- **The river by day** is low in chroma (grey-green-blue), never brighter than its banks,
  with few 1–2 px glints. Sandbars have smooth outlines, no slivers, and a darker wet rim.
- **Banks**: granite or concrete only where the bank is built (the Bulwary, embankments);
  natural banks get a wet-sand band and a 1-px foam line, no wall.
- **Trees** (the user agreed): crowns about 3/4 of the scanned size within ~12 m of a road
  (real size in parks), lumpy 2–3-blob crowns with a two-tone pixel dapple, autumn colours
  towards rust and olive (pure orange is the jobs' colour).

## Reserved colours

| Who | Colour | Nobody else uses |
| --- | --- | --- |
| The player's car (the user chose: keep it red) | red-orange body, white roof stripes | saturated red or orange on traffic |
| Jobs | orange beacon, teal | saturated orange on trees, signs, ground |
| Police | blue and red light bars | |
| Collectibles | gold | |
| The marker over the car | HUD yellow `#ffd23f` | |

- **The player's car at night** is never darker than the road under it (luma at least +30
  over the road's), with tail-light pixels and a headlight cone.

## Text and HUD

- In the world: Polish only, uppercase, in the game's 5×7 pixel font with Polish letters
  (`pixel_font.gd`); jokes follow the warsaw-tone skill. Never let a generator draw words.
- HUD: dark translucent cards (near-black violet, ~94 % opaque), ink `#fbf7ee`, sub-text
  `#c9c2d8`, accent yellow `#ffd23f`, the device's system font; Polish above English.
- Phone sizes: touch targets at least 44 pt, text at least ~11 pt, sized in points (the
  settings panel does this; the rest of the HUD is still in 720-line units, a known gap).
- Labels, bubbles and cards keep clear of each other and of the controls.
- **One card recipe** for every HUD surface (top bar, job card, toasts, bubbles, buttons):
  ≥ 90 % opaque near-black violet, ink `#fbf7ee`, sub-text `#c9c2d8`, yellow accent; pink
  only as the radio's edge. No surface takes its colour from the world behind it. Buttons
  sit on a plate (BRAKE and GAS in one family). The minimap follows the time of day.
- Polish above English everywhere, the title's call to action included. Developer toggles
  live in Settings, not on the driving screen.

## 2D art (portraits, icons, signs, posters, UI)

Made with the PixelLab MCP server following `.claude/skills/pixellab/SKILL.md`: the game's
palette passed in, few colours, a single dark outline, no text in the image, saved with its
provenance under `game/art/`. Whole-number scaling on screen, nearest filtering.

## Never

- Real brand names, logos, mascots or trade dress (parodies only), a real person's likeness.
- Photographic textures, smooth gradients fighting the pixel grid, sub-pixel scaling, mixed
  outline styles, a new UI font without the user's yes.
- Removing a landmark, the ghost, the river or the night lights to save frame time.
- A look change judged without shots at phone size on both city paths.
