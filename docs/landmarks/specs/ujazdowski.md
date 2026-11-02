# Zamek Ujazdowski: spec

Site key `ujazdowski` in `game/scripts/landmarks.gd` (`_build_ujazdowski`, `_portal`, `_dormers`). Written 2026-11-01 in a cloud thread (F: "improve Ujazdów and the castle on it") from the OpenStreetMap outline in `centrum.json`; no photo and no LoD2 here. Values marked *(photo check)* wait for the Mac's `refs/`. Before this the castle was only the mapped boxes in one skin.

## 1. Identity

Ujazdowski Castle (Al. Ujazdowskie 6): a Baroque residence built for Sigismund III in 1619-24, razed in 1944, rebuilt from 1975, now the Centre for Contemporary Art. A square of four steep-roofed wings round a courtyard with a round tower at each outer corner.

## 2. Massing

Frame: origin (460.5, 1601.7), u along the north wall (2.25 degrees off east), v south. Wings (OSM outline): west u -27.4 to -17.4, east 13.6 to 23.6, north and south 9.5 m deep between them; all to the 9 m eave (OSM 8.8). The east wing has a bay 5.7 m deep and 24.6 m wide (v -12 to 12.5), as the outline does. The courtyard stays open (the map's lawns and path show). Four round towers (radius 3.35, octagon) at the outer corners, to 16 m.

## 3. Facade, base to top

Cream plaster in the M_MONUMENT window shader; a 1.1 m stone plinth; a trim cornice under every eave. West portal on the wing's middle: three stone steps, a bay 1.2 m out, a warm lit door between two trim posts and a lintel, two lamps, and a pediment over the eave *(photo check: where the real entrance is)*.

## 4. Roof

Copper-green hipped roofs, 6.2 m of rise over the 9 m eave (OSM ridge 15 m); the east bay's roof is lower (3.4 m rise). Hipped dormers every 6 m on the outer faces (not under the portal's pediment). Six stone chimneys on the ridges. Tower caps: a flared bell, a tapering shoulder, a lantern in trim, a copper spire to 26.5 m *(photo check: the real cap shape and height)*.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Wall | #ece4d0 | M_MONUMENT |
| Plinth, chimneys | #bdb4a0 | M_STONE |
| Trim | #f5efe0 | M_STONE |
| Copper roofs | #8fae9b (spires 12 % darker) | M_STONE |
| Portal door | #f3d9a8 | M_PAVILION |

No new material, shader or draw call (the OSM roof colour is the pale copper #b9d0bf).

## 6. Ground and night

Own car walls: the whole outline (47 edges). The door glows and two lamps burn at night; the monument shader lights the windows. Card: "Zamek Ujazdowski". Open *(photo check)*: the facade's real colour, the courtyard (open or roofed: OSM maps an 8.8 m roof patch in it), the entrance side.

## 7. Detail level and budget

L2; 1379 triangles measured, budget 1650 (`check_mesh_quality.gd`, `check_sites.gd`).

Shot: `--at=455,1602 --yaw=270 --pitch=-30 --time=dusk --size=60 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wings | four boxes | 9.5-10 m deep, 9 m high | ring round the courtyard | M_MONUMENT | 2 massing |
| plinth, cornice | boxes | 1.1 m and 0.8 m high | foot and eave of each wing | M_STONE | 3 facade |
| roofs | hips | 6.2 m rise | over each wing | M_STONE copper | 4 roof |
| east bay | box and hip | 5.7 x 24.6 m | east wing, middle | M_MONUMENT | 2 massing |
| towers | octagon prisms, frustums, pyramid | r 3.35, 26.5 m high | four outer corners | M_MONUMENT, copper | 4 roof |
| portal | steps, box, gable | 8 m wide, 1.2 m out | west wing, middle | M_STONE, M_PAVILION | 3 facade |
| dormers | box and hip | 1.1 m wide, every 6 m | outer roof faces | M_STONE, M_GLASS | 4 roof |
| chimneys | boxes | 0.9 m square | ridges | M_STONE | 4 roof |
