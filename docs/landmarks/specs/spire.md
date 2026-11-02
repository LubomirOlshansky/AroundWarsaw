# Warsaw Spire: spec

Site key `spire` in `game/scripts/landmarks.gd` (TOWERS row `spire` with its `with` points,
`_build_tower`, `_spire`, `_spire_fin`, `_spire_canopy`, `_spire_wing`, `_spire_plaza`).
Rebuilt 2026-11-02 in a cloud thread from F's three photos (the street view of the tower, the
night aerial, the entrance with its canopy) and the OpenStreetMap plan and parts in
`centrum.json`. No terrain or LoD2 in the cloud, so heights are the mapped ones. The values
marked *(photo check)* have not been compared on the Mac yet.

## 1. Identity

The Warsaw Spire (Plac Europejski 1, 2016, Daniel Libeskind's tower for Ghelamco): 220 m with
its masts, a 180 m glass tower that is slim at the ground and **widens toward the top**. What
makes a passer-by say its name:

1. **The flaring glass shaft**: curved, banded glass narrowing to a lobby at the ground.
2. **The fin** that rises above the roof on one edge, a glass blade.
3. **The mirrored canopy** over the entrance, a beak of polished steel on V-shaped legs.
4. **The two curved 15-storey wings** (about 55 m) either side of the plaza.
5. **The plaza** in front: pale paving and a line of low black bollards.
6. **Night**: the shaft lit in bands, the two beacon masts, the parody sign near the top.

## 2. Massing

World plan (x east, z south). The tower's mapped outline is its widest plan (the roof's):
x -2743..-2698, z 171..232, an egg 45 x 61 m. The plaza and entrance face north (-z).

| Volume | Plan | Heights | Source |
| --- | --- | --- | --- |
| Lobby | the outline scaled to 0.74 about its centre | ground to 8 m, lit dark glass | photo 3 |
| Shaft | the outline, scaled from 0.74 (8 m) to 1.0 (165 m), nine rings | 8 m to 180 m | OSM outline, photos 1 and 2 |
| Roof | two shallow dome steps, 0.93 then 0.72 of the plan | 180 m to 182.6 m | photo 2 |
| Fin | a blade 0.9 m thick on the east rim, peaking 22 m over the roof | 181 m to 203 m | photos 1 and 2 *(photo check: side)* |
| Masts | two 1 m posts at the OSM parts' spots | 182 m to 220 m | OSM parts (h 220) |
| Canopy | a beak 14 m wide at the glass, 32 m at its wings, 20 m out | 9.5 m at the glass, 15.5 m at its wings, 12.5 m at its point | photo 3 |
| Wings | the two mapped 55 m crescents (east, north-west) | ground to 55 m, plant screen to 58 m | OSM outlines (h 55) |
| Plaza | a half disc 26 x 22 m north of the lobby | paving 3 cm over the ground | photo 3 |

## 3. Facade, base to top

- **Lobby band** (0 to 8 m): dark glass (#34505f), lit at night (M_PAVILION).
- **Shaft**: the tower's glass (#5a8fb8) in the banded skin (S_BANDS: silver floor lines),
  curving with the plan; the Spire's old diamonds are gone (the real glass is banded).
- **Fin**: glass a step lighter than the shaft, a pale mirrored top edge.
- **Wings**: banded glass (#4d7389) over a dark lit ground floor 5 m high; the real wings
  are glass too, with a lighter top storey *(photo check)*.
- **Sign**: SAMSONG (parody, neon_signs.gd) on the east and west faces 18 m under the roof.

## 4. Roof

Flat rim at 180 m in the roof colour (#a3b6c4), a shallow two-step dome in lighter steel, the
two masts, aviation lights on the rim (dusk loop). The fin stands on the east rim.
Wings: flat roofs in light grey-blue stone with a plant screen set back 2.5 m.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Shaft | #5a8fb8 | M_SKIN + S_BANDS |
| Lobby | #34505f | M_PAVILION |
| Canopy top, underside, rim | #c7d3da, #7f8c96, #f0f3f4 | M_STONE |
| Legs | #aeb6bc | steel beams |
| Wings | #4d7389, roof #aab4ba | M_SKIN + S_BANDS, M_STONE |
| Paving, bollards | #c9c4b6, #26282b | M_STONE |

## 6. Ground and night

Everything stands on the highest ground under its footprint. The lobby and the wings'
ground floors glow at night; the paving is plain. The sign and the beacons are the dusk
loop's (lit words in `neon_signs.gd`, red lights on the rim).

## 7. Detail level and budget

L3, triangle budget 3000. The tower is nine rings of about 30 sides (540 triangles), the
roof 130, fin 20, canopy 40, four legs 80, the wings 400 each with their ground floors, the
plaza and 11 bollards 150. No new materials, so no extra draw calls.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| lobby | lofted ring | 33 x 45 x 8 | outline centre | M_PAVILION | the lit glass ground floor |
| shaft | nine lofted rings | 45 x 61 x 172 | outline centre | M_SKIN S_BANDS | the flaring glass tower |
| dome | two frustums | 42 x 57 x 2.6 | roof centre | M_SKIN | the domed roof |
| fin | swept blade | 24 x 1 x 22 | east rim | M_SKIN S_BANDS | the roof fin |
| masts | two posts | 1 x 1 x 38 | OSM part spots | M_STONE | the beacon masts |
| canopy | beak, 3 planes and rim | 32 x 20 x 6 | 0.8 m inside the glass, north | M_STONE | the mirrored entrance canopy |
| legs | four beams | 0.7 x 0.7 x 12 | under the canopy | steel | the V legs |
| wing-east | crescent prism | 22 x 76 x 58 | mapped outline | M_SKIN S_BANDS | the east wing |
| wing-nw | crescent prism | 22 x 60 x 58 | mapped outline | M_SKIN S_BANDS | the north-west wing |
| plaza | half disc, 11 bollards | 52 x 22 x 0.9 | north of the lobby | M_STONE | the paved plaza |
