import hashlib,json,runpy
from pathlib import Path
ROOT=Path.cwd();image=Path('build/i386-dc-constructor-scope-cross-v1/kernel.img');out=Path('build/dc-constructor-context-v1');out.mkdir()
paths=[image,Path(__file__),Path('tools/test-i386-autocomplete-interaction.py'),Path('tools/test-i386-timeclock-welcome.py'),Path('tools/package-i386-native-image.py'),Path('Kernel/FontStd.HC'),Path('Kernel/I386/GraphicsContextCheck.HC'),Path('Kernel/I386/GraphicsAllocationCheck.HC')]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();pins={str(p):sha(p) for p in paths};g=None
code=b'''#include "/Kernel/I386/GraphicsContextCheck.HC"
#include "/Kernel/I386/GraphicsAllocationCheck.HC"
U0 DCRegress(){Bool paused=Suspend(sys_winmgr_task);try{if(GraphicsContextCheck!=20)throw('DCCheck',TRUE);if(GraphicsAllocationCheck!=2)throw('DCAlloc',TRUE);}catch{Suspend(sys_winmgr_task,paused);}Suspend(sys_winmgr_task,paused);U8*s="PASS DC CONTEXT20 ALLOC2\\n";while(*s)OutU8(0xE9,*s++);}
DCRegress;
'''
r=dict(result='running',input_sha256=pins,scope='Unchanged20 graphics context groups and2 allocation-recovery checks via public APIs in the normal image; manager suspended only during transient gr.dc replacement. Not complete graphics/resource/C1-C5 qualification.')
try:
 pack=runpy.run_path('tools/package-i386-native-image.py');working=out/'working.img';r['packaging']=pack['package'](image,working,additions={'/Probe/DCRegression.HC':code});before=pack['snapshot'](working.read_bytes())[1]
 g=runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest'](working,out/'guest',True);g.wait('DONE native kernel startup\n');g.command('#include "/Kernel/I386/PublicUser.HH"');g.command('#include "C:/Probe/DCRegression.HC"',timeout=180);g.wait('PASS DC CONTEXT20 ALLOC2\n');g.command('6*7;');r['fresh_result']=g.result_pixels();g.close();g=None
 assert pack['snapshot'](working.read_bytes())[1]==before;r.update(result='pass',groups=20,allocation_checks=2,files_unchanged=True)
except Exception as exc:r.update(result='fail',error=str(exc));raise
finally:
 if g:g.close()
 r['inputs_unchanged']=all(sha(p)==pins[str(p)] for p in paths)
 if not r['inputs_unchanged']:r.update(result='fail',error='Inputs changed')
 (out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
