# Młotek (Smolna 8) reference report

Files: refs/mlotek/ (17 Commons photos 1-17, licences and per-photo notes in SOURCES.md; ortho.jpg 3072x3072, 0.0846 m/px,
x = -47.0 + px*0.0846, z = -97.9 + py*0.0846). Gathered on F's Mac 2026-11-03. Game coords: x = (lon - 21.024) * 68240.4,
z = (52.234 - lat) * 110574. Orthophoto numbers are eyeballed (+-3 m); the tower leans in the ortho, so the footprint comes from OSM.

## Outline and corners (OSM "Młotek", apartments, h=66.0; centrum.json)
- 15 points, a rectangle ~33 x 17 m, long axis about 21 deg north of east (dx 28, dz -11). Corners (x, z):
  N long side: (68.4, 29.2) - (89.5, 20.6) - (94.9, 18.4) - (96.2, 17.8) (NE corner);
  E end: (96.2, 17.8) - (102.7, 33.6) (SE corner), ~17 m;
  S long side: (102.7, 33.6) - (99.6, 34.8) - (97.2, 35.8) - (84.0, 41.2) - (82.1, 42.0) - (80.1, 42.8) - (74.9, 45.0);
  W end: (74.5, 44.0) - (69.4, 46.1) - (63.7, 32.2) (NW corner) - (68.7, 30.1) - (68.4, 29.2). Centre ~ (83, 32).
- LoD2 footprint 2563 (11 pts) is the same within 0.6 m. The ortho shows the roof as one long grey slab with a lower annex to the west
  and the garage/car-park roofs to the north (garages at (85,2)-(95,19), 4.3 m; outbuilding at (59..71, 33..52), 4.3 m).
- Neighbours: Smolna runs ~49 m to the south side of the centre; the Powiśle station canopy and the SKM line are south-west;
  parking lot to the south-east; Kopernik park (dense trees) north and east.

## Heights (LoD2, map y = metres above sea level - 100)
- LoD2 wall foot y = 4.0 (terrace level at the foot); roof deck levels 66.4-68.9; the top parapet/plant boxes to 70.2.
  So the roof is **~62.5-65 m above the LoD2 foot**, the top ~66 m: matches the OSM 66 m and Wikipedia's "66 m structural, 61 m to the roof".
- 20 above-ground storeys (Wikipedia; the brief says 19 storeys): 61 m / 20 = ~3.05 m a storey. Floors 19-20 are the club level
  ("Akropol", later "Top Floor") with a terrace: that is the crown.
- The ground falls away to the south (the escarpment); the lowest level at the foot reads 4.0 (a few vertices at 4.4).

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shaft | box with 21 deg yaw | 33 x 17 m, from LoD2 foot to roof deck (~62 m) | OSM outline, centre (83, 32) | grey-brown roughcast concrete | the plain slab with window strips |
| crown_slab | flat slab ("jaw"), overhanging the shaft at one end | 2 storeys (~6.5 m) high, ~6-7 m overhang at the NE (east) end, a thin eaves slab above (photo 1, 2) | top of shaft, x 90..103, z 17..34 | darker concrete, underside very dark | the "dropped jaw" that gives the nickname |
| crown_glaze | glazed band under the slab | 1 storey, runs the length of the long face, ~25 m | on the long face at floor 19 | dark glass, pale mullions | the club level |
| balcony_strip | deep loggia strip, full height | 2.5-3 m deep, along the end face (left in photo 1) and the right end, 17 storeys | W end face and NE end | concrete with yellow-edged slabs | the vertical balcony stripe |
| window_bands | horizontal strip windows | 17 bands, one per storey, ~28 m long, in 4 groups | long face, storeys 3-19 | white-framed casements, dark glass | the rhythm |
| stair_column | single windows | 1 per storey, 1 m wide | long face, ~12 % of the width from the end | white-framed | stair/lift core |
| base | two lower storeys, shop/lobby glazing, steps | ~7 m | long face foot | grey stone/concrete, glass | entrance (west side, photo 1) |
| canopy | flat roof on pilotis (pergola) | ~14 x 8 m, 4 m clear | NW foot, west of the entrance (photo 15, 16) | concrete frame, steel pergola | the low entrance canopy |
| roof_plant | small boxes, masts | 2-3 boxes ~3 x 3 x 2 m + antennas | crown roof, ends of the slab | grey | silhouette on the skyline |

## Facade, colours and rhythm (photos 1, 2, 14, 15, 16)
- Wide (long) face, seen in photo 1 from the south-east: ~85 % of the width is a grid; per storey, from the left: balcony strip
  (the left end, ~12 % of the width, with a yellow-edged slab per floor), then ~12 casement units in 4 groups of 3-4 (strip windows
  ~55 % of the width, each band ~1.1 m high), a narrow pier, then a plain wall (~15 %), then a column of single windows (~8 %)
  and, at the right, the deep balcony strip receding along the end face.
- Storeys read by the grid: 17 window bands between a 2-storey base and the 2-storey crown (3.05 m each, band ~1.1 m high,
  spandrel ~1.9 m).
- Colours (photos 1, 2): wall grey-brown roughcast **#8F877A** (shade #6E675C, weathered streaks darker); window frames white **#E8E8E4**
  on dark glass #2E3640; balcony slab edges yellow **#E3C33A** (peeling); the crown slab **#8A857C** with a very dark underside **#4A4743**;
  glazed band dark #343C46; base and plinth grey **#8C8A86**; the canopy concrete #7F7B74.
- The wall is plain roughcast concrete panels with almost no ornament; relief only from the loggias, the crown slab and the
  yellow edge strips.

## What each photo shows (full text: refs/mlotek/SOURCES.md)
- 1, 2: best silhouettes of the long face, winter and summer; 3: the same face from the park side (E).
- 4, 5, 6, 7: end faces and the full height from the park and the escarpment steps.
- 8, 9, 10, 11: the tower seen from Powiśle station (the view the player has from the south-west).
- 12: the lower storeys through trees; 13: the crown close-up (jaw slab, glazed band).
- 14: wall close-up from below (window strips, roughcast); 15, 16, 17: the base (canopy, pergola, fence, rear car park).
- No night photo found; no roof/aerial photo apart from ortho.jpg (the ortho shows grey flat roofs with plant boxes).

## Facts to confirm
- Year: 1964 design, completed 1976 (Wikipedia pl "Młotek (budynek)"); brief says 1976. OK.
- Architects: Jan Bogusławski and Bohdan Gniewiewski (Wikipedia pl; matches the brief "Bogusławski & Gniewiewski").
- Storeys: 19 (brief, "19-piętrowy" in the history section) vs "20 above-ground storeys" in the technical data (the crown's two storeys
  counted separately). Height: 66 m (structural), 61 m to the roof deck.
- Which end the jaw overhangs: from photo 1's position (the south-east car park looking north-west) the overhang is at the right
  end, which is the NE/E end of the outline; confirm by the shadow in the ortho (the crown's shadow at ~ (100,25)).
- Entered into the municipal register of monuments in August 2016 (Wikipedia pl). 140 flats of 40-60 m².

## Sources (photos stay on F's Mac in refs/mlotek/, gitignored)

All 17 photos are 1600 px thumbnails from Wikimedia Commons (CC BY, CC BY-SA, CC0); authors: WisłaWwa, Fred Romero, Wistula,
Oleslawlama, Plaksie, Roman Eugeniusz, Michał Kwasiżur, Nenea hartia, Валерий Дед, Аимаина хикари. Per-photo URL, author and licence: refs/mlotek/SOURCES.md.
ortho.jpg: GUGiK orthophoto, https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/HighResolution, layer Raster, WMS 1.3.0, EPSG:4326, bbox 52.232534,21.023311,52.234886,21.027121, 3072x3072 jpeg. Open data.
