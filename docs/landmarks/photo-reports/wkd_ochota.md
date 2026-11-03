# Warszawa Ochota WKD reference report (railway S3d)

Files: refs/wkd_ochota/ (3 Commons photos, SOURCES.md; ortho.jpg 260 m square centred on Plac Zawiszy,
ortho_north.jpg 200 m square north of it; frames in ortho.txt). Gathered on F's Mac 2026-11-02.
Game coords: x = (lon - 21.024) * 68240.4, z = (52.234 - lat) * 110574. Ortho values ±3 m.

## Where it is
- OSM: Warszawa Ochota WKD halt **(-2353, 950)** (stop positions (-2354, 946) and (-2352, 954)); the PKP/SKM
  halt Warszawa Ochota is ~90 m east at (-2263, 904). Both lie in the **cross-city rail cutting just east of
  the Towarowa bridge, north-east corner of Plac Zawiszy**.
- In ortho_north: the cutting east of Towarowa runs x -2385..-2330 (and on east, out of frame), z ~938..968,
  with the tracks at the bottom (rails brown ballast) and a **long flat brown-roofed concrete deck over its south
  half (x -2385..-2330, z 958..980)**: that deck is the roof of the WKD platform (photo 1). North of the cutting
  a grass bank and the office block's yard; the glazed sloping entrance hall of the PKP halt stands at the
  cutting's north-east (x -2335..-2320, z 925..950 in ortho_north; the slanted glass roof of photos 2-3).
- West of Towarowa the main-line platforms (Ochota PKP's west end) continue (x -2520..-2450, z 900..960).

## The WKD platform (photo 1)
- One side platform under a **heavy concrete slab carried on V-shaped concrete columns** (pairs of raked legs
  meeting at the floor, ~1.5 m wide at the top), spaced ~8 m; behind them the cutting's back wall, covered in
  graffiti and posters; the slab's edge is rough grey concrete **#9E9A92**; floor concrete with a red-brown
  edge strip; blue steel benches and a blue timetable board.
- The PKP side (2, 3): a covered platform with a rust-brown long roof, the glazed hall with a gabled
  brown-striped roof and glass walls (#9DB6C0 reflections), the Mazowieckie (green-white-yellow) and SKM / ŁKA
  trains; the cutting's slopes are grassy with weeds.

## Open questions
- Exact stair/ramp from the street to the WKD platform (not in these photos): probably from the Al.
  Jerozolimskie / Towarowa corner at the deck's west end (~(-2385, 970)). Default: one stair there.

## Sources (photos stay on F's Mac in refs/wkd_ochota/, gitignored)

All photos are 1600 px thumbnails from Wikimedia Commons under free licences. What each shows: REPORT.md.

### 1.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Warszawa_Ochota_WKD.jpg
- Author: Jan Stradowski
- Licence: CC BY 3.0

### 2.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Warszawa_Ochota_train_station.03.jpg
- Author: Nenea hartia
- Licence: CC BY-SA 4.0

### 3.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Warszawa_Ochota_train_station.04.jpg
- Author: Nenea hartia
- Licence: CC BY-SA 4.0

### ortho.jpg
- Ortofotomapa, GUGiK (geoportal.gov.pl), WMS https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/HighResolution, layer Raster, bbox (lat/lon) 52.223424,20.986595,52.225776,20.990405, EPSG:4326, 3072x3072 px, ~260 m square, fetched 2026-11-02, open data
- Frame: game x = -2552.5 + px*0.0846, z = 909.4 + py*0.0846 (north up)
### ortho_north.jpg
- Ortofotomapa, GUGiK (geoportal.gov.pl), WMS https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/HighResolution, layer Raster, bbox (lat/lon) 52.225047,20.987072,52.226855,20.990003, EPSG:4326, 2857x2857 px, ~200 m square, fetched 2026-11-02, open data
- Frame: game x = -2520.0 + px*0.0700, z = 790.0 + py*0.0700 (north up)
