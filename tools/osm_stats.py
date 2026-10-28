import json, sys, collections
d = json.load(open(sys.argv[1]))
els = d["elements"]
c = collections.Counter(e["type"] for e in els)
print(c)
hw = collections.Counter(); bt = collections.Counter(); hgt = 0; lev = 0; nb = 0; parts = 0; colour = 0
for e in els:
    t = e.get("tags", {})
    if e["type"] == "way" and "highway" in t: hw[t["highway"]] += 1
    if "building" in t or "building:part" in t:
        nb += 1; parts += "building:part" in t
        hgt += "height" in t; lev += "building:levels" in t
        colour += "building:colour" in t or "roof:colour" in t
    if e["type"] == "relation": bt[t.get("type")] += 1
print("highways", hw.most_common(25))
print("buildings+parts", nb, "parts", parts, "height", hgt, "levels", lev, "colour", colour)
print("relations", bt)
pk = [e for e in els if "Pałac Kultury" in e.get("tags", {}).get("name", "")]
for e in pk: print(e["type"], e["id"], {k: v for k, v in e["tags"].items() if k in ("building", "height", "building:part", "name")})
