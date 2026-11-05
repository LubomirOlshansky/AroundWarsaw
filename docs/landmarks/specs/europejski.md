# Hotel Europejski: spec

Site key `europejski` in `game/scripts/landmarks.gd` (`_build_europejski`, helpers `_euro_*`). Written 2026-11-03 in a cloud thread from F's photos (online photos, reference only, never shipped: the Krakowskie Przedmieście front square on at dusk, the north-east corner close up, a three-quarter street view and two aerials), with `refs/krakowskie/` photos 28-29 (report `docs/landmarks/photo-reports/krakowskie.md`), the OSM outline and the GUGiK LoD2 heights from the CI map pack. It replaces the 2026-10-31 model (a pilaster box under a grey-green hipped roof).

## 1. Identity

Enrico Marconi's Hotel Europejski (1857-1877), Krakowskie Przedmieście 13, restored and reopened in 2018 as it stands today: a cream four-storey block round a courtyard, between Krakowskie Przedmieście (east), Ossolińskich (north), Plac Piłsudskiego's side (west) and the south lane. Card "Hotel Europejski". The hotel operator's brand is never shown; the front's own HOTEL EUROPEJSKI plaque is.

## 2. Massing

Plan: the outline's four straight fronts (OSM lines, corners where they meet: NE (-615.4, -914.0), SE (-587.8, -854.6), SW (-673.8, -833.9), NW (-689.0, -895.7)); fronts 65.5 m (Krakowskie), 88.5 m (south), 63.7 m (west), 75.8 m (north). Every corner rounded at 6.5 m (front photo: ~13 m corner pavilions on the 65 m front) in five facets; the bow sits up to 1.2 m inside the mapped corner. Heights from LoD2 (ground ~8 m, eaves ~28 m, roof top ~33-34 m) and the front photo's proportions: ground floor to 7.2 m, first floor to 12.4 m, second balcony 13.4 m, cornice 19.4-20.0 m, attic to 21.5 m, roof storey to 25 m. Wings 14 m deep round a courtyard roofed in glass at 8.5 m (LoD2's courtyard roofs 7-10 m).

## 3. Facade, base to top

- Ground floor: six rusticated courses; tall round-arched shop windows (2.3 m wide, to 5.6 m) on every other bay with a door and a small window over it between them; one arch in each pavilion and in each bow's middle facet.
- String course at 7.2 m. First floor: a balustrade panel under each window, the window, a cap and a triangular pediment (photo: 11 bays on Krakowskie, 3.6 m). The plaque band with HOTEL EUROPEJSKI in warm gold letters over the middle bays of the Krakowskie front only.
- Second floor: windows with flat caps; third floor: small square windows under the cornice.
- Corner pavilions: each bow has six Corinthian columns per tier (hexagonal shafts, flared capitals) standing 0.55 m off the wall, arched windows between them, a curved balcony with a balustrade at 7.2 m and another at 12.45 m; the straight part of each pavilion has a pair of columns at its inner end and an arched window per storey.
- String course at 12.4 m, frieze under the cornice, cornice 0.7 m proud.

## 4. Roof

A balustrade attic (plinth, the balusters' shade, rail; a die at every bay joint) on the cornice. Behind it, 1.7 m back, the dark louvred glass roof storey following the plan with its rounded ends, its top curving in over 1.3 m to a flat lead top; it faces the courtyard too. Courtyard walls in stone with windows (M_MONUMENT), its glass roof low.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls | #eeeae0 | M_STONE |
| Rusticated courses | #e4dfd2, alternate darkened | M_STONE |
| Trim, columns, balconies | #f6f3ea | M_STONE |
| Balusters' shade | #cfc8b8 | M_STONE |
| Windows | #3a3f47 | M_GLASS |
| Shop windows | #4a4036 | M_GLASS |
| Roof storey | #262b2b | M_GLASS, curve M_STONE |
| Roof top | #8d918e (cornice), #66746f (roof storey), #a39d92 (courtyard) | M_STONE |
| Plaque letters | gold (1.0, 0.8, 0.45) | landmark sign |

## 6. Ground and night

The pavements, lamps and bus stop are the map's. The car meets the mapped outline. At night the window glass (M_GLASS) lights in places, the shop arches warm; the plaque's letters glow. Only the phone can show the louvres' read at play zoom.

## 7. Detail level and budget

L3, triangle budget 8000 (built 7324).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| courses | ring prisms | 6 x 1.3 m | 0-7.2 m | M_STONE #e4dfd2 | rusticated ground floor |
| walls | ring prism | 7.2-19.4 m | plan | M_STONE #eeeae0 | stone fronts |
| shop_arches | arch panels | 2.3 x 5.6 m | every other bay, pavilions, bows | M_GLASS #4a4036 | arched shop windows |
| windows | panes with surrounds | 1.0-1.25 m wide | every bay, three floors | M_GLASS #3a3f47 | the floors' windows |
| pediments | triangles, ledges | 1.9 x 0.6 m | first floor | M_STONE #f6f3ea | pedimented windows |
| columns | hex shafts, flared capitals | r 0.32-0.34 m | bows, pavilion ends | M_STONE #f6f3ea | Corinthian tiers |
| balconies | slabs, balustrades | 1.0 / 0.8 m deep | pavilions at 7.2 and 12.45 m | M_STONE | curved balconies |
| plaque | panel, sign | 8.4 x 0.9 m | Krakowskie front, middle | M_STONE, sign | HOTEL EUROPEJSKI |
| cornice | ring prism | 0.7 m proud | 19.4-20 m | M_STONE | main cornice |
| attic | parapets, dies | 1.5 m | on the cornice | M_STONE | balustrade attic |
| roof_storey | ring prism, two frustums | 5 m, 1.7 m back | over the attic | M_GLASS #262b2b | louvred glass roof storey |
| courtyard | inward walls, glass cap | 14 m wings | inside | M_MONUMENT, M_STONE | inner courtyard |
