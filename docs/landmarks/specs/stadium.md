# Stadion Narodowy: spec

Site key `stadium` in `game/scripts/landmarks.gd` (`_find_stadium`, `_build_stadium`, `_beam`;
the skin's weave is `weave()` in `shaders/building.gdshader`). Written 2026-11-01 in a cloud
thread from the OpenStreetMap parts in `centrum.json` (the stadium is mapped in 3D: 72 pairs
of masts, the skin in ten stacked rings with their colours, the roof rim, the roof, the upper
tier's sectors, the hub, the folded roof and the needle, all with heights) and the earlier
model. The reference photos in `refs/` live on the Mac and were not reachable from the cloud:
the values marked *(photo check)* are the ones the side-by-side check on the Mac should
confirm or move.

## 1. Identity

Gerkan, Marg und Partner's national stadium (opened 2012 for Euro 2012) on the Praga bank, in
the bowl of the old Tenth-Anniversary Stadium's embankment. What makes a passer-by say its
name:

1. **The basket in the flag's colours**: a skin of red and silver mesh panels in staggered
   rows, leaning out from the embankment to the roof, red below and white above.
2. **The ring of masts**: 72 slim white masts leaning out with the skin and spiking above
   the roof's rim.
3. **The white roof round an open middle**: a membrane ring sloping down from a raised rim to
   a rounded-rectangle opening over the pitch.
4. **The needle**: a white spindle hanging over the pitch on cables, the folded roof stored
   in a drum on it, a red light on its tip.
5. **Inside, seen through the opening**: two tiers of red seats round a striped pitch.

## 2. Massing

World plan (x east, z south, metres). Centre (1480.5, -605.1), the mean of the 72 inner
masts. Heights over the street round it (the lowest terrain at 1.25 x the outer masts'
radius); the pitch at the terrain under the centre.

| Volume | Plan | Heights | Source |
| --- | --- | --- | --- |
| Inner masts (feet) | 72, radius 121.7 to 142.5 | 0 to 50 m | OSM parts h 50 |
| Outer masts (spikes) | 72, radius 131.2 to 152.2 | 44 to 60 m | OSM parts h 60, mh 44 |
| Skin | from 0.965 x the inner masts' radius at the crest to 0.62 of the way to the outer masts | crest to 41 m, belly at 45 % | OSM rings 22-44 m, 269 x 286 to 289 x 307 m |
| Roof rim | 1.5 m outside the outer masts | 42.4 to 46.2 m | OSM ring h 46.2, mh 44 (292 x 308 m) |
| Roof membrane | from 1.5 m inside the outer masts to the opening | 44 m falling to 40.5 m | OSM roof h 44.5 |
| Opening | rounded rectangle 140 x 108 m (power 4) along the pitch | 40.5 m | OSM 133 x 146 m blue part at 44.6 (the closed roof) |
| Upper tier | from a rounded rectangle 162 x 124 m to 0.86 x the inner masts' radius | 19 to 38.5 m | OSM steps h 38.5, mh 19 |
| Boxes | rounded rectangle 162 x 124 m | 13 to 19 m | between the tiers |
| Lower tier | rounded rectangle 122 x 84 m to 156 x 118 m | 1.4 to 13 m | the pitch with its run-off |
| Pitch | 105 x 68 m inside a 122 x 84 m grass rim, along the masts' principal axis | 0.4 m | FIFA size |
| Hub | 10-sided ring, 15.6 m across | 37 to 43 m | OSM part h 43, mh 37 |
| Folded roof | 10-sided drum, 21 m across, cones above and below | 51.5 to 63.5 m | OSM part h 63, mh 55 |
| Needle | 10-sided spindle, 2 m at the hub to 0.6 m at the tip | 30 to 100.5 m | OSM part h 100, mh 30, red top |

## 3. Facade, base to top

- **Promenade (crest)**: a paved ring on the old embankment's crest, 0.96 to 1.17 x the inner
  masts' radius, in two greys every three masts.
- **Concourse (crest to 7.5 m)**: a dark glass curtain wall with lighter mullions (M_GLASS
  #2b3440), set back behind the masts' feet at 0.935 x their radius (Mac photo check
  2026-11-01).
- **Skin (7 m over the crest to 41 m)**: two bands (the lower one leaning out, the upper one
  leaning out more and tipped down) of M_WEAVE: mesh panels 3.2 x 1.6 m in staggered rows
  (each row shifted half a panel), thin dark joints. Each panel is red or light silver
  (#cfd1d0); silver more often the higher it is, a smooth ramp with no all-of-one-colour
  band: about 17 % at the foot, half at 60 % of the height, 88 % at the top (Mac photo check
  2026-11-01: the first pass's diagonal diamonds and its red-to-white split at 21-35 m were
  off; the real panels are horizontal rectangles).
- **Masts**: square white beams 0.55 m, from the inner mast's foot to the outer mast's tip at
  60 m, crossing the skin; over the rim each spike is a 1 m beam (the street silhouette).
- **Roof rim (42.4-46.2 m)**: a vertical light grey band over the skin, its top 2.2 m over the
  membrane, its inside sloping down to the membrane; its soffit back to the skin's top.

## 4. Roof

The fixed roof: a white membrane in 72 panels (two tones in turn, the radial cables' rhythm)
falling from the rim's inner foot at 44 m to the opening at 40.5 m; its last 7 m before the
opening are grey-blue polycarbonate (#8f9aa3 / #98a2aa). The opening's size and axis were
confirmed on the Mac (2026-11-01). The opening is a rounded
rectangle along the pitch (the retractable roof, stored in the needle's drum, is open). The
needle hangs at the centre: the spindle from 30 m, the dark hub ring at 37-43 m where 24
cables from the opening's edge meet, the white drum of the folded roof at 55-61 m (cones to
51.5 and 63.5 m), the spindle on up to 99 m and a red light to 100.5 m. The old model's four
dark cables from the hub across the membrane to the rim are gone (they read as cracks).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Skin | red #c71f29, silver #cfd1d0, joints #29262b (shader) | M_WEAVE |
| Concourse glass | #2b3440 | M_GLASS |
| Polycarbonate ring | #8f9aa3 / #98a2aa | M_MEMBRANE |
| Masts, spikes | #e4e6ea, #f2f3f5 | M_STONE |
| Promenade | #cbc6ba / #c3beb2 | M_STONE |
| Rim | outside #dcdee2, inside #c9ccd1, soffit #9da1a8 | M_STONE |
| Membrane | #f4f4f1 / #eaebe8 | M_MEMBRANE |
| Seats | #c42a31, aisles 25 % lighter | M_STONE |
| Gangway, boards, boxes | #8e8a88, #2d3138, #3d4652 | M_STONE |
| Pitch | #4f8a3a, stripes #5a9643, lines #f2f2ee | M_STONE |
| Hub | #2c2d31, top #3a3b40 | M_STONE |
| Needle, drum | #f1f1ee, #e6e7e4 | M_STONE |
| Tip light | #ff3b30 | M_LAMP |
| Cables | #c8cbd0 | M_STONE |

No new material, no draw call of its own: everything goes into the city's building surface.

## 6. Ground and night

The embankment round the promenade stays the map's terrain with its mapped surfaces (BACKLOG:
bare in places). The car collides with the skin's foot ring. At night the skin glows from
inside (the red strips more, the white ones catch the light), the membrane gives a faint warm
glow and the needle's tip is red. Card (kept): "Stadion Narodowy", PL "Otwarty w 2012 roku na
Euro 2012, w misie dawnego Stadionu Dziesięciolecia. Biało-czerwona plecionka fasady.", EN
"Opened in 2012 for Euro 2012, in the bowl of the old Tenth-Anniversary Stadium. A
red-and-white woven skin."

## 7. Detail level and budget

L3 (a hero: the skyline over the river and the race finish), triangle budget 4750 in
`check_mesh_quality.gd` (3958 measured plus 20 %; raised from 3470 on purpose for the photo
check's parts: the spikes 576, the concourse glass 144, the polycarbonate ring 144. The bowl
720, the masts 576, the skin 288, the roof 432, the promenade 432, the pitch and its lines
about 90, the needle and cables about 400). Shots: `--solo=stadium --solo-look=sil` and `flat` (the
`first` set), then in the city at day and night from the west.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| skin | 2 bands of 72 quads | 0.965 x inner radius to 0.62 inner-to-outer, crest + 7 m to 41 m | round the bowl | M_WEAVE | 1 woven basket |
| masts | 72 square beams | 0.55 m, foot to 60 m | inner mast to outer mast | M_STONE #e4e6ea | 2 ring of masts |
| spikes | 72 square beams | 1 m, rim to 60 m | the masts' tops | M_STONE #f2f3f5 | 2 ring of masts |
| concourse | 72 glass quads | crest to 7.5 m | 0.935 x inner radius | M_GLASS #2b3440 | 1 woven basket |
| polycarbonate | 72 sloping quads | 7 m wide | the opening's edge | M_MEMBRANE #8f9aa3 | 3 white roof |
| promenade | 3 rings of 72 quads | 0.96 to 1.17 x inner radius | the crest | M_STONE #cbc6ba | 1 woven basket |
| rim | 72 x (face, slope, soffit) | 42.4 to 46.2 m | 1.5 m outside the outer masts | M_STONE #dcdee2 | 3 white roof |
| membrane | 72 sloping quads | 44 to 40.5 m | rim to opening | M_MEMBRANE #f4f4f1 | 3 white roof |
| bowl | 5 rings of 72 quads | 122 x 84 m to 0.86 x inner radius, 0.4 to 38.5 m | under the roof | M_STONE #c42a31 | 5 seats |
| pitch | grass cap, 6 stripes, 25 line quads | 105 x 68 m in 122 x 84 m | the centre, along the principal axis | M_STONE #4f8a3a | 5 pitch |
| hub | 10-sided prism | 15.6 m, 37 to 43 m | the centre | M_STONE #2c2d31 | 4 needle |
| drum | 10-sided frustums | 21 m, 51.5 to 63.5 m | the centre | M_STONE #e6e7e4 | 4 needle |
| needle | 10-sided frustums | 2 to 0.6 m, 30 to 99 m | the centre | M_STONE #f1f1ee | 4 needle |
| tip | 10-sided prism | 0.9 m, 99 to 100.5 m | the needle's tip | M_LAMP #ff3b30 | 4 needle |
| cables | 24 thin beams | 0.18 m | hub to the opening's edge | M_STONE #c8cbd0 | 4 needle |
