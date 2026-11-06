"""LoD2 runs (from lod2.bin) whose triangles sit in a ported outline but whose box centre doesn't."""
import array,json,sys
S=sys.argv[1]
raw=open(S+'/twport/game/map/lod2.bin','rb').read()
n=int.from_bytes(raw[:4],'little'); f=array.array('f'); f.frombytes(raw[4:4+n*14*4])
o2=n*12
idx=json.load(open(S+'/twport/game/data/tw_port/index.json'))
meta={str(r['id']):r for r in json.load(open(S+'/tw/meta.json'))}
def inside(x,z,p):
    c=False
    for i in range(len(p)):
        x1,z1=p[i];x2,z2=p[i-1]
        if (z1>z)!=(z2>z) and x<(x2-x1)*(z-z1)/(z2-z1)+x1:c=not c
    return c
outs=[(d['id'],list(zip(d['outline'][0::2],d['outline'][1::2]))) for d in idx]
X0,X1,Z0,Z1=-470,-120,-500,330
runs=[];t=0
while t<n:
    seed=f[o2+t*2]; x0=x1=f[t*3]; z0=z1=f[t*3+2]; u=t
    while u<n and f[o2+u*2]==seed:
        x=f[u*3]; z=f[u*3+2]
        if abs(x-f[t*3])+abs(z-f[t*3+2])>600: break
        if x<x0:x0=x
        if x>x1:x1=x
        if z<z0:z0=z
        if z>z1:z1=z
        u+=1
    if x1>X0 and x0<X1 and z1>Z0 and z0<Z1: runs.append((t,u,x0,x1,z0,z1))
    t=u
print(len(runs))
extra=json.load(open(S+'/tw/extra.json'))
for t,u,x0,x1,z0,z1 in runs:
    cx,cz=(x0+x1)/2,(z0+z1)/2
    tot=(u-t); hits={}
    for i in range(t,u,3):
        x,z=f[i*3],f[i*3+2]
        for mid,p in outs:
            if inside(x,z,p): hits[mid]=hits.get(mid,0)+1
    if not hits: continue
    mid,h=max(hits.items(),key=lambda kv:kv[1])
    share=h*3/tot
    p=dict(outs)[mid]
    if share>.3 and not inside(cx,cz,p):
        print(meta[mid]['no'],mid,'run',round(cx,1),round(cz,1),'share',round(share,2),'tris',tot//3,'others',{meta[k]['no']:v for k,v in hits.items() if k!=mid})
        extra.setdefault(mid,[]).append([round(cx,1),round(cz,1)])
json.dump(extra,open(S+'/tw/extra.json','w'))
