# Szeraton Grand (Sheraton Grand Warsaw, Bolesława Prusa 2): spec

Site key `sheraton` in `game/scripts/landmarks.gd` (`_build_sheraton`). Written 2026-11-03 from the Mac photo report `docs/landmarks/photo-reports/sheraton.md` (refs/sheraton/: three Commons photos and the GUGiK ortho) and the OpenStreetMap outline "Sheraton Grand Warsaw" with its mapped parts (24.1 m body, two 7.6 m halls, the 10.9 m west wing). The brand never appears: the card and the crown say SZERATON.

## 1. Identity

The hotel on Prusa by Plac Trzech Krzyży: a long white block in horizontal bands with a glass drum on the corner.

## 2. Massing

The mapped outline simplified (0.4 m). The tall body is the outline less the two low halls between its three north wings (SHER_COURTS, the 7.6 m parts) and the lower west wing (10.9 m): white to 21.6 m, a top storey set back 1.4 m to 24.6 m under a flat roof slab overhanging 1.8 m. The drum (r 6.8 m) at the Plac Trzech Krzyży corner, on OSM's round corner (the report's ortho spot is ~15 m north: OSM trusted), to 28 m.

## 3. Facade, base to top

Two lower storeys in white with four grey bands; five storeys of grey ribbon windows; the top storey's glass. The halls: window bays, glass roofs. The drum: alternating bands of glass (2 m) and white (1.4 m).

## 4. Roof

Grey flat roofs; on the drum eight steel posts and a 0.8 m hoop at 31.4 m carrying the name.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Render | #ecebe6 | M_STONE |
| Bands | #9a9c9e | M_STONE |
| Ribbon windows, drum glass | #5e6a74 | M_GLASS |
| Hall roofs | #a9bcc6 | M_STONE |
| Ring frame, flag poles | #b8bec4 | M_STONE |
| Roofs | #a8a9a6 | M_STONE |

No new material or draw call.

## 6. Ground and night

Car walls on the mapped outline and the drum, handed to the pocket bridging. SZERATON on the crown facing south and west; three flags on the Prusa side. Card "Szeraton Grand". Open (photo check): the forecourt's glazed restaurant pavilion and umbrellas (not built), the drum's size and spot, the band rhythm.

## 7. Detail level and budget

L2, triangle budget 2400 (`check_mesh_quality.gd`; 1995 built).

Shot: `--at=55,704 --yaw=0 --pitch=-45 --size=75 --nohud --no-ghost --time=dusk`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | clipped ring prism | 22 m high | ground | M_STONE | 2 massing |
| bands | offset rings | 0.7 m high | 1-7 m | M_STONE | 3 facade |
| ribbons | offset rings | 1.45 m high | five storeys | M_GLASS | 3 facade |
| top | inset prism and slab | 3 m and 0.6 m | 21.6 m | M_GLASS, M_STONE | 4 roof |
| halls | prisms | 7.6 m high | between the wings | M_STONE | 2 massing |
| west wing | prism | 10.9 m high | Plac Trzech Krzyży | M_STONE | 2 massing |
| drum | banded prisms | r 6.8 m, 28 m | south-west corner | M_GLASS, M_STONE | 3 facade |
| crown | 8 posts and hoop | 4.2 m | drum top | M_STONE | 6 night |
| flags | poles and flags | 9 m | Prusa side | M_STONE | 6 night |
