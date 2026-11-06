"""Which LoD2 footprints sit under each ported outline, and is their box centre inside it?"""
import json,sys
S=sys.argv[1]
f=json.load(open(S+'/twport/game/map/lod2.json'))['footprints']
idx=json.load(open(S+'/twport/game/data/tw_port/index.json'))
meta={str(r['id']):r for r in json.load(open(S+'/tw/meta.json'))}
def inside(x,z,p):
    c=False
    for i in range(len(p)):
        x1,z1=p[i];x2,z2=p[i-1]
        if (z1>z)!=(z2>z) and x<(x2-x1)*(z-z1)/(z2-z1)+x1:c=not c
    return c
L=[]
for q in f:
    p=list(zip(q[0::2],q[1::2]))
    xs=[a for a,b in p];zs=[b for a,b in p]
    L.append((p,(min(xs)+max(xs))/2,(min(zs)+max(zs))/2,min(xs),max(xs),min(zs),max(zs)))
out={}
for d in idx:
    o=list(zip(d['outline'][0::2],d['outline'][1::2]))
    ox=[a for a,b in o];oz=[b for a,b in o]
    ex=[]
    for p,cx,cz,x0,x1,z0,z1 in L:
        if x1<min(ox) or x0>max(ox) or z1<min(oz) or z0>max(oz): continue
        n=h=0
        x=x0
        while x<x1:
            z=z0
            while z<z1:
                if inside(x,z,p):
                    n+=1; h+=inside(x,z,o)
                z+=1.0
            x+=1.0
        if n and h/n>.5 and not inside(cx,cz,o):
            ex.append([round(cx,1),round(cz,1)]); print(meta[d['id']]['no'],d['id'],'lod2 centre outside',round(cx),round(cz),'share',round(h/n,2),'area',n)
    if ex: out[d['id']]=ex
json.dump(out,open(S+'/tw/extra.json','w')); print(len(out))
