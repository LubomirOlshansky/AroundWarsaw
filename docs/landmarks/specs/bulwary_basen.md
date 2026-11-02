# Bulwary Wiślane, stage 2: the splash pool and the fish (site `bulwary_basen`)

Written 2026-11-02 for Krajobraz places K7 (docs/design/krajobraz-places.md). The six bar
pavilions of the same stage are `bulwary_pawilony` in `bulwary.md` (the boulevard dressing
lane); this site is the children's corner only. No photos in the cloud: the studio's and
press descriptions (a splash pool, Vistula fish sculptures) and the plaza between the third and
fourth pavilions in `centrum.json`. The Mac look check is open (QUESTIONS): the pool's real
spot, size, colours.

## 1. Identity

A shallow splash pool with two rows of jets on a paved apron, and three Vistula fish (sturgeon,
pike, perch) leaping out of stone plinths round it.

## 2. Massing

Pool rim 9.2 x 6 m, 0.32 m high, water 8.4 x 5.2 m; apron 12.8 x 9.2 m; fish 1.7-3.4 m long on 0.75 m plinths, at -124,-1365 along the boulevard.

## 3. Facade, base to top

Plinth, then the fish as a chain of tapering beams with head, forked tail and dorsal fin.

## 4. Roof

The pool is open to the sky: no roof, no canopy. Only the fish stand above the rim, a stone stem from each plinth to the belly of the leap.

## 5. Colour and material

Granite rim #8d8f8c, water #2fb3dd, jets pale #e3f6fa, paving #cfc7b2; fish bronze, steel grey, patina green. All in the city's one building surface (M_STONE): no new draw call.

## 6. Ground and night

On the plaza's own ground. Car collision round the rim only (the plaza is a footway).

## 7. Detail level and budget

L2, budget 700 triangles (`check_mesh_quality.gd`).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| apron | flat cap | 12.8 x 9.2 m | the plaza | paving | the paved apron |
| rim | prism | 9.2 x 6 m, 0.32 m | round the pool | granite | the pool wall |
| water | slab | 8.4 x 5.2 m | in the rim | water blue | the shallow water |
| jets | thin beams | 0.07 m, 0.7-1.2 m | two rows of seven | pale | the splash jets |
| plinth | box | 0.9 m, 0.75 m | beside the pool | granite | the fish's stands |
| fish | beam chain | 1.7-3.4 m | on the plinths | bronze, steel, patina | the Vistula fish |
