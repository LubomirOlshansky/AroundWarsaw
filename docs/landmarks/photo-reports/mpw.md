# Muzeum Powstania Warszawskiego (Elektrownia Tramwajów Miejskich): reference report

Gathered 2026-11-02 on F's Mac. Photos: 1.jpg, 4-27.jpg (25 files, sources and licences in SOURCES.md; 2 and 3 do not exist, the earlier set was 1/4/5/6/7).
Ortho: ortho.jpg + ortho.json (3072 px, 0.0846 m/px, north up). Game coordinates throughout: x east, z SOUTH, metres, origin 52.234 N / 21.024 E.
Ortho frame: `x = -3030.2 + px*0.0846`, `z = 35.9 + py*0.0846`.

**Read this first**
- The bbox in the brief (20.9810-20.9875 E) is shifted east: it starts at x = -2934 and cuts the museum in half. The ortho here uses 52.231324-52.233676 N, 20.979595-20.983405 E (x -3030..-2770, z 36..296), which holds the whole block with a margin.
- The ortho is off-nadir. Roofs of the 14-20 m buildings sit about 1.5-3 m north-west of their footprint (the hipped office block's roof overhangs its OSM outline on the NW side by about 2 m). Take footprints from OSM and the walls in photos; take roof shape and colour from the ortho.
- Positions are +-2 m unless marked. Heights are estimated from photos (storey about 4.5-5 m); only the OSM 14.2 m hall height is data.
- Pixel medians of the photos mixed mortar, shadow and sky, so brick/render colours below are chosen by eye from photos 6, 14, 15, 24 and 27 (sunlit midtone), not computed.
- Check images used while writing: OSM outlines drawn on the ortho showed the museum outline fits the roofs; the buildings west of Przyokopowa also fit (parallax only).

## (a) The power station: halls and wings

OSM outline "Elektrownia Tramwajów Miejskich" (index 2815 in centrum.json, h 14.2): (-2955.1,160.4) (-2948.9,160.0) (-2948.8,160.8) (-2936.8,160.2) (-2918.3,159.7) (-2918.1,158.2) (-2902.7,157.6) (-2902.5,163.9) (-2897.2,163.7) (-2896.6,179.9) (-2897.4,185.9) (-2895.5,202.9) (-2910.2,203.5) (-2910.2,202.3) (-2934.7,203.3) (-2933.8,232.2) (-2946.2,232.8) (-2946.1,233.6) (-2952.0,233.9), closing back to the start along the west wall at x about -2955..-2952. The footprint is an L: a long west leg (x -2955..-2934, z 160..234) and a block of halls to the east (x -2937..-2896, z 158..203).

Brick colour everywhere on the street front: warm orange-red, sunlit midtone **#B4553F**, shaded **#8A4A3C**, light buff mortar **#C8B79F**. Cream rendered bands, attics and blind arches **#D9CDB5** (shaded **#A79E8F**). Style: Romanesque-revival brickwork, round arches, corbel-table friezes, cream (plastered) arch infills.

| Part | Footprint (x, z) | Roof | Heights | Facade |
| --- | --- | --- | --- | --- |
| **W1 north brick tower block** (photos 1, 6, 14, 15) | x -2957..-2946, z 160..172 | flat behind a tall cream parapet ("attic", slopes to the street like a sheared lid), grey tar roof with one skylight | eaves 15 m, top of the cream attic about 19 m | 3 storeys of round-arched brick windows, 1.1 x 2.2 m, singles and one pair per floor on the west and north faces; a corbelled arch frieze under the cream attic (photo 15); city coat-of-arms relief with wings on the west face; brick quoins |
| **W2 long arcade hall** (photos 1, 6, 14) | x -2955..-2937, z 172..224 (about 52 m long) | flat/low tar roof behind a cream parapet, a grey light strip down the middle (x -2945..-2942), roof terrace railing on the west edge | eaves 14 m, cream attic to about 15.5 m | the main street front: ground floor of **small arched windows in groups of 2-3 (1.0 x 1.6 m) under shared arches**, a corbelled sill band, then **tall round-arched windows with iron fan glazing, about 2.4 x 5 m, 10-11 bays at about 4.5 m pitch**; two bays are blind (cream plastered arch infill, photo 6 centre-left and photo 14 centre); between bays brick piers with cream blind lancets in groups of 4-6 along the attic frieze; stepped gable (about 17 m) where the hall steps up at its mid-point (photo 6 centre) |
| **W3 south brick tower block** (photo 14 right edge) | x -2955..-2938, z 224..234 | flat, a glass roof light on top (photo 14) | eaves about 15 m, attic to about 17 m | narrower arched windows 3 per floor, cream attic with arch frieze, small brick wing at the south end (z 230..234) |
| **M1 middle hall, north bay** | x -2937..-2918, z 162..181 | standing-seam metal, hipped-gable with a round vent/chimney (-2930,171), ridge runs about E-W (uncertain: lit plane faces south) | eaves 12 m, ridge 16-17 m | seen from the yard: pale rendered walls, round-arched windows (photo 11 left, photo 27 left) |
| **M2 middle hall, south bay** | x -2937..-2910, z 181..203 | metal, hipped-gable with vent at (-2930,191), ridge E-W (uncertain) | eaves 12 m, ridge 16 m | long south wall to the lawn: pale render (**#A09B94**) with 5-6 tall round-arched windows (photo 8) |
| **E1 east hall, north** | x -2917..-2897, z 162..181 | metal, ridge E-W, **gable end facing the park**; round vent at (-2905,170) | eaves 12 m, ridge 17 m | east gable: pale render with a red (**#9A2A25**) steel grid frame painted on it, 5x4 panels (photo 8), a big door at ground (photos 8, 13) |
| **E2 east hall, south** | x -2915..-2896, z 181..203 | metal, ridge E-W, smaller gable to the park; tower base at its SE corner | eaves 11 m, ridge 15 m | same pale render with the red grid |
| **Low connecting wing** (north of the halls, between yard and halls) | x -2946..-2918, z 158..165 | flat/low dark roof (photo 11, ortho z_n bottom) | about 6-8 m | cream render, small arched windows in a row (photo 11 centre) |

Roof colours (ortho): all halls grey-blue standing seam, lit **#A5B5C0**, shaded **#596577**; the west leg roof (W2) is flat dark grey **#8F9396** with a pale light strip.

West annex: a flat-roofed white-render wing with rooftop plant sits just outside the OSM outline along Przyokopowa at about x -2961..-2953, z 176..214 (ortho z_s left edge) and a smaller one north of W1 around x -2960..-2948, z 148..160 (the white 4-storey wing with the red-white banners, photos 1 and 14; in deep shadow on the ortho, position unverified). OSM has neither.

**Entrances.**
1. Yard gate at the NW corner: black riveted steel double sliding gate about 6 m wide x 2.5 m high at about (-2958, 148..153), flanked by brick posts with pyramidal tile caps (photos 1, 21, 11). The Przyokopowa side is the visitor and staff entrance from the street.
2. Museum doors face the yard on the north wall of the halls at about x -2945..-2935, z 160 (round-arched door group under cream render, photos 10, 11, 27). The ticket pavilion KASA stands in the yard in front of it (see (d)).
3. The grey concrete portal frame (about 6 x 6 x 7 m, an open frame with a dark panel) in the yard near x -2938, z 158 is the way to the park side with a ramp; photos 21 and 27.

Chimneys: none standing on the halls in any photo or on the ortho; only the pinnacled stacks on the guardhouse (see (e)). Photos 19 and 20 (historic and 2013) were not inspected, look there if the original silhouette matters.

## (b) The observation tower

- **Where.** Base at the SE corner of the hall block, x -2905..-2898, z 191..199 (the LoD2 square matches the ortho: a steel cage with a glass floor and a glass skylight at (-2905..-2898, 190..198) is the top platform seen from above). Night photo 11 agrees: from the NW corner the tower stands over the hall, to the east of the brick tower block. The ortho object I first took for the tower at (-2946,156), a hollow 4 m square, is a lamp/AC frame, not the tower.
- **Height.** About 30 m to the platform floor, 32 m to the cage roof, flag pole to about 36 m (photos 8, 9, 11; the viewing cage sits on a cantilever).
- **Shape.** A reinforced-concrete shaft about 5 x 7 m. The south/east face is a **tapering wedge**: wide at the top where it carries the Kotwica, narrowing to the ground (photos 8, 9). The lower part is an open steel frame with stairs and a lift. At about 24 m a **steel viewing cage 8 x 8 m** overhangs: black steel mesh balustrade on a cantilevered platform, a closed black mesh cabin on top (about 3 m), a flag pole with the national flag.
- **Colour.** Concrete **#8A8A88**, steel and mesh black-brown **#2A2523**, Kotwica white **#F2F0EA**, flag white/red. At night the platform underside is lit blue-white (photo 11).
- **Kotwica.** Yes: the white Polish Underground State anchor ("PW", Kotwica), about 4 m high on the wedge face, facing east/south-east (photos 8, 9).

## (c) Freedom Park (Park Wolności) and the Wall of Remembrance

- **Wall of Remembrance (Mur Pamięci).** A long black granite wall with the names of the fallen, gently curved (photo 23). On the ortho it runs from about **(-2903, 141) to (-2858, 236)** (about 105 m straight, a dark line with a pale terrace beside it), with a retaining wall and steps starting further north at about (-2910, 129); south of z 236 it disappears under trees, so the full length (public sources say about 156 m, not verified here) would end near **(-2848, 255)**. Height **3.5-5 m** (the person in photo 23 stands at the foot and the wall is about 3x his height; I take 4 m), thickness about 0.6 m, **black granite #3A3B3D**, plates about 1.2 x 0.9 m with bolted rivets and white engraved names (photo 22). Bell recess: a rectangular opening about 1.8 x 2.2 m at about 2/3 of the way along (photo 22), holding the bell "Monter" (Dzwon Chruściela, dark bronze **#4A3F36**, about 1 m). A black low bench and a steel beam stand in front of the wall in the gravel plaza (photo 23).
- **Terrace on the museum side.** A pale paved strip 6-10 m wide along the wall (x -2900..-2885, z 160..205), granite paving in warm grey-pink **#B6B2AF** with ground lights, four low planter boxes (OSM has them as 4 tiny buildings at x -2886..-2878, z 181..213: they are planters, not buildings), a boulder at about (-2889, 198).
- **Path.** A pale gravel/asphalt footpath east of the wall (x -2890..-2868), meandering with planting between the wall and the lawn (ortho z_e). A cycle path and Towarowa lie further east at x -2860..-2850.
- **Gravel yard.** The big plaza south of the museum, x -2935..-2900, z 205..240, pale **#CFCECA**; photo 8 shows a gravel court in front of the pale hall, with rust-brown tree planters (**#7A3A28**), solar lamp posts, and trees (a large old multi-stem poplar at about (-2925, 205)).
- **Lawns.** Green lawn **#737E51** at x -2900..-2880, z 205..215 and a big lawn south of z 240; the dark brown-grey paved square at x -2890..-2860, z 212..250 (**#3B3D48**, in shadow) is a plaza with a pale tilted corner.
- **Objects.** Glass-and-steel photo screens ("cubes") in the park (photo 9, 8 right), a black granite monument with steps and a armoured-car replica at the wall's north end (photo 8 right), the Tobruk bunker, the B-24 Liberator replica, memorials to the Allied airmen and advocates (all in Commons subcategories, not located on the ortho). Pale temporary pavilion roofs at x -2890..-2865, z 125..140 (ortho z_e) are not in OSM. Tree rows: dense poplars/maples east of the wall, a hedge along the path.
- **Tobruk (Ringstand 58c).** OSM puts it at (-2926, 117), north of the hipped building; the ortho shows a small round feature with a dark centre there. The museum's own bunker was installed in Freedom Park in 2004 (plaque in photo 26); treat the OSM spot as unverified. A concrete Tobruk is a rounded shell about 3.5 x 2.5 m, top 0.5-0.8 m above ground with a round gun opening.

## (d) The hipped building at about (-2931, 130)

OSM index 2769, "yes", 14.2 m, x -2943..-2919, z 121..139. It is the **former administration/office building of the power station, now museum offices and education rooms** (Commons category "Office building of former Warsaw tram power plant"; photos 7, 12, 27).
- **Footprint.** A rectangle about 25 x 14 m rotated about 15 degrees (ridge from (-2943, 126) to (-2921, 121)); OSM's 15-point outline is fine.
- **Floors.** 4 storeys plus a usable attic, about 12.5 m to the eaves, ridge about 17 m.
- **Roof.** Hipped, **orange-brown tile** (lit slope about **#C9784A**, shaded north slope about **#6B4A3F**), 3-4 roof windows per slope on the south and north, small gable dormers at the corners (photos 7, 12, 27), brick chimneys with tile caps.
- **Walls.** Red brick **#B4553F** with **cream-grey rendered vertical strips** (pilaster-like bands, **#A8A29A**) running the full height between window columns, brown windows **#4A3A32** with brick sills and arched heads on the top floor, a gable-end pediment in render on the narrow end (photo 12).
- **Colour on the ortho:** the roof reads orange (south slope) and dark grey-brown (north slope); it is the only warm roof in the block.

## (e) Fences, gates and the small buildings

- **Przyokopowa fence** (photos 1, 6, 14, 21): brick wall **1.2 m** high with a cream stone coping and pinnacled brick **posts every 6-7 m** (0.5 m square, 2.4 m high, pyramid tile caps, a cream inset panel), black iron railings **1.2 m** on top (total about 2.7 m). Runs along x about -2958 from z 148 to z 235, and returns along Grzybowska at the north end.
- **Gates.** Black riveted steel gate (see (a)), brick gate posts 3.5-4 m with tile caps; a smaller pedestrian gate beside it. The yard is closed by metal railings against the park.
- **Guardhouse (portiernia)** (photos 21, 11): single storey, brick with dark sheet-metal gable roof, **ridge about 6.5 m**, two-step stepped chimney pinnacles with tile caps, a bronze plaque; OSM index 2817, x -2959..-2950, z 142..148. It stands at the gate right behind the fence.
- **Ticket pavilion KASA** (photo 10): brick gabled pavilion with three blind arches over the door, about 6 x 10 m, 5.5 m ridge. OSM index 2816 "retail" at x -2912..-2904, z 139..151 is the most likely match (its roof reads grey-blue on the ortho); verify when modelling.
- **Yard paving** pale grey granite sett **#C0C2BD**; a cobble yard in the front of the hall (photos 10, 27).

## (f) Roof colours from the ortho (lit / shaded)

| Roof | Lit | Shaded |
| --- | --- | --- |
| Hipped office block, S slope | #C9784A | |
| Hipped office block, N slope | | #6B4A3F |
| Halls M1, M2, E1, E2 (grey-blue metal) | #A5B5C0 | #596577 |
| W2 long hall (flat) | #8F9396 | #6E7276 |
| Pavilions (KASA, guardhouse) | #8D97A0 | |
| Tower platform glazing | #77858F | |
| Yard paving | #C0C2BD | |
| Plaza S of the museum | #CFCECA | |
| Terrace by the wall | #B6B2AF | |
| Lawn | #737E51 | |
| Dark paved square | #3B3D48 | |

## (g) Neighbours in the bbox that look wrong against OSM

- **Planters as buildings:** four 4.3 m "yes" buildings at x -2886..-2878, z 181..213 (OSM 9688-9691) are the wall terrace's planters/low benches. Remove or swap for props.
- **No outline for a real roof:** pale temporary pavilion roofs at x -2890..-2865, z 125..140, and a pale flat roof at x -2868..-2852, z 283..300 (the left of two adjacent roofs south of the park; the right one has an outline at x -2851..-2841, z 285..320 that runs as a long thin triangle down to z 320, a bad polygon).
- **West annex and white wing** (see (a)) missing from OSM.
- **Hipped office block**: outline right, but the OSM height (14.2) is a mean; use eaves 12.5 / ridge 17.
- **Building at x -3016..-2979, z 130..193** (OSM 4209, office 24.1 m) west of Przyokopowa: footprint matches the northern roof, parallax only; the southern roof at x -3003..-2977, z 190..226 is covered by 6834 (apartments 20.8 m), also OK.
- **Bellona** (x -2800..-2763, z 99..156) and the buildings at the top left (x -3016..-2969, z 28..98) match their roofs.
- **Road and rail:** Towarowa (x -2860..-2850), the tram track at x -2845..-2830 and Grzybowska (z 95..110) are on the ortho and agree with the map; Przyokopowa carriageway sits at x -2975..-2962.

## Sources (photos stay on F's Mac in refs/mpw/, gitignored)

All photos are 1920 px (1600 px thumbnails are not offered by Commons; 1920 is the nearest allowed thumbnail size, a few small originals are kept at their own size) from Wikimedia Commons under free licences. Fetched 2026-11-02. Files marked "from title" were not inspected in detail. What matters for modelling: REPORT.md.

### 1.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Muzeum_Powstania_Warszawskiego_2023.jpg
- Author: Adrian Grycuk
- Licence: CC BY 3.0 pl
- Shows: Przyokopowa 28, west facade seen from the north corner looking south: brick tower block with cream attic and stepped gable at the north end, white 4-storey wing with red-white banners, arcaded hall behind the pinnacled brick fence, black steel gate (very good for facade rhythm and brick colour). Viewed from the W/NW.

### 4.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:The_Observation_Tower_of_the_Warsaw_Uprising_Museum.JPG
- Author: Ivanevian
- Licence: CC BY-SA 4.0
- Shows: Observation tower, top part: grey concrete shaft, steel viewing cage (from title; not inspected closely). Viewed from the yard side.

### 5.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Muzeum_Powstania_Warszawskiego_2020.jpg
- Author: Adrian Grycuk
- Licence: CC BY-SA 3.0 pl
- Shows: Street front on Przyokopowa, 2020 (from title and earlier report). Viewed from the W.

### 6.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Budynek_Muzeum_Powstania_Warszawskiego_2017.jpg
- Author: Adrian Grycuk
- Licence: CC BY-SA 3.0 pl
- Shows: Przyokopowa west facade from the north-west corner at a wide angle: brick tower block at the right, the whole arcade (about 14 bays, two tiers of arched windows, cream attic band), fence with pinnacled posts. Best single facade photo. Viewed from the W/NW.

### 7.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Muzeum_powstania_warszawskiego_z_wtt.jpg
- Author: Panek
- Licence: CC BY-SA 4.0
- Shows: Aerial from the Warsaw Trade Tower looking south-west: full roof layout, hipped red-tile office block nearest, the hall roofs, tower with cage at the far end, Wall of Remembrance on the left (east) edge, lawns. Viewed from above NE.

### 8.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Warszawa-MPW.jpg
- Author: Marcin Białek
- Licence: CC BY-SA 3.0
- Shows: Freedom Park from the south-east: pale rendered east/south hall facades with round-arched windows and red grid lines on the gable ends, steel-and-glass photo screens, wall path on the right, gravel yard, tower rising behind the roofs. Viewed from the S/SE.

### 9.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Muzeum_Powstania_Warszawskiego_(4469925313).jpg
- Author: VnGrijl from Warsaw, Poland
- Licence: CC BY 2.0
- Shows: Observation tower close up from the park side: grey concrete shaft with the white Kotwica (Polish Underground State anchor) on a tapering wedge face, black steel-mesh cage and balcony, flag on top; glass-and-steel photo cubes in front. Viewed from the E.

### 10.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Muzeum_Powstania_Warszawskiego1.jpg
- Author: Bialo-zielony
- Licence: CC BY 4.0
- Shows: Yard behind the gate: brick ticket pavilion KASA (gable with three blind arches), arcaded brick hall wing on the right, cobbled yard, dark granite wall panel behind. Viewed from the north (yard side).

### 11.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Muzeum_Powstania_Warszawskiego_Noc_Muze%C3%B3w_2013.JPG
- Author: Adrian Grycuk
- Licence: CC BY-SA 3.0 pl
- Shows: Night view from the Grzybowska/Przyokopowa corner: hipped office block floodlit red, brick guardhouse with dark roof at the gate, tower with lit cage and flag over the hall, brick tower block and arcade lit red. Viewed from the NW.

### 12.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Warsaw_Uprising_Museum,_Skyline,_1.jpg
- Author: Wistula
- Licence: CC BY-SA 4.0
- Shows: Hipped brick office block (north-end gable, brick with rendered pilaster strips, tile roof) with the Warsaw Spire behind; brick fence with iron railings and pinnacled posts in front. Viewed from Grzybowska looking south.

### 13.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Warsaw_Uprising_Museum,_Skyline,_2.jpg
- Author: Wistula
- Licence: CC BY-SA 4.0
- Shows: Second skyline shot from Grzybowska (from title; not inspected closely). Viewed from the N.

### 14.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Varsovie_-_Mus%C3%A9e_de_l%27insurrection.jpg
- Author: Mith
- Licence: CC BY-SA 4.0
- Shows: Przyokopowa facade seen from the north-east across the street (2015): brick tower block, the long arcade, the second smaller brick tower block at the south end with a roof light, cream attic. Viewed from the NW/N.

### 15.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Warszawa-tower_of_Uprising_Museum.jpg
- Author: Mariochom
- Licence: CC BY-SA 4.0
- Shows: Corner of the brick tower block from below: cream rendered attic, corbelled arch frieze, round-arched windows with brick archivolts, city coat of arms with wings relief, street lamp. Viewed from the W (street level).

### 16.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Wie%C5%BCa_w_Muzeum_Powstania_Warszawskiego_-_panoramio.jpg
- Author: Arek N.
- Licence: CC BY-SA 3.0
- Shows: Observation tower (panoramio, 2009; from title, not inspected closely).

### 17.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Przyokopowa_Muzeum_Powstania01.jpg
- Author: Łeba
- Licence: CC BY 3.0
- Shows: Przyokopowa fence and guardhouse, 2004, before restoration (from title, not inspected closely). Viewed from the W.

### 18.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Przyokopowa_Muzeum_Powstania03.jpg
- Author: Łeba
- Licence: CC BY 3.0
- Shows: Przyokopowa wall, 2004 (from title, not inspected closely). Viewed from the W.

### 19.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Gmach_Elektrowni_Tramwajowej_w_Warszawie_przed_1950.jpg
- Author: nieznany/unknown
- Licence: Public domain
- Shows: Historical photo of the power station building before 1950 (from title; public domain). Useful for the original roof shapes and chimney.

### 20.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Warszawa,_zesp%C3%B3%C5%82_Elektrowni_Tramwaj%C3%B3w_Miejskich.JPG
- Author: VinceB
- Licence: CC BY-SA 3.0 pl
- Shows: Power station complex, 2013 (from title, not inspected closely).

### 21.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Portiernia_elektrowni_tramwaj%C3%B3w_warszawskich.jpg
- Author: Panek
- Licence: CC BY-SA 4.0
- Shows: Guardhouse (portiernia) at the Przyokopowa/Grzybowska gate: low brick building with dark sheet-metal gable roof, stepped chimney pinnacles, plaque, pinnacled fence posts, iron railings; concrete portal frame and the pale hall behind. Viewed from the W (street).

### 22.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Warsaw_Memorial_Wall.JPG
- Author: Monikoska
- Licence: CC BY 3.0
- Shows: Wall of Remembrance close: black granite plates with names, bell in a rectangular recess (Dzwon Chruściela), pink paving path with ground lights, flats in the background. Viewed from along the wall.

### 23.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Muzeum_Powstania_Warszawskiego_panorama.jpg
- Author: User:Darwinek
- Licence: CC BY-SA 3.0
- Shows: Wall of Remembrance panorama: gently curved black wall about 3 m high, low black bench and steel beam in front, gravel plaza, bell recess, big trees at the right. Viewed from the E/SE.

### 24.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Warszawa_8390.jpg
- Author: User:Darwinek
- Licence: CC BY-SA 3.0
- Shows: Close-up of the plaque on brick (true brick colour: orange-red, light buff mortar). Viewed from the W.

### 25.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Dzwon_Chru%C5%9Bciela_MPW_beax.jpg
- Author: Beax
- Licence: CC BY-SA 2.5 pl
- Shows: The bell in the wall (Dzwon Chruściela) (from title, not inspected closely).

### 26.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Warsaw_MPW_Tobruk_00.jpg
- Author: Halibutt
- Licence: CC BY-SA 3.0
- Shows: Tobruk bunker information plaque (the bunker itself is a small round concrete shelter with a gun opening); plan and section of a Ringstand 58c.

### 27.jpg
- Commons page: https://commons.wikimedia.org/wiki/File:Czyste,_Warsaw,_Poland_-_panoramio_(21).jpg
- Author: Roman Eugeniusz
- Licence: CC BY-SA 3.0
- Shows: Yard from a roof: the hipped red-tile office block on the right (brick with rendered strips, roof windows), KASA pavilion in the middle, concrete portal frame with ramp, grey metal-roofed wing on the left. Viewed from the S (yard) looking N/NE.

### ortho.jpg
- Ortofotomapa, GUGiK (geoportal.gov.pl), WMS https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/HighResolution, layer Raster, bbox (lat/lon) 52.231324,20.979595,52.233676,20.983405, EPSG:4326, 3072x3072 px, ~260 m square, fetched 2026-11-02, open data
- Frame: game x = -3030.2 + px*0.0846, z = 35.9 + py*0.0846 (north up)
