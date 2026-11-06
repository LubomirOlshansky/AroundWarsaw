"""Front edge of each candidate: the longest edge of our outline near Nowy Świat's centreline."""
import json,math,sys,re
S=sys.argv[1]
d=json.load(open(S+'/twport/game/map/centrum.json'))
road=[]
for r in d['roads']:
    if r.get('name')=='Nowy Świat':
        p=list(zip(r['p'][0::2],r['p'][1::2]))
        for (a,b),(c,e) in zip(p,p[1:]):
            n=max(1,int(math.hypot(c-a,e-b)/3)); road+=[(a+(c-a)*t/n,b+(e-b)*t/n) for t in range(n+1)]
meta=json.load(open(S+'/tw/meta.json'))
for r in meta:
    b=d['buildings'][r['bi']]; p=list(zip(b['p'][0::2],b['p'][1::2]))
    best=None
    for i in range(len(p)):
        a,c=p[i-1],p[i]; L=math.hypot(c[0]-a[0],c[1]-a[1])
        if L<3: continue
        m=((a[0]+c[0])/2,(a[1]+c[1])/2)
        dr,q=min((math.hypot(m[0]-x,m[1]-z),(x,z)) for x,z in road)
        sc=L-dr*1.2
        if best is None or sc>best[0]: best=(sc,m,L,dr,q)
    _,m,L,dr,q=best
    r['front']=[round(m[0],1),round(m[1],1)]; r['frontlen']=round(L,1); r['road_d']=round(dr,1); r['roadpt']=[round(q[0],1),round(q[1],1)]
    h=r['head']; mm=re.search(r'Nowy Świat (\d+\w?(?:[/–-]\d+\w?)?)',h) or re.search(r'Nowym Świecie (\d+\w?(?:/\d+)?)',h)
    r['no']=mm.group(1) if mm else ''
    r['title']=(h.split(',')[0].split(':')[0]).strip()
    r['skip_pre']='already built by us' if r['id'] in (71489,11634086) else ''
json.dump(meta,open(S+'/tw/meta.json','w'),ensure_ascii=False,indent=0)
print([ (r['no'],r['road_d']) for r in meta])
