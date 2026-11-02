# Dobra and Tamka tenements: spec

Not a site: a street dress in `game/scripts/map_builder.gd` (`_powisle_house`, `_powisle_trim`) and
`game/scripts/tenement_trim.gd`, for the houses within 24 m of the centre lines of Dobra and
Tamka (Powiśle). Written 2026-11-02 in a cloud thread from the OpenStreetMap houses and the LoD2
walls; no photo reachable, so the plasters, the cornice depth and the shop fronts are estimates
*(photo check)*. It touches only pre-war tenements (R4 type 1: 10 to 26 m, a home kind); slabs,
offices, landmarks (Ostrogski, the Chopin Institute, BUW, Piano House, Hortus) keep their own look.

## 1. Identity

Tamka and Dobra are the Powiśle of narrow pre-war tenements in a row, each its own height and
colour, a shop on every ground floor, a deep cornice under the roof, gaps where the war took a
house. What makes a passer-by say it: the row's uneven colours, the cornice line, the shops.

## 2. Massing

The LoD2 shell stays as it is (heights, roofs, gables). Nothing is added to the outline.

## 3. Facade, base to top

- Base: on a wall that faces the street (a point 8 m out nearer to the street than the wall, wall
  within 15 m of the centre line), shop glass in bays of 3.4 m with 1.0 m piers, panes from 0.55
  to 3.3 m, 6 cm proud, every fifth bay lit warm; a fascia board 3.3 to 3.85 m in a dark tone.
- Middle: a string course at 3.9 m (12 cm deep, 30 cm tall) on every wall 8 m tall or more, the first-floor line.
- Top: a two-step cornice 0.7 m tall (18 cm and 38 cm out) on every flat top edge.

## 4. Roof

Unchanged (LoD2 planes, `RoofDress` parapets and chimneys).

## 5. Colour and material

Plaster per house from `POWISLE_PASTELS` (sooty cream, ochre, faded rose, sage, grey, sand), a
quarter of the mapped colour left in. Cornice and course the plaster lightened; fascia from five
dark tones; glass #34444e. Everything in the walls' own tile meshes (building shader): no new
draw call, no new material.

## 6. Ground and night

No collision. The shop panes are vertex colours (no emission): the lit ones are a warm tone by day too.

## 7. Detail level and budget

L2 on every tenement of the two streets, triangle budget 12000 (an exception: a street dress over ~100 houses, not one building)
(about 30 triangles a wall edge at most). Shots: Tamka at (190, -412) and Dobra at (395, -330), day.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plaster | wall colour | per house | the house's walls | building shader | 1 identity (uneven colours) |
| cornice | two ledges | 0.7 m tall, 0.38 m out | every flat top edge | wall tile mesh | 3 facade top |
| course | ledge | 0.3 m tall, 0.12 m out | 3.9 m over the foot | wall tile mesh | 3 facade middle |
| shop | panes and fascia | 3.4 m bays, 3.3 m tall | street-facing foot | wall tile mesh | 3 facade base |
