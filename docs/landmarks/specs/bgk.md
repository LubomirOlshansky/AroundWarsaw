# Gmach Banku Gospodarstwa Krajowego (Al. Jerozolimskie 7): spec

Site key `bgk` in `game/scripts/landmarks.gd` (`_build_bgk`). Written 2026-11-03 from the Mac photo report `docs/landmarks/photo-reports/bgk.md` (refs/bgk/: 8 Commons photos, the GUGiK ortho with the OSM outline checked on it) and the OSM outline (unnamed 'office', 27.4 m, OSM relation 71489), found by `BGK_AT`; `tools/bake_sectors.py` SITE_AREAS keeps it for the streamed path. Asked for by F on 2026-11-03 ("near the Vitkac").

## 1. Identity

Rudolf Świerczyński's 1928-31 granite bank on Al. Jerozolimskie between Bracka (Vitkac) and the Nowy Świat corner by Rondo de Gaulle'a.

## 2. Massing

The mapped outline simplified (0.4 m), 72 m of front on Jerozolimskie. A 5.5 m base, six storeys of 3.3 m, the cornice at 25.6 m, an attic storey set back 1.6 m to 29 m; the two corner blocks (the Bracka end and the Nowy Świat corner) cut from the outline less 1.2 m rise to 33 and 34 m.

## 3. Facade, base to top

A darker stone base with grouped tall windows every 3.9 m and a band over it; four rusticated storeys of paired windows (1.1 x 2 m, dark brown frames) in 3.9 m stone bays; a string course at 18.7 m; two smooth storeys of paired windows; a heavy cornice 0.6 m proud. In the middle of the Jerozolimskie front two pilasters to the string course frame a tall window and the gilded monogram roundel over it. The east corner block carries a lighter relief-frieze band under its top.

## 4. Roof

Flat grey roofs on the attic and the corner blocks, parapets on the corner blocks. The two institutions' roof signs (real marks) are left out.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Granite | #9a9c99 | M_STONE |
| Bands, string course | #78797a | M_STONE |
| Base | #6b6d6e | M_STONE |
| Frieze | #b3b0a6 | M_STONE |
| Windows | #4a3a36 | M_GLASS |
| Monogram | #c8b070 | M_STONE |
| Roofs | #6f7173 | M_STONE |

No new material or draw call.

## 6. Ground and night

Car walls on the mapped outline, handed to the pocket bridging. Card from INFO. Open (photo check): the light wells (not cut), the stepped south side's heights, the balconettes, the relief frieze's real extent.

## 7. Detail level and budget

L2, triangle budget 2700 (`check_mesh_quality.gd`; 2244 built).

Shot: `--at=-250,282 --yaw=160 --pitch=-38 --size=70 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| base | ring prism | 5.5 m high | ground | M_STONE | 3 facade |
| body | ring prism | 20 m high | 5.5 m | M_STONE | 2 massing |
| bands | offset rings | 0.5-0.6 m | 5.5 m, 18.7 m | M_STONE | 3 facade |
| cornice | offset prism | 0.9 m | 25.6 m | M_STONE | 3 facade |
| windows | paired bays | 1.1 x 2 m, every 3.9 m | six storeys | M_GLASS | 3 facade |
| attic | inset prism | 2.5 m | 26.5 m | M_STONE | 4 roof |
| corner blocks | clipped prisms | to 33-34 m | the two front corners | M_STONE | 2 massing |
| frieze | band | 2.2 m | east block top | M_STONE | 3 facade |
| portal | 2 pilasters, window, disc | 18.7 m, r 1 m | front middle | M_STONE, M_GLASS | 3 facade |
