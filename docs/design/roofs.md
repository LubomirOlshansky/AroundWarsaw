# Roofs across the map (F, 2026-11-01)

F's ask: "improve the roofs on the map". The camera looks down at 30-45 degrees and the
helicopter flies over them, so roofs are a large share of every frame. This file is the plan
and the lane file; the items are ticked in docs/ROADMAP.md ("v1.0 checklist", visuals) and
docs/BACKLOG.md ("Roofs across the map").

## What there is today

- **Shapes are already real.** The GUGiK LoD2 models (tools/bake_gugik.py) carry each
  building's own roof planes: flat roofs, low tenement pitches, MDM's hipped roofs, mansards.
  Each roof plane takes the aerial photo's colour. In the old LoD2 bake: 103 k flat roof
  triangles (2.05 km²) and 65 k pitched ones (1.12 km²), 3 k of them steep (mansard faces).
- **Flat roofs get plant** at bake time: 1-6 lift rooms, vents and AC boxes on each flat roof
  over 150 m² (`rooftop_boxes`).
- **The Old Town and New Town** got tile colours, dormers, chimneys and the market square's
  stepped gables (old_town_roofs.gd).
- **What is missing:** every roof plane is drawn the same way, its photo colour with a little
  gravel noise (building.gdshader). A tiled roof, a zinc sheet roof, a tar-paper slab roof and
  an office's white membrane all read as the same flat colour; flat roofs end in a knife edge
  (no parapet), and the tenements outside the Old Town have no chimneys.

## Warsaw's roofs by district (what we aim for)

- **Old Town, New Town**: steep red ceramic tiles (karpiówka), dormers, chimneys (done).
- **Śródmieście's pre-war tenements** (Hoża, Wilcza, Mokotowska, Poznańska, Nowogrodzka):
  low pitched roofs of sheet metal (painted red-brown or grey, standing seams down the slope)
  or tar paper, rows of brick chimney stacks along the party walls, some mansard attic
  floors with windows in the steep face.
- **MDM** (Marszałkowska, Plac Konstytucji): steep hipped sheet-metal roofs over the
  socialist-realist blocks, dormers.
- **The Royal Route's palaces**: hipped roofs, copper (green) or red sheet metal.
- **Muranów, Za Żelazną Bramą, the 1960s-80s slabs**: flat tar-paper roofs (overlapping
  bitumen strips), a low parapet, lift machine rooms.
- **Offices and new flats** (Wola's towers, Rondo ONZ, Powiśle): flat light-grey membranes
  with welded seams, gravel, a metal coping, plant; some green (sedum) roofs.

## The plan

All of it at load time or in the shader, so both city paths (runtime and prebuilt sectors)
get it, and **no new draw call**: extra geometry joins the walls' own tile meshes, as the Old
Town's dormers do. The roof grid (helicopter landings, roof cassettes, roof rescues) is built
from the LoD2 planes only and does not change.

- **RF1 roof materials (shader).** building.gdshader's roof branch picks a material from the
  plane's slope, the building's type (R4: tenement, slab, office) and the photo colour:
  - pitched and red or orange: ceramic tile courses across the slope, staggered joints;
  - pitched otherwise: sheet metal with standing seams down the slope;
  - steep faces (mansards) of tenements and untyped houses: dark zinc or slate with a row of
    attic windows (lit some nights);
  - flat on a slab: tar paper in overlapping strips;
  - flat on an office: a light membrane with welded seams and gravel;
  - flat and green in the photo: sedum and grass clumps.
  Detail fades with distance (fwidth) so it never shimmers on the phone.
- **RF2 parapets and copings (geometry).** Each flat LoD2 roof of 60 m² or more gets a 0.7 m
  parapet on its outer edges (2 triangles per edge of 2 m or more, double-sided, the coping's
  light concrete or metal), not on the plant boxes. Budget: about 2 triangles per 10 m of
  roof edge.
- **RF3 chimneys on tenements (geometry).** Tenement roofs (type 1) outside the Old Town take
  chimney stacks (mostly plastered, some brick), 10 triangles each, seeded by place: rows
  along the party walls on flat roofs, one on some big pitches. Dormers on mansard faces were
  tried (OldTownRoofs.dress) and dropped: on the Royal Route's palaces they read as black
  holes from the helicopter.
- **RF4 later**: OpenStreetMap-only buildings (no LoD2) get hipped or gabled roofs from their
  footprint when small and low; MDM's and the Royal Route's copper by district; roof
  terraces with decking in Powiśle. A Mac look at the phone size for all of it.

**Checks**: check_cassettes (roof cassettes and their landing spots), check_streaming
(sector identity: the dress is seeded by position only), the bench before and after
(draw calls must not move; triangles reported), before/after shots by day and night.
