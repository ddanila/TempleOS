from pathlib import Path
import hashlib,json,re,runpy
out=Path(__file__).resolve().parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
mapping={'Kernel/I386/PublicCompiler.HH':'Compiler/I386/SystemCompiler.HH','Kernel/I386/PublicLoader.HH':'Compiler/I386/SystemLoader.HH','Compiler/CompilerA.HH':'Compiler/I386/SystemCompilerA.HH'}
r={'result':'running','scope':'Reverse all three generated interfaces to byte-identical originals; verify source-only packaging and regression receipts'}
try:
 for source,target in mapping.items():
  original=Path(source).read_bytes();mirror=Path(target).read_bytes().split(b'\n',1)[1]
  for include in re.findall(rb'^#include "([^"]+)"$',original,re.M):
   n=include.decode('ascii').lstrip('/');guard=Path(n).read_bytes().splitlines()[0].split()[1]
   wrapped=b'#ifndef '+guard+b'\n#include "/'+mapping.get(n,n).encode()+b'"\n#endif'
   assert mirror.count(wrapped)==1
   mirror=mirror.replace(wrapped,b'#include "'+include+b'"',1)
  assert mirror==original
 r['original_sha256']={n:sha(Path(n)) for n in mapping}
 snapshot=runpy.run_path('tools/package-i386-native-image.py')['snapshot'];r['candidates']={}
 for folder,base in [('private-guarded-transitive-v1','private-guarded-provider-v1'),('private-guarded-transitive-production-v1','private-guarded-production-v1')]:
  image=Path('build')/folder/'candidate.img';before=Path('build')/base/'candidate.img'
  old=snapshot(before.read_bytes())[1];files=snapshot(image.read_bytes())[1]
  assert files.keys()-old.keys()=={'/Compiler/I386/SystemCompilerA.HH'} and not old.keys()-files.keys()
  assert {n for n in old if old[n]!=files[n]}=={'/Compiler/I386/SystemCompiler.HH'}
  for n in mapping.values():assert files['/'+n][2]==Path(n).read_bytes()
  for n in mapping:assert files['/'+n][2]==Path(n).read_bytes()
  assert image.read_bytes()[:2048*512]==before.read_bytes()[:2048*512]
  r['candidates'][folder]=sha(image)
 r['runs']={}
 for folder,name,expected,ram,sub in [('private-guarded-transitive-production-v1','optimizer16','pass',16,'guest'),('private-guarded-transitive-v1','user8','fail',8,'qemu')]:
  base=Path('build')/folder/name;receipt=base/'result.json';d=json.loads(receipt.read_text())
  assert d['result']==expected and d['inputs_unchanged']
  assert all(sha(Path(n))==h for n,h in d['input_sha256'].items())
  command=base/sub/'command.json';args=json.loads(command.read_text());assert args[args.index('-m')+1]==str(ram)
  r['runs'][folder]={'result':expected,'ram_mib':ram,'receipt_sha256':sha(receipt),'command_sha256':sha(command)}
 r['result']='pass'
finally:(out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
