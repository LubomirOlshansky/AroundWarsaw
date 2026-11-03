# The Vistula boulevards' dressing (sites `bulwary_pawilony`, `bulwary_bary`, `bulwary_pomosty`)

Written 2026-11-02 for the Powiśle street-by-street lane (LANDMARKS 2.14, "boulevard dressing:
deck strips, bar containers"). The Bulwary Wiślane between Most Śląsko-Dąbrowski and Tamka were
rebuilt in 2017-2020: a granite lower promenade by the water, concrete bar pavilions set into
the embankment on Bulwar Grzymały-Siedleckiego, timber decks and stepped seating, summer bar
containers, striped deck chairs everywhere. OpenStreetMap maps the six pavilions as 4.3 m
`pavilion` boxes and the boulevard's containers and kiosks (at Karowa, by the Marina barge,
by the Kaskada barge) as blocks up to 14 m tall. No reference photos in the cloud: positions
measured from `centrum.json` (outlines, the shore runs, steps, roads). The Mac photo check is
open (QUESTIONS): the pavilions' real fronts and roofs, what the Karowa containers are, colours.

## 1. Identity

Summer on the boulevard: long low concrete pavilions with lawn on their roofs and glass bars
facing the river, terraces under umbrellas and bulbs; colourful shipping containers and timber
kiosks selling beer, lemonade and zapiekanki through a lit hatch; timber deck strips at the
water's edge with a row of leżaki facing the river. Parody bar names only: CUDAK, POMOSTEK,
RZECZKA (no real venue's name). Cards: "Pawilony na bulwarach", "Kontenery na bulwarach".

## 2. Massing

- Pavilions: each mapped outline's oriented box (25-57 m long, 6-7.4 m deep), 3.6 m tall, its
  v axis turned to the river (`BULWAR_RIVER`).
- Containers: an outline under 3.2 m wide is a shipping box 2.6 m tall; wider is a timber
  kiosk 2.8 m with a 0.2 m roof slab overhanging 0.3 m. Neighbours alternate 6 cm in height.
- Deck strips: 10 x 3.2 m, 0.25 m high, 4.5 m in from the edge, at 17 spots along the left
  bank from the Old Town to Tamka (`BULWAR_DECKS`, measured clear of buildings, steps, roads).

## 3. Facade

- Pavilions: river front glazed from 0.3 m to 0.45 m under the top between concrete ends 1.2 m
  wide, dark mullions every ~2.4 m; the closed pavilion has grey shutters instead. The back
  (the embankment's side): timber slats and a dark door.
- Containers: corrugation as ribs every 0.45 m, 4 cm proud; the hatch on the long face the
  camera sees most, lit inside, a flap propped over it at 2.1-2.45 m, a counter under it.

## 4. Roof

- Pavilions: a lawn behind a 0.35 m concrete rim (the real roofs are green).
- Containers: flat, a shade darker; kiosks: a painted slab.

## 5. Colour and material

Concrete `#c3c0b8`, timber `#a37a52`, lawn `#6d8b4b`, glass `#6f8c96` (M_PAVILION, lit warm at
night). Containers in blue, red, yellow, green, cream and graphite. Deck chairs and umbrellas in
blue, cream, red, yellow and green canvas. Everything in the city's one building surface
(M_STONE, M_PAVILION, M_LAMP for the hatches and bulbs) plus five new neon words in
`neon_signs.gd` LANDMARK_WORDS: no new draw calls, no new skin slot.

## 6. Ground and night

Each piece stands on the lowest ground under its box; the boulevard, steps and the water are
the map's own. At night the open pavilions' glass glows, bulbs along their eaves light, the
hatches glow, and the bar names burn in neon on the face the game's camera sees most
(BEHIND_FACE). Car collision round the pavilions and the containers; the decks, chairs and
umbrellas are low and open, like the street furniture.

## 7. Detail level and budget

L2, triangle budget 3500 at most per site (an exception to L2's 3000: `bulwary_pawilony` is six
buildings in one site), budgets in `check_mesh_quality.gd`: bulwary_pawilony 3500 (built 2910), bulwary_bary 1760 (1462, 14
boxes), bulwary_pomosty 1450 (1206, 17 strips).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| pavilion | box + rim | the outline's box, 3.6 m, 0.35 m rim | Bulwar Grzymały-Siedleckiego | concrete, lawn top | the bar pavilions |
| glass front | quad + mullions | 0.3 m to top - 0.45 m | river face | M_PAVILION, dark mullions | the bars' glass |
| back | timber quad + door | as the front | embankment face | timber, dark door | the back |
| terrace | timber deck | 3.1 m deep | before the glass | timber | the bar terrace |
| umbrellas | table + pole + 8-sided cone | 1.1-1.2 m radius | terraces, decks, by the boxes | canvas colours | café tables |
| leżak | sling + back leg | 0.56 m wide, 0.86 m high | terraces, decks, by the boxes | canvas colours | the deck chairs |
| festoons | wire + bulbs | 5 per string, 12 m pieces | along the pavilions' river eave | M_LAMP warm | string lights |
| container | box + ribs | the outline, 2.6 m | Karowa, by the Marina | paint | the bar containers |
| kiosk | box + slab | the outline, 2.8 m + 0.2 m | by Kaskada, by the Marina | timber, paint | the food kiosks |
| hatch | lit quad + flap + counter | 60 % of the long face, 1.05-2.0 m | the camera's side | M_LAMP, paint | the serving hatch |
| deck strip | low box | 10 x 3.2 x 0.25 m | 17 spots by the water | timber | the sun decks |
| neon | sign | the parody name | top edge, camera side | neon | the bars' names |
