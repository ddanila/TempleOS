import hashlib,json,struct,runpy,subprocess
from pathlib import Path
ROOT=Path.cwd();OUT=Path(__file__).parent
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
checked=[];rejected=0;historical_source_pins=[];iso_cache={}

def receipt(name,expected='pass'):
 p=Path('build')/name;r=json.loads((p/'result.json').read_text())
 assert r['result']==expected,(name,r.get('error'))
 assert r.get('inputs_unchanged',True)
 for filename,h in r.get('input_sha256',{}).items():
  f=Path(filename)
  if f.name.startswith('test-') and f.parent.name=='tools' and sha(f)!=h and (p/'runner-source.py').exists():f=p/'runner-source.py'
  if sha(f)!=h and '/build/rebuild-test/' in str(f):
   relative=str(f).split('/build/rebuild-test/',1)[1]
   candidates=list(Path('build').glob('rebuild-test-before-*/'+relative))
   matches=[c for c in candidates if sha(c)==h]
   assert matches,(name,str(f));f=matches[0]
  if sha(f)!=h and name in ('user-constructor-current-original-v1','user-main-heap-before-cells-v1','user-startup-scroll-original-v1') and f.suffix in ('.HC','.HH') and 'tests/guest' not in str(f):
   iso=p/'original.iso'
   assert iso.exists(),(name,'historical ISO missing')
   if name not in iso_cache:
    read=runpy.run_path('tools/package-i386-native-image.py')['snapshot'];read.__globals__['START']=88
    iso_cache[name]=read(iso.read_bytes())[1]
   rel='/'+str(f.relative_to(ROOT))
   assert hashlib.sha256(iso_cache[name][rel][2]).hexdigest()==h,(name,rel)
   historical_source_pins.append(dict(receipt=name,path=str(f),sha256=h,verified_in=str(iso)));continue
  assert sha(f)==h,(name,str(f))
 checked.append(name);return p,r
build=json.loads(Path('build/i386-user-startup-cross-v5/result.json').read_text())
for key in ('source_sha256','build_inputs_sha256'):
 for n,h in build[key].items():assert sha(n)==h,n
bootstrap=json.loads(Path('build/rebuild-test/result.json').read_text());assert bootstrap['result']=='pass'
for n,h in bootstrap['source_sha256'].items():assert sha(n)==h,n
old=json.loads(Path('build/i386-terminal-scrolls-cross-v1/result.json').read_text())
changed=[n for n,h in build['modules'].items() if old['modules'][n]!=h]
assert changed==['Kernel','ConsoleRuntime'] and build['kernel_bytes']==458680
expanded=Path('HomeSys.HC').read_bytes()
for n in ('User','Srv'):
 expanded=expanded.replace(f'#include "/Adam/{n}StartUpCore.HC"'.encode(),Path(f'Adam/{n}StartUpCore.HC').read_bytes().rstrip(b'\n'))
for rev in ('c26482bb6ad3f80106d28504ec5db3c6a360732c','ce055f205fc38536443289fb1cfc73632f6624f4'):
 assert expanded==subprocess.check_output(['git','show',rev+':HomeSys.HC'])
for name in ('user-constructor-current-original-v1','user-constructor-native-v4','user-constructor-native-8m-v2','user-hook-original-v2','user-hook-native-v3'):
 receipt(name)
model=runpy.run_path('tools/test-i386-dir-output.py')['listing']
for name in ('dir-output-original-v8','dir-output-native-v4'):
 p,r=receipt(name);assert r['counts']==[3,3,0,1]
 for case in ('default','full','empty','mask'):
  raw=(p/f'dir-{case}.bin').read_bytes();expected=model((p/f'dir-{case}-meta.bin').read_bytes(),case=='full');assert raw==expected
  for i in range(len(raw)):
   bad=bytearray(raw);bad[i]^=1;assert bytes(bad)!=expected;rejected+=1
assert Path('build/dir-output-native-v4/dir-returns.bin').read_bytes()==Path('build/dir-output-original-v8/dir-returns.bin').read_bytes()
for name in ('user-main-heap-native-v3','user-main-heap-before-cells-v1'):
 p,r=receipt(name);raw=(p/'user-main-heap.bin').read_bytes();v=struct.unpack('<24q',raw);assert list(v)==r['values']
 def heap_ok(raw):
  v=struct.unpack('<24q',raw);return all(v[i]==v[i+4] and v[i+1]==v[i+5] for i in (0,8,16))
 assert heap_ok(raw) and r['files_unchanged'] and r['fresh_result']
 for trial in (0,8,16):
  for field in (0,1,4,5):
   for byte in range(8):
    bad=bytearray(raw);bad[(trial+field)*8+byte]^=1;assert not heap_ok(bad);rejected+=1
new=json.loads(Path('build/user-main-heap-native-v3/result.json').read_text())['live_deltas']
old=json.loads(Path('build/user-main-heap-before-cells-v1/result.json').read_text())['live_deltas']
assert [a-b for a,b in zip(old,new)]==[110112]*3
for name in ('user-startup-scroll-original-v1','user-startup-scroll-native-v3'):
 p,r=receipt(name);assert (p/'terminal-scroll.bin').read_bytes()==struct.pack('<9q',1,1,1,1,5,2,0,1,1)
 assert r['lifecycle_mask']==4095
 v=struct.unpack('<12q',(p/'terminal-scroll-lifecycle.bin').read_bytes());assert all(v[i]==v[i+1] and v[i+2]==v[i+3] for i in (0,4,8))
p,r=receipt('user-legacy-native-v3');assert r['pixels']==614400 and r['mask']==3 and r['files_preserved']==1890
p,r=receipt('user-text-projection-vga-v3');assert r['pixels']==307200
read=runpy.run_path('tools/package-i386-native-image.py')['snapshot'];read.__globals__['START']=88
vga_files=read((p/'compiler.iso').read_bytes())[1]
for source,delivered in [('Kernel/I386/Text.HC','/Kernel/I386/Text.HC'),('Kernel/I386/Text.HH','/Kernel/I386/Text.HH'),('tests/guest/i386-vga/Projection.HC','/Projection.HC'),('tests/guest/i386-vga/Target.HC','/Target.HC')]:
 assert vga_files[delivered][2]==Path(source).read_bytes(),source
p,r=receipt('user-startup-startup-8m-v2');assert r['startup_60s_gate'] and r['startup_seconds']<=60 and r['other_qemu_processes_before']==[]
for name,ref in [('msg-loop-user-startup-native-v1','msg-loop-stream-original-v1'),('msg-loop-user-startup-shift-native-v1','msg-loop-stream-shift-original-v1')]:
 p,r=receipt(name,'fail');q=Path('build')/ref
 assert (p/'msg-loop-stream.bin').read_bytes()==(q/'msg-loop-stream.bin').read_bytes()
 assert (p/'msg-loop-mask.bin').read_bytes()==struct.pack('<q',7)
 assert (p/'msg-loop.DD').read_bytes()!=(q/'msg-loop.DD').read_bytes() and r['error']=='Program output differs from original'
p,r=receipt('msg-loop-repeat-original-v1');q=Path('build/msg-loop-stream-original-v1')
assert (p/'msg-loop-stream.bin').read_bytes()==(q/'msg-loop-stream.bin').read_bytes()
assert (p/'msg-loop.DD').read_bytes()!=(q/'msg-loop.DD').read_bytes()
report=dict(result='pass',historical_source_pins_verified_in_iso=historical_source_pins,source_pins=len(build['source_sha256']),helper_pins=len(build['build_inputs_sha256']),changed_modules=changed,checked_receipts=checked,corruptions_rejected=rejected,live_main_heap_saving_per_user=110112,qualification='Partial startup, directory, projection and ownership evidence only. Both strict MsgLoop saved documents fail; C1-C5 remain open,2/686.')
(OUT/'result.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
