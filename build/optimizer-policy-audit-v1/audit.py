from pathlib import Path
import hashlib,json,runpy,subprocess
out=Path(__file__).resolve().parent;sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=dict(result='running',scope='Shared core source integrity, unchanged original wrapper/service layout, exact resident packaging and scoped optimizer/User/native diagnostics/callback test receipts',runs={})
try:
 old=subprocess.check_output(['git','show','82297e44:Compiler/OptPass012Core.HC'])
 new=Path('Compiler/OptPass012Core.HC').read_bytes()
 wrapper=b'\nCIntermediateCode *OptPass012Core(CCmpCtrl *cc,COptPass012Services *services)\n{//Retain the original entry point and its containing compiler\'s ownership policy.\n  return OptPass012CorePolicy(cc,services,&OptBrZero,&OptBrNotZero);\n}\n'
 assert new.endswith(wrapper)
 body=new[:-len(wrapper)].replace(b'CIntermediateCode *OptPass012CorePolicy(CCmpCtrl *cc,COptPass012Services *services,\n  CIntermediateCode *(*branch_zero)(CCmpCtrl *cc,CIntermediateCode *node),\n  CIntermediateCode *(*branch_nonzero)(CCmpCtrl *cc,CIntermediateCode *node))',b'CIntermediateCode *OptPass012Core(CCmpCtrl *cc,COptPass012Services *services)').replace(b'(*branch_zero)(cc,tmpi)',b'OptBrZero(cc,tmpi)').replace(b'(*branch_nonzero)(cc,tmpi)',b'OptBrNotZero(cc,tmpi)')
 assert body==old
 old_header=subprocess.check_output(['git','show','82297e44:Compiler/OptPass012.HH'])
 new_header=Path('Compiler/OptPass012.HH').read_bytes()
 assert new_header.split(b'//Explicit invocation-local')[0]+b'#endif\n'==old_header
 root=Path('build/optimizer-policy-core-v1');image=root/'candidate.img';base=Path('build/private-guarded-transitive-production-v1/candidate.img');snap=runpy.run_path('tools/package-i386-native-image.py')['snapshot']
 a=snap(base.read_bytes())[1];b=snap(image.read_bytes())[1];assert a.keys()==b.keys()
 assert {n for n in a if a[n]!=b[n]}=={'/Modules/I386/CompilerRuntime.t32m','/Compiler/OptPass012Core.HC','/Compiler/OptPass012.HH'}
 for name in ['OptPass012Core.HC','OptPass012.HH']:assert b['/Compiler/'+name][2]==Path('Compiler',name).read_bytes()
 assert image.read_bytes()[:2048*512]==base.read_bytes()[:2048*512]
 for name,path,result,ram,sub in [('user8',root/'user8','pass',8,'qemu'),('optimizer16',root/'optimizer16','pass',16,'guest'),('diagnostic16',root/'diagnostic16','pass',16,'guest'),('policy-dispatch',Path('build/optimizer-policy-dispatch-final-v1'),'pass',2048,'guest')]:
  receipt=path/'result.json';d=json.loads(receipt.read_text());assert d['result']==result and d['inputs_unchanged']
  assert all(sha(Path(p))==h for p,h in d['input_sha256'].items())
  cmd=path/sub/'command.json';args=json.loads(cmd.read_text());assert args[args.index('-m')+1]==str(ram)
  r['runs'][name]=dict(result=result,receipt_sha256=sha(receipt),ram_mib=ram,command_sha256=sha(cmd))
 cap=Path('build/optimizer-public-capacity-v1/user8');receipt=cap/'result.json';d=json.loads(receipt.read_text())
 assert d['result']=='fail' and d['ram_mib']==8 and d['inputs_unchanged']
 log=cap/'qemu/debug.log';assert 'OPT ROOT HEAP 00000000000F4518 00000000000FAC00 0000000000112400 0000000000113000' in log.read_text()
 cmd=cap/'qemu/command.json';args=json.loads(cmd.read_text());assert args[args.index('-m')+1]=='8'
 r['capacity_probe']={'result':'expected-fail','root_reserved_unused_bytes':26344,'backing_unused_bytes':3072,'receipt_sha256':sha(receipt),'log_sha256':sha(log),'scope':'Existing reserved capacity only; growth/reclaim into other allocations not tested'}
 r.update(result='pass',candidate_sha256=sha(image),resident_module_delta_bytes=len(b['/Modules/I386/CompilerRuntime.t32m'][2])-len(a['/Modules/I386/CompilerRuntime.t32m'][2]),source_sha256={n:sha(Path(n)) for n in ['Compiler/OptPass012Core.HC','Compiler/OptPass012.HH']})
finally:(out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
