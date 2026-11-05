---
name: street-pass
description: Runs Operation Unslop on one street block of Around Warsaw (docs/design/operation-unslop.md): score the road surface, markings, lane splits, trees, props and barriers with tools/street_pass.py, classify every object and match it to a library model (tools/model_library.py), gather fresh evidence (Mapillary/Panoramax in the cloud, orthophoto on the Mac), fix, verify with before/after shots, and keep the street's record so the dev console shows progress. Use when asked to unslop, clean up, prettify or fix a street, its markings, lanes, trees, barriers or the buildings along it.
---

# Street pass: one street block at a time

The plan: docs/design/operation-unslop.md. It merges the earlier plans and does not replace them:
docs/design/roads-and-objects-plan.md (RS1-RS9 road shapes, the object budget, section 3a "log
everything, add only what earns its place") and docs/design/road-objects.md (verdicts, rules
B1-B15, collisions). One street block per thread and PR. The first street was Marszałkowska,
Rondo Dmowskiego to Świętokrzyska (`marszalkowska-centrum`).

## 0. Claim and define

1. Check open PRs, "In progress" in docs/QUESTIONS.md and the project's other threads for the
   same area. A place another thread models (a square, a landmark) goes into the street's
   `owned` list: findings there are listed, never scored, never fixed by you.
2. Add the street to `docs/streets/streets.json`: its frame (`o`, `s`, `t` unit vectors: along
   and across), the box, blocks between junctions, `owned`, `changed` and `fresh_since`.
   - **changed**: every place rebuilt after the data was drawn (a car-free street, a new square,
     a rebuilt junction). OSM, the 2023 GUGiK scan and the orthophoto can be older than the
     street. A finding in a changed zone is not fixed until a fresh photo shows today's street.
   - **fresh_since**: street photos older than this are history, not evidence.

## 1. Measure (cloud, seconds)

```zsh
python3 -I tools/street_pass.py --street=SLUG --evidence --write   # record + newest photo per block
python3 -I tools/model_library.py                                   # refresh the model database
```

The record (`docs/streets/SLUG.json` and `.md`) holds the score per block, the findings
(L1 lane step, L2 loose lane line, L3 line on a kerb, T1 tree on the drawn road, P1 prop on the
drawn road, O1 solid within 1 m of a lane), every object within 3 m of a lane with its rule,
verdict and **model**, and the history. The first `--write` is the baseline.

Then the before shots: fixed cameras along the street (every block, day and one night,
`--prebuilt` too). The cloud recipe is in memory `cloud-godot-shots`: `--quality=low`,
`--shots=30 --out=DIR`, `--at=X,Z --heading=DEG --size=70`, three at a time.

## 2. Evidence: newest first

- **Street photos** (cloud): `python3 -I tools/street_photos.py X Z --r=25 --slug=road-SLUG-sN`
  per block and per CHECK object. Look at the date first: only photos since `fresh_since`
  decide; older ones say what used to be there.
- **Orthophoto** (Mac, with F's yes in that thread): `tools/overlay_ortho.py` crops of each
  block with the lanes and markings drawn on it. The ortho is the truth for paint and kerbs,
  unless the block is in a `changed` zone newer than the flight.
- **F's photos** and the Mac photo gather: landmarks and anything tier S/A (the photos-only rule).
- Mapillary detections (`tools/street_features.py --street=NAME`) count objects per stretch.
  Their positions are 10-20 m off, so use them as evidence, never as coordinates.

Never Google Street View. Nothing from a photo is traced or shipped.

## 3. Classify and match (the model step)

Every object gets a verdict (KEEP, RETEXTURE, REPLACE, SOFTEN, REMOVE, CHECK, A/B) and a model id.
- The model id comes from `docs/models/library.json` (console "Models" tab). Reuse a model that
  exists, even with a new colour, before asking for a new one.
- When nothing fits, the id is a **wanted** model (`WANTED` in tools/model_library.py, with
  the reason). The library lists how many objects on which streets ask for it, so the most-wanted
  model is built first, once, for every street. Hand it to `object-modeler` (Sonnet) with a spec
  from the photos, and Opus accepts it. When its code exists, remove it from WANTED and the scan
  finds it.
- Add a rule to `classify()` in tools/street_pass.py when you decide the same thing by hand twice.
  Rules scale to the whole map, and hand calls don't.
- F's object rule: signs, poles, junction boxes, cones and CCTV are logged, never placed. A/B
  items (feel calls such as solid or soft median fences) go to F on the phone.

## 4. Fix, in this order

1. **Lanes and markings**: lane counts and widths that match today's street, a taper instead
   of a step (RS3), one continuous line per lane boundary, arrows only on lanes that go there.
   Fix at the source (bake_roads.py rules, run for the whole map) when the cause is a rule. Fix
   by an override keyed to the street when the cause is outdated OSM. Never hand-edit centrum.json
   without a script that re-applies it after a re-bake (the tools/car_free.py pattern).
2. **Trees and props on the drawn road**: when the scan shows a real median tree, the road
   surface is wrong, not the tree. Narrow the strip or map the median.
3. **Objects**: the verdicts by stable id (class, kind, 2 m cell), so a re-bake keeps them.
4. **Buildings along the street**, by the ladder in the plan (section 3). Landmarks go the
   photo-way. Ordinary fronts get a kit read from fresh street photos (storeys, bays, colour,
   shopfront, roof). Everything else keeps the data baseline.

Both city paths (runtime and `--prebuilt`). After any change to the map data: the bake chain,
`python3 -I tools/check_map_data.py`, and new counts only on purpose.

## 5. Verify

- `python3 -I tools/street_pass.py --check`: the ratchet. No check's open count may grow on any
  street with a record. Re-record with `--write` only on purpose and say why in the PR.
- `python3 -I tools/model_library.py --check`: every model id a record names is in the library or
  WANTED.
- `zsh tools/verify.sh --only=streetpass,models` plus the steps your change touches. The map
  jobs on CI must be green.
- After shots at the same cameras, and `python3 -I tools/shot_sheet.py BEFORE AFTER` as the
  PR's one review sheet.
- Bench before and after for anything that adds geometry, materials or lights.

## 6. Record and report

`--write` again (stage: `baseline` → `evidence` → `fixed` → `accepted` when F says so; set
`stage` in streets.json). The PR shows the score before and after per block, the verdict counts,
the wanted models, the CHECK and A/B list for F, and the shot sheet. Tick the street's line in
ROADMAP "v1.0 checklist" and the Unslop item in docs/plan/city-plan.json. The dev console
(Streets and Models tabs) shows all of it to F.
