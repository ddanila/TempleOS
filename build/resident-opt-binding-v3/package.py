from pathlib import Path
import hashlib,json,runpy,shutil,subprocess
ROOT=Path.cwd();out=Path(__file__).resolve().parent
source=Path('build/optimizer-policy-core-v1/candidate.img');pack=runpy.run_path('tools/package-i386-native-image.py');snapshot=pack['snapshot'];package=pack['package'];original=snapshot(source.read_bytes())[1]
exports=out/'audit/exports';exports.mkdir(parents=True,exist_ok=True)
for name,value in original.items():
 if name.startswith('/Modules/I386/') and name.endswith('.t32m'):(exports/Path(name).name).write_bytes(value[2])
for p in (out/'exports').iterdir():
 if p.suffix=='.t32m' or p.name=='Kernel32.BIN':shutil.copyfile(p,exports/p.name)
ns=runpy.run_path('tools/build-i386-kernel.py');ns['compiler_runtime_layout']((exports/'CompilerRuntime.t32m').read_bytes());ns['compiler_probe_layout']((exports/'CompilerProgramRuntimeProbe.t32m').read_bytes(),program=True);ns['audit'](exports,out/'audit')
image=(exports/'Kernel32.BIN').read_bytes();checksum=2166136261
for byte in image:checksum=((checksum^byte)*16777619)&0xffffffff
stage=out/'stage.bin';listing=out/'stage.lst'
subprocess.run(['nasm','-f','bin',f'-DPAYLOAD_FNV={checksum}','-l',str(listing),f'-DKERNEL_FILE="{exports / "Kernel32.BIN"}"','tools/i386-extended-stage.asm','-o',str(stage)],check=True)
assert stage.read_bytes()[4608:]==image and stage.stat().st_size<2048*512
subprocess.run(['python3','tools/audit-i386-boot.py',str(stage),str(listing),'--out',str(out/'boot-audit.json')],check=True)
raw=bytearray(source.read_bytes());raw[:2048*512]=stage.read_bytes().ljust(2048*512,b'\0');rebased=out/'rebased.img';rebased.write_bytes(raw)
replacements={'/Modules/I386/'+p.name:p for p in (out/'exports').glob('*.t32m')}
additions={}
for p in (out/'overlay/Kernel/I386').iterdir():
 n='/Kernel/I386/'+p.name
 if n in original:replacements[n]=p
 else:additions[n]=p.read_bytes()
def patched(raw):
 tree,files,dirs=snapshot(raw)
 for n,p in replacements.items():
  parts=n.strip('/').split('/');node=tree
  for part in parts[:-1]:node=node[part][2]
  attr,date,_=node[parts[-1]];node[parts[-1]]=(attr,date,p.read_bytes());files[n]=(attr,date,p.read_bytes())
 return tree,files,dirs
package.__globals__['snapshot']=patched
try:r=package(rebased,out/'candidate.img',additions=additions)
finally:package.__globals__['snapshot']=snapshot
files=snapshot((out/'candidate.img').read_bytes())[1];assert files.keys()==original.keys()|additions.keys()
assert all(files[n]==v for n,v in original.items() if n not in replacements)
assert all(files[n][2]==p.read_bytes() for n,p in replacements.items())
assert all(files[n][2]==b for n,b in additions.items())
assert (out/'candidate.img').read_bytes()[:2048*512]==raw[:2048*512]
r.update(scope='Append-only resident optimizer policy binding: rebuilt Kernel/CompilerRuntime/CompilerProgramRuntimeProbe and matching sources, added diagnostic source, re-linked/audited boot. Other files unchanged; public facade not switched.',candidate_sha256=hashlib.sha256((out/'candidate.img').read_bytes()).hexdigest(),instruction_audit='pass',replacement_sha256={n:hashlib.sha256(p.read_bytes()).hexdigest() for n,p in replacements.items()})
(out/'packaging.json').write_text(json.dumps(r,indent=2)+'\n')
