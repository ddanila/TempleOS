from pathlib import Path
import hashlib,json,runpy,subprocess
out=Path(__file__).resolve().parent;sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=dict(result='running',scope='Resident optimizer production integration: complete algorithm/helpers preserved, caller metadata and callback ABI, native diagnostics, exact original folding, User8 and original-loop recovery64; original-loop8 remains an expected open failure',runs={})
try:
 old=subprocess.check_output(['git','show','f9929924:Compiler/OptPass012Core.HC'])
 new=Path('Compiler/OptPass012Core.HC').read_bytes()
 sig=b'CIntermediateCode *OptPass012CorePolicy(CCmpCtrl *cc,COptPass012Services *services,\n  CIntermediateCode *(*branch_zero)(CCmpCtrl *cc,CIntermediateCode *node),\n  CIntermediateCode *(*branch_nonzero)(CCmpCtrl *cc,CIntermediateCode *node))'
 wrapper=b'\n'+sig+b'\n{//The original policy entry retains this compiler\'s actual metadata table.\n  return OptPass012CoreMetadata(cc,services,branch_zero,branch_nonzero,\n    intermediate_code_table,sizeof(CIntermediateStruct));\n}\n'
 assert new.count(wrapper)==1;new=new.replace(wrapper,b'')
 new=new.replace(sig.replace(b'CorePolicy',b'CoreMetadata').replace(b'CIntermediateCode *node))',b'CIntermediateCode *node),\n  U8 *opcodes,I64 opcode_bytes)'),sig)
 new=new.replace(b'  CIntermediateStruct *code_info,*result_info;\n',b'').replace(b'    code_info=opcodes+code*opcode_bytes;\n',b'').replace(b'code_info->arg_cnt',b'intermediate_code_table[code].arg_cnt').replace(b'code_info->not_const',b'intermediate_code_table[code].not_const').replace(b'    result_info=opcodes+tmpi_push->ic_code*opcode_bytes;\n',b'').replace(b'result_info->res_cnt',b'intermediate_code_table[tmpi_push->ic_code].res_cnt')
 assert new==old
 source=Path('Compiler/I386/PublicOptSupport.HC').read_bytes();assert source==subprocess.check_output(['git','show','f9929924:Compiler/I386/PublicOptSupport.HC'])
 generated=Path('Compiler/I386/ResidentOptSupport.HC').read_bytes().split(b'\n',1)[1]
 generated=generated.replace(b'#include "/Compiler/I386/ResidentOptCore.HC"\n#define OPT_PASS012_CORE_EXTERNAL 1\n',b'').replace(b'#define OPT_PASS012_CORE_EXTERNAL 0\n',b'').replace(b'PUBLIC OPT resident\\n',b'PUBLIC OPT loaded\\n');assert generated==source
 snap=runpy.run_path('tools/package-i386-native-image.py')['snapshot'];image=Path('build/resident-opt-public-v5/candidate.img');files=snap(image.read_bytes())[1]
 assert '/Modules/I386/OptRuntime.t32m' not in files
 for name in ['Compiler/OptPass012.HC','Compiler/OptPass012.HH','Compiler/OptPass012Core.HC','Compiler/I386/OptPass012.HC','Compiler/I386/PublicOptSupport.HC','Compiler/I386/ResidentOptCore.HC','Compiler/I386/ResidentOptSupport.HC','Kernel/I386/Kernel.HC','Kernel/I386/CompilerRuntime.HC','Kernel/I386/CompilerProgramProbe.HC','Kernel/I386/OptimizerPolicyProbe.HC','Kernel/I386/ConsoleRuntime.HC']:
  assert files['/'+name][2]==Path(name).read_bytes(),name
 for label,folder,status,ram,surface in [('resident16','build/resident-opt-public-v5/default16','pass',16,'guest'),('source16','build/resident-opt-public-v5/source16','pass',16,'guest'),('diagnostic16','build/resident-opt-public-v5/diagnostic16','pass',16,'guest'),('production-user8','build/resident-opt-public-v5/user8','pass',8,'qemu'),('host-policy','build/resident-opt-metadata-policy-host-final','pass',2048,'guest'),('original-recovery64','build/resident-opt-original-user-final/recovery64','pass',64,'guest'),('original-user8','build/resident-opt-original-user-final/user8','fail',8,'qemu')]:
  root=Path(folder);p=root/'result.json';d=json.loads(p.read_text());assert d['result']==status and d['inputs_unchanged']
  assert all(sha(Path(n))==h for n,h in d['input_sha256'].items())
  cmd=root/surface/'command.json';args=json.loads(cmd.read_text());assert args[args.index('-m')+1]==str(ram)
  r['runs'][label]=dict(result=status,ram_mib=ram,receipt_sha256=sha(p),command_sha256=sha(cmd))
  if label in ('resident16','source16'):
   assert d['state']==[1]*18 and d['heap_metrics']==[0,0]
   assert (d['source_loads'],d['provider_loads'],d['resident_loads'])==((0,0,1) if label=='resident16' else (1,0,0))
   assert (root/'optimizer-trace.bin').read_bytes()==Path('build/i386-public-opt-original-v3/optimizer-trace.bin').read_bytes()
 log=Path('build/resident-opt-public-v5/diagnostic16/guest/debug.log').read_text()
 assert all(log.count(f'OPT RESIDENT METADATA {phase:016X}\n')==1 for phase in (0,1))
 assert Path('build/resident-opt-original-user-final/recovery64/guest/debug.log').read_text().count('PUBLIC OPT resident\n')==1
 r.update(result='pass',candidate_sha256=sha(image),canonical_support_byte_identical=True,complete_algorithm_preserved=True,extra_optimizer_module=False)
finally:(out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
