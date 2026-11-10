from pathlib import Path
import hashlib,json,runpy,struct
out=Path(__file__).resolve().parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=dict(result='running',scope='Callback-only optimizer provider/source differential receipts, exact packaging/imports and retained kernel binding coverage; not parser, malformed-module, native generation or resource qualification',runs={})
try:
 snap=runpy.run_path('tools/package-i386-native-image.py')['snapshot']
 base=Path('build/private-guarded-transitive-v1/candidate.img');image=Path('build/optimizer-provider-load-v1/candidate.img')
 before=snap(base.read_bytes())[1];after=snap(image.read_bytes())[1]
 changed={n for n in before if before[n]!=after[n]}
 assert changed=={'/Kernel/I386/ConsoleRuntime.HC','/Modules/I386/ConsoleRuntime.t32m'}
 added=after.keys()-before.keys();assert added=={'/Kernel/I386/OptRuntime.HC','/Modules/I386/OptRuntime.t32m'}
 assert image.read_bytes()[:2048*512]==base.read_bytes()[:2048*512]
 assert after['/Kernel/I386/OptRuntime.HC'][2]==Path('build/on-demand-optimizer-v5/overlay/Kernel/I386/OptRuntime.HC').read_bytes()
 assert after['/Modules/I386/OptRuntime.t32m'][2]==Path('build/on-demand-optimizer-v5/exports/OptRuntime.t32m').read_bytes()
 def imports(b):
  _,cnt,recs=struct.unpack_from('<III',b,16);names=set()
  for i in range(cnt):
   k,o,n,l=struct.unpack_from('<4I',b,recs+16*i)
   if k in (2,5):names.add(b[n:n+l].decode('ascii'))
  return names
 old=imports(before['/Modules/I386/ConsoleRuntime.t32m'][2]);new=imports(after['/Modules/I386/ConsoleRuntime.t32m'][2])
 assert new-old=={'I386F64Mod'} and not old-new
 kernel=after['/Kernel/I386/Kernel.HC'][2]
 assert b'I386F64Div\\0I386F64Mod\\0I386F64FromI64' in kernel
 assert b'for(i=27;i<37;i++)' in kernel
 for name,folder,storage in [('provider16','build/optimizer-provider-load-v1/optimizer16','provider'),('source16','build/optimizer-storage-source-regression-v1','source')]:
  root=Path(folder);p=root/'result.json';d=json.loads(p.read_text());assert d['result']=='pass' and d['inputs_unchanged']
  assert d['ram_mib']==16 and d['optimizer_storage']==storage
  assert d['state']==[1]*18 and d['heap_metrics']==[0,0]
  assert (d['source_loads'],d['provider_loads'])==((1,0) if storage=='source' else (0,1))
  assert all(sha(Path(n))==h for n,h in d['input_sha256'].items())
  cmd=root/'guest/command.json';args=json.loads(cmd.read_text());assert args[args.index('-m')+1]=='16'
  assert (root/'optimizer-trace.bin').read_bytes()==Path('build/i386-public-opt-original-v3/optimizer-trace.bin').read_bytes()
  r['runs'][name]=dict(result='pass',receipt_sha256=sha(p),command_sha256=sha(cmd))
 root=Path('build/optimizer-provider-load-v1/user8');receipt=root/'result.json';d=json.loads(receipt.read_text())
 assert d['result']=='fail' and d['inputs_unchanged'] and d['ram_mib']==8
 assert all(sha(Path(n))==h for n,h in d['input_sha256'].items())
 cmd=root/'qemu/command.json';args=json.loads(cmd.read_text());assert args[args.index('-m')+1]=='8'
 log=root/'qemu/debug.log';text=log.read_text()
 assert 'HEAP EXHAUSTED 0000000000021D1B' in text and '00656C694674704F' in text
 assert 'PUBLIC OPT provider\n' not in text
 r['runs']['user8']={'result':'fail','receipt_sha256':sha(receipt),'log_sha256':sha(log),'command_sha256':sha(cmd),'failed_raw_read_bytes':138523}
 r.update(result='pass',candidate_sha256=sha(image),changed=sorted(changed),added=sorted(added),new_console_imports=sorted(new-old),kernel_unchanged=True)
finally:(out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
