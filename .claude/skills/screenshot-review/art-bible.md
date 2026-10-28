# Nocna Warszawa art bible (short and living)

Written from what the game already decided (README.md, docs/ROADMAP.md, the shaders and the
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

## Light and colour

| Look | Character | Notes |
| --- | --- | --- |
| Day (the default) | bright, stylised, friendly; soft cloud shadows; sky `#a8cde6` | the original look; changes to it need before/after shots |
| Dusk | low orange sun from the south-west, violet fill, pink-purple sky, first lamps | magenta/cyan split-tone |
| Night | deep navy-violet ambient, cold moon, stars, light bloom | water dark and calm; lamps' reflections carry it |
| Rain | overcast, wet asphalt and paving with a sky sheen, mirrored lights | streaks are screen-space |

- Neon: pink `#ff1a8c`, cyan `#1ae6ff`, violet `#9e40ff`; word colours for pharmacy green,
  exchange amber, hotel red. Street lamps: warm sodium, cold white LED in parks.
- The river is a slow lowland river: low contrast, few small glints, never an open sea.

## Text and HUD

- In the world: Polish only, uppercase, in the game's 5×7 pixel font with Polish letters
  (`pixel_font.gd`); jokes follow the warsaw-tone skill. Never let a generator draw words.
- HUD: dark translucent cards (near-black violet, ~94 % opaque), ink `#fbf7ee`, sub-text
  `#c9c2d8`, accent yellow `#ffd23f`, the device's system font; Polish above English.
- Phone sizes: touch targets at least 44 pt, text at least ~11 pt, sized in points (the
  settings panel does this; the rest of the HUD is still in 720-line units, a known gap).
- Labels, bubbles and cards keep clear of each other and of the controls.

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
