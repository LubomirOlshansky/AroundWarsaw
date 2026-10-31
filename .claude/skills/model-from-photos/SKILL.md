---
name: model-from-photos
description: How Around Warsaw builds a landmark or building model that reads as the real one - reference photos first (Wikimedia Commons, free licences, kept in refs/), a spec written from the photos at a set detail level, the build, and a side-by-side check of the game shot against the photo with a scored checklist. Use when writing a landmark spec, building or reworking a model (landmarks.gd, models.gd, props.gd, map_builder facades), and when accepting one.
---

# Models from photos: the detail bar and the photo check

The user, 2026-10-31: "I want more detailed models", compared against real photos, the way a
good isometric city game builds each landmark as a small program from photos and maps, tested
for defects, with a person making the final pick. Until then specs came from the OSM outline,
GUGiK LoD2 heights and what the model remembered; nobody put a photo beside the shot.

## 1. Reference photos (before any spec)

- **Where**: `refs/<slug>/` at the repo root, gitignored (other people's photos under CC BY-SA
  don't go into the MIT repo). `refs/<slug>/SOURCES.md` lists each file: Commons page URL,
  author, licence, and one line on what it shows (angle, which face). `refs/INDEX.md` lists
  the buildings. The slug is the site key in `landmarks.gd` when there is one.
- **What**: 3-4 photos a building: one street-level front, one elevated or aerial view that
  shows the whole silhouette and roof (the game is seen from above), one detail (base,
  entrance, crown). Daylight; a night photo only for what lights up.
- **From**: Wikimedia Commons only (CC0, CC BY, CC BY-SA, public domain), the API
  (`commons.wikimedia.org/w/api.php`, `generator=search`, `gsrnamespace=6`,
  `prop=imageinfo`, `iiprop=url|extmetadata`, `iiurlwidth=1600`), the 1600 px thumb, a
  descriptive User-Agent. Free downloads are pre-approved (CLAUDE.md "Hard rules").
- **Who**: the Mac (or a Remote Control session on it). Cloud containers get 403 from
  Wikimedia: a cloud thread asks for the photos, or uses the photos the user drops in chat.
  Photos are never published, never traced into textures, and never shipped in the game.
- Open every photo before using it; drop the wrong building, crops and interiors.

## 2. The spec (Opus, from the photos)

The spec is self-contained text: the Sonnet builder may have no photos, so everything the
photos say goes into the spec as values. Sections, every value filled:

1. **Identity**: the 3-5 features that make a passer-by say its name (Palace: the stepped
   tiers, the spire, the corner pinnacles, the attic parapets). These are judged first.
2. **Massing**: footprint from the OSM outline (`centrum.json`), heights from LoD2 and from the
   photos (storeys × ~3.2 m, or proportions measured against the footprint), each volume's
   setbacks.
3. **Facade, base to top**: the base (arcade, plinth, shop glass, entrance, steps), the middle
   (window grid: bays per face, storey bands, recess depth, piers or fins), the top (cornice,
   attic, parapet). Window rhythm in bays and storeys, not "some windows".
4. **Roof**: shape, crown, skylights, plant, spire, flagpole.
5. **Colour and material**: sampled from the daylight photos, then mapped to the art bible's
   palette (the game's colours stay calmer than the photo); which material code each part uses.
6. **Ground and night**: what stands at its foot (steps, a forecourt, a canopy, the sign under
   a parody name), what lights up at night.
7. **Detail level and budget** (below), and the shots to take.
8. **Parts table**: one row per part (id, shape, size, position, material code, which identity
   feature it serves). The builder names its functions after the part ids, and a failed check
   or a reviewer's fix points at a row, not at prose.

## 3. Detail levels

| Level | What it has | For |
| --- | --- | --- |
| L1 silhouette | the right massing, heights and colour | background buildings |
| L2 articulation | L1 + the facade's base/middle/top, real window rhythm, cornices, roof shape | every named landmark |
| L3 signature | L2 + every identity feature modelled in 3D (columns, pinnacles, fins, arcades, crowns, sculpture as blocks) and its ground | hero landmarks: the first scene (docs/design/first-scene.md), the Palace, the Old Town square, the Castle, the stadium, the bridges, the towers on the skyline |

**Detail costs triangles, not draw calls.** The phone's frame grows with draw calls
(DEVELOPMENT.md "Performance budgets"), so detail goes into the one shared building material
through the landmark material codes (no draw call of its own), merged into the site's mesh.
Budgets in triangles: L2 up to ~3,000, L3 up to ~8,000 a site (the Palace and the stadium may go
higher, named in the spec); the site's triangle budget goes into `check_sites.gd` (which holds the budgets today) in the same change.
No new material, light or MultiMesh without a measured before/after draw-call count. Window
grids belong in `building.gdshader`'s window rhythm, not one mesh per window.

## 4. The checks, in this order (research 2026-10-31)

Cheap checks first, the expensive eye last: retrying on error feedback is what makes code-built
models work; longer agent runs don't improve the shape, and the commonest failures (floating
parts, z-fighting) are ones a judge looking at shots misses.

1. **Automatic** (the builder, before any review): `tools/verify.sh --quick`, the site's
   triangle budget, and the mesh check when it exists (BACKLOG: `check_mesh_quality.gd`:
   coplanar overlapping faces, zero-area and flipped triangles, parts touching neither the
   ground nor another part). A FAIL goes back to the builder, not to the reviewer.
2. **The builder's own look** at the matched shots against the photos.
3. **The reviewer** (`art-director`, Opus), section 5 below.
4. **At most two fix rounds** between builder and reviewer; still failing after two, the spec
   is wrong or open: the lane session re-specs or asks the user. No third guess.

**Detail without draw calls.** The Mobile renderer has no automatic instancing: N copies of
a column as separate nodes cost N draw calls. Cornices, pilasters, columns, battlements and
lamps on a landmark are triangles merged into the site's mesh with the shared material; only a
kind repeated across the whole map gets one MultiMesh. No new node, material or decal per detail.

## 5. The photo check (after the build)

- **Matched shots**: for each reference photo that shows the silhouette, a game shot from the
  nearest angle (`--at=x,z` and the camera, helicopter for aerial views), at 2532x1170, day.
  Plus the usual before/after at the default view.
- **Shots for the judge**: besides the lit matched shots, one unlit (flat colour) shot and one
  silhouette on a plain background per main angle, with the landmark alone when the flag
  exists: shape errors hide in lighting and street clutter.
- **Side by side, photo first**: the reviewer opens the photos and shots and scores them
  *before* reading the spec (a judge favours what it wrote or read; the spec comes after, to
  name what is missing). Scores 1-5 on silhouette, proportions, colour, identity features
  (each one named: there or missing), facade rhythm, ground. Every score cites what in the
  shot earns it ("the spire's base is 1.4x too wide against photo 2"). Pass: every score ≥ 4
  for L3, ≥ 3 for L2. A missing identity feature is a fail whatever the scores. A one-point
  difference is within a judge's noise: a borderline score is looked at again, not argued.
- **Anchors** (what the numbers mean, the same for every landmark):

  | Score | Silhouette and proportions | Colour | Identity features | Facade rhythm | Ground |
  | --- | --- | --- | --- | --- | --- |
  | 5 | reads as the photo's outline from its angle; every volume's ratio within ~10 % | the photo's hues, calmed to the palette, right light/dark split | all there and placed right | bays and storeys counted right, base/middle/top clear | what stands at its foot is there |
  | 3 | recognisable, one volume or ratio clearly off | right family, one part wrong | all there, one misplaced or crude | rhythm close, one band or level missing | partly |
  | 1 | could be another building | wrong colour family | one or more missing | generic grid | nothing |

- **Choosing between two builds**: compare them pairwise, twice with the order swapped; if the
  two answers disagree, call it a tie.
- **Defects** (automatic where a check exists, by eye always): z-fighting and flicker on
  coplanar faces, a part inside another, floating or sunken parts, gaps at joins, faces that
  vanish at a zoom.
- **The user picks last**: the report to the user shows photo, before and after for each hero
  landmark; the user's "no" sends it back.

## 6. Who does what

| Step | Who | Model |
| --- | --- | --- |
| Fetch and sort the photos | the Mac session or `qa-tester` on the Mac | Sonnet |
| Write the spec from the photos | the lane session | Opus |
| Build, render before/after and the matched shots | `object-modeler` | Sonnet |
| Score against the photos, accept or return a fix list | `art-director` | Opus |
| Final pick | the user | |
