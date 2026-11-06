"""Select Tiny Warsaw models on Nowy Świat: frame, match by IoU to our outlines."""
import json,math,cmath,sys
root,out=sys.argv[1],sys.argv[2]
ROT=cmath.exp(1j*math.radians(1.4651)); MOVE=complex(-1228.52,240.62)
def tf(x,z):
    c=ROT*complex(x,z)+MOVE; return c.real,c.imag
def area(p):
    return abs(sum(p[i-1][0]*p[i][1]-p[i][0]*p[i-1][1] for i in range(len(p))))/2
def cen(p):
    a=cx=cz=0
    for i in range(len(p)):
        x0,z0=p[i-1];x1,z1=p[i];k=x0*z1-x1*z0;a+=k;cx+=(x0+x1)*k;cz+=(z0+z1)*k
    return (cx/(3*a),cz/(3*a)) if abs(a)>1e-6 else p[0]
def inside(x,z,poly):
    c=False
    for i in range(len(poly)):
        x1,z1=poly[i];x2,z2=poly[i-1]
        if (z1>z)!=(z2>z) and x<(x2-x1)*(z-z1)/(z2-z1)+x1:c=not c
    return c
def iou(a,b,dx=0,dz=0,step=1.0):
    xs=[q[0]+dx for q in a]+[q[0] for q in b];zs=[q[1]+dz for q in a]+[q[1] for q in b]
    A=[(q[0]+dx,q[1]+dz) for q in a];i=u=0;x=min(xs)
    while x<max(xs):
        z=min(zs)
        while z<max(zs):
            ia=inside(x,z,A);ib=inside(x,z,b)
            i+=ia and ib;u+=ia or ib;z+=step
        x+=step
    return i/u if u else 0
d=json.load(open(root+'/game/map/centrum.json'))
idx=json.load(open(__import__('os').path.expanduser('~/Downloads/models_/index.json')))
road=[]
for r in d['roads']:
    if r.get('name')=='Nowy Świat':
        road+=list(zip(r['p'][0::2],r['p'][1::2]))
print('road pts',len(road),min(p[0] for p in road),max(p[0] for p in road),min(p[1] for p in road),max(p[1] for p in road))
def seg_d(x,z):
    return min(math.hypot(x-a,z-b) for a,b in road)
# densify road
dense=[]
for r in d['roads']:
    if r.get('name')=='Nowy Świat':
        p=list(zip(r['p'][0::2],r['p'][1::2]))
        for (a,b),(c,e) in zip(p,p[1:]):
            n=max(1,int(math.hypot(c-a,e-b)/4))
            dense+=[(a+(c-a)*t/n,b+(e-b)*t/n) for t in range(n+1)]
road=dense
bl=[]
for i,b in enumerate(d['buildings']):
    p=list(zip(b['p'][0::2],b['p'][1::2]))
    if len(p)<3: continue
    dm=min(seg_d(x,z) for x,z in p)
    if dm<28: bl.append((i,b,p,cen(p)))
print('our buildings near street',len(bl))
res=[]
for t in idx:
    if 'footprint' not in t or not t['footprint']: continue
    fp=[tf(x,z) for x,z in t['footprint']]
    c=cen(fp)
    if seg_d(*c)>70: continue
    best=None
    for i,b,p,oc in bl:
        if math.hypot(c[0]-oc[0],c[1]-oc[1])>45: continue
        dx,dz=oc[0]-c[0],oc[1]-c[1]
        v=iou(fp,p,dx,dz)
        if not best or v>best[0]: best=(v,i,dx,dz,b)
    res.append(dict(id=t['id'],name=t['name'],ground=t.get('ground'),area=round(area(fp)),iou=round(best[0],2) if best else 0,bi=best[1] if best else None,dx=round(best[2],1) if best else None,dz=round(best[3],1) if best else None,oname=best[4]['name'] if best else '',kind=best[4]['kind'] if best else '',h=best[4]['h'] if best else 0,cx=round(c[0]),cz=round(c[1])))
res.sort(key=lambda r:r['cz'])
json.dump(res,open(out,'w'),ensure_ascii=False,indent=0)
for r in res: print(r['id'],r['name'],'|',r['area'],'iou',r['iou'],'off',r['dx'],r['dz'],'|',r['oname'],r['kind'],r['h'],'@',r['cx'],r['cz'])
print(len(res))
used={r['bi'] for r in res if r['iou']>=.6}
print('ours unmatched:')
for i,b,p,oc in bl:
    if i not in used: print(i,b['name'],b['kind'],b['h'],round(area(p)),[round(v) for v in oc])
