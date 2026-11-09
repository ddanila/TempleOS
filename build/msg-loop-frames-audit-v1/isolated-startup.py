import hashlib,json,runpy,subprocess
from pathlib import Path
image=Path('build/i386-managed-pointer-cross-v5/kernel.img');out=Path('build/managed-pointer-startup-8m-v1');out.mkdir();sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
paths=[image,Path('tools/i386-kernel-input.py'),Path('Kernel/FontStd.HC'),Path(__file__)];pins={str(p):sha(p) for p in paths}
processes=subprocess.check_output(['ps','-eo','comm=,args='],text=True).splitlines();other=[p for p in processes if p.split(None,1)[0].startswith('qemu-system')];assert not other,other
r=dict(result='running',input_sha256=pins,other_qemu_processes_before=other,scope='Final full-profile image, single test job, 8 MiB KVM 486,-fpu, normal welcome/live WinMgr and fresh42. Startup <=60s is one measured baseline subgate; not original desktop/all-app/full-C5 or dedicated-host benchmarking qualification.')
try:
 r['behavior']=runpy.run_path('tools/i386-kernel-input.py')['run_input'](image,out/'qemu',ram_mib=8,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,managed_pointer=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':[('6*7;',['42'])],'pause_window_manager':False})
 r['functional_result']='pass';r['startup_seconds']=r['behavior']['startup_seconds'];r['startup_60s_gate']=r['startup_seconds']<=60;r['result']='pass' if r['startup_60s_gate'] else 'fail'
except Exception as exc:r.update(result='fail',error=str(exc));raise
finally:
 r['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
 if not r['inputs_unchanged']:r.update(result='fail',error='Inputs changed')
 (out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
print(json.dumps({k:r.get(k) for k in ['result','functional_result','startup_seconds','startup_60s_gate','inputs_unchanged']}))
