from pathlib import Path
import hashlib,json,runpy,shutil
ROOT=Path.cwd();out=Path(__file__).resolve().parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
source=Path('build/private-guarded-transitive-v1/candidate.img')
exports=out/'audit/exports';exports.mkdir(parents=True,exist_ok=True)
for p in Path('build/on-demand-lexer-v9/audit/exports').iterdir():
 if p.is_file():shutil.copyfile(p,exports/p.name)
shutil.copyfile(out/'exports/ConsoleRuntime.t32m',exports/'ConsoleRuntime.t32m')
opt=Path('build/on-demand-optimizer-v5/exports/OptRuntime.t32m');shutil.copyfile(opt,exports/opt.name)
helper=ROOT/'tools/build-i386-kernel.py';text=helper.read_text().replace("if set(imports) != {'HashSingleTableFind',", "if set(imports) != {'I386CompactReadModule', 'I386F64Mod', 'HashSingleTableFind',")
ns={'__file__':str(helper),'__name__':'opt_loader_build_helper'};exec(compile(text,str(helper),'exec'),ns);ns['DISK_MODULES']=ns['DISK_MODULES']+('LexRuntime','OptRuntime')
ns['console_runtime_layout']((exports/'ConsoleRuntime.t32m').read_bytes());ns['audit'](exports,out/'audit')
pack=runpy.run_path('tools/package-i386-native-image.py');snapshot=pack['snapshot'];package=pack['package'];original=snapshot(source.read_bytes())[1]
replacements={'/Modules/I386/ConsoleRuntime.t32m':exports/'ConsoleRuntime.t32m','/Kernel/I386/ConsoleRuntime.HC':out/'overlay/Kernel/I386/ConsoleRuntime.HC'}
additions={'/Modules/I386/OptRuntime.t32m':opt.read_bytes(),'/Kernel/I386/OptRuntime.HC':Path('build/on-demand-optimizer-v5/overlay/Kernel/I386/OptRuntime.HC').read_bytes()}
assert not (additions.keys() & original.keys())
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
files=snapshot((out/'candidate.img').read_bytes())[1]
assert files.keys()==original.keys()|additions.keys()
assert all(files[n]==v for n,v in original.items() if n not in replacements)
assert all(files[n][2]==p.read_bytes() for n,p in replacements.items())
assert all(files[n][2]==b for n,b in additions.items())
assert (out/'candidate.img').read_bytes()[:2048*512]==source.read_bytes()[:2048*512]
r.update(scope='Callback-only optimizer provider experiment: Console module/source replacement and Opt module/source additions only; all other files/boot unchanged. No parser namespace or production qualification.',candidate_sha256=sha(out/'candidate.img'),instruction_audit='pass',console_import_contract='existing exact imports plus I386CompactReadModule and I386F64Mod only; retained Kernel already binds all ten F64 functions',replacement_sha256={n:sha(p) for n,p in replacements.items()})
(out/'packaging.json').write_text(json.dumps(r,indent=2)+'\n')
