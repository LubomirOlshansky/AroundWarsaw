"""Read each matched model's own data: address, floors, edges; write fronts with game coordinates."""
import json,re,math,cmath,sys
S=sys.argv[1]
ROT=cmath.exp(1j*math.radians(1.4651)); MOVE=complex(-1228.52,240.62)
def tf(x,z):
    c=ROT*complex(x,z)+MOVE; return c.real,c.imag
sel=[r for r in json.load(open(S+'/tw/selected.json')) if r['iou']>=.6]
out=[]
for r in sel:
    t=open(f"{S}/twmodels/{r['id']}.js").read()
    head=t.split('\n')[0:3]
    m=re.search(r'const C=(\{.*?\});\n',t,re.S)
    C=None
    try: C=json.loads(m.group(1))
    except Exception as e: pass
    r['head']=head[0][3:120]
    if C:
        r['addr']=C.get('name'); r['floors']=C.get('floors'); r['eave']=C.get('eave'); r['wall']=C.get('wall'); r['roof']=C.get('roof')
        ed=C.get('edges') or []
        fr=[e for e in ed if len(e)>5 and e[5]] or [e for e in ed if len(e)>4 and e[4]]
        if fr:
            e=max(fr,key=lambda e:math.hypot(e[2]-e[0],e[3]-e[1]))
            x,z=tf((e[0]+e[2])/2,(e[1]+e[3])/2)
            r['front']=[round(x+r['dx'],1),round(z+r['dz'],1)]
            r['frontlen']=round(math.hypot(e[2]-e[0],e[3]-e[1]),1)
    out.append(r)
json.dump(out,open(S+'/tw/meta.json','w'),ensure_ascii=False,indent=0)
for r in out: print(r['id'],r.get('addr') or r['name'],'|',r.get('floors'),r.get('eave'),r.get('wall'),r.get('roof'),r.get('front'),r.get('frontlen'),'|',r['head'][:70])
