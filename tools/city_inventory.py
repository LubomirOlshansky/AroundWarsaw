"""Regenerate docs/CITY_INVENTORY.md's counts and Part 2 (street by street).

Usage: python3 -I tools/city_inventory.py [--check]

Part 1 (the ranked list) is written by hand; this script reads its rows and their status marks,
then lists every named outline in game/map/centrum.json (OSM `landmarks` and named `buildings`)
under its street (the nearest OSM address point) and district (game/data/districts.json). A
named outline that a Part 1 row names (whole words, or "(OSM: name)") takes that row's status;
one named in a quoted string of the game's scripts or data is "○ in game"; the rest are ✗.
Ranked places that have no outline (monuments, bars) are listed under their row's first street.
--check exits 1 when the file on disk differs from what the script would write.
"""
import collections
import glob
import json
import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, 'docs', 'CITY_INVENTORY.md')
MARKS = ['★', '◐', '○', '⏳', '✗']
SKIP_KINDS = {'kiosk', 'service', 'outbuilding', 'toilets', 'garage', 'allotment_house', 'plinth',
              'bunker', 'demolished'}
SHORT = {'apartments': 'flats', 'residential': 'flats', 'office': 'offices', 'commercial': 'commercial',
         'retail': 'shop', 'university': 'university', 'church': 'church', 'chapel': 'chapel',
         'cathedral': 'cathedral', 'government': 'government', 'public': 'public', 'hotel': 'hotel',
         'palace': 'palace', 'hospital': 'hospital', 'school': 'school', 'monastery': 'monastery',
         'convent': 'convent', 'dormitory': 'dormitory', 'train_station': 'station', 'theatre': 'theatre',
         'museum': 'museum', 'synagogue': 'synagogue', 'detached': 'house', 'industrial': 'industrial',
         'boat': 'boat', 'sports_hall': 'sports hall', 'sports_centre': 'sports', 'civic': 'civic'}
CHARACTERISTIC = re.compile(r'Kamienic|Pałac|Kości|Dom |Hotel|Muzeum|Teatr|Kino|Synagog|Cerkiew|Klasztor|'
                            r'Willa|Gmach|Hala|Zamek|Baszta|Brama|Wieża|Rezydencja|Apartament|Tower')


def centroid(p):
    xs, zs = p[0::2], p[1::2]
    n = len(xs)
    a = cx = cz = 0.0
    for i in range(n):
        j = (i + 1) % n
        c = xs[i] * zs[j] - xs[j] * zs[i]
        a += c
        cx += (xs[i] + xs[j]) * c
        cz += (zs[i] + zs[j]) * c
    if abs(a) < 1e-6:
        return sum(xs) / n, sum(zs) / n, 0.0
    return cx / (3 * a), cz / (3 * a), abs(a) / 2


def inside(x, z, p):
    xs, zs = p[0::2], p[1::2]
    n = len(xs)
    c = False
    j = n - 1
    for i in range(n):
        if (zs[i] > z) != (zs[j] > z) and x < (xs[j] - xs[i]) * (z - zs[i]) / (zs[j] - zs[i] + 1e-12) + xs[i]:
            c = not c
        j = i
    return c


def street_of(addr):
    return re.sub(r'\s+\S*\d\S*$', '', addr).strip()


def parse_rows(text):
    """Part 1's rows: (number, place, street, status)."""
    rows = []
    part1 = text.split('## Part 1.', 1)[1].split('## Part 3.', 1)[0]
    for line in part1.splitlines():
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if len(cells) >= 6 and cells[0].isdigit():
            mark = next((m for m in MARKS if m in cells[4]), '✗')
            rows.append((int(cells[0]), cells[1], cells[2], mark))
    return rows


def build(text):
    data = json.load(open(os.path.join(ROOT, 'game', 'map', 'centrum.json'), encoding='utf-8'))
    districts = json.load(open(os.path.join(ROOT, 'game', 'data', 'districts.json'), encoding='utf-8'))['districts']
    order = [d['name_pl'] for d in districts]

    def district(x, z):
        for d in districts:
            for ar in d.get('areas', []):
                if inside(x, z, ar):
                    return d['name_pl']
        return 'poza dzielnicami'

    addr = [(p['x'], p['z'], p['name']) for p in data['pois'] if p['k'] == 'address']
    grid = collections.defaultdict(list)
    for a in addr:
        grid[(int(a[0] // 100), int(a[1] // 100))].append(a)

    def nearest(x, z):
        best, bd = None, 1e18
        gx, gz = int(x // 100), int(z // 100)
        for r in range(6):
            for i in range(gx - r, gx + r + 1):
                for j in range(gz - r, gz + r + 1):
                    for a in grid.get((i, j), []):
                        dd = (a[0] - x) ** 2 + (a[1] - z) ** 2
                        if dd < bd:
                            bd, best = dd, a
            if best and math.sqrt(bd) < r * 100:
                break
        return best

    street_district = collections.defaultdict(collections.Counter)
    for x, z, name in addr[::3]:
        street_district[street_of(name)][district(x, z)] += 1

    code = ''
    for f in glob.glob(os.path.join(ROOT, 'game', 'scripts', '*.gd')) + glob.glob(os.path.join(ROOT, 'game', 'data', '*.json')):
        code += open(f, encoding='utf-8').read()

    outlines = {}
    for lm in data['landmarks']:
        x, z, a = centroid(lm['p'])
        o = outlines.setdefault(lm['name'], {'x': x, 'z': z, 'area': 0.0, 'kinds': set(), 'polys': []})
        o['area'] += a
        o['polys'].append(lm['p'])
    for b in data['buildings']:
        if not b['name']:
            continue
        x, z, a = centroid(b['p'])
        o = outlines.setdefault(b['name'], {'x': x, 'z': z, 'area': 0.0, 'kinds': set(), 'polys': []})
        o['kinds'].add(b['kind'])
        o['polys'].append(b['p'])
        if not o['area']:
            o['area'] = a

    # hand-built sites placed by position (the church kit, hotels' fronts): `"at": Vector2(x, z)`
    sites = [(float(a), float(b)) for a, b in
             re.findall(r'"at": Vector2\(([-\d.]+), ([-\d.]+)\)', open(os.path.join(ROOT, 'game', 'scripts', 'landmarks.gd'), encoding='utf-8').read())]

    rows = parse_rows(text)
    entries = collections.defaultdict(list)   # (district, street) -> [(sort, label)]
    covered = set()
    counts = collections.Counter()
    for name, o in outlines.items():
        pat = re.compile(r'(?<!\w)' + re.escape(name) + r'(?!\w)')
        hit = next((r for r in rows if pat.search(r[1])), None)
        if hit:
            covered.add(hit[0])
            continue
        kinds = o['kinds'] - {'yes'}
        if kinds and kinds <= SKIP_KINDS:
            continue
        if o['area'] < 150 and not CHARACTERISTIC.search(name):
            continue
        a = nearest(o['x'], o['z'])
        street = street_of(a[2]) if a else '?'
        dist = district(o['x'], o['z'])
        if any(inside(sx, sz, p) for sx, sz in sites for p in o['polys']):
            mark = '◐ model'
        elif ('"' + name + '"') in code:
            mark = '○ in game'
        elif dist == 'Stare Miasto' and name.startswith('Kamienica'):
            mark = '○ old-town dress'
        else:
            mark = '✗'
        kind = ', '.join(sorted(SHORT.get(k, k) for k in kinds)) if kinds else ''
        label = name + (' (' + kind + ')' if kind else '') + ' ' + mark
        entries[(dist, street)].append((1, mark != '✗', label))
        counts['c_' + mark.split()[0]] += 1
    for num, place, street, mark in rows:
        first = re.split(r' / |, | \(', street)[0].strip()
        dist = street_district[first].most_common(1)[0][0] if street_district.get(first) else 'poza dzielnicami'
        entries[(dist, first)].append((0, -num, '**#%d %s** %s' % (num, re.sub(r' \(OSM: [^)]*\)', '', place), mark)))
        counts[mark] += 1

    out = []
    by_d = collections.defaultdict(list)
    for (d, s), items in entries.items():
        by_d[d].append((s, items))
    for d in order + sorted(set(by_d) - set(order)):
        if d not in by_d:
            continue
        streets = sorted(by_d[d], key=lambda si: (-sum(1 for i in si[1] if i[0] == 0), -len(si[1]), si[0]))
        total = sum(len(i) for _, i in streets)
        out.append('### %s (%d places)\n' % (d, total))
        for s, items in streets:
            items.sort(key=lambda i: (i[0], -i[1] if i[0] == 0 else 0, not i[1] if i[0] else 0, i[2]))
            out.append('- **%s**: %s' % (s, '; '.join(i[2] for i in items)))
        out.append('')
    part2 = ('## Part 2. Street by street\n\nGenerated by `python3 -I tools/city_inventory.py` from the map '
             'data and Part 1. Ranked places in bold with their number; the rest are named outlines '
             'in OpenStreetMap (tier C), marked "◐ model" when a hand-built site stands in them (the church kit, the hotels\' '
             'fronts), "○ in game" when the game names them (a card, a sign, a skin), "○ old-town dress" '
             'for the dressed Old Town houses, and ✗ when they are a plain block. Streets are the nearest address point, so a '
             'corner building can sit on the cross street.\n\n' + '\n'.join(out).rstrip() + '\n')
    tier_c = sum(v for k, v in counts.items() if k.startswith('c_'))
    count_md = ('**Counts** (Part 1, %d ranked rows): ★ %d photo builds · ◐ %d outline builds · '
                '○ %d dress only · ⏳ %d in progress · ✗ %d not done. Part 2 adds %d named outlines '
                '(tier C): %d with a model of their own, %d dressed or named in the game, %d plain blocks.\n'
                % (len(rows), counts['★'], counts['◐'], counts['○'], counts['⏳'], counts['✗'],
                   tier_c, counts['c_◐'], counts['c_○'], counts['c_✗']))
    text = re.sub(r'<!-- counts:start -->.*?<!-- counts:end -->',
                  lambda m: '<!-- counts:start -->\n' + count_md + '<!-- counts:end -->', text, flags=re.S)
    text = re.sub(r'<!-- streets:start -->.*?<!-- streets:end -->',
                  lambda m: '<!-- streets:start -->\n' + part2 + '<!-- streets:end -->', text, flags=re.S)
    return text


def main():
    text = open(DOC, encoding='utf-8').read()
    new = build(text)
    if '--check' in sys.argv:
        if new != text:
            print('city_inventory: docs/CITY_INVENTORY.md is stale, run python3 -I tools/city_inventory.py')
            sys.exit(1)
        print('city_inventory: OK')
        return
    open(DOC, 'w', encoding='utf-8').write(new)
    print('city_inventory: wrote', DOC)


if __name__ == '__main__':
    main()
