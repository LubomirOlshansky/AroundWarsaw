"""For each building: find 360 photos in the street before its front, cut a flat view looking at the front.
Usage: MAPILLARY_TOKEN=... python3 pano.py SCRATCH  (writes tw/flat/ID_k.jpg and tw/flat.json)"""
import json,math,os,sys,urllib.parse,urllib.request,io
from concurrent.futures import ThreadPoolExecutor
from PIL import Image
S=sys.argv[1]
import re
LAT0,LON0,MLA,MLO=52.234,21.024,110574.0,68176.60465478347
un=lambda x,z:(LAT0-z/MLA,LON0+x/MLO)
pr=lambda la,lo:((lo-LON0)*MLO,(LAT0-la)*MLA)
tok=os.environ['MAPILLARY_TOKEN']
def query(x,z,r):
    la,lo=un(x,z); d=r/MLA; e=r/MLO
    q=urllib.parse.urlencode({'access_token':tok,'bbox':f'{lo-e:.6f},{la-d:.6f},{lo+e:.6f},{la+d:.6f}','limit':200,'fields':'id,captured_at,computed_compass_angle,compass_angle,geometry,thumb_2048_url,is_pano,creator'})
    return json.load(urllib.request.urlopen('https://graph.mapillary.com/images?'+q,timeout=40)).get('data',[])
def flat(im,azi,el=14,fov=78,W=640,H=480):
    w,h=im.size; px=im.load(); out=Image.new('RGB',(W,H)); po=out.load()
    f=W/2/math.tan(math.radians(fov/2)); ce,se=math.cos(math.radians(el)),math.sin(math.radians(el))
    for j in range(H):
        y=(H/2-j)/f
        for i in range(W):
            x=(i-W/2)/f
            # camera axes: forward tilted up by el
            fy=se+y*ce; fz=ce-y*se
            lon=math.atan2(x,fz); lat=math.atan2(fy,math.hypot(x,fz))
            u=((azi/360+lon/(2*math.pi))%1)*w; v=(0.5-lat/math.pi)*h
            po[i,j]=px[min(w-1,int(u)),min(h-1,int(v))]
    return out
RAD=int(os.environ.get('RAD','40'))
meta=[r for r in json.load(open(S+'/tw/meta.json')) if not r['skip_pre']]
os.makedirs(S+'/tw/flat',exist_ok=True)
res={}
def one(r):
    fx,fz=r['front']; rx,rz=r['roadpt']; nx,nz=rx-fx,rz-fz; l=math.hypot(nx,nz) or 1; nx/=l; nz/=l
    try: data=query(rx,rz,RAD)
    except Exception as e: print('fail',r['id'],type(e).__name__); return
    c=[]
    for f in data:
        lo,la=f['geometry']['coordinates']; x,z=pr(la,lo)
        dx,dz=x-fx,z-fz; out=dx*nx+dz*nz; along=abs(dx*-nz+dz*nx); hd=f.get('computed_compass_angle',f.get('compass_angle')) or 0
        if out<3: continue
        if f.get('is_pano'):
            sc=abs(out-14)+along*1.2
        else:
            b=math.degrees(math.atan2(fx-x,-(fz-z))); off=abs((hd-b+180)%360-180)
            if off>45: continue
            sc=abs(out-14)+along*1.2+off*.5+12
        c.append((sc,f,x,z,hd))
    c.sort(key=lambda t:t[0])
    picked=[]; seen=[]
    for sc,f,x,z,hd in c:
        if any(math.hypot(x-a,z-b)<3 for a,b in seen): continue
        seen.append((x,z))
        try:
            im=Image.open(io.BytesIO(urllib.request.urlopen(f['thumb_2048_url'],timeout=40).read())).convert('RGB')
        except Exception: continue
        name=f"{r['id']}_{len(picked)}.jpg"
        if f.get('is_pano') and abs(im.width/im.height-2)<.1:
            b=math.degrees(math.atan2(fx-x,-(fz-z)))
            flat(im,(b-hd)+180,el=12 if math.hypot(fx-x,fz-z)>15 else 18).save(S+'/tw/flat/'+name,quality=86)
        else:
            im.thumbnail((640,480)); im.save(S+'/tw/flat/'+name,quality=86)
        picked.append(dict(file=name,id=f['id'],url=f"https://www.mapillary.com/app/?pKey={f['id']}",by=(f.get('creator') or {}).get('username',''),lic='CC-BY-SA-4.0',pano=bool(f.get('is_pano')),date=str(f.get('captured_at'))[:10]))
        if len(picked)>=3: break
    res[str(r['id'])]=picked; print(r['no'],len(picked),flush=True)
ids=sys.argv[2].split(',') if len(sys.argv)>2 else None
todo=[r for r in meta if not ids or str(r['id']) in ids]
with ThreadPoolExecutor(3) as p: list(p.map(one,todo))
old=json.load(open(S+'/tw/flat.json')) if os.path.exists(S+'/tw/flat.json') else {}
old.update(res)
json.dump(old,open(S+'/tw/flat.json','w'),indent=0)
