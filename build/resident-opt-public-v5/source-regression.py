from pathlib import Path
import runpy,json,hashlib
out=Path(__file__).resolve().parent;pack=runpy.run_path('tools/package-i386-native-image.py');snapshot=pack['snapshot'];package=pack['package']
source=out/'candidate.img';files=snapshot(Path('build/resident-opt-metadata-v2/candidate.img').read_bytes())[1]
original=snapshot(source.read_bytes())[1];names=['/Modules/I386/ConsoleRuntime.t32m','/Kernel/I386/ConsoleRuntime.HC']
def patched(raw):
 tree,entries,dirs=snapshot(raw)
 for n in names:
  parts=n.strip('/').split('/');node=tree
  for part in parts[:-1]:node=node[part][2]
  node[parts[-1]]=files[n];entries[n]=files[n]
 return tree,entries,dirs
package.__globals__['snapshot']=patched
try:r=package(source,out/'source-candidate.img')
finally:package.__globals__['snapshot']=snapshot
changed=snapshot((out/'source-candidate.img').read_bytes())[1]
assert {n for n in original if original[n]!=changed[n]}==set(names)
r.update(candidate_sha256=hashlib.sha256((out/'source-candidate.img').read_bytes()).hexdigest(),scope='Same current metadata-aware sources and kernel, original source-loader Console restored; resident helper additions remain unused')
(out/'source-packaging.json').write_text(json.dumps(r,indent=2)+'\n')
