# Sejm RP (the Polish parliament): spec

Site key `sejm` in `game/scripts/landmarks.gd` (`_build_sejm`). Written 2026-11-01 in a cloud
thread from the OpenStreetMap outline of the plenary hall in `centrum.json` and the building's
well-known curved colonnade (no photo, no LoD2 here: heights are estimates). The complex's mass
stays the kept LoD2 skin; the model adds the colonnade round the plenary hall. Values marked
*(photo check)* wait for the Mac's `refs/`.

## 1. Identity

The Sejm of the Republic of Poland on Wiejska, built 1925-1928 by Kazimierz Skórewicz and
Bohdan Pniewski, with the semicircular plenary hall (Sala Posiedzeń) at its heart.

1. **A semicircular front**: the hall's arc, bulging south toward Wiejska.
2. **A curved colonnade** of tall pale columns under a continuous entablature.
3. **Pale stone** over a darker plinth.

## 2. Massing

Plan frame: origin at the arc's centre (-> world (277.1, 967.5)), u south (the bulge's axis),
+v west. The arc is a circle of radius 21.75 m (fitted to the 17 mapped arc nodes, error under
0.1 m). The colonnade stands 1.6 m outside the wall and spans 168 degrees (-84..+84). Heights
above the ground: plinth to 0.9 m, columns 0.9..9.4 m, entablature 9.4..10.9 m, attic wall to
16.2 m, eave cornice 16.2..17.2 m *(estimate; photo check: the real eave and column heights)*.

## 3. Facade, base to top

- **Plinth**: a stone ring 3.4 m deep, 0.9 m high, round the arc.
- **Colonnade**: fifteen columns (r 0.5 m, 8-sided) at 12 degrees apart *(photo check: count)*.
- **Entablature**: a 1.5 m band over the columns, curved in 12-degree slices.
- **Door**: a dark panel 12 degrees wide in the middle of the arc wall *(photo check)*.

## 4. Roof

Attic wall in the hall's pale stone up to a thin eave cornice. The hall roof is the skin's.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Hall and complex (skin) | #e2e0d8 | M_MONUMENT |
| Columns, entablature, cornice | #efece2 | M_STONE |
| Plinth | #b4b0a4 | M_STONE |
| Door | #3a3d40 | M_GLASS |

No new material or draw call.

## 6. Ground and night

The car is stopped along the plinth's arc. Card (kept): "Sejm RP", PL "Przy Wiejskiej.", EN
"On Wiejska." Open: the Wiejska-side gate and the wings' detail, the exact eave height.

## 7. Detail level and budget

L2 for the colonnade, L1 for the rest, triangle budget 1400 (1072 measured, plus about 30 %, in
`check_mesh_quality.gd`). Shots: `--solo=sejm --solo-look=lit`, then in the city from Wiejska.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | 14 arc slices | 3.4 m deep, 0.9 m | r 21.35..24.75 | M_STONE | 3 plinth |
| columns | 15 on 8-sided shafts | r 0.5, 8.5 m | r 23.35, every 12 deg | M_STONE | 3 colonnade |
| entablature | 14 arc slices | 1.5 m | y 9.4..10.9 | M_STONE | 3 entablature |
| attic | 14 arc slices | 5.3 m | y 10.9..16.2 | M_STONE | 4 roof |
| cornice | 14 arc slices | 1.0 m | y 16.2..17.2 | M_STONE | 4 roof |
| door | 1 panel | 12 deg, 5.5 m | middle of the arc | M_GLASS | 3 door |
