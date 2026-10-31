# Landmark specs

One file per landmark, `<slug>.md`, written from the reference photos (model-from-photos skill,
section 2). `tools/check_spec.py` checks each one (sections, level, triangle budget, parts
table); it is a `tools/verify.sh` step, so an open spec fails CI. Start from this skeleton and
delete nothing; headings may be `##` or `###`, numbered or not.

```
## 1. Identity
## 2. Massing
## 3. Facade, base to top
## 4. Roof
## 5. Colour and material
## 6. Ground and night
## 7. Detail level and budget      <- "L3, triangle budget 6000"
## 8. Parts table                  <- | id | shape | size | position | material | feature |
```
