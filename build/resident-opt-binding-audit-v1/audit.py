from pathlib import Path
import hashlib,json,runpy,subprocess
out=Path(__file__).resolve().parent;sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=dict(result='running',scope='Resident optimizer binding publication and native callback routing, exact packaging, boot/module audits and scoped regression receipts; no public facade reuse or C5 qualification',runs={})
try:
 root=Path('build/resident-opt-binding-v3');base=Path('build/optimizer-policy-core-v1/candidate.img');image=root/'candidate.img'
 snap=runpy.run_path('tools/package-i386-native-image.py')['snapshot'];old=snap(base.read_bytes())[1];new=snap(image.read_bytes())[1]
 changed={'/Modules/I386/'+n+'.t32m' for n in ['Kernel','CompilerRuntime','CompilerProgramRuntimeProbe']}|{'/Kernel/I386/'+n+'.HC' for n in ['Kernel','CompilerRuntime','CompilerProgramProbe']}
 assert {n for n in old if old[n]!=new[n]}==changed
 assert new.keys()-old.keys()=={'/Kernel/I386/OptimizerPolicyProbe.HC'}
 for name in changed|{'/Kernel/I386/OptimizerPolicyProbe.HC'}:
  if name.endswith('.HC'):assert new[name][2]==Path(name.lstrip('/')).read_bytes()
  else:assert new[name][2]==(root/'exports'/Path(name).name).read_bytes()
 assert image.read_bytes()[:2048*512]==(root/'stage.bin').read_bytes().ljust(2048*512,b'\0')
 stage=(root/'stage.bin').read_bytes();assert stage[4608:]==(root/'exports/Kernel32.BIN').read_bytes()
 original=subprocess.check_output(['git','show','d13ed56a:Kernel/I386/CompilerRuntime.HC'])
 current=Path('Kernel/I386/CompilerRuntime.HC').read_bytes()
 current=current.replace(b'#include "/Compiler/OptPass012.HH"\n',b'').replace(b'index>6',b'index>5')
 current=current.replace(b'if(index==6) {\n    binding->name="_I386_OPT_CORE_POLICY";\n    binding->address=(&OptPass012CorePolicy+0)(U64);\n  } else if(index==5)',b'if(index==5)')
 assert current==original
 for name,ram,sub in [('user8',8,'qemu'),('optimizer16',16,'guest'),('diagnostic16',16,'guest')]:
  folder=root/name;receipt=folder/'result.json';d=json.loads(receipt.read_text());assert d['result']=='pass' and d['inputs_unchanged']
  assert all(sha(Path(p))==h for p,h in d['input_sha256'].items())
  cmd=folder/sub/'command.json';args=json.loads(cmd.read_text());assert args[args.index('-m')+1]==str(ram) and '486,-fpu' in args
  r['runs'][name]=dict(result='pass',ram_mib=ram,receipt_sha256=sha(receipt),command_sha256=sha(cmd))
 log=root/'diagnostic16/guest/debug.log';text=log.read_text()
 assert all(text.count(f'OPT RESIDENT POLICY {phase:016X}\n')==1 for phase in (0,1))
 r.update(result='pass',candidate_sha256=sha(image),native_policy_log_sha256=sha(log),old_export_indices_preserved=True,module_delta_bytes={n:len(new['/Modules/I386/'+n+'.t32m'][2])-len(old['/Modules/I386/'+n+'.t32m'][2]) for n in ['Kernel','CompilerRuntime','CompilerProgramRuntimeProbe']})
finally:(out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
