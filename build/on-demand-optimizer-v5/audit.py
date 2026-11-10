from pathlib import Path
import runpy,shutil,struct,json,hashlib
out=Path(__file__).resolve().parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
exports=out/'audit/exports';exports.mkdir(parents=True,exist_ok=True)
inputs=[Path('tools/build-i386-kernel.py'),Path('tools/test-i386.py'),out/'exports/OptRuntime.t32m',out/'overlay/Kernel/I386/OptRuntime.HC']
for p in Path('build/on-demand-lexer-v9/audit/exports').iterdir():
 if p.is_file():shutil.copyfile(p,exports/p.name);inputs.append(p)
inputs.append(Path('Compiler/I386/PublicOptSupport.HC'))
pins={str(p):sha(p) for p in inputs}
original=Path('Compiler/I386/PublicOptSupport.HC').read_bytes()
body=original[original.index(b'#include "/Compiler/ICInfo.HC"'):original.index(b'ICInfoInit;')]
assert (out/'overlay/Kernel/I386/OptRuntime.HC').read_bytes().count(body)==1
cross=json.loads((out/'result.json').read_text());assert cross['result']=='pass' and cross['inputs_unchanged']
shutil.copyfile(out/'exports/OptRuntime.t32m',exports/'OptRuntime.t32m')
ns=runpy.run_path('tools/build-i386-kernel.py');ns['audit'].__globals__['DISK_MODULES']=ns['DISK_MODULES']+('LexRuntime','OptRuntime');ns['audit'](exports,out/'audit')
b=(exports/'OptRuntime.t32m').read_bytes();size,count,records=struct.unpack_from('<III',b,16);symbols={};imports=set()
for i in range(count):
 kind,offset,n,length=struct.unpack_from('<4I',b,records+16*i)
 if kind in (1,2,3,5):
  name=b[n:n+length].decode('ascii')
  if kind in (2,5):imports.add(name)
  else:symbols[name]=dict(kind=kind,offset=offset)
expected={'COCMiscNew','Free','I386F64Add','I386F64Compare','I386F64Div','I386F64FromI64','I386F64Mod','I386F64Mul','I386F64Sub','I386F64ToI64','LexExcept','LexWarn','MAlloc','Print','PrintErr','PutChars','Yield','cmp','throw'}
assert imports==expected
for name in ['Main','NativeSystemOptPass012','PrsPush','PrsPop','OptFree','CmpTargetSize','ICPut']:assert symbols[name]['kind']==1
assert symbols['intermediate_code_table']['kind']==3
assert all(sha(Path(p))==h for p,h in pins.items())
r=dict(result='pass',scope='Full shared optimizer cross compile, exact 19-import contract, helper/metadata exports and complete 386 instruction audit only; no provider integration, namespace publication, runtime or resource qualification',module_bytes=len(b),code_bytes=size,module_sha256=sha(exports/'OptRuntime.t32m'),input_sha256=pins,inputs_unchanged=True,imports=sorted(imports),exports=symbols)
(out/'module-audit.json').write_text(json.dumps(r,indent=2)+'\n')
print(json.dumps({k:r[k] for k in ['result','module_bytes','code_bytes','module_sha256']}))
