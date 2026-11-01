# Muzeum Sztuki Nowoczesnej (MSN): spec

Site key `msn` in `game/scripts/landmarks.gd` (`_find_msn`, `_build_msn`). Written 2026-10-31 in
a cloud thread from the OpenStreetMap parts in `centrum.json` (the museum is mapped in 3D: an
outline, a glazed core, 29 fins, a recessed band and the upper box, with heights) and the
design brief in `docs/design/first-scene.md`. The reference photos in `refs/msn/` (or
`refs/muzeum_sztuki_nowoczesnej/`) live on the Mac and were not available here: the values
marked *(photo check)* are the ones the side-by-side check on the Mac should confirm or move.

## 1. Identity

Thomas Phifer's museum (opened October 2024) on Plac Defilad's east edge, its long side on
Marszałkowska, the Palace of Culture behind it. What makes a passer-by say its name:

1. **One long, low, plain white box**, 104 x 40 m and 26 m high, against the Palace's ornament
   and the glass towers round it. No cornice, no parapet, no joints: a clean edge at the roof.
2. **The box floats on a glazed ground floor**: the glass lobby set back about 6 m under a
   white soffit, behind a row of deep white fins (piers) on every face.
3. **One thin dark slot** all round at mid-height, where the upper box sits back 0.7 m from
   the lower one.
4. **A few large "city room" windows** on the upper floor, looking at the Palace.
5. **A gridded glass roof round two small light wells**, glowing at night (the view from above, which
   is the game's view).

## 2. Massing

Plan axes (local u, v in metres): origin (-1022.4, 100.15); u along the long side at 69.85°
(world direction (0.3445, 0.9388), north-north-west end at u < 0, Świętokrzyska's end);
v = (-0.9388, 0.3445), +v towards the Palace (the Plac Defilad face), -v towards Marszałkowska.

| Volume | Plan (local) | Heights above ground | Source |
| --- | --- | --- | --- |
| Glazed core (ground floor) | u -45.8..45.8, v -13.95..13.95 | 0 to 5.0 m | OSM part h 5, mh 0 |
| Lower box | u -51.85..51.85, v -19.9..19.9 | 5.0 to 12.5 m | OSM part h 12.5, mh 5 |
| Slot band | u -51.2..51.2, v -19.2..19.2 (0.65-0.7 m in) | 12.5 to 13.8 m | OSM part h 13.8, mh 12.5 |
| Upper box | as the lower box | 13.8 to 26.0 m | OSM part h 26, mh 13.8 (LoD2 says 26 m too) |

The OSM outline is a rectangle to within 0.1 m (its 12 points include a mapped corner notch
under 0.1 m deep), so the model uses the rectangle. Ground: the lowest terrain under the
corners; the core and the fins start 0.4 m below it so nothing floats on a slope.

## 3. Facade, base to top

- **Base (0-5 m)**: the core's four walls are glass lit from inside (lobby, café, bookshop)
  with mullions at 1.6 m (the material's own rhythm). Between the core and the box's edge a
  flat white soffit at 5.0 m, 6 m deep on the long faces and 6 m on the ends.
- **Fins**: 1.0 m wide x 3.0 m deep x 5 m tall, their centres 1 m inside the box's edge
  (v = ±17.4 on the long faces). Positions from OSM: Marszałkowska face (v -17.4) at u =
  -50.4, -39.4, -26.4, -18.4, -10.4, 0.4, 7.4, 15.3, 26.4, 33.8, 40.8, 50.4 (12, the wider gaps
  are the entrances); Plac Defilad face (v +17.35) at u = -50.4, -39.5, -32.5, -26.5, -18.5,
  -10.6, 0.4, 7.3, 15.2, 26.2, 33.7, 40.7, 50.3 (13). On the ends the fins turn 90°
  (3.0 m along u, 1.0 m across): north end at u -49.4, v 3.95 and -8.5; south end at u 49.4,
  v 6.3 and -8.55. Total 29.
- **Middle (5-12.5 m)**: blank white wall, the lower galleries (no windows: top-lit and
  artificially lit rooms).
- **Slot (12.5-13.8 m)**: a 1.3 m dark glass ribbon round all four faces, 0.7 m in; a white
  ledge on the lower box's top and a white underside on the upper box's.
- **Top (13.8-26 m)**: blank white wall, the upper galleries. Windows from F's night photo
  (2026-10-31, taken from the north-west), all flush with the wall (lit warm at night), the wall
  cut round them:
  - **W1** on the Plac Defilad face (+v), u 0..14, 16.5 to 22.5 m; **W3** under it, u -1..5,
    7 to 10.5 m (the lower galleries);
  - **W4** on the north end (-u), v -15..-9, 15.5 to 22 m, and **W5** under it, v -14..-11.5,
    7 to 9.5 m;
  - **W2** on the Marszałkowska face (-v), photo-checked on the Mac 2026-11-01 (refs/msn/4.jpg,
    from the Świętokrzyska corner): a deep recess in the upper box at mid-face, u -1..11, 14 to
    20.5 m, the glass 3 m back behind white reveals, sill and head; and a small window near the
    south end, u 37..39, 14.5 to 19 m, flush. The game's camera looks north, so the player sees
    the south end and this face.
- **Corner block**: at the north-west corner a full-height block stands out from the box to
  the ground (OSM's part at about (-1062, 54): 26 m on an 8 m base), u -64.3..-51.85,
  v 16.5..27, solid white, its glazed top 1 m under the main roof (lit at night).

## 4. Roof

Flat at 26.0 m, no parapet. Photo-checked on the Mac 2026-11-01 against `refs/msn/ortho.jpg`
(and 2.jpg, the roof's steel grid during construction): nearly the whole roof is one gridded
glass field (M_GLASS_ROOF, lit warm at night) inside a 2.2 m white edge (#d9d8d2), with two
small square light wells cut into it: 8 x 8 m at (5, 4.9) and 7 x 7 m at (31.5, -0.6), 4 m deep,
their floors in shade. No plant on the roof.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| White concrete walls, fins, soffits, ledges | #ebe9e3 (a step under pure white, calmer than the photo's glare) | M_STONE |
| Roof | #d9d8d2 | M_STONE |
| Ground-floor glass | #a9c3cd | M_PAVILION (+0, warm at night) |
| Slot ribbon | #4a5960 | M_GLASS |
| City-room windows | #8fa9b6 | M_PAVILION (+0, warm at night) |
| Roof panels, corner block top | #cfd8dc | M_GLASS_ROOF (lit warm at night) |

No new material, no draw call of its own: everything goes into the city's building surface.

## 6. Ground and night

At its foot the square's paving and the park strip (first-scene item 4, not this spec); the
car is stopped at the box's outline (the fins and soffit read as an arcade from the street, but
driving under it is not allowed). At night the ground-floor glass and the two big windows glow
warm from inside (M_PAVILION), the slot stays dark, the white box takes the street light. Card:
"Muzeum Sztuki Nowoczesnej", PL "Biały gmach Thomasa Phifera przy Placu Defilad. Otwarty w 2024 roku.",
EN "Thomas Phifer's white museum on Plac Defilad. Opened in 2024." Next door (outside this
site): the small mapped block at about (-1062, 54), left as the map has it; TR Warszawa's black
box is a later item.

## 7. Detail level and budget

L3 (a first-scene hero), triangle budget 500 (412 measured after the Mac photo check, 410 after the first photo pass, plus about 20 %, in
`check_mesh_quality.gd` BUDGET). Shots: `--solo=msn --solo-look=sil` and `flat` (the silhouette
and the plain box), then in the city at day and night from the Marszałkowska side.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| core | box, glass walls only | 91.6 x 27.9 x 5.4 m | u 0, v 0, y -0.4..5 | M_PAVILION #a9c3cd | 2 floating box |
| soffit | 4 downward quads, ring | outer 103.7 x 39.8, inner 91.6 x 27.9 | y 5.0 | M_STONE #ebe9e3 | 2 floating box |
| fins | 29 boxes | 1.0 x 3.0 x 5.4 m | listed in section 3 | M_STONE #ebe9e3 | 2 arcade fins |
| lower | box walls | 103.7 x 39.8 m | y 5.0..12.5 | M_STONE #ebe9e3 | 1 white box |
| ledge | ring top | 0.7 m wide | y 12.5 | M_STONE #ebe9e3 | 3 slot |
| slot | box walls, inset | 102.4 x 38.4 x 1.3 m | y 12.5..13.8 | M_GLASS #4a5960 | 3 slot |
| under | ring underside | 0.7 m wide | y 13.8 | M_STONE #ebe9e3 | 3 slot |
| upper | box walls and roof | 103.7 x 39.8 m | y 13.8..26.0 | M_STONE #ebe9e3, roof #d9d8d2 | 1 white box |
| w1 | flush glass panel | 14 x 6 m | +v face, u 0..14, y 16.5..22.5 | M_PAVILION #8fa9b6 | 4 city room |
| w3 | flush glass panel | 6 x 3.5 m | +v face, u -1..5, y 7..10.5 | M_PAVILION #8fa9b6 | 4 city room |
| w4 | flush glass panel | 6 x 6.5 m | -u end, v -15..-9, y 15.5..22 | M_PAVILION #8fa9b6 | 4 city room |
| w5 | flush glass panel | 2.5 x 2.5 m | -u end, v -14..-11.5, y 7..9.5 | M_PAVILION #8fa9b6 | 4 city room |
| corner | box, glazed top | 12.45 x 10.5 x 25.4 m | u -64.3..-51.85, v 16.5..27 | M_STONE #ebe9e3, top M_GLASS_ROOF | 1 white box |
| w2 | recess: glass 3 m back, reveals, sill, head | 12 x 6.5 m | -v face, u -1..11, y 14..20.5 | M_PAVILION #8fa9b6, M_STONE | 4 city room |
| w6 | flush glass panel | 2 x 4.5 m | -v face, u 37..39, y 14.5..19 | M_PAVILION #8fa9b6 | 4 city room |
| sky | flat glass field with 2 holes | 99.3 x 35.4 m | roof, y 26 | M_GLASS_ROOF #cfd8dc | 5 skylights |
| wells | 2 open courts | 8 x 8 and 7 x 7 m, 4 m deep | (5, 4.9) and (31.5, -0.6), y 22..26 | M_STONE | 5 skylights |
