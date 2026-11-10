from pathlib import Path
import hashlib,json,runpy,shutil
ROOT=Path.cwd();out=Path(__file__).resolve().parent;prototype=True
source=Path('build/resident-opt-original-user-final/candidate.img' if prototype else 'build/resident-opt-public-v5/candidate.img')
pack=runpy.run_path('tools/package-i386-native-image.py');snapshot=pack['snapshot'];package=pack['package'];original=snapshot(source.read_bytes())[1]
exports=out/'audit/exports';exports.mkdir(parents=True,exist_ok=True)
for name,value in original.items():
 if name.startswith('/Modules/I386/') and name.endswith('.t32m'):(exports/Path(name).name).write_bytes(value[2])
shutil.copyfile('build/resident-opt-original-user-v2/exports/Kernel32.BIN' if prototype else 'build/resident-opt-metadata-v2/exports/Kernel32.BIN',exports/'Kernel32.BIN')
shutil.copyfile(out/'exports/ConsoleRuntime.t32m',exports/'ConsoleRuntime.t32m')
shutil.copyfile(out/'exports/FileRuntime.t32m',exports/'FileRuntime.t32m')
helper=ROOT/'tools/build-i386-kernel.py';text=helper.read_text()
if prototype:text=text.replace("if set(imports) != {'HashSingleTableFind',", "if set(imports) != {'I386CompactReadModule', 'HashSingleTableFind',")
ns={'__file__':str(helper),'__name__':'preload_audit'};exec(compile(text,str(helper),'exec'),ns)
if prototype:ns['DISK_MODULES']=ns['DISK_MODULES']+('LexRuntime',)
ns['console_runtime_layout']((exports/'ConsoleRuntime.t32m').read_bytes());ns['audit'](exports,out/'audit')
replacements={'/Modules/I386/ConsoleRuntime.t32m':exports/'ConsoleRuntime.t32m','/Kernel/I386/ConsoleRuntime.HC':out/'overlay/Kernel/I386/ConsoleRuntime.HC'}
replacements.update({'/Modules/I386/FileRuntime.t32m':exports/'FileRuntime.t32m','/Kernel/I386/TaskFileRead.HC':out/'overlay/Kernel/I386/TaskFileRead.HC','/Compiler/I386/LexFileRead.HH':out/'overlay/Compiler/I386/LexFileRead.HH'})
ns['file_runtime_layout']((exports/'FileRuntime.t32m').read_bytes())
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
r.update(scope='Lazy raw CompilerA declarations with control-local include policy; all public headers retained, other bytes and boot unchanged',candidate_sha256=hashlib.sha256((out/'candidate.img').read_bytes()).hexdigest(),instruction_audit='pass',prototype=prototype)
(out/'packaging.json').write_text(json.dumps(r,indent=2)+'\n')
