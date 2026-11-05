# Footbridges, bridges, stairs: what needs improving

Survey of 2026-11-05 (F's ask), from the baked map data (`centrum.json`: 59 deck groups, 359 piers, 2,262 stair ways) and cloud shots of the worst cases. Coordinates are game metres (x east, z south).

## What the game draws today

- **Footbridges** (23 groups that are only footways) are one plain concrete slab with a low parapet. No handrails, no lamps, no steel, glass or arch character. Real Warsaw footbridges have railings and most have a recognisable form.
- **Stairs** (`steps`, 2,262 ways) are a flat beige strip 2.4 m wide laid on the ground (`_build_steps`). No treads, no height change, no handrails. Where a stair meets a bridge it is a grey wall box (the stairwell walls are the map's 1.9 m walls; real balustrades are about 1 m).
- **Vehicle bridges and viaducts** (28 road/tram groups, 8 rail groups) were reviewed one by one on 2026-10-29. Two are photo builds (Poniatowskiego, Średnicowy), the Powiśle viaduct has its arcade. The rest are slabs on the bake's piers.

## Findings, worst first

| # | Problem | Where / how many | Evidence |
| --- | --- | --- | --- |
| 1 | **Footbridge ends float.** The deck ends 2.6 to 10.5 m above the ground with nothing to climb. | 11 of 23 groups: 36 (1458, 1702) 6.4/6.7 m, 41 (2054, 862) 7.2/10.5 m, 39 (439, 1049) 5.3 m, 49-53 around (320, -937) and (344, -787) 3.8 m, 45 (1495, 926) 2.6 m | shots s36, s39 |
| 2 | **No handrails or lamps on footbridges**, so they read as a concrete plank. | all 36 path pieces | s36, s39 |
| 3 | **Stairs are painted on the ground.** No treads, no rise, no handrail. | 2,262 stair ways | s36, s39 |
| 4 | **Stairwell walls are 1.9 m solid boxes**, not 1 m balustrades with a stair inside. | about 100 walls (BACKLOG, road-objects plan) | s36 |
| 5 | **Decks sagged onto the floor of a trench** (fixed on the load side in PR #440 for 6 pieces: Armii Ludowej, three over the Ochota cutting, deck 48). The bake still produces the sag, and the piers under the lifted decks were placed for the sagged shape. | decks 37, 43, 48, 55 | armii_ludowej_after |
| 6 | **Known and still open:** the Karowa footbridge's end stands 2.2 m in the ground; the Tamka footbridge's dip is level but its stairs are unmapped; schematic footbridges keep short clearance (Centralna). | BACKLOG "From loop 3e", C3 allowlist | BACKLOG |
| 7 | Footbridge 58 (262, 500), the Książęca one, is 8.4 m up with ramps at both ends and no sag. Its shot is hidden by trees, so I can't say what is wrong with it. Needs F's description. | deck 58 | s58 |
| 8 | Vehicle-bridge piers, parapets and undersides are generic (one slab style). | 28 groups | map review A |

## Proposed work, in order

1. **Footbridge kit** (Sonnet, light DoD plus a bench): rails (1.1 m, thin, dark steel) and a lamp every 15 m along every path deck, as vertex-colour strips in the walls surface, so no new draw calls. Fixes #2 for all 36 pieces at once.
2. **Stair kit** (Opus, full DoD: it adds geometry and touches the stairwell colliders): real treads as a stepped ramp (rise 0.17 m, run 0.3 m) with two handrails, for stair ways that join a deck or a slope over 1 m; the rest stay flat. Replaces the 1.9 m walls with 1 m balustrades. Fixes #3 and #4.
3. **Footbridge ends** (Opus): where a deck ends more than 1.5 m above the ground, add the missing ramp or stair (from the stair kit) so the end lands on the ground. Fixes #1; the 11 groups above are the list.
4. **Bake the sag fix at the source** (Opus, Mac re-bake): `bake_roads._solve` takes the rim level for a deck over a trench; then `_lift_sagging_deck` can go. Fixes #5 and re-places the piers.
5. **Named footbridges from photos** (Sonnet with the Mac photo way): Karowa, Tamka, Wisłostrada's, Świętokrzyska, the Ochota ones, one at a time by `docs/CITY_INVENTORY.md` rank.
6. **Vehicle-bridge dressing** (Sonnet): pier shapes and undersides per bridge, after 1-3.

Not done in this survey: the full 28-group vehicle-bridge look-through, the underpass stairs by the metro, the Wisłostrada footbridges' look (no shot yet). Say if you want those next.
