# Road design rollout: every street on the map (F, 2026-11-06)

F, after areas 1-2: "continue with the next areas... make the plan to unslop all the roads in my map,
the backlog for it and some visualisation of progress with % done and area done."

## What is being replaced

The map's streets come from OSM ways baked as ribbons, one per way, each sized from its own lane
count. The road design system (docs/design/road-design-system.md, tools/road_design.py) rebuilds a
street from one axis and its cross-sections measured on the GUGiK orthophoto, and builds each
junction from its arms. Unslop's objects (barriers, lamps, signals, shelters, benches, trees) stay;
only the road surface inside a design's footprint is replaced, and objects left on the new asphalt
move behind the new kerb.

Scale (tools/road_progress.py on main's map): 242 km of street ribbon outside service ways, of which
the main streets (trunk, primary, secondary, tertiary) are the part that gets hand-designed first.
Service ways (209 km: driveways, yards, car parks) are not designed; they keep their ribbons and get
a mouth where they meet a designed kerb.

## The areas (docs/plan/road-areas.json)

- **Tier A, the core (12 areas, 1-2 done).** Hand-measured on the ortho, one area per thread round,
  each closing onto the done ones so no free end is left in the middle of a block. Order: 3
  Marszałkowska north, 4 Świętokrzyska east, 5 Jerozolimskie east, 6 Rondo Dmowskiego, 7
  Marszałkowska south, 8 Emilii Plater south and Chałubińskiego, 9 Rondo ONZ and Świętokrzyska west,
  10 Królewska and Plac Małachowskiego, 11 Jerozolimskie west, 12 Plac Trzech Krzyży and Ujazdowskie.
- **Tier B, the arterials (10 corridors).** Jana Pawła II north, Solidarności, Krakowskie
  Przedmieście and Nowy Świat, Powiśle, Jerozolimskie to the bridge, Solec and Czerniakowska, the
  Wola edge, Śródmieście south, Praga's riverside, the Ochota edge. Same method, bigger steps: the
  seed tool drafts each street, the ortho corrects it.
- **Tier C, everything else.** A 500 m grid, nearest the Palace first. Local streets are simple
  (one carriageway, parking lanes), so a cell is mostly seed + check, with the ortho for the
  junctions only.

## The loop for one area

1. Ortho tiles for the box (Mac: GUGiK WMS into refs/road_design2/, mosaic).
2. `tools/road_design_seed.py` drafts each street from the map's ribbons; measure every section,
   crossing and junction arm on the ortho (`road_design_plot.py unroll` / `flat --ortho`).
3. `road_design.py AREA --check` (0 problems), apply to a copy of the map: continuity 0, lane drive
   bot on every street both ways and into the side roads.
4. In-game shots of the same spots on main and on the design; a before/after page for F.
5. `tools/road_progress.py` updates the % per area; the area's status moves in road-areas.json.

## Gates (every area)

`--check` 0 problems; continuity 0 (paths meet crossings both ways); `check_lane_drive.gd` passes;
`check_map_data.py` counts recorded on purpose; the phone bench before the first area goes into the
shipped map (the carriageway comes in 8 m pieces).

## Progress page

`python3 -I tools/road_progress.py` prints the table and writes build/road_progress.html: the map
with every area coloured by status and its % of main streets and of all streets done. A metre is
done when a design in docs/roads/ covers it, applied to the map or not.

## Open questions

- When does the design replace the OSM ribbons in the shipped map? Default: after area 6 closes the
  core around the Palace with no free ends, with a phone bench (BACKLOG).
- The traffic lane graph still follows the OSM ways moved onto the designed lanes; a graph built
  from the spec's lanes is its own item.
