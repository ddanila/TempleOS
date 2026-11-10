from pathlib import Path
import hashlib,json,runpy
out=Path(__file__).resolve().parent;source=Path('build/resident-opt-original-user-v2/candidate.img');pack=runpy.run_path('tools/package-i386-native-image.py');snapshot=pack['snapshot'];package=pack['package'];original=snapshot(source.read_bytes())[1]
replacements={'/Compiler/I386/'+n:Path('Compiler/I386',n) for n in ['PublicOptSupport.HC','ResidentOptSupport.HC']}
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
r.update(scope='Original User/provider-lexer prototype with final single-document resident optimizer helpers; only two support source files changed; all modules/boot unchanged',candidate_sha256=hashlib.sha256((out/'candidate.img').read_bytes()).hexdigest());(out/'packaging.json').write_text(json.dumps(r,indent=2)+'\n')
