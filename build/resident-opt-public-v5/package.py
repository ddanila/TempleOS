from pathlib import Path
import hashlib,json,runpy,shutil
ROOT=Path.cwd();out=Path(__file__).resolve().parent
source=Path('build/resident-opt-metadata-v2/candidate.img');pack=runpy.run_path('tools/package-i386-native-image.py');snapshot=pack['snapshot'];package=pack['package'];original=snapshot(source.read_bytes())[1]
exports=out/'audit/exports';exports.mkdir(parents=True,exist_ok=True)
for name,value in original.items():
 if name.startswith('/Modules/I386/') and name.endswith('.t32m'):(exports/Path(name).name).write_bytes(value[2])
shutil.copyfile('build/resident-opt-metadata-v2/exports/Kernel32.BIN',exports/'Kernel32.BIN')
shutil.copyfile(out/'exports/ConsoleRuntime.t32m',exports/'ConsoleRuntime.t32m')
ns=runpy.run_path('tools/build-i386-kernel.py');ns['console_runtime_layout']((exports/'ConsoleRuntime.t32m').read_bytes());ns['audit'](exports,out/'audit')
replacements={'/Modules/I386/ConsoleRuntime.t32m':exports/'ConsoleRuntime.t32m','/Kernel/I386/ConsoleRuntime.HC':out/'overlay/Kernel/I386/ConsoleRuntime.HC','/Compiler/OptPass012.HC':Path('Compiler/OptPass012.HC'),'/Compiler/I386/PublicOptSupport.HC':Path('Compiler/I386/PublicOptSupport.HC')}
additions={'/Compiler/I386/'+n:Path('Compiler/I386',n).read_bytes() for n in ['ResidentOptCore.HC','ResidentOptSupport.HC']}
assert not additions.keys()&original.keys()
def patched(raw):
 tree,files,dirs=snapshot(raw)
 for n,p in replacements.items():
  parts=n.strip('/').split('/');node=tree
  for part in parts[:-1]:node=node[part][2]
  attr,date,_=node[parts[-1]];node[parts[-1]]=(attr,date,p.read_bytes());files[n]=(attr,date,p.read_bytes())
 return tree,files,dirs
package.__globals__['snapshot']=patched
try:r=package(source,out/'candidate.img',additions=additions)
finally:package.__globals__['snapshot']=snapshot
files=snapshot((out/'candidate.img').read_bytes())[1];assert files.keys()==original.keys()|additions.keys()
assert all(files[n]==v for n,v in original.items() if n not in replacements)
assert all(files[n][2]==p.read_bytes() for n,p in replacements.items())
assert all(files[n][2]==b for n,b in additions.items())
assert (out/'candidate.img').read_bytes()[:2048*512]==source.read_bytes()[:2048*512]
assert '/Modules/I386/OptRuntime.t32m' not in files
r.update(scope='Public source helpers delegate to resident metadata-aware full core. Console loader path is experimental; no extra optimizer module. All unrelated files and boot preserved.',candidate_sha256=hashlib.sha256((out/'candidate.img').read_bytes()).hexdigest(),instruction_audit='pass')
(out/'packaging.json').write_text(json.dumps(r,indent=2)+'\n')
