import hashlib,json,re,runpy,struct,subprocess
from pathlib import Path
from PIL import Image
ROOT=Path.cwd();OUT=Path(__file__).parent
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
expected=runpy.run_path('tools/test-i386-msg-loop.py')['stream_expected']
pack=runpy.run_path('tools/package-i386-native-image.py')
fixture=Path('tests/guest/i386-msg-loop/Contract.HC').read_bytes()
frames=Path('tests/guest/i386-msg-loop/Frames.HC').read_bytes()
start=fixture.index(b'U0 MLObserve(');end=fixture.index(b'U0 MLStart()',start)
harness=(fixture[:start]+frames+fixture[end:]).replace(b'DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS',b'DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS|DOCF_DO_FULL_REFRESH')
checked=[];pixels=0
build=json.loads(Path('build/i386-managed-pointer-cross-v5/result.json').read_text())
for key in ('source_sha256','build_inputs_sha256'):
 for n,h in build[key].items():assert sha(n)==h,n
bootstrap=json.loads(Path('build/rebuild-test/result.json').read_text());assert bootstrap['result']=='pass'
for n,h in bootstrap['source_sha256'].items():assert sha(n)==h,n
old=json.loads(Path('build/i386-user-startup-cross-v5/result.json').read_text())
assert [n for n,h in build['modules'].items() if old['modules'][n]!=h]==['Kernel','ConsoleRuntime']
assert build['kernel_bytes']==458680
for file,cores in [('Adam/Win.HC',['Adam/DrawMouseCore.HC']),('Adam/Gr/GrComposites.HC',['Adam/Gr/DrawStdMouseCore.HC','Adam/Gr/DrawWaitMouseCore.HC'])]:
 expanded=Path(file).read_bytes()
 for core in cores:expanded=expanded.replace(('#include "/'+core+'"').encode(),Path(core).read_bytes().rstrip(b'\n'))
 assert expanded==subprocess.check_output(['git','show','cd7d6521:'+file]),file

def receipt(name):
 p=Path('build')/name;r=json.loads((p/'result.json').read_text())
 assert r['result']=='pass' and r['inputs_unchanged'],(name,r.get('error'))
 for n,h in r['input_sha256'].items():
  f=Path(n)
  if f==ROOT/'tools/test-i386-msg-loop.py':f=p/'runner-source.py'
  if sha(f)!=h and f==ROOT/'tools/build-i386-kernel.py':
   blob=subprocess.check_output(['git','show','cd7d6521:'+str(f.relative_to(ROOT))]);assert hashlib.sha256(blob).hexdigest()==h
  else:assert sha(f)==h,(name,str(f))
 assert (p/'fixture.HC').read_bytes()==fixture
 assert (p/'frame-fixture.HC').read_bytes()==frames
 assert (p/'program.HC').read_bytes()==Path('Demo/MsgLoop.HC').read_bytes()
 assert (p/'msg-loop-stream.bin').read_bytes()==expected(r['shift_exit'])
 assert (p/'msg-loop-mask.bin').read_bytes()==struct.pack('<q',7)
 heaps=struct.unpack('<3q',(p/'msg-loop-heaps.bin').read_bytes());assert heaps[0]==heaps[2]
 states={int(row[0]):tuple(map(int,row[1:])) for row in re.findall(r'ML STATE (\d+) (\d+) (\d+) (\d+) (\d+) ([0-9A-F]+) ([0-9A-F]+)',(p/'guest/debug.log').read_text())}
 required=[0,1,2,3,4,5,6,7,9,11,13,14,15,16,17,18]+([19] if r['shift_exit'] else [])
 assert set(required)<=set(states)<=set(range(20 if r['shift_exit'] else 19)),(name,states.keys())
 assert 'ML WHEEL FRAME\n' in (p/'guest/debug.log').read_text()
 native='native' in name;drive='C' if native else 'T'
 code=harness+f'\nExeFile("{drive}:/Demo/MsgLoop.HC",CCF_JUST_LOAD);\nU0 MLRun(){{MLStart;MsgLoop;MLFinish;}}\nMLRun;\n'.encode()
 if native:
  files=pack['snapshot']((p/'working.img').read_bytes())[1]
  assert files['/Probe/MsgLoopWorkflow.HC'][2]==code
  assert r['harness_sha256']==hashlib.sha256(code).hexdigest()
  source=pack['snapshot'](Path('build/i386-managed-pointer-cross-v5/kernel.img').read_bytes())[1]
  assert files=={**source,'/Probe/MsgLoopWorkflow.HC':(2048,0,code)}
  assert r['pixels']==307200 and r['raster_equal'] and r['fresh_result'] and r['files_unchanged']
 else:
  read=runpy.run_path('tools/package-i386-native-image.py')['snapshot'];read.__globals__['START']=88
  files=read((p/'original.iso').read_bytes())[1]
  assert files['/Once.HC'][2]==b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+code
 assert files['/Demo/MsgLoop.HC'][2]==Path('Demo/MsgLoop.HC').read_bytes()
 image=Image.open(p/'guest/program-final.png').convert('RGB');assert image.size==(640,480)
 if 'raster_sha256' in r:assert hashlib.sha256(image.tobytes()).hexdigest()==r['raster_sha256']
 checked.append(name);return p,r,image.tobytes()

for shift in ('','shift-'):
 originals=[receipt(f'msg-loop-frames-{shift}original-v{i}') for i in (3,4)]
 p,r,rgb=originals[0]
 assert originals[1][2]==rgb
 for file in ('msg-loop.DD','msg-loop-return.bin','msg-loop-stream.bin','msg-loop-mask.bin'):
  assert (p/file).read_bytes()==(originals[1][0]/file).read_bytes(),(shift,file)
 q,native,actual=receipt(f'msg-loop-frames-{shift}native-v7')
 for file in ('msg-loop.DD','msg-loop-return.bin','msg-loop-stream.bin','msg-loop-mask.bin'):
  assert (p/file).read_bytes()==(q/file).read_bytes(),(shift,file)
 assert actual==rgb;pixels+=307200

expected_states=[(1,1,0,0,0,0,0,0),(2,11,0,0,0,0,0,0),(1,511,0,0,0,0,0,0),(1,498,0,0,0,0,0,0),(1,500,0,0,0,0,0,0),(1,498,0,0,0,0,0,0),(5,1,0,0,0,0,0,0),(5,1,0,0,0,0,0,0),(5,2,0,1,0,12,12,0),(5,4,0,0,1,12,12,0),(5,4,0,0,1,12,12,1),(1,511,0,0,0,0,0,0)]
arrow={(12+i,12+i) for i in range(9)}|{(12,12+i) for i in range(1,5)}|{(12+i,12) for i in range(1,5)}
for name in ('draw-mouse-original-v2','draw-mouse-native-v4'):
 p=Path('build')/name;r=json.loads((p/'result.json').read_text());assert r['result']=='pass' and r['inputs_unchanged'] and r['cases']==12
 raw=(p/'draw-mouse-pixels.bin').read_bytes();values=struct.unpack('<96q',(p/'draw-mouse-values.bin').read_bytes())
 assert [tuple(values[i:i+8]) for i in range(0,96,8)]==expected_states
 for case,color in ((0,1),(2,240),(3,253),(4,251),(5,253),(11,240)):
  want=bytes(color if (x,y) in arrow else 15 for y in range(32) for x in range(32));assert raw[case*1024:(case+1)*1024]==want
 for case in (6,7):assert raw[case*1024:(case+1)*1024]==bytes([15])*1024
 for case,width,height,color in ((8,3,2,2),(9,2,3,4),(10,3,3,4)):
  want=bytes(color if 12<=x<12+width and 12<=y<12+height else 15 for y in range(32) for x in range(32));assert raw[case*1024:(case+1)*1024]==want
 ref=Path('build/draw-mouse-original-v2')
 for file in ('draw-mouse-pixels.bin','draw-mouse-values.bin'):assert (p/file).read_bytes()==(ref/file).read_bytes()
 checked.append(name)


pen_model=runpy.run_path('tools/test-i386-graphics-pens.py')['expected']()
for name in ('graphics-pens-original-v3','graphics-pens-native-v3'):
 p=Path('build')/name;r=json.loads((p/'result.json').read_text());assert r['result']=='pass' and r['inputs_unchanged']
 assert (p/'graphics-pens.bin').read_bytes()==pen_model
 assert r['initially_cached']==('native' not in name)
 assert r['cases']==256 and r['pixels']==369152 and r['bound_bytes']==8192
 if 'native' in name:assert r['files_unchanged'] and r['fresh_result']
 checked.append(name)
for name in ('managed-pointer-user-8m-v6','managed-pointer-user-legacy-v3','managed-pointer-startup-8m-v1'):
 p=Path('build')/name;r=json.loads((p/'result.json').read_text());assert r['result']=='pass' and r['inputs_unchanged'],(name,r.get('error'))
 if 'legacy' in name:assert r['pixels']==614400 and r['mask']==3
 if 'startup-8m' in name:assert r['startup_60s_gate'] and r['startup_seconds']<=60 and not r['other_qemu_processes_before']
 checked.append(name)


for name in checked:
 p=Path('build')/name;r=json.loads((p/'result.json').read_text())
 for n,h in r.get('input_sha256',{}).items():
  f=Path(n)
  if f==ROOT/'tools/test-i386-msg-loop.py':f=p/'runner-source.py'
  if sha(f)!=h and f==ROOT/'tools/build-i386-kernel.py':
   blob=subprocess.check_output(['git','show','cd7d6521:'+str(f.relative_to(ROOT))]);assert hashlib.sha256(blob).hexdigest()==h
  else:assert sha(f)==h,(name,str(f))
p=Path('build/managed-pointer-user-legacy-v3')
console_pixels=runpy.run_path('tools/i386-kernel-input.py')['console_pixels']
for label,suffix in [('typed',''),('saved',' - Saved')]:
 rows=['TempleOS i386','DolDoc editor'+suffix,'C:/UserLegacy.DD','','abc'+bytes([0xDB]).decode('cp437')]
 assert Image.open(p/'guest'/(label+'.png')).convert('RGB').tobytes()==console_pixels(rows)
assert (p/'UserLegacy.DD').read_bytes()==b'abc\x05'
src=Path('Kernel/I386/ConsoleRuntime.HC').read_text();part=src[src.index('Bool ConsoleInit('):]
names=part[part.index('U8 *export_names='):part.index(';',part.index('U8 *export_names='))]
assert int(re.search(r'console_doc_exports\[(\d+)\]',src)[1])==names.count('\\0')==part.count('ConsoleDocExportSet(')==697

report=dict(result='pass',checked_receipts=checked,pixels=pixels,source_pins=len(build['source_sha256']),helper_pins=len(build['build_inputs_sha256']),pen_cache_bytes=len(pen_model),pen_cases=256,legacy_pixels=614400,startup_seconds=json.loads(Path('build/managed-pointer-startup-8m-v1/result.json').read_text())['startup_seconds'],scope='Unchanged MsgLoop with explicitly full-refresh test documents and real frame barriers; exact complete original documents/streams/pixels, actual input and caller heap/restoration. Default-mode snapshot nondeterminism and full C1-C5 remain open.')
(OUT/'result.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
