from pathlib import Path
import runpy,shutil,hashlib,json,struct,sys
label=sys.argv[1];source=Path(sys.argv[2]);out=Path(__file__).resolve().parent/label;out.mkdir()
image=out/'working.img';shutil.copyfile(source,image);before=hashlib.sha256(source.read_bytes()).hexdigest()
Guest=runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest'];g=Guest(image,out/'guest',True,ram_mib=8,reference_cpus=1)
try:
 g.wait('DONE native kernel startup\n');g.call('stop');g.call('pmemsave',val=0,size=8*1024*1024,filename=str(out/'memory.bin'))
finally:g.close()
b=(out/'memory.bin').read_bytes();r=dict(result='pass',scope='Physical heap state immediately after startup; no user command yet',image_sha256=before,heaps={})
for name,address in [('kernel',0x102538),('fallback',0x102550)]:
 base,size,used,peak,count,sig=struct.unpack_from('<6I',b,address);assert sig==0x48323349
 rows=[];off=0;actual=0
 while off<size:
  span,request,tag,reserved=struct.unpack_from('<4I',b,base+off);assert span>=24 and not span&7 and span<=size-off and not reserved
  assert tag in (0x46523349,0x55523349)
  if tag==0x55523349:actual+=span
  rows.append(dict(address=base+off,span=span,requested=request,free=tag==0x46523349));off+=span
 assert actual==used and sum(not row['free'] for row in rows)==count
 free=[x['span']-16 for x in rows if x['free']]
 r['heaps'][name]=dict(base=base,size=size,used=used,allocations=count,free_payload=sum(free),largest_free=max(free,default=0),large_used=[row for row in rows if not row['free'] and row['requested']>200000],blocks=rows)
assert hashlib.sha256(source.read_bytes()).hexdigest()==before
(out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
print(json.dumps({n:{k:v for k,v in h.items() if k not in ('blocks',)} for n,h in r['heaps'].items()},indent=2))
