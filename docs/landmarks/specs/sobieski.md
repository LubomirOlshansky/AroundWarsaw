# Radysław Blu (the Radisson Blu Sobieski): spec

Site key `sobieski` in `game/scripts/landmarks.gd` (`_build_sobieski`). Written 2026-11-02 in a cloud thread from the OpenStreetMap outline "Radisson Blu Sobieski" (Plac Zawiszy 1) in `centrum.json`; no photo, no LoD2 here. Values marked *(photo check)* wait for the Mac's `refs/`. The real brand never appears in the game: the card and the sign say RADYSŁAW BLU.

## 1. Identity

The big hotel on Plac Zawiszy, known for a postmodern facade in colourful bands.

## 2. Massing

The mapped outline simplified (1.2 m), three set-back tiers: 4.6 m plinth and salmon tier to 13 m, yellow tier (inset 1.4 m) to 22 m, mint tier (inset 2.8 m) to 31 m *(photo check: storeys, real height)*.

## 3. Facade, base to top

Dark teal plinth with glass bays; salmon tier in the M_MONUMENT window shader; a magenta stripe at 13 m and another at 22.6 m; vertical coloured fins every 6 m on every public front longer than 10 m (salmon and yellow tiers); teal crown band under the roof.

## 4. Roof

Flat, a teal crown band with a lighter cap.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Salmon tier | #e59a86 | M_MONUMENT |
| Yellow tier | #f0d27a | M_MONUMENT |
| Mint tier | #8fd0b4 | M_MONUMENT |
| Crown, plinth | #2f8f9a, darker | M_STONE |
| Stripes, canopy | #c2287a | M_STONE |

No new material or draw call.

## 6. Ground and night

Brings its own car walls (the simplified ring). A lit door under a magenta canopy on the longest front; the name RADYSŁAW BLU burns cyan at night. Card "Radysław Blu". Open *(photo check)*: real colours and order of the bands, entrance position, storey count.

## 7. Detail level and budget

L2, triangle budget 1500 (`check_sites.gd`, `check_mesh_quality.gd`).

Shot: `--at=-2405,1130 --heading=0 --size=60 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | ring prism | 5 m high | ground | M_STONE | 3 facade |
| tier 1 | ring prism | 8.4 m high | 4.6 m | M_MONUMENT | 2 massing |
| tier 2 | inset prism | 8.3 m high | 13.7 m | M_MONUMENT | 2 massing |
| tier 3 | inset prism | 7 m high | 22.6 m | M_MONUMENT | 2 massing |
| stripes | rings | 0.7 m high | 13 m, 22 m | M_STONE | 3 facade |
| fins | boxes | 0.6 m wide, every 6 m | tiers 1 and 2 | M_STONE | 3 facade |
| canopy, door, board | boxes | 8.4 m canopy | longest front | M_STONE, M_PAVILION | 6 night |
