# Kościół św. Teresy od Dzieciątka Jezus (Powiśle parish church): spec

Site key `teresy` in `game/scripts/landmarks.gd` (`_build_teresy`). Written 2026-11-01 in a
cloud thread from the OpenStreetMap outline "Parafia Świętej Teresy od Dzieciątka Jezus" in
`centrum.json` (no photo). Everything not read from the outline is marked *(photo check)* and
waits for the Mac's `refs/`.

## 1. Identity

A brick parish church of Powiśle (neo-style, 20th century *(photo check)*). Defining: a long
brick hall under a steep gable roof, a small bell turret on the ridge, a lower polygonal chapel
and a lower parish house behind.

## 2. Massing

Frame: origin (369.93, -579.04) (the outline's centre), u along the nave (axis (0.643, 0.766),
a 50 degree turn), +v to the right. The outline says: a main block u -13.6..22.5, v -8..14.3
(about 36 x 22 m), a polygonal bump of 10 x 4 m on the v < -8 side near u -10..-1.4, and a
second block u -11..4.3, v 14.2..29 behind the nave. The model: nave u -10..21.8 (31.8 x 22.1 m,
walls 10 m, eaves cornice to 10.5 m, ridge 17.3 m), a lower annex u -13.4..-10 (6.5 m), the
chapel (7.5 m, hipped cap to 9 m), the parish house (8.5 m, hipped roof to 12.1 m). Heights
*(photo check)*. The tower is not in the footprint: a ridge turret instead *(photo check)*.

## 3. Facade, base to top

The front gable is the u = 21.8 end *(photo check: which end is the front)*: a trimmed plinth
(0.9 m), a dark portal (5 x 5.1 m) under a trim lintel with three steps, brick above, a round
window (r 1.5 m, 12.6 m up) and a small gilt cross at the apex. Side walls: M_GOTHIC brick
with buttresses and lancets.

## 4. Roof

- **Nave**: a steep gable roof, 6.8 m rise over 22.7 m span (about 31 degrees), dark tile.
- **Turret**: a square brick shaft (3 m) with dark louvres, a trim ring, a steep pyramid cap to
  7.6 m above the base ring and a gilt cross *(photo check: shape, position)*.
- **Chapel and house**: hipped caps, tile.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Brick | #b8644b, #a65a44 | M_GOTHIC, M_MONUMENT (house) |
| Roof tile | #8f4f40 | M_STONE |
| Trim, plinth, steps | #d9cdb4 | M_STONE |
| Portal, round window, louvres | #3a3f42 | M_GLASS, M_STONE |
| Cross | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

Car stopped by the nave, the parish house and the chapel (three rings). Card: "Kościół św.
Teresy od Dzieciątka Jezus", PL "Ceglany kościół parafialny na Powiślu, ze stromym dachem i
sygnaturką.", EN "A brick parish church in Powiśle, with a steep roof and a bell turret."
Open *(photo check)*: the real front, tower or not, brick colour, roof material, the window
pattern.

## 7. Detail level and budget

L2, triangle budget 280 (228 measured; `check_mesh_quality.gd`, `teresy`). Shot: `--at=370,-579 --heading=0 --size=40`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | box | 31.8 x 22.1 m, 1.5 m high | u 5.9, v 3.25 | M_STONE | 3 facade |
| nave walls | box | 31.6 x 21.9 m, 9.1 m high | 0.9..10 m | M_GOTHIC | 3 facade |
| eaves cornice | box | 31.8 x 22.1 m, 0.5 m high | 10..10.5 m | M_STONE | 3 facade |
| roof | gable | 22.7 m span, rise 6.8 m | 10.5..17.3 m | M_STONE | 4 roof |
| annex | box | 3.4 x 17 m, 7.1 m high | u -11.7, v 5.8 | M_GOTHIC | 2 massing |
| chapel | 6-sided prism and cap | 8.6 x 4.3 m, 9 m high | v -7.9..-11.9 | M_GOTHIC | 2 massing |
| parish house | box and hip | 15.1 x 14.8 m, 12.1 m high | u -3.25, v 21.6 | M_MONUMENT | 2 massing |
| portal | dark pane, lintel, 3 steps | 5 x 5.1 m | u 21.97, v 0..5 | M_GLASS, M_STONE | 3 facade |
| round window | disc | r 1.5 m | 12.6 m up | M_STONE | 3 facade |
| turret | shaft, ring, pyramid | 3 m square, 8.4 m cap | u 16, ridge | M_STONE, M_GLASS | 4 roof |
| crosses | 4 boxes | 2.6 and 2 m | gable apex, turret | M_STONE | 4 roof |
