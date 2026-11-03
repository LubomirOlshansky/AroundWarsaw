# Karowa 18a reference report (stepped balcony block on the Karowa bend)

Files: refs/karowa18a/ (12 Commons photos 1-12, licences and per-photo notes in SOURCES.md; ortho.jpg 3072x3072, 0.0846 m/px,
x = -592.9 + px*0.0846, z = -1082.1 + py*0.0846). Gathered on F's Mac 2026-11-03. Game coords: x = (lon - 21.024) * 68240.4,
z = (52.234 - lat) * 110574. Ortho numbers are eyeballed (+-3 m).

## Outline and corners (OSM, apartments, no name, h=30.7; centrum.json)
- 27 points, a long slab ~43 x 12.6 m, long axis bearing about 33 deg north of east (running from the NW end (-483, -946) to the SE end (-447, -969)).
  The street (Karowa) face is the south-west long side, a **sawtooth** of 0.2-0.4 m jogs every ~4 m:
  (-483.5, -946.2) - (-479.6, -948.3) - (-475.8, -950.8) - (-472.0, -953.2) - (-468.2, -955.6) - (-464.4, -958.1) - (-460.6, -960.5) - (-456.8, -962.9) - (-453.1, -965.3) - (-447.1, -969.0) (SE corner).
  SE end: (-447.1, -969.0) - (-440.2, -958.9) (~12 m). Rear (north-east) long side, straight, facing the Wisła side of the escarpment:
  (-440.2, -958.9) - (-446.9, -954.6) - (-463.7, -944.0) - (-476.8, -935.8) - (-477.2, -935.2) (NW corner); NW end (-477.2, -935.2) - (-483.5, -946.2).
- Centre ~ (-463, -952). The LoD2 footprint 3534 is the same. OSM h=30.7 comes from the top of the block, not the stepped profile.
- Ortho: a stepped grey roof of five terraces on the long axis (the shadow side is the north-east), a car park/forecourt on the street side
  (the garage at (-494..-461, -967..-981), 4.3 m), the Karowa bend to the south-west, the Visitation convent garden behind, Hotel Bristol/
  Presidential Palace across Krakowskie Przedmieście to the west.

## Heights (LoD2, map y = metres above sea level - 100)
- Ground / garage level: y 1.8 under most of the block, 3.4 at the street entrance, -0.7 at the low (south-east) corner (the slope down to the Wisła).
- Roof levels along the axis (t from the NW end): 0-12 m: **34.3** (tall end, with a 32.1 step at the very end); 12-16 m: 30.6;
  16-40 m: **31.5 / 27.8** alternating (two terrace steps); 40-44 m: **28.1 -> 23.0** (the low SE end).
  Heights above the garage floor: ~32.5 m at the tall NW end, ~29.5 and ~26 in the middle, ~21 at the SE end. OSM 30.7 is the mean.
- Storeys: the face reads 8-9 rows of balcony boxes over a garage base at the tall end (to confirm; ~3.0 m a floor).

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| slab | box, axis 33 deg N of E | 43 x 12.6 m, from garage floor to the 34.3 / 31.5 / 27.8 / 23.0 levels (stepped, see Heights) | OSM outline, centre (-463, -952) | tan roughcast concrete | the stepped terrace profile |
| balcony_boxes | projecting boxes, each ~2.4 m wide, 3.0 m high (one storey), 1.5 m out, a window beside each | ~10 per row x 8 rows on the street face; staggered one bay on every other storey | along the SW long face, 4 m pitch | tan roughcast, white window frames | the staggered balcony boxes |
| terrace_steps | roof set-backs | 4 steps, each ~3.2 m down (34.3 -> 31.5 -> 27.8 -> 23.0), tread ~4-6 m | along the axis | grey roof membrane | the stepped roofline |
| garage_base | open ground storey (car park in the base) | ~4 m high, dark openings every ~4 m, concrete piers | the foot of the street face | dark concrete, black openings | the car park in the base |
| base_cladding | grey stone panels | ground storey strip ~1 m high, 8 x 1 m panels | the foot, street side (plaques are fixed on it) | grey stone **#8C8A86** | plaque wall |
| entrance | small door pair, steps | ~3 m | street face, near the NW end | dark glazing | entrance |
| rear_wall | plain rendered wall, windows in strips | no balcony boxes | NE long side | tan render | rear |
| roof_plant | small boxes and a stair head | 2-3 boxes ~3 x 3 m | at the 34.3 end | grey | roof detail |

## Facade, colours and rhythm (photos 1, 2, 3, 4, 5, 6)
- A tight 4 m module: window + balcony box per bay; the boxes are staggered like a brick bond, so each floor's boxes sit half a bay off the floor
  below, giving a sawtooth silhouette in plan and a woven look in elevation (1, 5, 6).
- Colours: boxes and walls ochre-tan roughcast **#C49A6C** (sunlit #C99E73, shade #A9805A), window recesses/shadow side darker
  **#8A6144**; window frames white **#F0EEE8**, dark glass #2E3640; base dark concrete **#5E5A55** and grey stone panels **#8C8A86**; roof grey #7A7873.
- The balcony boxes are plain roughcast with a flat soffit and a thin parapet; no railings visible in 1, 8.

## What each photo shows (full text: refs/karowa18a/SOURCES.md)
- 1: straight-on street front (2024), the best elevation; 2, 3, 8: oblique views along the face (2013, 2025, 2009).
- 4: balcony boxes close-up with windows; 6: boxes and the stepped top; 5, 7: long views with the garage base and the escarpment.
- 9: the neighbour Karowa 18 (white, Instytut Socjologii) with the 18a face at the left edge; 10: Karowa with older buildings, 18a at the right.
- 11, 12: plaques on the base wall (grey stone panels).
- No night photo and no aerial photo found beyond ortho.jpg.

## Facts to confirm
- Year 1978 (brief); the Wikipedia pl list "Dobra kultury współczesnej w Warszawie" has no entry I could read for Karowa 18a. Not verified.
- Architects (brief): Dąbrowski, Kuźmienko, Nowak and Sembrat. Not verified from a source here.
- Number of storeys (8-9 rows of boxes + garage base) and the garage's width/openings (count in photos 1, 5).
- Whether the boxes overhang the pavement (they stand on the garage piers; confirm in 1).

## Sources (photos stay on F's Mac in refs/karowa18a/, gitignored)

12 photos, 1600 px thumbnails from Wikimedia Commons (CC BY, CC BY-SA, public domain); authors: Adrian Grycuk, Lukas Plewnia, PiotrMig, piotr iłowiecki,
Z thomas, Szczebrzeszynski, Panek, Marcin Białek. Per-photo URL, author, licence: refs/karowa18a/SOURCES.md.
ortho.jpg: GUGiK orthophoto, https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/HighResolution, layer Raster, WMS 1.3.0, EPSG:4326, bbox 52.241435,21.015312,52.243786,21.019122, 3072x3072 jpeg. Open data.
