"""Developer console: one local page that shows everything the game has and how far each part has come.

Usage: python3 -I tools/console.py [--out DIR] [--renders DIR ...] [--watch [SECONDS]]
       then open build/console/index.html in a browser (one self-contained file plus the renders
       it links to; works offline). `--watch` rebuilds when the branch, the docs or the game data
       change (default check: every 20 s); the page reloads itself when "Auto-refresh" is on.
       `--renders DIR` (repeatable) indexes screenshots (default: shots/ and docs/media if present).

Tabs (everything is worked out from the repo each time, nothing is written by hand):
  Overview   progress cards, the stage bars, history over runs, the v1.0 checklist, recent merges.
  City map   the map box with filters, sliders and an area picker (whole map, a district, or a
             circle with a radius). Layers: the ranked places (colour by stage, tier, district or
             data used), the other named outlines of CITY_INVENTORY Part 2 (own model / dressed /
             plain), street life (cafes, kiosks, benches), shops and transit, monuments, park
             details, trees, lamps, signals, parked cars, buildings by kind, roads by class, trams,
             rails, cycle paths, bridges and tunnels, and the game's content points (notebook
             places, eggs, Fotka spots, Syrenki, cassettes). Counts and km follow the area.
  Content    the game's content as tables (activities, notebook places, eggs, Kadr spots, Syrenki,
             cassettes, speed traps, districts) with the file to edit; points also show on the map.
  Approvals  what waits for F: the parked questions (docs/QUESTIONS.md), A/B mentions and "check
             open" lines of the ROADMAP; a click jumps to the place on the map when it names one.
  Renders    screenshots found in the renders folders, matched to places by their file names.
The stage rules are the wiki's (tools/wiki_build.py model_rows), so the wiki and this page agree.
Needs game/map/centrum.json (tools/setup_map.sh or tools/map_pack.py fetch). Standard library only.
Deploying it (rarely): console/README.md.
"""
import collections
import datetime
import json
import math
import os
import re
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import status_page as sp  # noqa: E402  (the map, the place locator and the stage rules)

IMG_EXT = ('.png', '.jpg', '.jpeg', '.webp')


def read(rel):
    return sp.read(rel)


def load(rel):
    return json.loads(read(rel))


def git(*args):
    try:
        return subprocess.run(['git', '-C', ROOT] + list(args), capture_output=True, text=True, timeout=20).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ''


def i1(v):
    return int(round(v))


# ---- coordinates ------------------------------------------------------------------------------

def ll_to_xz(origin, lat, lon):
    """The map's metres from lat/lon: x east, z south (the bake's own projection, to a few metres)."""
    return ((lon - origin[1]) * math.cos(math.radians(origin[0])) * 111320.0, -(lat - origin[0]) * 111320.0)


class Districts:
    def __init__(self):
        self.list = load('game/data/districts.json')['districts']
        self.polys = []   # (index, bbox, flat)
        for i, d in enumerate(self.list):
            for ar in d.get('areas', []):
                xs, zs = ar[0::2], ar[1::2]
                self.polys.append((i, (min(xs), min(zs), max(xs), max(zs)), ar))

    def of(self, x, z):
        for i, bb, ar in self.polys:
            if bb[0] <= x <= bb[2] and bb[1] <= z <= bb[3] and sp.inside(x, z, ar):
                return i
        return -1


# ---- layers -----------------------------------------------------------------------------------

STREET_KINDS = {'cafe': ('Cafe terraces', '#e07b39'), 'kiosk': ('Kiosks', '#d4a017'), 'stall': ('Market stalls', '#c0803a'),
                'bench': ('Benches', '#8d6e63'), 'planter': ('Planters', '#4f9d5a'), 'column': ('Ad columns', '#b5651d'),
                'bollards': ('Bollards', '#78909c'), 'cart': ('Carts', '#a1887f'), 'post': ('Posts', '#90a4ae'),
                'ticket': ('Ticket machines', '#5c8fd6'), 'heater': ('Patio heaters', '#ef5350'), 'shelter': ('Bus shelters', '#26a69a')}
POI_KINDS = {'kebab': ('Kebab stands', '#e8553d', 'shops'), 'convenience': ('Convenience shops', '#f2b134', 'shops'),
             'bicycle_rental': ('Bike rental (Veturilo)', '#3aa17e', 'transit'), 'scooter': ('Scooters', '#7e57c2', 'transit'),
             'scooter_zone': ('Scooter zones', '#9575cd', 'transit'), 'subway_entrance': ('Metro entrances', '#d32f2f', 'transit'),
             'station': ('Stations', '#455a64', 'transit'), 'hospital': ('Hospitals', '#e91e63', 'places'),
             'square': ('Squares', '#c9a227', 'places'), 'park': ('Parks (named)', '#43a047', 'places'),
             'stadium': ('Stadiums', '#00897b', 'places'), 'beach': ('Beaches', '#e6c35c', 'places')}
MON_COL = {'statue': '#b0bec5', 'bust': '#cfd8dc', 'allegory': '#9fa8da', 'stone': '#a1887f', 'stele': '#bcaaa4',
           'obelisk': '#ffcc80', 'cross': '#ef9a9a', 'sculpture': '#ce93d8', 'bench': '#8d6e63', 'plaque': '#80cbc4'}
PARK_COL = '#66bb6a'
BLD_CLASSES = [('home', 'Homes (apartments, houses)', '#c58f5a', ('apartments', 'house', 'detached', 'terrace', 'residential', 'dormitory', 'semidetached_house')),
               ('office', 'Offices', '#5c8fd6', ('office', 'commercial', 'public', 'government')),
               ('retail', 'Shops and malls', '#f2b134', ('retail', 'supermarket', 'kiosk')),
               ('civic', 'Schools, hospitals, churches, culture', '#9575cd', ('school', 'hospital', 'church', 'university', 'museum', 'cathedral', 'hotel', 'civic', 'kindergarten', 'chapel', 'theatre', 'train_station', 'sports_hall')),
               ('minor', 'Outbuildings, garages, steps, roofs', '#78909c', ('outbuilding', 'garage', 'garages', 'steps', 'service', 'roof', 'shed', 'carport')),
               ('plain', 'Unclassified (yes)', '#90a4ae', ('yes', ''))]


def pts_layer(key, group, label, color, pts, names=None, shape='dot'):
    flat = []
    for x, z in pts:
        flat += [i1(x), i1(z)]
    out = {'key': key, 'group': group, 'label': label, 'color': color, 'type': 'pt', 'n': len(pts), 'p': flat, 'shape': shape}
    if names:
        out['names'] = names
    return out


def line_layer(key, group, label, color, lines, width=1.0, dash=False, drawn=True):
    arr, total = [], 0.0
    for p in lines:
        if len(p) < 4:
            continue
        L = sum(math.hypot(p[k + 2] - p[k], p[k + 3] - p[k + 1]) for k in range(0, len(p) - 2, 2))
        total += L
        mid = p[len(p) // 4 * 2: len(p) // 4 * 2 + 2]
        arr.append([round(L), i1(mid[0]), i1(mid[1]), [i1(v) for v in p]])
    return {'key': key, 'group': group, 'label': label, 'color': color, 'type': 'line', 'n': len(arr),
            'km': round(total / 1000, 2), 'lines': arr, 'width': width, 'dash': dash}


def object_layers(data, origin):
    L = []
    sd = load('game/data/street_details.json')['items']
    by = collections.defaultdict(list)
    for it in sd:
        by[it[0]].append((it[1], it[2]))
    for k, (label, col) in STREET_KINDS.items():
        if by.get(k):
            L.append(pts_layer('sd_' + k, 'Street life', label, col, by[k]))
    pk = collections.defaultdict(list)
    names = collections.defaultdict(list)
    for p in data['pois']:
        if p['k'] in POI_KINDS:
            pk[p['k']].append((p['x'], p['z']))
            names[p['k']].append(p.get('name', ''))
    for k, (label, col, grp) in POI_KINDS.items():
        if pk.get(k):
            nm = names[k] if any(names[k]) else None
            L.append(pts_layer('poi_' + k, {'shops': 'Shops and food', 'transit': 'Transit', 'places': 'Places'}[grp], label, col, pk[k], nm))
    mon = load('game/data/monuments.json')['items']
    mk = collections.defaultdict(list)
    mn = collections.defaultdict(list)
    for it in mon:
        mk[it[0]].append((it[1], it[2]))
        mn[it[0]].append(it[5] if len(it) > 5 else '')
    for k, col in MON_COL.items():
        if mk.get(k):
            L.append(pts_layer('mon_' + k, 'Monuments', k.capitalize() + 's' if not k.endswith('s') else k.capitalize(), col, mk[k], mn[k]))
    pd = load('game/data/park_details.json')['items']
    pdk = collections.defaultdict(list)
    for it in pd:
        pdk[it[0]].append((it[1], it[2]))
    for k, v in sorted(pdk.items()):
        L.append(pts_layer('park_' + k, 'Park details', k.capitalize(), PARK_COL, v))
    tr = data['trees3d']
    L.append(pts_layer('trees', 'Nature', 'Trees (laser-scanned)', '#2e7d32', [(tr[i], tr[i + 1]) for i in range(0, len(tr) - 5, 6)]))
    L.append(pts_layer('lamps', 'Street furniture', 'Street lamps', '#fdd835', [(data['lamps'][i], data['lamps'][i + 1]) for i in range(0, len(data['lamps']) - 1, 2)]))
    sg = data['signals']
    L.append(pts_layer('signals', 'Street furniture', 'Traffic signals', '#ff7043', [(sg[i], sg[i + 1]) for i in range(0, len(sg) - 2, 3)]))
    pc = data['parked']
    L.append(pts_layer('parked', 'Street furniture', 'Parked cars', '#6d8cff', [(pc[i], pc[i + 1]) for i in range(0, len(pc) - 3, 4)]))
    cls = {c[0]: [] for c in BLD_CLASSES}
    for b in data['buildings']:
        c = sp.centroid(b['p'])
        key = 'plain'
        for ck, _, _, kinds in BLD_CLASSES:
            if (b.get('kind') or '') in kinds:
                key = ck
                break
        cls[key].append((c[0], c[1]))
    for ck, label, col, _ in BLD_CLASSES:
        L.append(pts_layer('bld_' + ck, 'Buildings', label, col, cls[ck]))
    return L


def road_layers(data):
    groups = collections.defaultdict(list)
    for r in data['roads']:
        k = r['k']
        key = 'primary' if k.startswith('primary') else 'secondary' if k.startswith('secondary') else \
            'tertiary' if k.startswith('tertiary') else 'service' if k == 'service' else 'local'
        groups[key].append(r['p'])
    meta = [('primary', 'Primary roads', '#e8a33a', 2.4), ('secondary', 'Secondary roads', '#d9c46a', 1.8),
            ('tertiary', 'Tertiary roads', '#b9b2a1', 1.3), ('local', 'Residential and living streets', '#8f97a3', 1.0),
            ('service', 'Service roads', '#6b7380', 0.7)]
    L = [line_layer('road_' + k, 'Roads and rails', label, col, groups[k], w) for k, label, col, w in meta if groups.get(k)]
    L.append(line_layer('trams', 'Roads and rails', 'Tram lines', '#ef5350', [t['p'] for t in data['trams']], 1.6))
    L.append(line_layer('rails', 'Roads and rails', 'Railway', '#ab47bc', [t['p'] for t in data.get('rails', [])], 1.6, dash=True))
    cyc = [p['p'] for p in data['paths'] if p.get('k') in ('cycle', 'cyclecross')]
    L.append(line_layer('cycle', 'Roads and rails', 'Cycle paths', '#26c6da', cyc, 1.4))
    L.append(line_layer('bridges', 'Roads and rails', 'Bridges and viaducts', '#ffee58', [p['p'] for p in data['decks']['pieces']], 3.0))
    L.append(line_layer('tunnels', 'Roads and rails', 'Tunnels and underpasses', '#8d6e63', [p['p'] for p in data['tunnels']['pieces']], 3.0, dash=True))
    L[-2]['groups'] = data['decks'].get('groups', 0) if isinstance(data['decks'].get('groups'), int) else len(data['decks'].get('groups', []))
    L[-1]['portals'] = data['tunnels'].get('portals', 0) if isinstance(data['tunnels'].get('portals'), int) else len(data['tunnels'].get('portals', []))
    return L


# ---- outlines of Part 2 -----------------------------------------------------------------------

def name_index(data):
    named = collections.defaultdict(list)
    for lm in data['landmarks']:
        c = sp.centroid(lm['p'])
        named[sp.norm(lm['name'])].append((c[0], c[1], c[2]))
    for b in data['buildings']:
        if b['name']:
            c = sp.centroid(b['p'])
            named[sp.norm(b['name'])].append((c[0], c[1], c[2]))
    return named


MARKS = {'★': ('photo', 'Photo build'), '◐': ('model', 'Own model'), '○': ('dress', 'Dressed or named in the game'), '✗': ('plain', 'Plain OSM block, not done')}


def outlines(data, ds):
    """The tier C named outlines of CITY_INVENTORY Part 2 that the map can place by name."""
    named = name_index(data)
    text = read('docs/CITY_INVENTORY.md').split('## Part 2', 1)[1]
    out = []
    for ln in text.splitlines():
        m = re.match(r'- \*\*(.+?)\*\*: (.*)', ln)
        if not m:
            continue
        street, rest = m.group(1), m.group(2)
        for seg in rest.split('; '):
            cat = 'outline'
            cm = re.match(r'\*(.+?):\*\s*(.*)', seg)
            items = [seg]
            if cm:
                cat, items = cm.group(1), cm.group(2).split(', ')
            for it in items:
                if it.startswith('**#'):
                    continue
                mm = re.match(r'(.+?)(?: \(([^)]*)\))? ([★◐○✗])', it.strip())
                if not mm:
                    continue
                nm, kind, mark = mm.group(1).strip(), mm.group(2) or cat, mm.group(3)
                hit = named.get(sp.norm(nm))
                if not hit:
                    continue
                big = max(hit, key=lambda h: h[2])
                out.append({'name': nm, 'street': street, 'kind': kind, 'mark': MARKS[mark][0], 'x': i1(big[0]), 'z': i1(big[1]), 'd': ds.of(big[0], big[1])})
    return out


# ---- the game's content -----------------------------------------------------------------------

def edit_line(rel, pattern):
    try:
        for n, ln in enumerate(read(rel).splitlines(), 1):
            if re.search(pattern, ln):
                return n
    except OSError:
        pass
    return 0


def content(data, origin, ds, place_xz):
    """Tables of the game's authored content; rows with a position also become points on the map."""
    cols = []
    places = load('game/data/places.json')
    chap = {c['id']: c['name_en'] for c in places['chapters']}
    pos = {}
    rows = []
    for p in places['places']:
        x, z = ll_to_xz(origin, *p['near'])
        pos[p['id']] = (x, z)
        rows.append({'id': p['id'], 'cells': [p['id'], p['name_en'], chap.get(p['chapter'], p['chapter']), p.get('address', ''),
                                              str(len(p.get('fact', []))) + ' facts', 'joke' if p.get('joke') else ''],
                     'x': i1(x), 'z': i1(z), 'd': ds.of(x, z)})
    cols.append({'key': 'notebook', 'label': 'Notebook places (MOJA WARSZAWA)', 'file': 'game/data/places.json',
                 'head': ['id', 'Place', 'Chapter', 'Address', 'Facts', 'Joke'], 'rows': rows, 'color': '#f06292'})

    def with_place(arr, keyf, label, key, file, head, cells, color, namef):
        rows = []
        for e in arr:
            p = pos.get(e.get('place'))
            r = {'id': e['id'], 'cells': cells(e)}
            if p:
                r.update({'x': i1(p[0]), 'z': i1(p[1]), 'd': ds.of(p[0], p[1])})
            rows.append(r)
        cols.append({'key': key, 'label': label, 'file': file, 'head': head, 'rows': rows, 'color': color})

    eg = load('game/data/eggs.json')['eggs']
    with_place(eg, None, 'Easter eggs', 'eggs', 'game/data/eggs.json', ['id', 'Name', 'Trigger', 'Reward', 'District'],
               lambda e: [e['id'], e['name'][1], (e.get('trigger') or {}).get('kind', ''), json.dumps(e.get('reward', {}), ensure_ascii=False), e.get('district', '')], '#ffb74d', None)
    kd = load('game/data/kadr.json')['kadr']
    with_place(kd, None, 'Fotka (Kadr) spots', 'kadr', 'game/data/kadr.json', ['id', 'Name', 'Place', 'Look'],
               lambda e: [e['id'], e['name'][1], e['place'], e.get('look', '')], '#4dd0e1', None)
    sy = load('game/data/syrenki.json')['syrenki']
    with_place(sy, None, 'Syrenki (mermaids)', 'syrenki', 'game/data/syrenki.json', ['id', 'Name', 'District', 'Place'],
               lambda e: [e['id'], e['name'][1], e.get('district', ''), e.get('place', '')], '#80deea', None)
    # cassettes lie on a landmark's roof
    lms = {sp.norm(l['name']): sp.centroid(l['p']) for l in data['landmarks']}
    rows = []
    for c in load('game/data/cassettes.json')['cassettes']:
        h = lms.get(sp.norm(c['roof']))
        r = {'id': c['id'], 'cells': [c['id'], c['name'][1], c['roof']]}
        if h:
            r.update({'x': i1(h[0]), 'z': i1(h[1]), 'd': ds.of(h[0], h[1])})
        rows.append(r)
    cols.append({'key': 'cassettes', 'label': 'Cassettes on roofs', 'file': 'game/data/cassettes.json', 'head': ['id', 'Name', 'Roof'], 'rows': rows, 'color': '#ba68c8'})
    rows = []
    for t in load('game/data/police_traps.json')['traps']:
        c = t.get('car') or [0, 0]
        rows.append({'id': str(t['id']), 'cells': [str(t['id']), t['road'], t['where'], str(t['limit_kmh']) + ' km/h'], 'x': i1(c[0]), 'z': i1(c[1]), 'd': ds.of(c[0], c[1])})
    cols.append({'key': 'traps', 'label': 'Police speed traps', 'file': 'game/data/police_traps.json', 'head': ['#', 'Road', 'Where', 'Limit'], 'rows': rows, 'color': '#42a5f5'})
    rows = [{'id': d['id'], 'cells': [d['id'], d['name_en'], d['name_pl'], 'hero' if d.get('hero') else '', d.get('jobs_goal', '') if isinstance(d.get('jobs_goal', ''), str) else str(d.get('jobs_goal', ''))]}
            for d in ds.list]
    cols.append({'key': 'districts', 'label': 'Districts', 'file': 'game/data/districts.json', 'head': ['id', 'English', 'Polish', 'Hero', 'Jobs goal'], 'rows': rows, 'color': '#fff'})
    try:
        import wiki_build
        dlg = wiki_build.dialogue()
        rows = []
        for key, title, rel, groups, flag, media, pitch in wiki_build.ACTIVITIES:
            if not os.path.exists(os.path.join(ROOT, rel)):
                continue
            nl = sum(len(dlg.get(g, [])) for g in groups)
            rows.append({'id': key, 'cells': [key, title, pitch, flag or '', str(nl) if groups else '', rel]})
        cols.insert(0, {'key': 'activities', 'label': 'Activities (quests, jobs, systems)', 'file': 'game/scripts', 'head': ['id', 'Activity', 'In one line', 'Test flag', 'Lines', 'Script'], 'rows': rows, 'color': '#fff'})
    except Exception as e:  # the console must still build if the wiki's helpers change
        print('console: activities skipped (%s)' % e)
    return cols, pos


# ---- approvals --------------------------------------------------------------------------------

FLAG_RX = [('look check', r'look check|photo check|side by side'), ('phone check', r'phone (check|listen)|listen check|on the phone|on the iphone'),
           ('A/B', r'A/B'), ('needs your go', r'\bgo\b.*\b(Mac|gather)|waits? (on|for) F|F.s (call|yes|go)'), ('default built', r'default')]


def approvals(items):
    out = []
    text = read('docs/QUESTIONS.md')
    wait = text.split('## Waiting', 1)[1].split('\n## ', 1)[0] if '## Waiting' in text else ''
    for ln in wait.splitlines():
        m = re.match(r'- \*\*(\d{4}-\d\d-\d\d)\s*·\s*(.*?)\s*·\s*(.*?)\*\*\s*[—-]\s*(.*)', ln)
        if m:
            out.append({'src': 'QUESTIONS', 'date': m.group(1), 'lane': m.group(2), 'title': m.group(3), 'text': m.group(4)})
        elif ln.startswith('- '):
            out.append({'src': 'QUESTIONS', 'date': '', 'lane': '', 'title': ln[2:70], 'text': ln[2:]})
    for rel in ('docs/ROADMAP.md', 'docs/BACKLOG.md'):
        t = read(rel)
        if rel.endswith('ROADMAP.md'):
            t = t.split('## v1.0 checklist', 1)[1].split('\n## ', 1)[0]
        for ln in t.splitlines():
            if re.search(r'A/B', ln) or (rel.endswith('ROADMAP.md') and re.search(r'(phone|look|listen|Mac) check open|check open', ln)):
                title = re.sub(r'^[\s\-\[\]xX*]+', '', ln)[:90]
                out.append({'src': os.path.basename(rel), 'date': '', 'lane': 'A/B' if 'A/B' in ln else 'check open', 'title': title, 'text': ln.strip()})
    names = [(i['n'], sp.norm(re.sub(r'\([^)]*\)', '', i['place']))) for i in items]
    for a in out:
        a['flags'] = [f for f, rx in FLAG_RX if re.search(rx, a['text'], re.I)]
        low = sp.norm(a['title'] + ' ' + a['text'])
        a['places'] = [n for n, nm in names if len(nm) >= 6 and re.search(r'(?<!\w)' + re.escape(nm) + r'(?!\w)', low)][:6]
    return out


# ---- renders ----------------------------------------------------------------------------------

def find_renders(dirs, out_dir):
    imgs = []
    for d in dirs:
        for dp, dn, fn in os.walk(d):
            dn[:] = [x for x in dn if not x.startswith('.')]
            for f in fn:
                if f.lower().endswith(IMG_EXT):
                    p = os.path.join(dp, f)
                    imgs.append((os.path.relpath(p, out_dir).replace(os.sep, '/'), p, os.path.relpath(p, d)))
    imgs.sort(key=lambda t: -os.path.getmtime(t[1]))
    return imgs[:1500]


def slug_words(item):
    out = set()
    for s, _ in item['links']:
        out.add(s.split(' ', 1)[-1])
    base = re.sub(r'\([^)]*\)', '', item['place'])
    words = [w for w in sp.norm(base).split() if len(w) >= 4]
    if words:
        out.add(words[0])
        if len(words) > 1:
            out.add('_'.join(words[:2]))
    return {w.lower() for w in out if len(w) >= 4}


# ---- history ----------------------------------------------------------------------------------

def update_history(out, snap):
    os.makedirs(out, exist_ok=True)
    path = os.path.join(out, 'history.json')
    try:
        with open(path, encoding='utf-8') as f:
            h = json.load(f)
    except (OSError, ValueError):
        h = []
    if not h or h[-1]['commit'] != snap['commit'] or h[-1]['counts'] != snap['counts']:
        h.append(snap)
    h = h[-400:]
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(h, f, ensure_ascii=False)
    return h


# ---- build ------------------------------------------------------------------------------------

def build(renders_dirs, out):
    data = load('game/map/centrum.json')
    origin = data['origin']
    ds = Districts()
    rws = sp.rows()
    pos = sp.locate(data, rws)
    items = []
    for r in rws:
        p = pos.get(r['num'])
        links = sp.links(r)
        ev = []
        if any(l[0].startswith('photo report') for l in links):
            ev.append('photo report')
        if any(l[0].startswith('spec') for l in links):
            ev.append('spec')
        if re.search(r"F's (own )?photos|F's own|F attached", r['next']):
            ev.append("F's photos")
        if re.search(r'refs/', r['next']):
            ev.append('Mac refs')
        if p and p[2]:
            ev.append('OSM outline')
        items.append({'n': int(r['num']), 'place': r['place'], 'street': r['street'], 'kind': r['kind'], 'tier': r['tier'],
                      'stage': r['stage'], 'next': r['next'], 'x': i1(p[0]) if p else None, 'z': i1(p[1]) if p else None,
                      'exact': bool(p and p[2]), 'links': links, 'ev': ev, 'd': ds.of(p[0], p[1]) if p else -2})
    layers = object_layers(data, origin) + road_layers(data)
    cont, _ = content(data, origin, ds, None)
    outl = outlines(data, ds)
    appr = approvals(items)
    imgs = find_renders(renders_dirs, out) if renders_dirs else []
    match = {}
    low = [(p[0], p[2].lower()) for p in imgs]
    for it in items:
        words = slug_words(it)
        m = [rel for rel, lp in low if any(w in lp for w in words)] if words else []
        if m:
            match[it['n']] = m[:8]
    cl = sp.checklist()
    counts = {'places': len(items), 'photos': sum(1 for i in items if i['stage'] == 'done_photos'),
              'models': sum(1 for i in items if i['stage'] in ('done_photos', 'done_outline')),
              'checklist_done': sum(c[1] for c in cl), 'checklist_open': sum(c[2] for c in cl),
              'approvals': len(appr), 'outlines_model': sum(1 for o in outl if o['mark'] in ('model', 'photo'))}
    commit = git('rev-parse', '--short', 'HEAD')
    snap = {'t': datetime.datetime.now().isoformat(timespec='minutes'), 'commit': commit, 'branch': git('rev-parse', '--abbrev-ref', 'HEAD'), 'counts': counts}
    hist = update_history(out, snap)
    merges = [l for l in git('log', '--merges', '-12', '--format=%h|%ad|%s', '--date=short').splitlines() if l]
    mp = sp.map_layers(data)
    mp['buildings'] = [[i1(b['h']), [i1(v) for v in b['p']]] for b in data['buildings'] if sp.centroid(b['p'])[2] >= 120]
    return {'stages': sp.STAGES, 'items': items, 'map': mp, 'checklist': cl, 'layers': layers, 'outlines': outl,
            'content': cont, 'approvals': appr, 'renders': [[p[0], p[2]] for p in imgs], 'render_match': match,
            'districts': [{'id': d['id'], 'name': d['name_en'], 'hero': bool(d.get('hero')), 'polys': [[i1(v) for v in a] for a in d.get('areas', [])]} for d in ds.list],
            'history': hist, 'git': {'branch': snap['branch'], 'commit': commit, 'subject': git('log', '-1', '--format=%s'), 'date': git('log', '-1', '--format=%ad', '--date=short'), 'merges': merges},
            'generated': snap['t'], 'bounds': data['bounds']}


def default_renders():
    return [d for d in (os.path.join(ROOT, 'shots'), os.path.join(ROOT, 'docs', 'media')) if os.path.isdir(d)]


def signature():
    paths = ['docs/CITY_INVENTORY.md', 'docs/ROADMAP.md', 'docs/BACKLOG.md', 'docs/QUESTIONS.md', 'game/map/centrum.json']
    s = [git('rev-parse', 'HEAD')]
    for rel in paths:
        try:
            s.append(str(os.path.getmtime(os.path.join(ROOT, rel))))
        except OSError:
            pass
    for d in ('game/data', 'docs/landmarks/specs', 'docs/landmarks/photo-reports'):
        try:
            s.append(str(max(os.path.getmtime(os.path.join(ROOT, d, f)) for f in os.listdir(os.path.join(ROOT, d)))))
        except (OSError, ValueError):
            pass
    return '|'.join(s)


def write(out, renders_dirs):
    payload = build(renders_dirs, out)
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(ROOT, 'tools', 'console_page.html'), encoding='utf-8') as f:
        html = f.read()
    path = os.path.join(out, 'index.html')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(html.replace('__DATA__', json.dumps(payload, ensure_ascii=False, separators=(',', ':')).replace('</', '<\\/')))
    with open(os.path.join(out, '_headers'), 'w', encoding='utf-8') as f:
        f.write('/*\n  X-Robots-Tag: noindex, nofollow\n  Cache-Control: no-cache\n')
    print('console: %d places, %d layers, %d outlines, %d content tables, %d approvals, %d renders -> %s (%d KB)' %
          (len(payload['items']), len(payload['layers']), len(payload['outlines']), len(payload['content']),
           len(payload['approvals']), len(payload['renders']), path, os.path.getsize(path) // 1024))


def main():
    a = sys.argv[1:]
    out = os.path.join(ROOT, 'build', 'console')
    rd = []
    watch = None
    i = 0
    while i < len(a):
        if a[i] == '--out':
            out = os.path.abspath(a[i + 1]); i += 1
        elif a[i] == '--renders':
            rd.append(os.path.abspath(a[i + 1])); i += 1
        elif a[i] == '--watch':
            watch = 20
            if i + 1 < len(a) and a[i + 1].isdigit():
                watch = int(a[i + 1]); i += 1
        i += 1
    if not os.path.exists(os.path.join(ROOT, 'game', 'map', 'centrum.json')):
        print('console: game/map/centrum.json is missing, run tools/setup_map.sh (or tools/map_pack.py fetch)')
        sys.exit(1)
    rd = rd or default_renders()
    write(out, rd)
    if watch:
        sig = signature()
        print('console: watching every %d s (Ctrl-C stops); open %s' % (watch, os.path.join(out, 'index.html')))
        while True:
            time.sleep(watch)
            s = signature()
            if s != sig:
                sig = s
                write(out, rd)


if __name__ == '__main__':
    main()
