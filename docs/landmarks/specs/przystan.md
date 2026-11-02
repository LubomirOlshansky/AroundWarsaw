# The sailing marina in Port Czerniakowski (site `marina`)

Written 2026-11-02 for F's ask ("the przystań dla żaglówek should be designed, with a building on
the water, real, with żaglówki on it"). Port Czerniakowski is the Vistula's yacht harbour on the
left bank at Gen. Zaruskiego street (Zaruski is the father of Polish sailing). OpenStreetMap
maps its club house as an unnamed `yes` building with no height standing in the water at the
dam's west end (drawn as a 14 m office block), the dam and the finger piers of the small south
basin as footpaths, and nothing else. No photos in the cloud: positions measured from
`centrum.json` (club house outline, the paths' coordinates, the water map). The Mac photo check
is open: club house colours and storeys, the berth count, which boats really winter here.

## 1. Identity

A members' sailing harbour: a white club house with a red hipped roof, a flagpole and a lit
name, finger piers, white and navy cruisers with their masts bare, more yachts on buoys in the
big basin. Card: "Przystań w Porcie Czerniakowskim".

## 2. Massing

- Club house: the mapped outline (about 15 x 24 m), piles and a deck from 0.8 m under the water
  to the quay, a 2.7 m white ground floor, a 2.7 m glazed upper band, a 0.25 m eave slab and a
  2.6 m hipped roof.
- Sailboat: 8.4-9.4 m (berths), 8.6-11.6 m (buoys); hull 0.35 m under to 0.85 m over the water,
  a 0.5 m doghouse, a mast 1.15 x its length, a boom with a furled sail, a forestay.
- Berths: two boats to each of four slips between the fingers (bows east), five along the dam
  (bows west), eight on buoys in the basin (bows into the wind).

## 3. Facade

White walls (#efeee8) over a dark pile deck, glazing in mullions every 1.6 m (lit at night).
Hulls in white, navy, red, teal, cream and graphite over a darker sheer band.

## 4. Roof

Red tile hip (#a4412e) on a navy eave slab; a flagpole at the corner with the white-and-red flag.

## 5. Colour and material

All in the city's one building surface (M_STONE, M_PAVILION, M_LAMP for the pier lamps), plus one
neon word, PRZYSTAŃ, in `neon_signs.gd` LANDMARK_WORDS: no new draw calls.

## 6. Ground and night

The water and the quay are the map's own. The club house glows and the five pier-end lamps burn
warm; the name shows in neon on the face the camera sees most (BEHIND_FACE). Car collision on
the club house only (boats are on the water).

## 7. Detail level and budget

L2, budget 5200 triangles for the whole site (an exception to the per-building L2 limit: it is a harbour of 20 boats and a club house) (in `check_mesh_quality.gd`): about 20 boats of
roughly 130 triangles and the club house.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| club | prism on piles + glazed band + hip | 15 x 24 m, 8 m | the mapped outline | white, glass, red tile | the club house |
| flag | pole + two quads | 9 m, 1.5 m flag | the club's corner | steel, white and red | the Polish flag |
| neon | sign | PRZYSTAŃ | the club's camera side | neon | the harbour's name |
| sailboat | hull + doghouse + mast + boom + sail | 8-12 m | slips, dam, buoys | hull paints, steel, canvas | the yachts |
| buoy | small drum | 0.7 m | 7.5 m ahead of each buoy boat | red | mooring buoys |
| lamp | post + lantern | 2.5 m | the five finger ends | steel, M_LAMP warm | pier lamps |
