# The railway: stations, the cross-city line and trains

F asked (2026-11-01): model the stations Warszawa Ochota and Warszawa Powiśle as proper
landmarks, then the other city stations the same way, and design the railway itself with trains
running through the city. This is the plan; each item is one PR, ticked in docs/ROADMAP.md
"v1.0 checklist", docs/LANDMARKS.md (P2 row 2.11) and docs/BACKLOG.md.

## 1. What the game has today

- `rails` in `centrum.json`: 233 OpenStreetMap rail ways in the open air (tunnels are left out by
  `bake_osm.py`), drawn by `map_builder.gd` as a 3.4 m ballast strip with two dark lines
  (`_build_rail_beds`, `_build_rails`). No sleepers, no catenary, no portals, no trains.
- `platforms`: 0.9 m concrete slabs. Rail bridge decks (`dk` 28-35, Most Średnicowy and its
  viaducts) are built by the structures bake.
- Stations: only Warszawa Centralna is a model (site `centralna`, spec `centralna.md`). Ochota,
  Powiśle and Stadion are plain LoD2 or OSM boxes; Wschodnia and Gdańska are at the box's edge.

Where the line runs in the box (game metres, x east, z south):

| Piece | Where | What the data has |
| --- | --- | --- |
| Ochota cutting | x -2930 .. -1924, z 790 .. 1230 | 12 tracks in the cutting by Plac Zawiszy; station building (-2313, 929), 7 platforms |
| Tunnel | x -1924 .. 171 | not in the data (underground): Centralna, Śródmieście and Śródmieście WKD below ground |
| Powiśle | x 171 .. 400, z 90 .. -50 | the west portal under the upper pavilion (171, 89); two side platforms on the embankment; the round lower pavilion (401, -6) |
| Most Średnicowy | from (400, -45) east | decks `dk` 28-35 over Wybrzeże Kościuszkowskie, the Vistula and Wybrzeże Szczecińskie |
| Stadion | (1388, -1337) | the 1955 pavilion box (4.3 m), platforms north and south of it |
| Wschodnia | (1930, -2010) at the east edge | two station outlines |
| The ring line north | z about -2700 | Gdańska's outline at the north edge |

## 2. The stations (landmark models, the model-from-photos approach)

Every station is a site in `landmarks.gd` with a card (PL + EN), a spec in
`docs/landmarks/specs/<slug>.md`, a triangle budget in `check_mesh_quality.gd` and a Mac photo
check afterwards (the cloud has no photos; facts below come from published descriptions).

### S1. Warszawa Ochota (site `ochota`), the first

Arseniusz Romanowicz and Piotr Szymaniak, 1962-63; on the monuments register. A glazed square
ticket hall, 17.25 m a side, standing on a bridge over the cutting so it overhangs the tracks.
Over it a thin reinforced-concrete hyperbolic paraboloid: two opposite corners rise to 8.34 m,
the other two sit low on hinged supports; the shell's underside is a black-and-white striped
mosaic. A black-and-white mosaic band runs along the glass near the floor. Stairs fold down to
the island platform in the cutting; a small kiosk stands by the entrance.

Model (L3): the hall's glass box on its deck over the tracks, the deck's edge beam and the
mosaic band, the saddle roof as a ruled surface (rulings drawn as a grid of quads), white on top,
striped underneath (vertex colours), two low supports and a sliding high bearing, the stairs down
to the platform, the kiosk, a small sign WARSZAWA OCHOTA. Lit warm at night (M_PAVILION).
Collision: the hall only (the car passes under the roof's high corners where it can reach them).

### S2. Warszawa Powiśle (site `powisle`)

Same architects, 1954-63. Two pavilions and the platforms between them:
- the upper pavilion on the Aleje level at the edge of the escarpment, over the tunnel's east
  portal, by the Poniatowski Bridge's little tower: the ticket hall whose roof is a surface
  stretched between two arches ("a kite floating in the air");
- the lower, round pavilion at the platforms' east end by Kruczkowskiego: a glass drum under an
  inverted dome, a shallow saucer (Ø about 21 m from the OSM outline) with its rim up, today the
  café-club "Warszawa Powiśle" with its neon letters on top;
- the platforms on the embankment between them under rows of steel X-shaped canopy supports.

Model (L3): both pavilions from their OSM outlines, the kite roof between two parabolic arches,
the saucer with its rim and the neon WARSZAWA POWIŚLE, the platform canopies, the stairs.

### S3. The others, by how often the player sees them

| # | Station | Plan |
| --- | --- | --- |
| S3a | Warszawa Stadion | the 1955-58 pavilion (Romanowicz and Szymaniak too), renovated for Euro 2012; side platforms with canopies; the stadium's crowd route |
| S3b | Śródmieście and Śródmieście WKD | underground: the entrances in Aleje Jerozolimskie's passages (stair heads with signs), the vents |
| S3c | Warszawa Wschodnia | at the east edge: the hall's front only (low priority, mostly off the map); the yard runs on past the edge since 2026-11-01 (`map_edge.gd`) |
| S3d | Warszawa Gdańska | at the north edge: the platforms' canopies and the footbridge (low priority); the land and tracks run on past the edge since 2026-11-01 (`map_edge.gd`) |
| S3e | Ochota WKD | the WKD stop next to Ochota in the cutting: platform shelters |

## 3. The line itself

### L1. Track that reads as railway (map_builder, both city paths)

Sleepers (concrete, every 0.65 m, as one strip texture in the ballast's vertex colours, not
separate meshes), raised steel rails with a light top, ballast shoulders, and the cutting's
retaining walls where the data has them (`lines` kind `wall`). Same meshes and materials as now:
no new draw calls. Before/after bench.

### L2. Catenary

Masts every 50-60 m along each double track (a steel H-mast, the cantilever arm, the insulator),
portal frames over the wide fans at Ochota and Powiśle, the contact wire and the messenger as
thin dark quads. Masts as one MultiMesh (one draw call), wires in one mesh. Catenary does not
collide with the car; it blocks the helicopter like a cable (lands no one on it).

### L3. Portals and the tunnel's ends

The tunnel's west mouth east of Ochota (x -1924) and the east mouth under the Powiśle pavilion
(x 171): a concrete headwall over a dark mouth 4 m deep, wing walls. The road tunnels' portal
frames (`tunnels.portals`) are another lane's; this stays a rail-only builder and does not touch
the bake (the "rail cutting" leftovers of loop 3e stay with the map lane).

### L4. Most Średnicowy

The deck is there; the bridge's look (spans, girders, piers) from photos on the Mac. Photo
check first, then a model like the other bridges. Built 2026-11-01 after the Mac photo check:
`map_builder._build_srednicowy` (granite piers with cutwaters, steel arch-truss spans under the
deck, in the walls surface).

## 4. Trains (T1, `trains.gd`, a new check and verify step)

Built like `trams.gd`: a graph from the `rails` pieces (both ways), trains that run 60-80 km/h
in the open, slow to stop about 20 s at Ochota, Powiśle and Stadion, and vanish into the tunnel
mouths and the map's edges (and come back out of another one a while later, so the city always
has a train somewhere). Three kinds, all our own shapes and liveries:

| Kind | Look | Name on the side (parody) |
| --- | --- | --- |
| Suburban EMU (most) | low-floor 4-car unit, green and white with yellow doors | KOLEJE MAZOWE |
| City line | 3-car unit, red and yellow | SKM → SKiM |
| Long-distance | a locomotive and five grey-blue coaches | INTERSZYBKO |

Each car is an AnimatableBody3D (the car bounces off, like the trams); at most 6 trains on the
map; cars are shared meshes (2 materials). A horn when a train leaves a portal near the player,
the rumble on the bridge (city_sounds). A check `check_trains.gd` (trains move, stop at the
three stations, never two on one track piece, leave and re-enter) joins `verify.sh`.

## 5. Order and size

| # | Item | Lane / model | Definition of done |
| --- | --- | --- | --- |
| R0 | this design, rows in BACKLOG, ROADMAP, LANDMARKS | docs | light |
| S1 | Warszawa Ochota | landmark | light + mesh check + shots |
| S2 | Warszawa Powiśle | landmark | light + mesh check + shots |
| L1 | track look | map | full (bench before/after) |
| L2 | catenary | map | full (bench) |
| L3 | portals | map | light + shots |
| T1 | trains | gameplay | full (bench, check_trains) |
| S3a | Warszawa Stadion | landmark | light + mesh check |
| S3b-e | the rest | landmark | light |
| L4 | Most Średnicowy | landmark, after the Mac photo check | light |

## 6. Open questions (defaults built, parked in docs/QUESTIONS.md)

- The parody names (KOLEJE MAZOWE, SKiM, INTERSZYBKO) and liveries: default as above.
- Can the player drive onto the tracks? Default no: the cutting's walls and the embankment keep
  the car out where they already do; trains push the car like trams elsewhere.
- Photo checks on the Mac for every station (shapes come from texts, not photos).
