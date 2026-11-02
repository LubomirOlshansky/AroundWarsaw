# Pokorna 2, the residential tower by Muranów (unnamed): spec

Site key `pokorna2` in `game/scripts/landmarks.gd` (`_find_pokorna2`, `_build_pokorna2`). Written
2026-11-01 after F's note "Pokorna 2 looks strange, not as an apartment". Source: the one
OpenStreetMap `apartments` outline (12 corners, 57.1 m) standing at (-2123, -2217) in
`centrum.json`, between Pokorna and Stawki. Left unnamed: no card, not on the picking grid.

## 1. Identity

A 1970s residential point block, twenty storeys. What makes it read as flats and not as an office:

1. **A window in every 3.6 m bay** on the long faces, in a loggia recess.
2. **A balcony slab with a railing on every floor** above the first, standing out 1 m.
3. **Warm plaster**, plain darker end walls, a flat roof with a lift house and a water tank.

## 2. Massing

| Volume | Plan | Heights above ground |
| --- | --- | --- |
| Tower | the outline (simplified at 0.6 m) | -0.4 to 57 m (20 floors of 2.85 m) |
| Balconies | 1 m deep slab on each face of 8 m or more, 0.8 m short of the corners | 15 cm thick at every floor 1 to 19, railing to +0.95 m |
| Lift house | 6 x 4 m, 3 m in from the longest face | 57 to 60.2 m |
| Water tank | 3.2 m square beside it | 57 to 59.4 m |

The zone is the outline grown 3 m (the LoD2 model stands a little off it).

## 3. Facade, base to top

- **Faces of 8 m or more**: skin S_SLAB (plaster #d6c3ad, floors of 2.85 m, balustrade band,
  loggia recess with a window per bay, ground floor and top plain).
- **Short faces**: plain #bda98f (M_STONE).
- **Balcony slabs** #e8e2d6, **railings** #6f8f95 (blue-grey), M_STONE.

## 4. Roof

Flat #8c8a84; lift house in plaster with a #7d7b75 roof; tank #9aa3a8.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Long faces | #d6c3ad | M_SKIN + S_SLAB / 16 |
| End walls | #bda98f | M_STONE |
| Balcony slabs, railings | #e8e2d6, #6f8f95 | M_STONE |
| Roof, lift house, tank | #8c8a84, #7d7b75, #9aa3a8 | M_STONE |

No new material: the building surface (+0 draw calls).

## 6. Ground and night

The car stops at the outline. At night about 45 % of the windows glow warm and some loggias glow.

## 7. Detail level and budget

L2 (balconies are geometry). Triangle budget 1500 (`check_mesh_quality.gd` BUDGET).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| long | walls on faces of 8 m or more | 57.4 m tall | the outline | M_SKIN S_SLAB #d6c3ad | 1 windows |
| ends | walls on the short faces | 57.4 m tall | the outline | M_STONE #bda98f | 3 plain |
| balconies | slab and railing | 1 m deep, 0.95 m rail | floors 1-19 on each long face | M_STONE #e8e2d6, #6f8f95 | 2 balconies |
| roof | cap of the outline | the outline | y 57 | M_STONE #8c8a84 | 3 roof |
| lift | box | 6 x 4 x 3.2 m | longest face, 3 m in | M_STONE #cdbd9b | 3 roof |
| tank | box | 3.2 x 3.2 x 2.4 m | beside the lift | M_STONE #9aa3a8 | 3 roof |
