# The river's barges (sites `barka_wieczor`, `barka_biala`, `barka_marina`, `barka_kaskada`, `houseboats`)

Written 2026-11-01 for F's ask ("the barges by the river should be real models"). OpenStreetMap
maps the moored bar barges along the Vistula boulevards as buildings of kind `boat` and the
houseboats in the harbour on the right bank as `houseboat`, with no height: the builder drew
each as a 14 m office block standing in the water. No reference photos in the cloud; measured
from the outlines in `centrum.json` (each barge on its smallest oriented box) and the venues'
published descriptions (bestofwarsaw.pl "Barges on the Vistula", 2025). The Mac photo check
(`refs/barki/`) is open: hull colours, the deckhouses' length and place, the terraces.

## 1. Identity

Converted river barges moored to the left bank's boulevards, bars in summer: a steel hull low in
the water, a glazed lower deck, a sun terrace on its roof under umbrellas, festoons of warm
bulbs, a gangway to the boulevard. Four of them, under parody names:

- `barka_wieczor` "Wieczorek nad Wisłą" (OSM "Wieczór nad Wisłą", below the Old Town by Most
  Śląsko-Dąbrowski, 40 x 11 m): navy hull, glazed lower level, a sun terrace, two bars.
- `barka_biala` "Biała Barka" (the unnamed `boat` north of it, the white BarKa at river km 512):
  white hull, food stalls on the open deck, a short deckhouse with a terrace at its far end.
- `barka_marina` "Marinka Warszawka" (OSM "Marina Warszawa", between the Copernicus Centre and
  the footbridge, 40 x 11 m): F's photo (2026-11-02) shows it as a two-deck white party barge, so
  it is: a white glazed lower storey with warm windows, an open upper deck under a canopy on
  slim posts with bulbs strung along the eaves, tables, an orange neon MARINKA on the canopy.
- `barka_kaskada` "Kaskadka" (OSM "Kaskada", 55 x 9 m): a long black concert barge, black and
  white, industrial: a long deckhouse with a plain roof under festoons.
- `houseboats`: nine private houseboats in the right bank's harbour (no card).

## 2. Massing

- Hull: the oriented box, ends raked 1.6 m (0.9 m on a houseboat), from 0.5 m under the water
  to the deck 1.0 m over it (0.6 m on a houseboat).
- Deckhouse: across the hull 0.8 m in from its sides, along a share of its length (per barge,
  `BARGE_STYLE` "house"), a 2.8 m glass storey and a 0.25 m roof slab.
- Gangway: 1.4 m wide, from the deck's edge on the bank's side (from the water map) to the first
  dry point, landing at the bank's height.
- Houseboat: a 2.5 m timber cabin on the hull's back half or so, a 0.2 m roof on a 0.3 m eave.

## 3. Facade

- Hull: an antifouling band to 0.3 m over the water, the hull's paint above to the deck.
- A 1 m bulwark round the open deck, a gap for the gangway.
- Deckhouse: glass (M_PAVILION, lit at night) between mullions every 1.8 m in the frame's colour.
- Houseboat: painted timber walls with a band of windows (lit at night) on both long sides.

## 4. Roof

- Terrace barges: a 1 m railing round the roof, a bar, tables under umbrellas, four festoon
  posts with three strings of bulbs.
- Kaskadka: a plain dark roof under the same festoons.
- Houseboats: flat, dark.

## 5. Colour and material

Per barge in `BARGE_STYLE` (hull, band, deck timber, frame, glass, roof, umbrellas, neon tube).
Everything in the city's one building surface (M_STONE, M_PAVILION, M_LAMP for the bulbs and the
stalls' hatches) plus one neon word each (WIECZOREK, BARKA, MARINKA, KASKADKA in
`neon_signs.gd` LANDMARK_WORDS): no new draw calls.

## 6. Ground and night

The water and the boulevard are the map's own. At night the deckhouses glow, the festoons'
bulbs and the stalls' hatches light, and each barge's name burns in neon on its terrace's
railing, on the face the game's camera sees most (BEHIND_FACE: on this run of the river the
deckhouse's southern end). Car collision round each hull.

## 7. Detail level and budget

L2, budget 2240 triangles at most per site (in `check_mesh_quality.gd`): barka_wieczor 1820 (built 1517), barka_biala 1400
(1162), barka_marina 2240 (1866), barka_kaskada 1880 (1562), houseboats 1080 (900, all nine).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| hull | raked prism | the oriented box, 1.5 m | the outline | band + hull paint, timber deck | the barge itself |
| bulwark | thin boxes | 1 m, 0.12 m thick | round the deck | hull paint | the deck's edge |
| deckhouse | glass prism + mullions + slab | 2.8 m + 0.25 m | per barge along the hull | M_PAVILION / frame | the glazed lower deck |
| terrace | railing, bar, umbrellas | 1 m railing, 1.1 m bar | on the deckhouse roof | frame, timber, canvas | the sun terrace |
| umbrellas | pole + 8-sided cone, table | 1.2-1.3 m radius, 2.6 m | rows on the open decks and the terrace | canvas colour | cafe tables |
| bar | box | 0.7 x up to 4.8 m, 1.1 m | across the open deck by the deckhouse | dark timber, light top | the deck bar |
| stalls | boxes + lit hatch | 2.6 x 1.8 m, 2.4 m | Biała Barka's river side | yellow, red, green | food stalls |
| festoons | wire + bulbs | 7 cm bulbs, 3-6 per string | posts at the open decks' corners and the terrace | M_LAMP warm | string lights |
| gangway | ramp + handrails | 1.4 m wide, to the first dry point | bank side | timber, steel | the way aboard |
| flag | pole + two quads | 4.2 m, 1.2 m flag | the -u end | white and red | the Polish flag |
| neon | sign | the parody name | the terrace's railing, camera side | neon | the bar's name |
| houseboat | hull + cabin + windows + roof + rail | 12-25 m long | the harbour | timber colours | the houseboats |
