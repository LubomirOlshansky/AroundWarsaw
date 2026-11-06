# Operation Unslop: one pipeline for every street

F, 2026-11-05: "unslop the roads and the objects on them, street by street, with every workflow we have; Marszałkowska between Centrum and Świętokrzyska is the test, so the same approach then improves the other places". Test street: Marszałkowska from Rondo Dmowskiego to Świętokrzyska, about 600 m, the first-ten-minutes street.

**Status (2026-11-05):** the pipeline's tools are built (section 2a). The test street has its baseline (score 82). Fixes come next. Run it with the skill `street-pass`; the agent `street-unslopper` (Opus) audits a street against fresh photos. The dev console shows the records (Streets tab) and the model library (Models tab).

## 2a. What is built

| Piece | Where | What it does |
| --- | --- | --- |
| Street definitions | docs/streets/streets.json | frame (s along, t across), box, blocks, `owned` (another thread's area: listed, never scored), `changed` (rebuilt after the data: needs fresh photos), `fresh_since` |
| Street pass | tools/street_pass.py | checks L1 lane step, L2 loose lane line, L3 line on a kerb, T1 tree on the drawn road, P1 prop on the drawn road, O1 solid within 1 m of a lane; score per block; object classify (road-objects B1-B15) with a verdict and a model per object; `--evidence` adds the newest Mapillary photo per block; `--write` keeps the record and its history; `--check` is the ratchet in verify.sh and CI (`streetpass`) |
| Street records | docs/streets/SLUG.json and .md | the score, blocks, findings, objects, evidence, history, baseline |
| Model library | tools/model_library.py → docs/models/library.json and .md | every model the game draws (landmark sites, instanced furniture, barrier styles, props, details, metro forms, vehicles), its code and its count; the **wanted** models street passes ask for and the game lacks; `--check` in verify.sh and CI (`models`) |
| Match step | `MODEL_FOR` in tools/street_pass.py | each verdict's model: reuse a library model, else a wanted id; the library counts how many objects on which streets want each one, so the most-wanted is built first |
| Console | tools/console.py, Streets and Models tabs, Unslop map layers | F's progress view ("CRM") |
| Skill and agent | .claude/skills/street-pass, .claude/agents/street-unslopper.md | the steps, and the auditor that compares a street to today's photos and names the cause of each difference |

Outdated data (F, 2026-11-05): OSM, the 2023 GUGiK scan and the orthophoto can be older than the street (the Złota skwer opened 2026-08; Plac Centralny is being rebuilt). So every street lists its `changed` zones with dates, the evidence step records each photo's date, and only photos since `fresh_since` decide; findings in a changed zone wait for fresh evidence. Plac Centralny itself belongs to its own thread (owned box s -45..92, t -245..-25).

## 0. What F's four screenshots show

| Shot | What looks wrong | Probable cause (to confirm in step 1) |
| --- | --- | --- |
| Night, wide road by the park | dark wedges and blobs in the carriageway, lane lines cut off at random, a wide slab with no clear lanes | overlapping ribbons and bend discs where several OSM ways meet; markings follow each way separately |
| Day, 47 km/h | the road jumps from 5 to 6 lanes with diagonal slashes; red cycle strip appears and vanishes; lane arrows in the middle of the road | lane count is one number per OSM way, so a change between ways is a step, not a taper; arrows come from the lane graph |
| Day, 94 km/h | a column of trees standing in the carriageway; cycle lane runs into a kerb | trees are real laser-scanned GUGiK trees, so the trunk is probably real (a median), but the drawn road ribbon is wider than the real one and covers it |
| Kebab route | tenements are plain extruded blocks with random roof planes; one tall chimney-like box | OSM outline plus LoD2 height only, no facade or roof study (tier C) |

I measured one thing: of 45,192 scanned trees, only 559 have a trunk inside a lane corridor, and none on Marszałkowska. So "trees on the street" is mostly about the drawn road surface, not the lanes. No current check looks at that. That is the first gap.

## 1. Every approach we already have (and where it runs)

| Approach | Tool or skill | Runs | Gives | Gap |
| --- | --- | --- | --- | --- |
| OSM tags and geometry | bake_osm, bake_roads | Mac (OSM blocked in cloud) | centrelines, lanes, tags | one width and one lane count per way; surface, kerb, crossing tags not read |
| GUGiK LoD2, trees, terrain | bake_gugik, bake_trees_gugik, map pack | Mac, or the map pack in the cloud | building heights, real trees | roofs and facades are generic |
| GUGiK orthophoto and LiDAR | fetch_gugik, overlay_ortho, overlay_structures | Mac only | the truth for road edges, markings, medians | used by hand, no automatic score |
| Mapillary detections | street_features.py, street_objects.py | cloud (token) | per-street object log, evidence per junction | positions 10-20 m off, so evidence only |
| Mapillary and Panoramax photos | street_photos.py | cloud | what a street really looks like | not yet a contact sheet next to the game shot |
| Photos from Commons and F's own | model-from-photos skill, refs/, photo reports | Mac gather | landmark and building specs | slow, only for ranked landmarks |
| Census and verdicts | road_objects.py, skill road-objects-sweep, agent road-auditor | cloud | every solid near the lanes, KEEP/SOFTEN/REMOVE | rules S2 and the override file are still to build |
| Drive evidence | check_lane_drive, check_stuck_spots, Autopilot | cloud and Mac | contacts per km, speed kept | contact log not built |
| Road geometry plan | roads-and-objects-plan.md RS1-RS9 | bake | junction shapes, kink fillets, tapering widths, surfaces | prototype not started |
| Street passes | tier C passes (Nowogrodzka, Mazowiecka) | cloud, Sonnet | signs, crowds at OSM points | content only, no geometry or facade work |
| Verification | verify.sh, check_roads C1-C11, check_map_data, CI map jobs, shots.sh, shot_sheet.py | both | invariants and before/after sheets | nothing for markings, trees on surface, facades |
| Progress and approval | console.py, status_page.py, city-plan.json, QUESTIONS | local | a map and a plan | no per-street score |

**Diagnosis:** the pieces are good but they run as separate threads with separate outputs. Nothing says "this street is done", and nothing is re-run when the map is re-baked. The merge is a single per-street driver plus a single per-street record.

## 2. The merged workflow: Street Pass

One street group (about 500 m between two junctions, or a named street in blocks) is one thread and one PR. Same steps every time. Existing tools are reused; the new parts are marked NEW.

| Step | What | Source and tool | Where |
| --- | --- | --- | --- |
| 0 Manifest | list the blocks of the street, their buildings, objects and the evidence available | NEW `tools/street_pass.py --street=NAME --manifest` (reads the road graph, census, inventory, street_features cache) | cloud |
| 1 Baseline | measure before: census, drive contacts, markings and tree checks, shots by day and night from fixed cameras, runtime and `--prebuilt` | road_objects.py, check_lane_drive, shots.sh | cloud |
| 2 Reference | gather truth: ortho crops (road edges, markings, medians) and 3-5 street photos per block, one contact sheet per block (game top view, ortho crop, photo) | overlay_ortho (Mac), street_photos.py (cloud) | Mac for ortho, cloud for photos |
| 3 Road geometry | fix bends, junction shapes, tapered lane changes, width from the ortho, surfaces | bake_roads RS1-RS4, osm2streets as reference | Mac re-bake |
| 4 Markings | rebuild markings from the lanes after step 3: one continuous line per lane boundary across ways, arrows only before a junction with a matching lane, cycle lane continuous | NEW rules in bake_roads, compared against the ortho | Mac re-bake |
| 5 Objects | classify every solid and prop, then keep, soften, retexture, replace or remove; trees on the surface are checked against the ortho and moved or removed only if the ortho disagrees with the scan | road_objects.py `--classify`, override file `game/data/road_objects.json`, road-auditor | cloud |
| 6 Buildings | see section 3 | model-from-photos, facade bays, kits | cloud and Mac |
| 7 Verify | all checks of section 4, after shots, before/after sheet | verify.sh, shot_sheet.py | both |
| 8 Record | street record written, baseline updated, ROADMAP and BACKLOG ticked | NEW `docs/streets/<slug>.md` and `game/data/street_pass/<slug>.json` | cloud |

The **street record** is the one new artifact: scorecard before and after, verdict counts, CHECK and A/B list for F, links to shots and photo sheets, and the list of overrides. The console reads it, so "which streets are done" is one table.

### Rules that keep it honest

1. **Truth order:** ortho and LiDAR (Mac) beat OSM; OSM beats Mapillary positions; Mapillary and photos are evidence, never traced or shipped.
2. **Overrides by stable id, never by edit:** every fix is a line in the override file, so a re-bake keeps it. This is what lets the pipeline run again on a new map.
3. **Log everything, add little:** F's object rule (2026-11-04) stands: signs, poles, boxes, cones are logged, not placed.
4. **Driving first:** when a look fix and drivability disagree, drivability wins and the look is kept by a texture or a decal.
5. **Both city paths** (runtime and prebuilt) for every check.

## 3. Buildings along the street: the best approach

Recommended is a ladder, chosen per building by the CITY_INVENTORY rank, so effort goes where the player looks.

| Rung | For | Method | Needs |
| --- | --- | --- | --- |
| A Landmark | ranked stars (Rotunda, Domy Towarowe Centrum, MSN, PKiN) | photo-way: refs, spec, hand-built model, scored side-by-side | Mac photo gather (already the project rule) |
| B Photo kit | tenements and offices on the street fronts | from 3-5 Mapillary/Panoramax photos read: storeys, bay count, colour, ground-floor shopfront, roof type; feed them into the existing facade bays, trim and roof-dress code per building | cloud, Sonnet builds, Opus accepts |
| C Data baseline | everything else | LoD2 geometry with the facade palette of its block and kind; no hand work | already there |

For Marszałkowska Centrum to Świętokrzyska: rung A for the six stars already built (look check only), rung B for the 34 buildings and 37 small buildings the census finds on the street, rung C behind them. The Eastern Wall fronts (Sezam as WACZEK, Coca-Cola sign, Pasaż slabs) are already F's photo-pass list; fold them in.

To make rung B repeatable, NEW `tools/facade_read.py` would turn photos into a small JSON per building (storeys, bays, colour, shopfront, roof) that an agent confirms, instead of each model being written by hand.

## 4. Checks for each step

| Step | Check | Kind | Status |
| --- | --- | --- | --- |
| 1 | census counts, drive contacts per km, speed kept | script | built (contact log to build) |
| 3 | no junction polygon cuts into a lane corridor; drawn surface covers every lane connector; kerb never crosses a lane | script, new C12 in check_roads | to build |
| 3 | lane count change between consecutive ways tapers over 20 m (no step of more than one lane) | script, C13 | to build |
| 4 | every lane boundary is one continuous line through a junction approach; no marking crosses a kerb, building or median; arrows only on lanes that continue; cycle lane has no gaps over 5 m | script, C14 | to build |
| 4 | markings against ortho: drawn lines within 0.5 m of detected paint on the crop | script on Mac, score per block | to build (Mac) |
| 5 | no tree trunk, bin or lamp inside the drawn carriageway or kerb of a swept street; every trunk inside is a verdict in the override file | script, C15 | to build |
| 5 | solids within 1 m of a lane: none new (baseline) | script, check_map_data baseline | to build (S10) |
| 6 | every building on the street has a rung; rung B buildings pass tenement trim, roof dress, osm roofs and mesh quality checks | existing checks plus a rung field | partly built |
| 7 | fixed-camera shots every 60 m along the street, day and night, runtime and prebuilt, before/after sheet | visual, F or art-director | shots.sh and shot_sheet.py exist |
| 7 | street_features game-only and Mapillary-only counts shrink | script | built |
| 7 | map checks on CI (the two map jobs) green | CI | built |
| 7 | bench: no more draw calls | phone | existing gate |
| 8 | street record exists and the scorecard did not get worse | script in verify.sh | to build |

What only a person can judge: the phone look, the feel of A/B calls, rung A acceptance. Those go to QUESTIONS and the console Approvals tab, one list per street.

## 5. How it scales to the whole map and to other object types

1. **Manifest from the data, not by hand.** The road graph gives every named street; split into blocks between junctions; order by the census (solid metres per lane metre) for roads and by CITY_INVENTORY rank for buildings. The first ten streets cover the first-ten-minutes and race routes.
2. **Object types are plug-ins with the same five hooks:** census, rules, evidence, verdict, apply, plus a check. Today: solids (done), trees, markings, lamps, signs (log only), buildings. A new type is a new rules file and one check, not a new process.
3. **Automatic first, people last.** Rules decide when confident. Evidence tools decide next. Only CHECK and A/B reach F, batched per street in one list. Mac work is batched too: one evidence request per street group (ortho crops, photo gather), so the Mac is asked once, not per object.
4. **Overrides and baselines survive re-bakes.** Stable ids (class, kind, 2 m cell) mean a new bake keeps decisions, and CI fails if a swept street gets a new solid within 1 m of a lane or loses its record.
5. **Geometry fixes are city-wide, street passes are local.** RS1/RS2 (junctions, bends) and the C12-C14 checks run once for the whole map; a street pass then handles what rules cannot (objects, buildings, markings against ortho). So most of the map gets the geometry win at once and the manual work is only the leftover.
6. **Progress is one table.** The console reads the street records: score before/after, rung mix, open CHECKs, so "how unslopped is the map" is a number per street and per district.
7. **Throughput:** one Opus thread per street group, Sonnet for rung B models, Haiku for counts; two or three threads in parallel across different districts, merge slots as today.

## 6. Recommended order

1. **Day 1 (cloud):** build the checks C12-C15 and the street record, run them on Marszałkowska to get the honest "before" score. This proves what is wrong with F's screenshots before anyone changes geometry.
2. **Day 1-2 (Mac, F's yes):** ortho crops and photo contact sheets for the test street; RS2 and RS1 on the three pilot junctions, which the roads plan already names, including Marszałkowska × Świętokrzyska.
3. **Day 2-3:** markings rebuild (step 4) and the object sweep (step 5) on the test street; rung B for its buildings.
4. **Day 3:** review the sheet with F, adjust rules, then run the same pipeline on Aleje Jerozolimskie and Nowy Świat unchanged. If it needs no new code, the pipeline is ready to go city-wide.

## 7. Decisions for F

- Yes to a Mac session for ortho crops and photo gather on the test street?
- Is rung B (photo-read kits, not hand-built models) acceptable for ordinary tenements, with hand-built models only for ranked landmarks?
- Should the markings be accepted on the ortho score alone, or do you want a look on the phone for each street?

Defaults if no answer: yes to the Mac session when F starts a thread, rung B accepted, ortho score plus your phone look only for the test street.
