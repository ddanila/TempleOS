from pathlib import Path
import runpy,re,json,hashlib
out=Path('build/compiler-flat-headers-v1');out.mkdir(exist_ok=True)
source=Path('build/resident-opt-original-user-final/candidate.img')
p=runpy.run_path('tools/package-i386-native-image.py');snapshot=p['snapshot'];package=p['package']
original=snapshot(source.read_bytes())[1]
inputs={}
def flatten(path):
 body=Path(path).read_bytes()
 inputs[path]=hashlib.sha256(body).hexdigest()
 def sub(m):
  name=m[1].decode().lstrip('/')
  return flatten(name)
 return re.sub(rb'^#include "([^"]+)"$',sub,body,flags=re.M)
#Only the complete CompilerA dependency graph; retain all declaration bytes and guards.
body=flatten('Compiler/CompilerA.HH');(out/'SystemCompilerA.HH').write_bytes(body)
replacement='/Compiler/I386/SystemCompilerA.HH'
def patched(raw):
 tree,files,dirs=snapshot(raw);node=tree['Compiler'][2]['I386'][2];attr,date,_=node['SystemCompilerA.HH'];node['SystemCompilerA.HH']=(attr,date,body);files[replacement]=(attr,date,body);return tree,files,dirs
package.__globals__['snapshot']=patched
try:r=package(source,out/'candidate.img')
finally:package.__globals__['snapshot']=snapshot
files=snapshot((out/'candidate.img').read_bytes())[1]
assert files.keys()==original.keys() and all(files[n]==v for n,v in original.items() if n!=replacement)
r.update(scope='Complete CompilerA and dependency bodies inline; source-only experiment, modules unchanged',header_bytes=len(body),source_sha256=inputs,sha256=hashlib.sha256((out/'candidate.img').read_bytes()).hexdigest())
(out/'packaging.json').write_text(json.dumps(r,indent=2)+'\n')
print(r['header_bytes'])
