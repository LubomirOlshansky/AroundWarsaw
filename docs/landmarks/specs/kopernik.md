# Centrum Nauki Kopernik: spec

Site key `kopernik` in `game/scripts/landmarks.gd` (`_find_kopernik`, `_build_kopernik`,
`_kop_front`, `_kop_frame`, `_kop_cantilever`, `_kop_roof`, `_kop_crater`, `_kop_planet`).
Written 2026-11-01 in a cloud thread from the OpenStreetMap outlines and parts in `centrum.json`
and GUGiK's LoD2 roof (flat, 13 m over the street), then corrected the same day from the Mac's
photo check against the reference photos in `refs/` (shots `kop_*.png` in that session). The
values still marked *(photo check)* are the ones nobody has compared yet.

## 1. Identity

The Copernicus Science Centre (RAr-2, opened 5 November 2010) on Wybrzeże Kościuszkowskie, over
the Wisłostrada tunnel, and its planetarium (June 2011) on the river side. What makes a
passer-by say its name:

1. **The long block in warm vertical strips**: 140 m of panel strips in dusty rose, beige-grey,
   grey and a few copper-red, cut by tall slits and multi-storey glazed bays, some slanted.
2. **The copper-red planetarium**: a faceted drum of rusty perforated metal, as big as the
   block, its roof edge level with the block's, a white dome in the middle.
3. **The roof garden**: meandering light paths round mixed beds, with concrete skylight
   craters, a teal glass strip and a small glass pavilion.
4. **The dark cantilever** on the planetarium's side, over a court.
5. **At night**: the slits and bays lit, the planetarium's clerestory ring glowing.

## 2. Massing

World plan (x east, z south), heights over the street on the city side (the highest ground
under the outline, about -12.6 m; the river side lies 4 m lower).

| Volume | Plan | Heights | Source |
| --- | --- | --- | --- |
| Block | the outline less the low wings, straightened 0.8 m: x 259..379, z -950..-786 | ground to 13 m | OSM outline, LoD2 roof |
| River corner | OSM part x 325..369, z -950..-904 | soffit 5 m over its own ground, to 13 m | OSM part h 7.6, mh 3.3 (kept, parked) |
| Cantilever | 12 m out of the block's longest front facing the planetarium, 3 m short of its ends, clear of the planetarium by 3 m | 8 m to 13 m | Mac photo check |
| West wing, link | OSM parts x 253..272 / 329..363 | ground to 4.5 m over the street | OSM parts h 4.3 |
| Planetarium | its outline (convex), about 44 x 38 m | walls leaning in 5 % to 13.8 m over the street (about 17.8 m over its own ground), chamfer to +0.9, clerestory 1.6 m, dome 5.5 m more | Mac photo check |

## 3. Facade, base to top

- **Block fronts**: vertical strips 1.5-4 m wide from below the ground to the roof, each a tone
  from the palette (one in a dozen copper-red); a steady hash per front and strip.
- **Openings** (7 cm proud, dark glass, lit at night, M_PAVILION): about one strip in five has
  a 0.6 m slit from 1.2 m over the local ground to 1.4 m under the roof; about one in eight
  (2.6 m or wider) a glazed bay over several storeys, half of them leaning (rhomboid).
- **South-east end** (facing the car park): all glass (lit), and in front of it a light steel
  frame: posts every 4 m 2.4 m out, two galleries (4.6 and 9 m) and two flights of stairs
  *(photo check: where the flights run)*.
- **Cantilever**: dark (#3f3936), a band of dark glass along its face, its soffit lighter.
- **River corner**: as before, a glazed ground floor under the hanging corner.
- **Low wings**: glass all round, paved roofs. **Parapet**: 0.9 m.
- **Planetarium**: facets alternating two coppers, leaning in.

## 4. Roof

Flat at 13 m, paved light grey (the paths). Inset 3 m: two meandering paths along the block
and six across it (2.6 m wide, sine-wave lines) cut the garden into beds 0.4 m high with a kerb,
each a colour from mixed greens, ochre and dark shrub. Seven skylight craters (KOP_CRATERS: two
in the north third, three in the middle, two in the south), octagons 9-15 m across of beige
concrete sloping 1.6 m up to a flat rim round a dark glazed opening, the fourth with a glazed
pyramid; each placed in the garden's width at its spot along the block, smaller where the
garden is narrow, left out where under 9 m fits (five are built today). A teal glass strip
along the city side of the southern half (3.6 m wide, 0.9 m high); a glass pavilion near the
south end (7 x 5 m, 3.4 m). The planetarium's top: a chamfer up 0.9 m to a flat copper ring,
the clerestory's glass ring (radius 9.6 m) and the white dome (8.5 m radius, 5.5 m high,
faceted like the drum).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Block strips | #9b7d78 #c8beb3 #8f8984 #a8908a #bdb2a6 #87736e #b49f97, copper #a24a36 | M_STONE |
| Slits, bays, cantilever glass | #3b4347 | M_PAVILION |
| Glass walls (wings, SE end, under the corner, pavilion, clerestory) | #8fa3a8 | M_PAVILION |
| Steel frame | #d9dad6 | M_STONE |
| Cantilever | #3f3936 | M_STONE |
| Parapet, soffits, pavilion roof | #7d6f6a | M_STONE |
| Roof paths | #c2bfb7 | M_STONE |
| Beds | #6f9a4c #87a659 #b39a5a #4f6b3a #7ea052, kerbs #9c968b | M_STONE |
| Craters | #d3c9b6, opening #2f3a40 | M_STONE, M_GLASS_ROOF |
| Teal strip | #5f9c98 | M_GLASS_ROOF |
| Planetarium | #a24a36 / #8e3b2c, chamfer #6f2e24, dome #eeeeea | M_STONE |

No new material, no draw call of its own. The far skyline proxy takes #a8958c (`tower_colour`).

## 6. Ground and night

The squares, the boulevard, the tunnel and the ramps stay the map's; the court under the
cantilever is the map's paving *(photo check: light paving there)*. The car collides with the
centre's outline and the planetarium's. The dog's ball (egg "Aport") lands on the roof's
highest flat spot (the pavilion's roof). At night the slits, bays and glass walls glow, the
planetarium's clerestory ring glows faintly, its copper takes the boulevard's lamps. Card:
"Centrum Nauki Kopernik", PL "Otwarte w 2010 roku. Ogród na dachu, obok miedzianoczerwone
planetarium.", EN "Opened in 2010. A roof garden, the copper-red planetarium beside it."

## 7. Detail level and budget

L2, triangle budget 1720 (1428 measured, plus about 20 %, in `check_mesh_quality.gd` BUDGET).
Shots: `--solo=kopernik --solo-look=flat` and `sil` (the `first` set), then in the city by day
and night from the river side.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| strips | wall pieces | 1.5-4 m wide, ground to 13 m | every front | M_STONE palette | 1 warm strips |
| openings | 7 cm panes, some rhomboid | slits 0.6 m, bays 2-3 m, several storeys | the strips | M_PAVILION #3b4347 | 1, 5 night |
| se_end | glass wall + steel frame | posts every 4 m, 2 galleries, 2 stairs | the south-east end | M_PAVILION, M_STONE #d9dad6 | 1 |
| cantilever | prism with soffit | 12 m deep, 8-13 m | the planetarium's side | M_STONE #3f3936 | 4 cantilever |
| corner | mapped corner over a glazed floor | 5-13 m | the river corner | M_STONE, M_PAVILION | 1 |
| wings | 2 mapped glass prisms | 0-4.5 m | the city corner, the link | M_PAVILION | 5 night |
| garden | beds between meandering paths | 0.4 m, 2 paths along, 6 across | the roof, inset 3 m | M_STONE beds | 3 roof garden |
| craters | octagonal frustums | 9-15 m across, 1.6 m | the roof | M_STONE #d3c9b6, M_GLASS_ROOF | 3 roof garden |
| strip_pavilion | glass prism, glass box | 3.6 m x 0.5 of the block; 7 x 5 x 3.4 m | the roof's south half | M_GLASS_ROOF, M_PAVILION | 3 roof garden |
| planetarium | leaning faceted drum, chamfer, ring, clerestory, dome | 44 x 38 m, to 13.8 m over the street + dome | its outline | M_STONE coppers, M_PAVILION, dome #eeeeea | 2 copper drum, 5 night |
