# MDM: arcades, corner towers and reliefs (spec)

Site key `mdm` in `game/scripts/landmarks.gd` (`_find_mdm` for the skin, `_build_mdm` for the
model). Written 2026-11-01 in a cloud thread ("Marszałkowska pass 2") from the OpenStreetMap
outlines and, from 2026-11-05, F's Street View shots and Mapillary frames (refs/mdm_*). Every height and bay is an estimate; the
Mac photo check is parked in QUESTIONS.

## 1. Identity

Marszałkowska Dzielnica Mieszkaniowa (1950-1952, socialist realism). From F's photos
(2026-11-05): cream-white plaster upper storeys with pale vertical strips and iron balconettes;
a sand-coloured stone base three storeys high with big shopfronts between stone piers; a
cornice and small finials along the roof; no spired towers (the first pass 2026-11-01 had
them: wrong). Roof neons: the red MDM, a Xiaomi sign and a BYD sign, the Hotel MDM's own sign.

## 2. Massing

The blocks stay LoD2's (kept skin `#e6dfcc`). Added in the street's grid (u 0.349 / 0.937):
a stone base on every long facade (14 m or more) looking at the square or the Marszałkowska
axis (dot > 0.55, within 100 m, not into another block), deep arcades on the facades within
80 m of the square's centre only, a stepped attic pavilion at each of four block ends.

## 3. Facade, base to top

Base: a wall 0.6 m proud, ground to 11 m (M_MONUMENT windows), a ledge 11-11.7 m. Ground
floor: stone piers 1 m wide every ~5.4 m to 5.8 m, a cornice 5.6-6.2 m, dark shopfronts between.
Arcade (ring only): square piers 1.4 m, 2.9 m out, an entablature 5.8-6.4 m, a cornice to 6.9 m.

## 4. Roof

Pavilion: a cornice, a recessed windowed attic 4.5 m, a cornice, a grey cap, finials on the
corners and along the long sides. Signs stand on the roofs, 8-12 m wide.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster (skin) | #e6dfcc | M_MONUMENT |
| Stone base | #cdb98d | M_MONUMENT |
| Piers | #d3c39a | M_STONE |
| Trim, cornices | #ece4d0 | M_STONE |
| Shopfronts | #34383b | M_GLASS |
| Neon MDM, HOTEL MDM | red | neon quad |
| Neon XIAOMY | orange | neon quad |
| Neon BYDŁO | silver-white | neon quad |

No new material or draw call; the four words join `neon_signs.gd` LANDMARK_WORDS.

## 6. Ground and night

Car collision on each facade's front. XIAOMY and BYDŁO are parodies of real brands (the real
names are in `brand_denylist.json`). Open *(photo check)*: which facades really have arcades
(F's Street View shows a copper-roofed colonnade on the far block at the square), the real
sign positions and sizes, balcony railings, the pavilions' real shape.

## 7. Detail level and budget

L3, 3403 triangles measured, budget 4100 in `check_mesh_quality.gd`; no zfight, degenerate,
bad-normal or floating parts (each pavilion has a hidden core tying it to the ground).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| stone base | wall plus ledge | 11 m high, 0.6 m proud | each street facade | M_MONUMENT, M_STONE | 3 base |
| piers | boxes | 1 m wide, 6 m high | every ~5.4 m | M_STONE | 3 ground floor |
| shopfronts | dark wall pieces | 4.9 m high | between the piers | M_GLASS | 3 ground floor |
| arcade | piers plus entablature | 1.4 m piers, 2.9 m deep | ring facades | M_STONE | 3 arcade |
| pavilion core | box | pavilion less 0.8 m, ground to roof | hidden in the block | M_STONE | 2 massing |
| pavilion attic | windowed box, two cornices, cap | 4.5 m attic | four block ends | M_MONUMENT, M_STONE | 4 roof |
| finials | pinnacles | 0.5-0.7 m, 1.6-2.4 m | pavilion corners and sides | M_STONE | 4 roof |
| roof signs | neon words | 8, 12 and 11 m wide | NE crown, east roof, SE block | neon quad | 4 roof |
| hotel sign | neon word | 5.2 m wide | NE block, 5.9 m up | neon quad | 3 ground floor |
