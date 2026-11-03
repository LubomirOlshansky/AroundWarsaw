# Arkadka (Westfield Arkadia): spec

Site key `arkadia` in `game/scripts/landmarks.gd` (`_build_arkadia` and its helpers
`_arkadia_entrance`, `_arkadia_tower`, `_arkadia_rotunda`, `_arkadia_office`, `_arkadia_wing`,
`_arkadia_plaza`). The Forest next door has its own spec, `forest.md`.

- First built 2026-11-01 in a cloud thread from the OpenStreetMap outline alone (158 points, about
  300 x 330 m, 10.9 m in OSM, 21 m built) with a guessed glass rotunda on the roof.
- **Rebuilt 2026-11-03 from F's ten photos** (F: "Westfield Arkadia can be better"): four aerials of
  the plaza side (summer, autumn, a drone frame from the south, the old 2004 aerial), the entrance at
  street level, the sign tower behind the letter sign, the night open-air cinema on the lawns, the
  office wing from the tram stop, and the plaza with the playground from the south-east. The photos
  are F's own reference set; they are not stored in the repo. The real names are never shown: the
  parodies are in section 5.

## 1. Identity (what the photos show, in order of what a player sees first)

1. **The round plaza** in front of the south-west entrance: a paved circle, the fountain in its
   middle (OSM `fountain` surface at (-2761, -2443), r 11 m), lawns and paths running down to Rondo
   Radosława.
2. **The sign tower** at the plaza's north-west corner: a pale rendered base with a big screen on its
   plaza face, a shaft of grey corner piers round dark louvres carrying three shop logo panels, and a
   sign box on four posts at the top with the mall's name in red over ARKADKA in white.
3. **The entrance**: a glass wall between four stone piers in three bays, each bay with a low dark
   canopy (planted on top) and a deep pale cornice near the top; the name over the middle bay. The
   OSM outline curves round the plaza (a 29.5 m arc from the tower to the south-east wing), so the
   front is built as that arc; behind it **six glass gables fan out** over the entrance hall (the
   "sawtooth" skylights of the aerials).
4. **The dark glass office wing** on the left (west, along Jana Pawła II), four storeys, pale floor
   slabs, a line of cypresses along its south face (OSM).
5. **The brick and render wing** on the right (the south-east face along the expressway), with **the
   rotunda** on its corner: a glass ground floor under yellow café awnings, a rendered drum, a pale
   cornice ring. Terracotta brick boxes between pale render pilasters along the wing.
6. **The roof**: the main block's deck with the roof car park, three skylight strips with glass
   pyramids, stair cores and floodlights (kept from the first build; the aerials show the deck full of
   plant and the old aerial shows the parked rows).
7. **The big letter sign** by the lawns at the foot of the paths towards the rondo: red letters on a
   long grey plinth with ARKADKA in white.

## 2. Massing (game metres; x east, z south)

| Part | Plan | Height |
| --- | --- | --- |
| Main block | OSM outline `_simplify`d 1.5 m, less the plaza circle (r 29.5 m round the fountain), the office box and the wing strip | 21 m (ARKADIA_TOP), parapet 1.1 m |
| Office wing | outline inside x -2860..-2796, z -2600..-2440 | 18 m, cornice to 18.9 m |
| Brick wing | outline inside a strip 12 m out and 26 m in from the line (-2700, -2404) → (-2545, -2517), 52 m deep at its west end (the low block between the rotunda and the entrance) | 13.6 m, parapet 0.9 m |
| Rotunda | circle r 13 m at (-2705, -2413) | 13.4 m, roof plant drum r 6 m to 15.6 m |
| Sign tower | 12 x 12 m square at (-2779, -2466), square to the office wing | base 14 m, shaft 41 m, posts to 42.6 m, sign box 15.2 m square 42.6..49.4 m |
| Entrance | ring sector r 29.1..31.5 m, from -104° to +4° round the fountain (plan angles, 0° east, -90° north) | 20 m glass, piers 21.6 m |
| Gables | six, radial, r 32.5..63.5 m, 6 m wide | 21 → 25.2 m ridge |
| Letter sign | 10.4 x 2 m plinth on the lawns' flowerbed at (-2797, -2361), facing the rondo's flag | 1.9 m |

## 3. Facade, base to top

- **Main block**: 0..5.6 m shop glass lit from inside (M_PAVILION #a9c6d2); 5.6..20 m pale panels
  #dcdbd5 with a row of punched windows (M_SKIN S_PUNCHED); 20..21 m grey cornice #b9bab6.
- **Entrance**: glass #a3c2cf (M_PAVILION) on the arc; four stone piers #cbb38e 3 m wide, 1.2 m proud,
  at the arc's ends and thirds; per bay a low canopy 4.6 m deep at 5.0..5.6 m (#3a3f44, green top
  #6f9a4a) and an upper cornice 5 m deep at 18.4..19.6 m (#ece9e1). ZACHODNIE POLE (red, scale 0.62)
  at 13 m and ARKADKA (white, 0.42) at 10.6 m over the middle bay, facing the fountain.
- **Office wing**: dark glass #2d3a44 (M_SKIN S_DARK), floor slabs #c9ccce 0.35 m proud at 4.6, 9.0 and
  13.4 m, dark cornice #22292f.
- **Brick wing**: shop glass 0..4.8 m, brick #a9583c 4.8..12.6 m, render cornice #dcc9a6 12.6..13.6 m;
  on its street face's long edges a render pilaster 4.4 m wide every 22 m (0.35 m proud, to 13.9 m)
  and yellow awnings #f2c230 (7.6 m wide, 3 m deep, sloping 0.9 m, 0.4 m valance) on the bays
  15..60 m from the rotunda.
- **Rotunda**: glass 0..4.6 m, render drum #dcc9a6 with punched windows to 12.4 m, cornice ring r 13.7 m
  to 13.4 m, parapet, six yellow awnings (6.4 m) round its outer side (40°..190°).
- **Sign tower**: base #c8c9c6; shaft louvres #30353a (M_SKIN S_FINS) inset 0.7 m inside grey corner
  piers #9a9da0 (1.5 m square); sign box #d7d8d6. On all four faces of the box: ZACHODNIE POLE (red,
  0.72) at 46 m over ARKADKA (white, 0.5) at 43.6 m. On the south (plaza) and east (entrance) faces of
  the shaft: a white panel at 33..37.6 m with KARFUREK (blue), MERLINEK's green triangle (lit) at
  27..31.4 m over MERLINEK (green), KINO SITKO (orange) at 20.4 m. The screen: 9.2 x 10.6 m pink lit
  panel (M_LAMP #d93d8e) on the base's south face with PROMOCJA in white.

## 4. Roof

Main deck #77797a with its parapet; three skylight strips (10 m wide glass with 18 m pyramids 3.8 m
high) across the deck, 70 m apart; four 8 m stair cores; floodlight masts on a 45 m grid (max 40);
up to 1500 parked cars in back-to-back rows (55 % fill, seeded), straight into the mesh and not the
roof grid. Since the rebuild the deck is the main block's biggest piece less the entrance hall's
sector (r 66 m), so no car or mast stands on the office wing, the brick wing or the gables. The lower
wings' roofs are plain grey with a parapet.

## 5. Colour, material and names

| Part | Colour | Material code |
| --- | --- | --- |
| Shop storey, entrance glass | #a9c6d2, #a3c2cf | M_PAVILION |
| Main block panels | #dcdbd5 | M_SKIN S_PUNCHED |
| Stone piers | #cbb38e | M_STONE |
| Office wing | #2d3a44 | M_SKIN S_DARK |
| Brick, render | #a9583c, #dcc9a6 | M_STONE |
| Awnings | #f2c230 | M_STONE |
| Tower louvres, piers, box | #30353a, #9a9da0, #d7d8d6 | M_SKIN S_FINS, M_STONE |
| Screen, MERLINEK triangle | #d93d8e, #3fae49 | M_LAMP |
| Gables | #a7c8d6 | M_GLASS_ROOF |

Names (warsaw-tone: parodies only):

| Real | In game | Why |
| --- | --- | --- |
| Westfield | ZACHODNIE POLE | "west field" said in Polish |
| Arkadia | ARKADKA | the first build's diminutive, kept |
| Carrefour | KARFUREK | the hypermarket, spelt the way it is said, made small |
| Leroy Merlin | MERLINEK (and a plain green triangle) | the DIY store's wizard, made small |
| Cinema City | KINO SITKO | "sitko" is a sieve: the city's cinema as a sieve |
| the screen's advert | PROMOCJA | a generic word |

Neon words are in `neon_signs.gd` LANDMARK_WORDS.

## 6. Ground, collision and night

The car stops at the mapped outline less the plaza circle (`_collide` on the raw ring, cut by the
circle), at the tower's 12 m square, the rotunda's circle and the letter sign's plinth. Arkadia shares
no wall with a neighbour, so no slit can open (PR #385's `_collide_raw` / `pocket_rings` are not
needed here). The shop glass, the entrance glass and the rotunda's ground floor glow at night; the
screen and MERLINEK's triangle are lit panels; all the words are neon. The fountain stays the map's
water disc with nine white jets on it (eight round, one tall in the middle).

## 7. Detail level and budget

L2, triangle budget 24000 (an exception to the L2 limit: a 300 m mall with its roof car park, as
before the rebuild). Cost: one landmark mesh, no new material, no new draw call (the words join the existing landmark
sign meshes). Triangles: the first build measured 16 900 (the parked cars 1500 x 10 of it); the
rebuild adds the entrance (arc sectors, piers, canopies, six gables), the tower, the rotunda, the
wings' parapets, pilasters and awnings and the plinth, about 4 000 more, and the smaller deck holds
fewer cars. Shots: `--at=-2760,-2450 --yaw=0 --pitch=-30 --size=90` (the plaza from the south, as in
photos 4, 5 and 8), `--at=-2770,-2440 --yaw=30 --pitch=-20 --size=50 --lift=18` (tower and entrance),
`--at=-2760,-2440 --yaw=20 --pitch=-22 --time=night --size=70 --lift=18`. The Forest has its own spec since 2026-11-03 (`forest.md`).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| main | outline less plaza, office, wing | 21 m | the block | M_PAVILION, M_SKIN | 6 roof |
| plaza cut | circle | r 29.5 m | fountain (-2761, -2443) | none | 1 plaza |
| entrance | ring sector, 4 piers, 6 canopies | 108°, 20 m | r 29.1..31.5 | M_PAVILION, M_STONE | 3 entrance |
| gables | 6 pitched glass roofs | 31 x 6 m, 4.2 m | radial, r 32.5..63.5 | M_GLASS_ROOF | 3 entrance |
| tower | base, shaft, piers, posts, box | 12 m square, 49.4 m | (-2779, -2466) | M_STONE, M_SKIN | 2 tower |
| logos | panel, triangle, 3 words | 8.8 x 4.6 m | tower S and E faces | M_STONE, M_LAMP, neon | 2 tower |
| screen | lit panel | 9.2 x 10.6 m | tower base, south | M_LAMP | 2 tower |
| office | outline piece, 3 slabs | 18.9 m | x < -2796 | M_SKIN S_DARK | 4 office |
| wing | outline piece, pilasters, awnings | 13.6 m | south-east strip | M_PAVILION, M_STONE | 5 wing |
| rotunda | drum, cornice, plant drum, 6 awnings | r 13 m, 15.6 m | (-2705, -2413) | M_PAVILION, M_SKIN, M_STONE | 5 wing |
| deck | parapet, skylights, cores, masts, cars | up to 1500 cars | main block's biggest piece | M_STONE, M_GLASS_ROOF | 6 roof |
| jets | 9 thin columns | r 0.3 m, 1.8 / 3.2 m | fountain | M_STONE | 1 plaza |
| letter sign | plinth and 2 words | 10.4 x 2 x 1.9 m | (-2797, -2361) | M_STONE, neon | 7 sign |

## 9. Open (photo check on the phone)

- The plaza's paving pattern (the photos show dark radial stripes on pale stone) and the dry
  fountain's jets in the paving: the map draws OSM's fountain as water today (map lane).
- The playground's green rope "worm" stands south-east of the plaza in the photos (OSM `playground`
  at (-2738, -2387)); K8's rope course was placed in the strip west of the mall. Moving it needs a
  clean `park` area there (the OSM polygon is self-crossing, `bake_park_details.py` finds none).
- The open-air cinema on the lawns (photo 2): a summer-night event, a content idea.
- The service road the map draws across the plaza (OSM) is a delivery lane in reality; check that
  traffic never uses it.
