#!/usr/bin/env python3 -I
"""Check that a landmark spec is complete before a build starts (LANDMARKS 0.4).

Usage:
  python3 -I tools/check_spec.py                 # every docs/landmarks/specs/*.md but README.md
  python3 -I tools/check_spec.py FILE.md ...     # just those files
  python3 -I tools/check_spec.py --selftest      # the checker's own tests

A spec follows the model-from-photos skill, section 2: eight sections as `## ` or `### `
headings (Identity, Massing, Facade, Roof, Colour and material, Ground and night, Detail level
and budget, Parts table). A spec passes when:
  S1 every section is present, in any order, with real content (not empty, not TODO/TBD/?/...);
  S2 the detail level is L1, L2 or L3, and a triangle budget (a number) is stated;
  S3 the parts table has the columns id, shape, size, position, material, feature, at least
     one row, every cell filled, unique ids;
  S4 the budget is within the skill's range for the level (L1 <= 1500, L2 <= 3000, L3 <= 8000)
     unless the spec names an exception with the word "exception".
Exit 0 and `check_spec: OK` when all pass, else 1 with one line per finding.
Standard library only.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SPEC_DIR = ROOT / "docs" / "landmarks" / "specs"

SECTIONS = [
	("identity", r"identity"),
	("massing", r"massing"),
	("facade", r"facade"),
	("roof", r"roof"),
	("colour", r"colou?r"),
	("ground", r"ground"),
	("detail", r"detail level|budget"),
	("parts", r"parts? table|parts"),
]
COLUMNS = [
	("id", r"id|part"),
	("shape", r"shape"),
	("size", r"size"),
	("position", r"position|pos"),
	("material", r"material|mat"),
	("feature", r"feature|serves|identity"),
]
LEVEL_MAX = {"L1": 1500, "L2": 3000, "L3": 8000}
OPEN = re.compile(r"^(todo|tbd|\?+|\.{2,}|…|-|n/?a|xxx|fixme)$", re.I)


def split_sections(text):
	"""Return {key: body} for the first heading matching each required section."""
	heads = [(m.start(), m.end(), m.group(2).strip().lower())
		for m in re.finditer(r"^(#{2,4})\s+(.+?)\s*$", text, re.M)]
	found = {}
	for i, (_, end, title) in enumerate(heads):
		stop = heads[i + 1][0] if i + 1 < len(heads) else len(text)
		for key, pat in SECTIONS:
			if key not in found and re.search(pat, re.sub(r"^\d+[.)]?\s*", "", title)):
				found[key] = text[end:stop].strip()
				break
	return found


def is_open(s):
	s = s.strip().strip("*_`")
	return s == "" or bool(OPEN.match(s))


def parse_table(body):
	rows = [[c.strip() for c in ln.strip().strip("|").split("|")]
		for ln in body.splitlines() if ln.strip().startswith("|")]
	rows = [r for r in rows if not all(re.fullmatch(r":?-{2,}:?", c) for c in r if c)]
	return rows


def check(text):
	errs = []
	secs = split_sections(text)
	for key, _ in SECTIONS:
		if key not in secs:
			errs.append(f"S1 section missing: {key}")
		elif is_open(re.sub(r"\s+", " ", secs[key])) or len(secs[key]) < 20:
			errs.append(f"S1 section empty or open: {key}")
		elif re.search(r"\b(TODO|TBD|FIXME)\b|\?\?", secs[key]):
			errs.append(f"S1 section has an open value (TODO/TBD/??): {key}")
	d = secs.get("detail", "")
	lvl = re.search(r"\bL([123])\b", d)
	bud = re.search(r"(?:budget|triangles?|tris)[^0-9\n]{0,40}?(~?\s*[\d][\d,._ ]*\d|\d)", d, re.I)
	if not lvl:
		errs.append("S2 detail level (L1, L2 or L3) not stated")
	if not bud:
		errs.append("S2 triangle budget (a number) not stated")
	if lvl and bud:
		n = int(re.sub(r"[^\d]", "", bud.group(1)))
		cap = LEVEL_MAX["L" + lvl.group(1)]
		if n > cap and "exception" not in d.lower():
			errs.append(f"S4 budget {n} over L{lvl.group(1)} limit {cap} with no named exception")
	if "parts" in secs:
		rows = parse_table(secs["parts"])
		if not rows:
			errs.append("S3 parts table missing")
		else:
			hdr = [c.lower() for c in rows[0]]
			idx = {}
			for name, pat in COLUMNS:
				for j, h in enumerate(hdr):
					if re.fullmatch(r"(%s)\b.*" % pat, h) and j not in idx.values():
						idx[name] = j
						break
				else:
					errs.append(f"S3 parts table column missing: {name}")
			body = rows[1:]
			if not body:
				errs.append("S3 parts table has no rows")
			ids = []
			for r in body:
				for name, j in idx.items():
					if j >= len(r) or is_open(r[j]):
						errs.append(f"S3 row '{r[0] if r else '?'}' column {name} is empty or open")
				if r:
					ids.append(r[0])
			for i in sorted({i for i in ids if ids.count(i) > 1}):
				errs.append(f"S3 duplicate part id: {i}")
	return errs


GOOD = """# Spec
## 1. Identity
The stepped tiers, the spire, the corner pinnacles and the attic parapets.
## 2. Massing
Footprint 120 x 100 m from the OSM outline, 42 m tall, setbacks at 30 m.
## 3. Facade, base to top
Base arcade of 9 bays, middle 11 storeys, top cornice and attic parapet.
## 4. Roof
Flat with a central spire, 4 pinnacles counted from ortho.jpg.
## 5. Colour and material
Warm sand stone mapped to the art bible palette, code M_STONE.
## 6. Ground and night
Forecourt steps, floodlit gold at night.
## 7. Detail level and budget
L3, triangle budget 6000.
## 8. Parts table
| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| tier1 | box | 40x30x20 | 0,0 | M_STONE | stepped tiers |
| spire | cone | 6x6x40 | 0,0 | M_STONE | spire |
"""


def selftest():
	assert check(GOOD) == [], check(GOOD)
	cases = {
		"S1 section missing: roof": re.sub(r"## 4\. Roof\n.*\n", "", GOOD),
		"S1 section empty or open: ground": GOOD.replace("Forecourt steps, floodlit gold at night.", "TBD"),
		"S2 detail level": GOOD.replace("L3, ", ""),
		"S2 triangle budget": GOOD.replace("triangle budget 6000", ""),
		"S4 budget 9000": GOOD.replace("6000", "9000"),
		"S3 parts table column missing: feature": GOOD.replace("| feature |", "| note |"),
		"S3 row 'spire' column size": GOOD.replace("6x6x40", "?"),
		"S3 duplicate part id: spire": GOOD.replace("tier1", "spire"),
		"S3 parts table has no rows": GOOD.split("| tier1")[0],
	}
	for want, txt in cases.items():
		got = check(txt)
		assert any(want in e for e in got), (want, got)
	assert check(GOOD.replace("6000", "9000 (exception: the Palace)")) == []
	print("check_spec selftest: OK")


def main(argv):
	if "--selftest" in argv:
		selftest()
		return 0
	files = [Path(a) for a in argv if not a.startswith("-")] or sorted(f for f in SPEC_DIR.glob("*.md") if f.name != "README.md")
	bad = 0
	for f in files:
		for e in check(f.read_text(encoding="utf-8")):
			print(f"check_spec: {f.name}: {e}")
			bad += 1
	print(f"check_spec counts: {len(files)} specs, {bad} findings")
	print("check_spec: OK" if not bad else f"check_spec: FAIL ({bad} findings)")
	return 1 if bad else 0


if __name__ == "__main__":
	sys.exit(main(sys.argv[1:]))
