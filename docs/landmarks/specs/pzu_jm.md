# PZU Tower and JM Tower (two towers on the Jana Pawła II / Jerozolimskie axes): spec

Site keys `pzu` and `jm` in `TOWERS` (`game/scripts/landmarks.gd`, `_build_tower`). Written
2026-11-01 from the OpenStreetMap parts in `centrum.json` (outlines "PZU Tower" at (-1790, -280)
and "JM Tower" at (-2300, -20)); the cloud has no photos, so colours are a first pass for a Mac
photo check.

## 1. Identity

PZU Tower: two stepped glass volumes (92 m and 97 m, the taller with a round-topped face) with
a slim white mast to 106 m. JM Tower: a dark glass block with a ring of grey pilasters (a dozen
small mapped pieces, 98 m).

## 2. Massing

Each mapped part is lofted as in every `TOWERS` site: PZU 92 and 97 m volumes on 16.5 m bases,
the mast 69-106 m; JM 98 m and 96.7 m volumes on a 7 m podium, pilasters 98 m.

## 3. Facade, base to top

PZU: S_RIBBON, pale green-blue glass #8fb5bd with white ribbon bands. JM: S_FINS on dark navy
#2b4560, parts kept in their mapped colours (grey #bfbfc4 pilasters).

## 4. Roof

PZU #c4cccf, JM #7d878e, flat. The PZU mast is painted steel.

## 5. Colour and material

Existing M_SKIN styles; no new material.

## 6. Ground and night

Car stops at the outlines (`_collide`). Windows glow at night through the skin shader.

## 7. Detail level and budget

L2, triangle budget 900 each (`check_mesh_quality.gd` BUDGET).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| pzu_volumes | prisms of the mapped parts | 92 and 97 m | from the 16.5 m base | M_SKIN S_RIBBON #8fb5bd | 1 shaft |
| pzu_mast | prism | to 106 m | on the roof | painted steel | 2 mast |
| jm_body | prisms of the mapped parts | 98 and 96.7 m | from a 7 m podium | M_SKIN S_FINS #2b4560 | 1 body |
| jm_pilasters | small prisms | 98 m | round the body | mapped #bfbfc4 | 2 fins |
