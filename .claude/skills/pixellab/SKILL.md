---
name: pixellab
description: Make 2D pixel art for Nocna Warszawa with the PixelLab MCP server (tools named mcp__pixellab__*). Use when a task needs character portraits for dialogue (drivers, rivals, police, customers, radio hosts), HUD and UI icons, minimap icons, billboard, poster and parody shop-sign art, neon sign textures, a pixel font, the app icon or store art, or seamless pixel textures. Not for the 3D city, cars or landmarks, which are built in code.
---

# PixelLab for Nocna Warszawa

PixelLab (<https://www.pixellab.ai>) generates pixel art through an MCP server. The game is a 3D
low-poly city drawn into a low-resolution pixel image, so PixelLab is for the **2D layer**:
faces, icons, signs, posters, UI and store art. Its tools appear as `mcp__pixellab__*` only in
sessions started after the server was added (`claude mcp list` shows `pixellab` connected).
If the tools are missing, say so and stop; never call the HTTP API by hand with a key.

The key lives only in the user's Claude Code config. **Never write it into any file, log,
script or commit** (this repo is public). If you see a key in a file, stop and tell the user.

## What to use it for, and which tool

| Need | Tool | Size | Cost (generations) |
| --- | --- | --- | --- |
| Speaker portrait for a dialogue bubble or the radio | `create_portrait_character` | 64 px (HUD shows it at 2–3×) | 10 at 16–64 px, 15 at 128–160 |
| HUD / minimap icon, pickup, small sign | `create_image_pixen` (`no_background: true`) | 16–48 px, multiples of 4 | 1 |
| Billboard, column poster, shop sign, neon panel (flat art on a 3D quad) | `create_image_pixen` to explore, `create_image_pro` for the final | 128–256 px wide | 1, then 10–25 |
| Button, panel or frame art | `create_ui_asset` | 192–688 px | 10–25 |
| Seamless texture (facade windows, pavement, roof) | `create_tiles_pro` | 32–64 px tiles | ~1–2 min per set |
| A font with Polish letters (ą ć ę ł ń ó ś ź ż) | `create_font` | 8–64 px glyphs | check `search_knowledge` first |
| Small loop (a blinking sign, pigeons flapping on a poster) | `animate_image` | ≤ 64×64, 8 frames | 1 |
| Clean up or recolour an existing sprite | `reduce_colors`, `correct_pixelart`, `pixelart_workbench` | any | 0.1 / free |

Image tools are async: they return a `job_id`; wait with `wait_for_jobs`, then fetch with
`get_image`. Prefer passing images as URLs (`get_upload_url`) rather than large base64, which
MCP clients truncate.

## Budget and approval

- Run `get_balance` before a batch and report it in your summary.
- Explore with the 1-generation tools (`create_image_pixen`, `edit_image_pixen`) and keep at
  most 2–3 candidates per asset; use the pro tools (10–25 each) only for a chosen final.
- A loop may spend up to **50 generations** without asking. Above that, list the assets, the
  tools and the estimated generations, and wait for the user's yes.

## Style rules (so it looks like one game)

- **Palette.** Start every asset from the game's own colours and pass them as `palette` (hex):
  the HUD ink `#fbf7ee`, sub-text `#c9c2d8`, accent yellow `#ffd23f`
  (`game/scripts/settings_panel.gd`), the night neons pink `#ff1a8c`, cyan `#1ae6ff`, violet
  `#9e40ff` (`neon_signs.gd`), car trims `#3a3b3f`, `#34404e`, tail red `#b3241f`
  (`models.gd`), and the day sky `#a8cde6` (`project.godot` boot colour). Keep `max_colors`
  low (8–16 for icons, ≤ 32 for posters).
- **Look.** Bright, friendly, slightly chunky: `outline` single-colour dark, `shading` basic,
  `detail` medium. No photo-real rendering, no gradients that fight the pixel grid.
- **View.** Things seen in the city (signs on walls, objects) use `view: "high top-down"` to
  match the isometric camera; portraits and UI are front-on.
- **Text.** Don't let the model draw words: generate the art without text and put the Polish
  text on in the game with `pixel_font.gd` (posters, signs) or the HUD font. That keeps the
  Polish letters right and the text translatable.

## Content rules (this game's tone)

- Real places are fine. **Brands are parodies only**: no real names, logos, mascots or
  trade dress. The frog-green 24h corner shop, the app-taxi, the square-backpack delivery
  riders get invented names and invented marks. Describe them in the prompt by function and
  colour ("a cheerful green corner-shop sign with a cartoon frog"), never by a real brand.
- Affectionate Warsaw humour; never real private people, never a real person's likeness
  (portraits are invented characters: describe age, style, mood, props).
- Family-friendly: police are funny and human, never violent.

## Where files go

- Save the chosen PNG under `game/art/<kind>/<name>.png` (`kind`: portraits, icons, signs,
  posters, ui, textures, fonts), and next to it `<name>.json` with the tool, the full prompt,
  the palette, the size, the seed if any, and the date: provenance for the open-source repo.
- Import settings: filter **Nearest**, mipmaps off, compression Lossless (or VRAM compressed
  for large textures). Scale only by whole numbers on screen.
- Credit nothing extra: PixelLab's terms give the user ownership of what they generate, with
  commercial use allowed, so these assets are the game's own art under the MIT licence
  (`LICENSE`, `CREDITS.md`). The terms forbid training other models on the outputs.
- Draw-call budget: each new sign or poster in the city is a material. Pack small art into an
  atlas and draw repeated signs with MultiMesh (see the performance budgets in README.md).

## Check before you call it done

- Look at the asset in the game at phone size (a screenshot at 2868×1320 and at 2532×1170),
  by day and at night, next to the existing HUD and signs.
- Confirm no text, logo or face in it resembles a real brand or person.
- Report: what you made, where it is, the generations spent (and `get_balance` after), and the
  prompts, so the user can reproduce or tweak them.
