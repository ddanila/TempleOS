from pathlib import Path
import hashlib,json,runpy,shutil
ROOT=Path.cwd();out=Path(__file__).resolve().parent
source=Path('build/private-guarded-transitive-production-v1/candidate.img')
pack=runpy.run_path('tools/package-i386-native-image.py');snapshot=pack['snapshot'];package=pack['package'];original=snapshot(source.read_bytes())[1]
exports=out/'audit/exports';exports.mkdir(parents=True,exist_ok=True)
for name,value in original.items():
 if name.startswith('/Modules/I386/') and name.endswith('.t32m'):(exports/Path(name).name).write_bytes(value[2])
shutil.copyfile('build/i386-emitter-known-cross-v1/exports/Kernel32.BIN',exports/'Kernel32.BIN')
shutil.copyfile(out/'exports/CompilerRuntime.t32m',exports/'CompilerRuntime.t32m')
ns=runpy.run_path('tools/build-i386-kernel.py');ns['compiler_runtime_layout']((exports/'CompilerRuntime.t32m').read_bytes());ns['audit'](exports,out/'audit')
replacements={'/Modules/I386/CompilerRuntime.t32m':exports/'CompilerRuntime.t32m'}
replacements.update({'/'+str(p.relative_to(out/'overlay')):p for p in (out/'overlay/Compiler').iterdir()})
def patched(raw):
 tree,files,dirs=snapshot(raw)
 for n,p in replacements.items():
  parts=n.strip('/').split('/');node=tree
  for part in parts[:-1]:node=node[part][2]
  attr,date,_=node[parts[-1]];node[parts[-1]]=(attr,date,p.read_bytes());files[n]=(attr,date,p.read_bytes())
 return tree,files,dirs
package.__globals__['snapshot']=patched
try:r=package(source,out/'candidate.img')
finally:package.__globals__['snapshot']=snapshot
files=snapshot((out/'candidate.img').read_bytes())[1];assert files.keys()==original.keys()
assert all(files[n]==v for n,v in original.items() if n not in replacements)
assert all(files[n][2]==p.read_bytes() for n,p in replacements.items())
assert (out/'candidate.img').read_bytes()[:2048*512]==source.read_bytes()[:2048*512]
r.update(scope='Resident compiler optimizer policy refactor: compiler module and two matching shared sources only; existing services/import ABI, all other files and boot unchanged.',candidate_sha256=hashlib.sha256((out/'candidate.img').read_bytes()).hexdigest(),instruction_audit='pass',compiler_import_contract='unchanged exact set')
(out/'packaging.json').write_text(json.dumps(r,indent=2)+'\n')
