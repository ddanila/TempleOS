import hashlib,json,re,runpy,struct,subprocess
from pathlib import Path
from PIL import Image
ROOT=Path.cwd();OUT=Path(__file__).parent
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
BASE='a46e151a';checked=[]
def receipt(name,result='pass'):
 p=Path('build')/name;r=json.loads((p/'result.json').read_text());assert r['result']==result and r['inputs_unchanged'],(name,r.get('error'))
 for n,h in r.get('input_sha256',{}).items():
  f=Path(n)
  if sha(f)==h:continue
  if f.name=='test-i386-pen-init-recovery.py' and (p/'runner-source.py').exists():assert sha(p/'runner-source.py')==h;continue
  rel=str(f.relative_to(ROOT)) if f.is_absolute() else str(f)
  old=subprocess.check_output(['git','show',BASE+':'+rel]);assert hashlib.sha256(old).hexdigest()==h,(name,rel)
 checked.append(name);return p,r
build=json.loads(Path('build/i386-dc-constructor-scope-cross-v1/result.json').read_text())
for key in ('source_sha256','build_inputs_sha256'):
 for n,h in build[key].items():assert sha(n)==h,n
boot=json.loads(Path('build/rebuild-test/result.json').read_text());assert boot['result']=='pass'
for n,h in boot['source_sha256'].items():assert sha(n)==h,n
old=json.loads(Path('build/i386-managed-pointer-cross-v5/result.json').read_text())
changed=[n for n,h in build['modules'].items() if old['modules'][n]!=h];assert changed==['Kernel','ConsoleRuntime']
assert build['kernel_bytes']==458680
prior=subprocess.check_output(['git','show',BASE+':Kernel/I386/RenderScope.HC']).decode();a=prior.index('class CNativeRenderScope');b=prior.index('\nCNativeRenderScope *native_render_scopes;',a)
assert prior[a:b] in Path('Kernel/I386/RenderScope.HH').read_text()
pack=runpy.run_path('tools/package-i386-native-image.py');model=runpy.run_path('tools/test-i386-graphics-pens.py')['expected']()
metrics=[]
for name,want,image in [('pen-init-recovery-before-v3','fail','build/i386-managed-pointer-cross-v5/kernel.img'),('pen-init-recovery-fixed-v2','pass','build/i386-dc-constructor-scope-cross-v1/kernel.img')]:
 p,r=receipt(name,want);raw=(p/'pen-recovery.bin').read_bytes();values=struct.unpack('<192q',raw);rows=[list(values[i:i+24]) for i in range(0,192,24)];assert rows==r['rows']
 for i,v in enumerate(rows):
  assert v[:4]==[i//4,(1,33,128,256)[i%4],(1,33,128,256)[i%4],2 if i<4 else 0]
  assert v[12:16]==[1]*4 and v[10]==v[11]
  assert v[6]-v[4]==v[17]-v[16] and v[7]-v[5]==v[19]-v[18]
  assert v[9]-v[8]==(392 if want=='fail' and i>=4 else 0)
 assert (p/'graphics-pens.bin').read_bytes()==model and r['retry_pen_bytes']==len(model) and r['fresh_result'] and r['files_unchanged']
 tree=pack['snapshot']((p/'working.img').read_bytes())[1];source=pack['snapshot'](Path(image).read_bytes())[1]
 code=(p/'delivered.HC').read_bytes();assert tree=={**source,'/Probe/PenRecovery.HC':(2048,0,code)}
 module=source['/Modules/I386/ConsoleRuntime.t32m'][2];assert hashlib.sha256(module).hexdigest()==r['module_sha256']
 memory=source['/Modules/I386/MemoryRuntime.t32m'][2];assert hashlib.sha256(memory).hexdigest()==r['memory_module_sha256']
 if want=='pass':
  _,count,records=struct.unpack_from('<III',memory,16);offsets=[]
  for i in range(count):
   kind,offset,n,length=struct.unpack_from('<4I',memory,records+i*16)
   if kind==1 and memory[n:n+length]==b'MemoryCAllocExact':offsets.append(offset)
  assert len(offsets)==1 and r['allocator_address']==r['runtime_memory_base']+offsets[0]
  assert r['allocator_restored'] and (p/'allocator-before.bin').read_bytes()==(p/'allocator-after.bin').read_bytes()==struct.pack('<I',r['allocator_address'])
 metrics.append(dict(receipt=name,adam_deltas=[v[9]-v[8] for v in rows],main_backing_reconciled=True))
for name,ref in [('msg-loop-dc-scope-native-v1','msg-loop-frames-original-v3'),('msg-loop-dc-scope-shift-native-v1','msg-loop-frames-shift-original-v3')]:
 p,r=receipt(name);q=Path('build')/ref;assert r['pixels']==307200 and r['raster_equal'] and r['fresh_result'] and r['files_unchanged']
 for file in ('msg-loop.DD','msg-loop-stream.bin','msg-loop-return.bin','msg-loop-mask.bin'):assert (p/file).read_bytes()==(q/file).read_bytes()
 assert Image.open(p/'guest/program-final.png').convert('RGB').tobytes()==Image.open(q/'guest/program-final.png').convert('RGB').tobytes()
p,r=receipt('dc-constructor-control-retirement-v1');assert (p/'modes.bin').read_bytes()==struct.pack('<3q',255,255,255) and r['files_unchanged'] and r['fresh_result']
p,r=receipt('dc-constructor-user-legacy-v1');assert r['pixels']==614400 and r['mask']==3 and (p/'UserLegacy.DD').read_bytes()==b'abc\x05'
console_pixels=runpy.run_path('tools/i386-kernel-input.py')['console_pixels']
for label,suffix in [('typed',''),('saved',' - Saved')]:
 rows=['TempleOS i386','DolDoc editor'+suffix,'C:/UserLegacy.DD','','abc'+bytes([0xDB]).decode('cp437')]
 assert Image.open(p/'guest'/(label+'.png')).convert('RGB').tobytes()==console_pixels(rows)
p,r=receipt('dc-constructor-context-v1');assert r['groups']==20 and r['allocation_checks']==2 and r['files_unchanged'] and r['fresh_result']
p,r=receipt('dc-constructor-user-8m-v1');assert r['ram_mib']==8 and r['managed_pointer'] and any(c[0]=='USCheck;' and c[1]==['255'] for c in r['commands'])
p,r=receipt('dc-constructor-startup-8m-v1');assert r['startup_60s_gate'] and r['startup_seconds']<=60 and r['other_qemu_processes_before']==[]
report=dict(result='pass',source_pins=len(build['source_sha256']),helper_pins=len(build['build_inputs_sha256']),kernel_bytes=build['kernel_bytes'],changed_modules=changed,checked_receipts=checked,metrics=metrics,retry_pen_bytes=len(model),startup_seconds=r['startup_seconds'],scope='DCNew unpublished-header cancellation recovery and recorded regressions only. Shared backing is reconciled, not assumed zero-growth; default scheduling/all resources/C1-C5 remain open,2/686.')
(OUT/'result.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
