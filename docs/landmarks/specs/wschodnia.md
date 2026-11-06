# Warszawa Wschodnia (site `wschodnia`)

Written 2026-11-03 for the railway's S3e (docs/design/railway.md) from the Mac photo report
`docs/landmarks/photo-reports/wschodnia.md` (9 Commons photos and the GUGiK orthophoto in
`refs/wschodnia/` on F's Mac). The hall's outline is OpenStreetMap's landmark outline "Warszawa
Wschodnia" in `centrum.json` (about 150 x 60 m, long axis with the tracks, 27° north of east). It is
not a building in the map data and GUGiK's LoD2 has no model of it, so before this the corner was
an empty forecourt beside a bare yard. Heights are estimates from the photos (no LoD2 here); the
map's north-east cut (`outside`, z < -2045) runs through the hall's north edge.

## 1. Identity

Praga's main station, 1969, refitted for Euro 2012: a long low glazed hall north of the tracks
under a flat roof whose edge is a folded (zig-zag) concrete fascia, the overhang carried on
V-shaped steel struts (white-grey on the Kijowska front, pale green on the track side), WARSZAWA
WSCHODNIA in white letters on the fascia. South-east of it the island platforms under long
rust-brown roofs on a row of columns, reached by passages under the tracks.

## 2. Massing

- Hall: OSM's outline (simplified to 0.6 m), a 1 m granite plinth, glass to 9.8 m.
- Roof: the outline grown 3.2 m (the overhang), its top at 10.4 m, the soffit at 9.8 m.
- Platform roofs: over the five long island platforms (the map's platforms over 300 m long near
  the hall), only where the platform's middle lies between x 1860 and 2120 (the ortho's roofs) and
  inside the map; 4.4 m over the platform, following its edges every 6 m.

## 3. Facade, base to top

- Hall: glass (M_PAVILION cool, lit at night) in 2.4 m bays with dark mullions, a dark mezzanine
  band at 4.4-4.75 m.
- V struts every ~7.5 m along each front longer than 14 m, 3.2 m out under the overhang: two legs
  from a granite foot block up to the soffit 3.4 m apart; pale green #9cc38e on the south (track)
  side, white-grey #d9dcdc on the north.
- Fascia: a vertical plate round the roof's edge, its foot zig-zagging every 3 m from 0.6 m down at
  the roof's edge to 1.6 m down at points standing 0.45 m out (the pleats), dark #3b3e43, both
  faces; a plain board over the pleats on the longest south front carries WARSZAWA WSCHODNIA.

## 4. Roof

- Hall: flat grey, three glazed ridge lights along it (the lattice roof's glazed strips seen from
  inside in photos 2, 3, 5; lit at night) and a few plant boxes on the north side.
- Platform roofs: rust-brown #8e5a44, a shallow ridge down the middle (0.25 m), a darker edge, a
  lighter soffit with a lamp strip down the middle (M_LAMP), a dark column every 12 m on the
  platform's middle.

## 5. Colour and material

Glass #5f7a88, mullions #4a4f55, fascia #3b3e43, roof #8f9296, soffit #c9c7c0, granite #8d8b86,
struts #9cc38e / #d9dcdc, platform roofs #8e5a44, columns #55524f, white letters. Everything in the
city's one building surface (M_STONE, M_PAVILION, M_LAMP) plus one new neon word (WSCHODNIA in
`neon_signs.gd` LANDMARK_WORDS; WARSZAWA was there): no new draw calls beyond the sign's.

## 6. Ground and night

The tracks, the platforms and the forecourt stay the map's. At night the hall's glass and the
ridge lights glow and the letters burn white on their board. Car collision round the hall.

## 7. Detail level and budget

L3, budget 7000 triangles (in `check_mesh_quality.gd`; built 5860, of which the platform roofs
are about two thirds).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | prism | the outline, 1 m | the hall | granite | the hall's base |
| hall | glass prism + mullions + band | the outline, 9.8 m | (1890, -2010) | M_PAVILION | the hall |
| roof | flat cap + soffit | outline + 3.2 m, top 10.4 m | over the hall | grey / pale | the overhanging roof |
| fascia | folded plate | 3 m pleats, 0.6-1.6 m deep, 0.45 m out | round the roof | dark | the zig-zag edge |
| struts | V of two beams + foot | 0.26 m legs, 3.4 m apart at the top | every 7.5 m under the overhang | green / white-grey | the V supports |
| board | box | the letters + 2 m, 1.75 m | the longest south front | dark | the sign's band |
| neon | sign x 2 | WARSZAWA, WSCHODNIA | on the board | white | the station's name |
| ridge_lights | glass boxes | 3 x the hall's length - 16 m, 2.2 x 0.7 m | the roof | M_PAVILION | the glazed strips |
| plant | boxes | 3.6 x 2.4 x 1.4 m | the roof's north side | grey | roof kit |
| platform_roofs | ridged slabs + columns | platform width - 0.7 m, 0.35 m, 4.4 m up | five platforms, x 1860-2120 | rust-brown | the platform roofs |

F's look check (2026-11-03): roof edge 10.4 m kept; pleats 2.3 m deep, 0.9 m out; struts 0.42 m, every 6 m; the short suburban platforms roofed from x 2020 east (endpoints to verify).
