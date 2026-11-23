from pathlib import Path
import json,hashlib,runpy,shutil
out=Path(__file__).resolve().parent/'diagnostic16';out.mkdir();exports=out/'exports';exports.mkdir()
source=Path(__file__).resolve().parent/'candidate.img';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
pins={str(p):sha(p) for p in [source,Path('tools/build-i386-kernel.py'),Path('tools/i386-kernel-input.py'),Path('Compiler/OptPass012Core.HC'),Path('Compiler/OptPass012.HH')]}
r=dict(result='running',scope='Existing complete program/compiler diagnostic probes twice, 386 without FPU at 16 MiB; exact boundary/completion markers, DocAllocationCheck and fresh arithmetic',input_sha256=pins)
try:
 build=runpy.run_path('tools/build-i386-kernel.py');payloads=build['mutated_file_contents'](source,{'/Modules/I386/Kernel.t32m'});(exports/'Kernel.t32m').write_bytes(payloads['/Modules/I386/Kernel.t32m'])
 normal=out/'normal.img';shutil.copyfile(source,normal);image,flag=build['diagnostic_disk'](normal,exports);before=sha(image)
 behavior=runpy.run_path('tools/i386-kernel-input.py')['run_input'](image,out/'guest',diagnostics=True,snapshot=True,ram_mib=16,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,managed_pointer=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':[('6*7;',['42']),('DocAllocationCheck;',['13'])],'pause_window_manager':False})
 log=(out/'guest/debug.log').read_text()
 for prefix in ['CODE HEADER BOUNDARIES','EMITTER BOUNDARIES','PROGRAM PROBE complete','OPT RESIDENT POLICY','OPT RESIDENT METADATA']:
  assert all(log.count(f'{prefix} {i:016X}\n')==1 for i in (0,1))
 assert sha(image)==before
 assert all(sha(Path(p))==h for p,h in pins.items())
 r.update(result='pass',behavior=behavior,diagnostic_image_sha256=before,inputs_unchanged=True)
except Exception as e:r.update(result='fail',error=str(e));raise
finally:(out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
