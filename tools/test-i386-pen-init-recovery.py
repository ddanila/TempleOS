#!/usr/bin/env python3
"""Inject throw/Kill at the actual graphics body allocator during native pen startup."""
import argparse,hashlib,json,re,runpy,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',required=True,type=Path);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 fixture=ROOT/'tests/guest/i386-pen-init-recovery/Contract.HC';pens=ROOT/'tests/guest/i386-graphics-pens/Contract.HC'
 paths=[a.disk.resolve(),fixture,pens,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ['package-i386-native-image.py','build-i386-kernel.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','test-i386-graphics-pens.py']]+[ROOT/n for n in ['Kernel/FontStd.HC','Kernel/I386/GraphicsContext.HC','Kernel/I386/GraphicsPens.HC','Kernel/I386/RenderScope.HC','Adam/Gr/GrDCCore.HC','Kernel/I386/Heap.HH','Kernel/I386/Scheduler.HH','Kernel/I386/MemoryBacking.HH','Kernel/I386/DCNewScope.HC','Kernel/I386/DCNewScope.HH','Kernel/I386/RenderScope.HH','Kernel/I386/Memory.HH','Kernel/MemoryTypes.HH','Kernel/MemoryAllocTypes.HH']]
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();out.mkdir();pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'pens.HC').write_bytes(pens.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None
 report=dict(result='running',input_sha256=pins,scope='Actual normal-image pen constructors: throw before body allocation or Kill while allocator yields, at1/33/128/256; complete table/state cleanup, exact Adam/caller logical recovery and physical main-heap changes fully reconciled to validated backing regions, successful public retry and all pen bytes. Existing allocator callback is temporarily replaced and restored; no pen implementation substitute. Not every allocation/cancellation/resource/C1-C5 qualification.')
 try:
  pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));source=pack['snapshot'](a.disk.read_bytes())[1];module=source['/Modules/I386/ConsoleRuntime.t32m'][2];size,count,records=struct.unpack_from('<III',module,16)
  wanted={'native_graphics_body_calloc','native_graphics_pens_ready','native_graphics_pen_builder','native_render_scopes'};offsets={};ranges=[]
  for i in range(count):
   kind,offset,name,length=struct.unpack_from('<4I',module,records+i*16);symbol=module[name:name+length].decode('ascii') if kind in (1,2,3) else ''
   if kind==4:ranges.append((offset,offset+name))
   if kind==3 and symbol in wanted:assert symbol not in offsets;offsets[symbol]=offset
  assert offsets.keys()==wanted
  assert all(any(lo<=o and o+(1 if n=='native_graphics_pens_ready' else 4)<=hi for lo,hi in ranges) for n,o in offsets.items())
  report['module_sha256']=hashlib.sha256(module).hexdigest();report['private_data_offsets']=offsets
  memory=source['/Modules/I386/MemoryRuntime.t32m'][2];_,mn,mrecords=struct.unpack_from('<III',memory,16);pool_offsets=[];allocator_offsets=[]
  for i in range(mn):
   kind,o,n,l=struct.unpack_from('<4I',memory,mrecords+i*16)
   if kind==3 and memory[n:n+l]==b'memory_pool':pool_offsets.append(o)
   if kind==1 and memory[n:n+l]==b'MemoryCAllocExact':allocator_offsets.append(o)
  assert len(pool_offsets)==len(allocator_offsets)==1
  report['memory_module_sha256']=hashlib.sha256(memory).hexdigest();report['memory_pool_offset']=pool_offsets[0]
  bind='\nU0 PCBind(U8 *base,U8 *memory){pc_pool=memory+0x%X;pc_slot=base+0x%X;pc_ready=base+0x%X;pc_builder=base+0x%X;pc_scope_head=base+0x%X;}\n'%tuple([pool_offsets[0]]+[offsets[n] for n in ['native_graphics_body_calloc','native_graphics_pens_ready','native_graphics_pen_builder','native_render_scopes']])
  code=fixture.read_bytes()+pens.read_bytes()+bind.encode();(out/'delivered.HC').write_bytes(code);image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/PenRecovery.HC':code});before=pack['snapshot'](image.read_bytes())[1]
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',True);g.wait('DONE native kernel startup\n');match=re.search(r'^CONSOLE ([0-9A-F]+) ',g.collect(),re.M);assert match;base=int(match[1],16)+8;report['runtime_module_base']=base;mm=re.search(r'^MEMORY ([0-9A-F]+) ',g.collect(),re.M);assert mm;memory_base=int(mm[1],16)+8;report['runtime_memory_base']=memory_base
  g.command('#include "/Kernel/I386/PublicUser.HH"');g.command('#include "C:/Probe/PenRecovery.HC"')
  slot=base+offsets['native_graphics_body_calloc']
  g.call('pmemsave',val=slot,size=4,filename=str(out/'allocator-before.bin'))
  original=struct.unpack('<I',(out/'allocator-before.bin').read_bytes())[0];assert original==memory_base+allocator_offsets[0]
  report['allocator_address']=original
  g.command(f'PCBind(0x{base:X},0x{memory_base:X});PCProbe;GPProbe;',timeout=300)
  g.wait('PEN RECOVERY DONE\n');g.wait('GRAPHICS PENS DONE\n')
  g.call('pmemsave',val=slot,size=4,filename=str(out/'allocator-after.bin'))
  assert (out/'allocator-before.bin').read_bytes()==(out/'allocator-after.bin').read_bytes();report['allocator_restored']=True
  for name in ('pen-recovery.bin','graphics-pens.bin'):(out/name).write_bytes((g.out/name).read_bytes())
  values=struct.unpack('<192q',(out/'pen-recovery.bin').read_bytes());rows=[list(values[i:i+24]) for i in range(0,192,24)];report['rows']=rows
  report['heap_deltas']=[dict(main=r[6]-r[4],allocations=r[7]-r[5],adam=r[9]-r[8],caller=r[11]-r[10],main_backing=r[17]-r[16],main_regions=r[19]-r[18]) for r in rows]
  expected=runpy.run_path(str(ROOT/'tools/test-i386-graphics-pens.py'))['expected']();assert (out/'graphics-pens.bin').read_bytes()==expected;report['retry_pen_bytes']=len(expected)
  g.command('6*7;');report['fresh_result']=g.result_pixels();g.close();g=None
  assert pack['snapshot'](image.read_bytes())[1]==before;report['files_unchanged']=True
  for i,r in enumerate(rows):
   assert r[:4]==[i//4,(1,33,128,256)[i%4],(1,33,128,256)[i%4],2 if i<4 else 0],(i,r)
   if any(r[x]!=r[y] for x,y in ((8,9),(10,11))) or r[6]-r[4]!=r[17]-r[16] or r[7]-r[5]!=r[19]-r[18] or r[12:16]!=[1]*4:raise ValueError(f'Pen recovery differs at trial{i}: {r}')
  report['result']='pass'
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
