"""Local status page: a map of the city coloured by how far each ranked place has come.

Usage: python3 -I tools/status_page.py [--out DIR]      (default build/status/, gitignored)
       then open build/status/index.html in a browser (one self-contained file, works offline)

What it shows (all worked out from the repo every time, nothing is written by hand):
  * the map box (roads, water, parks, buildings from game/map/centrum.json) with one dot per
    ranked place of docs/CITY_INVENTORY.md Part 1, coloured by stage: done from photos, done
    from outline, researching, dress only, planned. A dot is hollow when the place has no
    outline of its own in the map and sits at its street's address points instead.
  * click a dot (or a row of the list): tier, street, kind, what is next, and links to its
    spec (docs/landmarks/specs/) and photo report (docs/landmarks/photo-reports/) if they exist.
  * the percentages: all ranked places and each tier, by stage, "has a model of its own" and
    "done from photos"; by district; the ROADMAP v1.0 checklist; the BACKLOG sections.
  * filters by stage and tier, a search box, and the list beside the map.
The stage rules are the wiki's (tools/wiki_build.py model_rows), so both pages agree.
Needs game/map/centrum.json (tools/setup_map.sh or tools/map_pack.py fetch). Standard library only.
"""
import collections
import json
import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))

STAGES = [  # key, label, colour (colour-safe pairs: hue plus a distinct shape letter in the list)
    ('done_photos', 'Done from photos', '#2e9e5b'),
    ('done_outline', 'Done from outline', '#e0a82e'),
    ('researching', 'Researching', '#3a86d8'),
    ('dress', 'Dress only', '#9a6fd1'),
    ('planned', 'Planned', '#d8504a'),
]


def read(rel):
    with open(os.path.join(ROOT, rel), encoding='utf-8') as f:
        return f.read()


def rows():
    """Part 1 rows with the wiki's stage rules (imported so the two pages cannot disagree)."""
    import wiki_build
    return wiki_build.model_rows()


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
    c = False
    j = len(xs) - 1
    for i in range(len(xs)):
        if (zs[i] > z) != (zs[j] > z) and x < (xs[j] - xs[i]) * (z - zs[i]) / (zs[j] - zs[i] + 1e-12) + xs[i]:
            c = not c
        j = i
    return c


def norm(s):
    s = s.lower().replace('ł', 'l')
    return re.sub(r'\s+', ' ', re.sub(r'[^\w ]', ' ', s)).strip()


def queries(place):
    """Names to look for in the map, best first: the OSM name, then the place's parts."""
    out = [m for m in re.findall(r'\(OSM: ([^)]*)\)', place)]
    base = re.sub(r'\([^)]*\)', '', place)
    out.append(base)
    for part in re.split(r' and | / |, | with |: ', base):
        out.append(part)
    return [norm(q) for q in out if len(norm(q)) >= 4]


# Inventory rows whose name differs from the map's: the number -> names to look for (outline, POI,
# monument or road). Add one when a new row lands without a dot.
ALIASES = {
    13: ['Narodowe Centrum Sportu', 'Stadion Narodowy'],
    14: ['Most Księcia Józefa Poniatowskiego'],
    24: ['Archikatedra pw. Świętego Jana Chrzciciela'],
    11: ['Kolumna Zygmunta III Wazy'],
    15: ['Most Świętokrzyski'],
    68: ['Plac Piłsudskiego'],
    69: ['Pomnik Poległym i Pomordowanym na Wschodzie'],
    122: ['Plac Żelaznej Bramy'],
    131: ['Stadion Miejski Legii Warszawa'],
    34: ['Kościół pw. Świętego Krzyża'],
    66: ['Pomnik Bohaterów Warszawy'],
    70: ['Stawki'],
}


def street_of(addr):
    return re.sub(r'\s+\S*\d\S*$', '', addr).strip()


def locate(data, rws):
    """x, z and an 'exact' flag for each row: a named outline or POI, else its street's address points."""
    named = collections.defaultdict(list)   # normalised name -> [(x, z, area)]
    for lm in data['landmarks']:
        x, z, a = centroid(lm['p'])
        named[norm(lm['name'])].append((x, z, a))
    for b in data['buildings']:
        if b['name']:
            x, z, a = centroid(b['p'])
            named[norm(b['name'])].append((x, z, a))
    for p in data['pois']:
        if p.get('name') and p['k'] != 'address':
            named[norm(p['name'])].append((p['x'], p['z'], 1.0))
    try:   # the baked monuments and statues (game/data/monuments.json): [kind, x, z, yaw, colour, name]
        for it in json.loads(read('game/data/monuments.json'))['items']:
            if it[5]:
                named[norm(it[5])].append((it[1], it[2], 1.0))
    except (OSError, ValueError, KeyError):
        pass
    roads = collections.defaultdict(list)   # a bridge or avenue by name: the middle of its longest piece
    for rd in data['roads']:
        if rd.get('name'):
            roads[norm(rd['name'])].append(rd['p'])
    streets = collections.defaultdict(list)
    for p in data['pois']:
        if p['k'] == 'address':
            streets[norm(street_of(p['name']))].append((p['x'], p['z']))
    keys = list(named)
    out = {}
    for r in rws:
        pos = None
        for q in queries(r['place']) + [norm(a) for a in ALIASES.get(int(r['num']), [])]:
            hit = named.get(q)
            if not hit:   # whole-word containment either way, longest name first
                cands = [k for k in keys if len(k) >= 5 and (re.search(r'(?<!\w)' + re.escape(k) + r'(?!\w)', q)
                                                              or re.search(r'(?<!\w)' + re.escape(q) + r'(?!\w)', k))]
                if cands:
                    hit = named[max(cands, key=len)]
            if hit:
                big = max(hit, key=lambda h: h[2])
                pos = (big[0], big[1], True)
                break
        if not pos:   # a road or bridge named like the place
            for q in queries(r['place']) + [norm(a) for a in ALIASES.get(int(r['num']), [])]:
                hit = next((v for k, v in roads.items() if k == q or (len(q) >= 8 and q in k)), None)
                if hit:
                    p = max(hit, key=len)
                    pos = (p[len(p) // 4 * 2], p[len(p) // 4 * 2 + 1], True)
                    break
        if not pos:
            first = norm(re.split(r' / |, | \(', r['street'])[0])
            pts = streets.get(first) or next((v for k, v in streets.items() if first and first in k), None)
            if pts:
                pos = (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts), False)
        out[r['num']] = pos
    return out


def districts_of(rws, pos):
    ds = json.loads(read('game/data/districts.json'))['districts']

    def district(x, z):
        for d in ds:
            for ar in d.get('areas', []):
                if inside(x, z, ar):
                    return d['name_en']
        return 'Elsewhere'
    return {r['num']: (district(pos[r['num']][0], pos[r['num']][1]) if pos.get(r['num']) else 'No position')
            for r in rws}


def links(r):
    """Files for this place: specs and photo reports named in its row, if they exist."""
    out = []
    for slug in set(re.findall(r'`([a-z0-9_]+)(?:\.md)?`', r['next'])) | set(re.findall(r'refs/([a-z0-9_]+)/', r['next'])):
        for sub, label in (('specs', 'spec'), ('photo-reports', 'photo report')):
            rel = 'docs/landmarks/%s/%s.md' % (sub, slug)
            if os.path.exists(os.path.join(ROOT, rel)):
                out.append([label + ' ' + slug, rel])
    return out


def checklist():
    text = read('docs/ROADMAP.md')
    sec = text.split('## v1.0 checklist', 1)[1].split('\n## ', 1)[0]
    parts, cur = [], None
    for ln in sec.splitlines():
        m = re.match(r'### (.*)', ln)
        if m:
            cur = [m.group(1).strip(), 0, 0]
            parts.append(cur)
        elif cur and re.match(r'- \[[ xX]\]', ln):
            cur[1 if ln[3] in 'xX' else 2] += 1
    return [p for p in parts if p[1] + p[2]]


def backlog_sections():
    text = read('docs/BACKLOG.md')
    out = []
    for m in re.finditer(r'^## (.*)$', text, re.M):
        out.append(m.group(1).strip())
    return out


def map_layers(data):
    """Compact geometry for the canvas: ints in metres, only what reads at city scale."""
    def pts(p, step=1):
        return [int(round(v)) for v in p]
    roads = {'major': [], 'minor': []}
    for r in data['roads']:
        if r['k'] in ('primary', 'secondary', 'primary_link', 'secondary_link'):
            roads['major'].append(pts(r['p']))
        elif r['k'] in ('tertiary', 'residential', 'living_street', 'unclassified'):
            roads['minor'].append(pts(r['p']))
    water = [pts(a['p']) for a in data['areas'] if a['k'] == 'water']
    green = [pts(a['p']) for a in data['areas'] if a['k'] in ('park', 'grass') and len(a['p']) >= 12]
    green = [g for g in green if abs(centroid(g)[2]) > 2500]
    blds = []
    for b in data['buildings']:
        c = centroid(b['p'])
        if c[2] >= 120:
            blds.append(pts(b['p']))
    return {'bounds': data['bounds'], 'outside': data['outside'], 'roads': roads, 'water': water,
            'green': green, 'buildings': blds}


def build():
    data = json.loads(read('game/map/centrum.json'))
    rws = rows()
    pos = locate(data, rws)
    dist = districts_of(rws, pos)
    items = []
    for r in rws:
        p = pos.get(r['num'])
        items.append({'n': int(r['num']), 'place': r['place'], 'street': r['street'], 'kind': r['kind'],
                      'tier': r['tier'], 'stage': r['stage'], 'next': r['next'], 'district': dist[r['num']],
                      'x': round(p[0], 1) if p else None, 'z': round(p[1], 1) if p else None,
                      'exact': bool(p and p[2]), 'links': links(r)})
    placed = sum(1 for i in items if i['x'] is not None)
    exact = sum(1 for i in items if i['exact'])
    cl = checklist()
    payload = {'stages': STAGES, 'items': items, 'map': map_layers(data), 'checklist': cl,
               'backlog_count': len(backlog_sections()), 'placed': placed, 'exact': exact}
    return payload


HTML = r'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Around Warsaw status</title>
<style>
:root{--bg:#14171c;--panel:#1c2027;--ink:#e8eaee;--mut:#8f97a3;--line:#2b313b;--acc:#f1c40f}
@media (prefers-color-scheme:light){:root{--bg:#f3f1ec;--panel:#fff;--ink:#1b1d21;--mut:#5d6570;--line:#dcd8cf}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:14px/1.45 system-ui,sans-serif}
header{padding:12px 16px;border-bottom:1px solid var(--line);display:flex;gap:16px;align-items:baseline;flex-wrap:wrap}
h1{font-size:18px;margin:0}h2{font-size:13px;text-transform:uppercase;letter-spacing:.06em;color:var(--mut);margin:18px 0 8px}
.wrap{display:grid;grid-template-columns:minmax(0,1fr) 380px;gap:0;height:calc(100vh - 54px)}
#mapbox{position:relative;min-height:320px;background:#0e1115}canvas{width:100%;height:100%;display:block;cursor:grab}
#side{overflow:auto;padding:12px 16px;border-left:1px solid var(--line);background:var(--panel)}
.cards{display:grid;grid-template-columns:repeat(2,1fr);gap:8px}.card{border:1px solid var(--line);border-radius:8px;padding:8px 10px}
.big{font-size:22px;font-weight:700}.sub{color:var(--mut);font-size:12px}
.bar{display:flex;height:10px;border-radius:5px;overflow:hidden;background:var(--line);margin:4px 0}.bar i{display:block}
.chips{display:flex;flex-wrap:wrap;gap:6px}.chip{border:1px solid var(--line);border-radius:14px;padding:3px 9px;cursor:pointer;user-select:none;font-size:12px}
.chip.off{opacity:.35}.dot{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:5px;vertical-align:-1px}
input{width:100%;padding:7px 9px;border-radius:6px;border:1px solid var(--line);background:var(--bg);color:var(--ink)}
#list{margin-top:8px}.row{padding:6px 4px;border-bottom:1px solid var(--line);cursor:pointer}.row:hover,.row.sel{background:rgba(127,127,127,.15)}
.row b{font-weight:600}.tag{font-size:11px;color:var(--mut)}
#detail{border:1px solid var(--acc);border-radius:8px;padding:10px;margin-top:10px;display:none}
#detail a{color:var(--acc)}table{width:100%;border-collapse:collapse;font-size:12px}td,th{padding:3px 4px;text-align:left;border-bottom:1px solid var(--line)}
td.r{text-align:right}#legend{position:absolute;left:10px;bottom:10px;background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:6px 10px;font-size:12px;opacity:.95}
@media (max-width:900px){.wrap{grid-template-columns:1fr;height:auto}#mapbox{height:60vh}#side{border-left:0}}
</style></head><body>
<header><h1>Around Warsaw: status</h1><span class="sub" id="gen"></span></header>
<div class="wrap">
 <div id="mapbox"><canvas id="cv"></canvas><div id="legend"></div></div>
 <aside id="side">
  <div class="cards" id="cards"></div>
  <h2>Show</h2><div class="chips" id="stagechips"></div><div class="chips" id="tierchips" style="margin-top:6px"></div>
  <div id="detail"></div>
  <h2>Places</h2><input id="q" placeholder="Search place, street, district…"><div id="list"></div>
  <h2>By tier</h2><div id="tiers"></div>
  <h2>By district</h2><div id="dists"></div>
  <h2>v1.0 checklist (ROADMAP)</h2><div id="road"></div>
 </aside>
</div>
<script>
const D=__DATA__;
const ST=Object.fromEntries(D.stages.map(s=>[s[0],{label:s[1],color:s[2]}]));
const items=D.items,M=D.map;
const on={stage:new Set(D.stages.map(s=>s[0])),tier:new Set(['S','A','B'])};
let sel=null,q='';
const pct=(a,b)=>b?Math.round(100*a/b):0;
document.getElementById('gen').textContent=items.length+' ranked places, '+D.placed+' on the map ('+D.exact+' exact, the rest at their street)';
function bars(list){const n=list.length||1;return '<div class="bar">'+D.stages.map(s=>{const c=list.filter(i=>i.stage===s[0]).length;return '<i title="'+s[1]+': '+c+'" style="width:'+(100*c/n)+'%;background:'+s[2]+'"></i>'}).join('')+'</div>'}
function summary(list){const ph=list.filter(i=>i.stage==='done_photos').length,mo=list.filter(i=>i.stage==='done_photos'||i.stage==='done_outline').length;return {ph,mo,n:list.length}}
(function(){const s=summary(items);
 document.getElementById('cards').innerHTML=
 '<div class="card"><div class="big">'+pct(s.ph,s.n)+'%</div><div class="sub">done from photos ('+s.ph+' of '+s.n+')</div></div>'+
 '<div class="card"><div class="big">'+pct(s.mo,s.n)+'%</div><div class="sub">have a model of their own ('+s.mo+')</div></div>'+
 '<div class="card" style="grid-column:span 2">'+bars(items)+'<div class="sub">'+D.stages.map(x=>'<span class="dot" style="background:'+x[2]+'"></span>'+x[1]+' '+items.filter(i=>i.stage===x[0]).length).join(' · ')+'</div></div>';
 const t=['S','A','B'].map(k=>{const l=items.filter(i=>i.tier===k),z=summary(l);return '<div>Tier '+k+' <span class="sub">'+z.ph+' photo · '+z.mo+' with a model · of '+z.n+' ('+pct(z.ph,z.n)+'% / '+pct(z.mo,z.n)+'%)</span>'+bars(l)+'</div>'}).join('');
 document.getElementById('tiers').innerHTML=t;
 const ds={};items.forEach(i=>(ds[i.district]=ds[i.district]||[]).push(i));
 document.getElementById('dists').innerHTML='<table><tr><th>District</th><th class="r">Places</th><th class="r">Photo</th><th class="r">Model</th></tr>'+Object.entries(ds).sort((a,b)=>b[1].length-a[1].length).map(([k,l])=>{const z=summary(l);return '<tr><td>'+k+'</td><td class="r">'+z.n+'</td><td class="r">'+pct(z.ph,z.n)+'%</td><td class="r">'+pct(z.mo,z.n)+'%</td></tr>'}).join('')+'</table>';
 let d=0,o=0;D.checklist.forEach(c=>{d+=c[1];o+=c[2]});
 document.getElementById('road').innerHTML='<div class="big">'+pct(d,d+o)+'%</div><div class="sub">'+d+' done, '+o+' open</div>'+D.checklist.map(c=>'<div>'+c[0]+' <span class="sub">'+c[1]+' / '+(c[1]+c[2])+'</span><div class="bar"><i style="width:'+pct(c[1],c[1]+c[2])+'%;background:#2e9e5b"></i></div></div>').join('');
 document.getElementById('legend').innerHTML=D.stages.map(x=>'<div><span class="dot" style="background:'+x[2]+'"></span>'+x[1]+'</div>').join('')+'<div class="sub">hollow = at its street, no outline of its own</div>';
 document.getElementById('stagechips').innerHTML=D.stages.map(x=>'<span class="chip" data-s="'+x[0]+'"><span class="dot" style="background:'+x[2]+'"></span>'+x[1]+'</span>').join('');
 document.getElementById('tierchips').innerHTML=['S','A','B'].map(k=>'<span class="chip" data-t="'+k+'">Tier '+k+'</span>').join('');
 document.querySelectorAll('[data-s]').forEach(e=>e.onclick=()=>{const k=e.dataset.s;on.stage.has(k)?on.stage.delete(k):on.stage.add(k);e.classList.toggle('off',!on.stage.has(k));refresh()});
 document.querySelectorAll('[data-t]').forEach(e=>e.onclick=()=>{const k=e.dataset.t;on.tier.has(k)?on.tier.delete(k):on.tier.add(k);e.classList.toggle('off',!on.tier.has(k));refresh()});
})();
const vis=()=>items.filter(i=>on.stage.has(i.stage)&&on.tier.has(i.tier)&&(!q||(i.place+' '+i.street+' '+i.district+' '+i.kind).toLowerCase().includes(q)));
function esc(s){return s.replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]))}
function md(s){return esc(s).replace(/`([^`]+)`/g,'<code>$1</code>').replace(/\*\*([^*]+)\*\*/g,'<b>$1</b>')}
function showList(){const l=vis();document.getElementById('list').innerHTML=l.map(i=>'<div class="row'+(sel===i.n?' sel':'')+'" data-n="'+i.n+'"><span class="dot" style="background:'+ST[i.stage].color+'"></span><b>#'+i.n+' '+esc(i.place)+'</b> <span class="tag">'+i.tier+' · '+esc(i.street)+'</span></div>').join('')||'<div class="sub">Nothing matches.</div>';
 document.querySelectorAll('.row').forEach(e=>e.onclick=()=>select(+e.dataset.n,true))}
function select(n,pan){sel=n;const i=items.find(x=>x.n===n);const d=document.getElementById('detail');
 d.style.display='block';d.innerHTML='<b>#'+i.n+' '+esc(i.place)+'</b><div class="sub">Tier '+i.tier+' · '+esc(i.kind)+' · '+esc(i.street)+' · '+esc(i.district)+'</div><div><span class="dot" style="background:'+ST[i.stage].color+'"></span>'+ST[i.stage].label+'</div><p><b>Next:</b> '+md(i.next)+'</p>'+(i.links.length?'<div>'+i.links.map(l=>'<a href="../../'+l[1]+'">'+esc(l[0])+'</a>').join(' · ')+'</div>':'')+(i.x==null?'<div class="sub">Not placed on the map.</div>':'');
 if(pan&&i.x!=null){view.cx=i.x;view.cz=i.z;view.s=Math.max(view.s,0.5)}refresh()}
const cv=document.getElementById('cv'),cx=cv.getContext('2d');
const view={cx:(M.bounds[0]+M.bounds[2])/2,cz:(M.bounds[1]+M.bounds[3])/2,s:0.12};
let W=0,H=0;
function fit(){const r=cv.getBoundingClientRect(),dpr=devicePixelRatio||1;cv.width=r.width*dpr;cv.height=r.height*dpr;W=r.width;H=r.height;cx.setTransform(dpr,0,0,dpr,0,0)}
const sx=x=>(x-view.cx)*view.s+W/2,sz=z=>(z-view.cz)*view.s+H/2;
function path(p,close){cx.moveTo(sx(p[0]),sz(p[1]));for(let k=2;k<p.length;k+=2)cx.lineTo(sx(p[k]),sz(p[k+1]));if(close)cx.closePath()}
function draw(){cx.clearRect(0,0,W,H);const dark=matchMedia('(prefers-color-scheme:dark)').matches;
 cx.fillStyle=dark?'#171b21':'#e9e5db';const b=M.bounds;cx.fillRect(sx(b[0]),sz(b[1]),(b[2]-b[0])*view.s,(b[3]-b[1])*view.s);
 cx.fillStyle=dark?'#0e1115':'#f3f1ec';M.outside.forEach(o=>cx.fillRect(sx(o[0]),sz(o[1]),(o[2]-o[0])*view.s,(o[3]-o[1])*view.s));
 cx.fillStyle=dark?'#1d3a2a':'#cfe3c4';cx.beginPath();M.green.forEach(p=>path(p,1));cx.fill();
 cx.fillStyle=dark?'#1c3550':'#a9c9e6';cx.beginPath();M.water.forEach(p=>path(p,1));cx.fill();
 cx.strokeStyle=dark?'#2a313b':'#d2cdc0';cx.lineWidth=Math.max(.5,view.s*5);cx.beginPath();M.roads.minor.forEach(p=>path(p));cx.stroke();
 cx.strokeStyle=dark?'#4a5260':'#b9b2a1';cx.lineWidth=Math.max(1,view.s*10);cx.beginPath();M.roads.major.forEach(p=>path(p));cx.stroke();
 cx.fillStyle=dark?'#2d333d':'#c9c3b6';cx.beginPath();M.buildings.forEach(p=>path(p,1));cx.fill();
 const r=Math.max(4,Math.min(11,view.s*18));vis().forEach(i=>{if(i.x==null)return;const x=sx(i.x),y=sz(i.z);if(x<-20||y<-20||x>W+20||y>H+20)return;
  cx.beginPath();cx.arc(x,y,i.n===sel?r+3:r,0,6.283);cx.lineWidth=2;cx.strokeStyle=i.n===sel?'#fff':'#0008';
  if(i.exact){cx.fillStyle=ST[i.stage].color;cx.fill();cx.stroke()}else{cx.strokeStyle=ST[i.stage].color;cx.stroke()}
  if(view.s>0.35){cx.fillStyle=dark?'#fff':'#111';cx.font='11px system-ui';cx.fillText('#'+i.n,x+r+2,y+4)}})}
function refresh(){showList();draw()}
let drag=null,moved=0;
cv.onpointerdown=e=>{drag={x:e.clientX,y:e.clientY,cx:view.cx,cz:view.cz};moved=0;cv.setPointerCapture(e.pointerId)};
cv.onpointermove=e=>{if(!drag)return;const dx=e.clientX-drag.x,dy=e.clientY-drag.y;moved=Math.max(moved,Math.abs(dx)+Math.abs(dy));view.cx=drag.cx-dx/view.s;view.cz=drag.cz-dy/view.s;draw()};
cv.onpointerup=e=>{if(moved<5){const r=cv.getBoundingClientRect(),mx=e.clientX-r.left,my=e.clientY-r.top;let best=null,bd=18*18;vis().forEach(i=>{if(i.x==null)return;const d=(sx(i.x)-mx)**2+(sz(i.z)-my)**2;if(d<bd){bd=d;best=i}});if(best)select(best.n,false)}drag=null};
cv.onwheel=e=>{e.preventDefault();const r=cv.getBoundingClientRect(),mx=e.clientX-r.left,my=e.clientY-r.top;const wx=(mx-W/2)/view.s+view.cx,wz=(my-H/2)/view.s+view.cz;view.s=Math.min(3,Math.max(0.05,view.s*(e.deltaY<0?1.2:1/1.2)));view.cx=wx-(mx-W/2)/view.s;view.cz=wz-(my-H/2)/view.s;draw()};
document.getElementById('q').oninput=e=>{q=e.target.value.toLowerCase();refresh()};
addEventListener('resize',()=>{fit();draw()});fit();
(function(){const b=M.bounds;view.s=Math.min(W/(b[2]-b[0]),H/(b[3]-b[1]))*0.95;refresh()})();
</script></body></html>
'''


def main():
    out = os.path.join(ROOT, 'build', 'status')
    if '--out' in sys.argv:
        out = os.path.abspath(sys.argv[sys.argv.index('--out') + 1])
    if not os.path.exists(os.path.join(ROOT, 'game', 'map', 'centrum.json')):
        print('status_page: game/map/centrum.json is missing, run tools/setup_map.sh (or tools/map_pack.py fetch)')
        sys.exit(1)
    payload = build()
    os.makedirs(out, exist_ok=True)
    path = os.path.join(out, 'index.html')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(HTML.replace('__DATA__', json.dumps(payload, ensure_ascii=False, separators=(',', ':'))))
    n = len(payload['items'])
    print('status_page: %d places, %d on the map (%d exact), wrote %s (%d KB)' %
          (n, payload['placed'], payload['exact'], path, os.path.getsize(path) // 1024))


if __name__ == '__main__':
    main()
