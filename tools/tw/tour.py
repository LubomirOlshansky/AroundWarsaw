"""Write the camera tour: one stop per building, facing its street front a little obliquely."""
import json,math,sys
S=sys.argv[1]; suffix=sys.argv[2] if len(sys.argv)>2 else ''
meta=json.load(open(S+'/tw/meta.json'))
stops=[]
for r in meta:
    if r['skip_pre']: continue
    fx,fz=r['front']; rx,rz=r['roadpt']
    vx,vz=fx-rx,fz-rz; l=math.hypot(vx,vz) or 1; vx/=l; vz/=l
    bearing=math.degrees(math.atan2(vx,-vz))
    yaw=(360-bearing+14)%360
    size=max(26,min(56,r['frontlen']*1.0+13))
    stops.append([round(fx+vx*6,1),round(fz+vz*6,1),round(yaw,1),-40,round(size,1),f"{r['id']}{suffix}"])
json.dump(stops,open(S+f'/tw/tour{suffix}.json','w'))
print(len(stops),stops[:2])
