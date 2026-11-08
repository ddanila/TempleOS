#!/usr/bin/env python3
"""Check normal expression failure cleanup, outer graphs, flags and repeated execution."""
from pathlib import Path
import argparse,hashlib,json,runpy,struct
ROOT=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True)
ap.add_argument('--array-partials',action='store_true',help='Also check partial dimension ownership, reset and successful transfer through normal expression/type services')
ap.add_argument('--declarations',action='store_true',help='Also check member/default-code cleanup, declaration state and diagnostic insertion ownership')
ap.add_argument('--joins',action='store_true',help='Also check anonymous function/type ownership and failed header replacement through normal shared services')
args=ap.parse_args();source=args.disk.resolve();out=args.out.resolve()
if out.exists():ap.error('Use a fresh output directory')
out.mkdir(parents=True)
fixture=ROOT/'tests/guest/i386-public-expression/Errors.HC'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
paths=[Path(__file__).resolve(),source,fixture]+[ROOT/'tools'/n for n in ('test-i386-autocomplete-interaction.py','package-i386-native-image.py','build-i386-kernel.py')]
paths+=sorted(p for directory in ('Compiler','Kernel') for p in (ROOT/directory).rglob('*') if p.is_file() and p.suffix in ('.HC','.HH'))
array_fixture=fixture.parent/'ArrayPartial.HC'
if args.array_partials:paths.append(array_fixture)
declaration_fixture=fixture.parent/'DeclarationErrors.HC'
if args.declarations:paths.append(declaration_fixture)
join_fixture=fixture.parent/'JoinErrors.HC'
if args.joins:paths.append(join_fixture)
pins={str(p):sha(p) for p in paths}
r=dict(result='running',input_sha256=pins,scope='Nine normal API cases: three syntax failures, successful flag preservation, backend precondition failure, raw/I64/F64 evaluation exceptions and a nested array-bound evaluation throw. Exact exception and error counters, graph/flag restoration, zero caller heap deltas, NULL/result ownership and continued execution. Not all error/OOM/cancellation paths.')
r['array_partials_requested']=args.array_partials
r['declarations_requested']=args.declarations
r['joins_requested']=args.joins
if args.joins:r['scope']+=' Also thirteen function/type-join cases: anonymous ownership, late bounds, whole-header restoration except the intended lookup use counter, early/late warning throws and successful transfer/replacement.'
if args.declarations:r['scope']+=' Also twelve direct normal declaration failure/control rows and a real MemberInsert warning exception: unlinked member/default-code ownership, caller snapshots/flags/graph, retained prefix and zero heap deltas.'
if args.array_partials:r['scope']+=' Also four partial-array expression failures and seven direct type cases: exact counters, reset dimensions, zero heap deltas, successful dimension transfer and continued execution.'
(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));g=None
try:
 before=pack['snapshot'](source.read_bytes())[1]
 for p in paths:
  if p.is_relative_to(ROOT) and p.suffix in ('.HC','.HH'):
   n='/'+str(p.relative_to(ROOT))
   if n in before and p.read_bytes()!=before[n][2]:raise ValueError('Delivered source differs: '+n)
 additions={'/Probe/Errors.HC':fixture.read_bytes()}
 if args.array_partials:additions['/Probe/ArrayPartial.HC']=array_fixture.read_bytes();(out/'array-fixture.HC').write_bytes(array_fixture.read_bytes())
 if args.declarations:additions['/Probe/DeclarationErrors.HC']=declaration_fixture.read_bytes();(out/'declaration-fixture.HC').write_bytes(declaration_fixture.read_bytes())
 if args.joins:additions['/Probe/JoinErrors.HC']=join_fixture.read_bytes();(out/'join-fixture.HC').write_bytes(join_fixture.read_bytes())
 r['packaging']=pack['package'](source,out/'working.img',additions=additions)
 Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(out/'working.img',out/'guest',True)
 g.wait('DONE native kernel startup\n');g.command('#include "C:/Probe/Errors.HC"',timeout=600);g.wait('EXPRESSION ERRORS DONE\n')
 data=(g.out/'expression-errors.bin').read_bytes();(out/'expression-errors.bin').write_bytes(data)
 records=list(struct.unpack('<81q',data));r['records']=[records[i:i+9] for i in range(0,len(records),9)]
 compiler=int.from_bytes(b'Compiler','little');evaluation=int.from_bytes(b'EvalFail','little')
 expected=[[compiler,2,1,1,1,0,0,1,42]]*3+[[0,0,1,1,1,0,0,0,42],[compiler,0,1,1,1,0,0,1,42]]+[[evaluation,0,1,1,1,0,0,1,42]]*4
 if r['records']!=expected:raise ValueError('Expression error state differs: '+str(r['records']))
 if args.array_partials:
  g.command('#include "C:/Probe/ArrayPartial.HC"',timeout=600);g.wait('ARRAY PARTIAL DONE\n')
  data=(g.out/'array-partial.bin').read_bytes();(out/'array-partial.bin').write_bytes(data)
  values=list(struct.unpack('<92q',data));r['array_expression_rows']=[values[i:i+9] for i in range(0,36,9)]
  r['array_type_rows']=[values[i:i+8] for i in range(36,92,8)]
  expression_expected=[[evaluation,0,1,1,1,0,0,1,42]]*2+[[compiler,2,1,1,1,0,0,1,42]]*2
  type_expected=[[evaluation,0,1,1,0,0,42,1]]*2+[[compiler,1,1,1,0,0,42,1]]*2+[[0,0,1,1,0,0,42,1]]*3
  if r['array_expression_rows']!=expression_expected or r['array_type_rows']!=type_expected:raise ValueError('Array ownership differs: '+str(r['array_expression_rows'])+' '+str(r['array_type_rows']))
 if args.declarations:
  g.command('#include "C:/Probe/DeclarationErrors.HC"',timeout=600);g.wait('DECLARATION ERRORS DONE\n')
  data=(g.out/'declaration-errors.bin').read_bytes();(out/'declaration-errors.bin').write_bytes(data)
  values=list(struct.unpack('<151q',data));r['declaration_rows']=[values[i:i+12] for i in range(0,144,12)];r['member_insert_row']=values[144:]
  r['declaration_type_detail']=list(struct.unpack('<8q',(g.out/'declaration-type-detail.bin').read_bytes()))
  detail=r['declaration_type_detail']
  if detail[0]!=detail[1] or detail[3:]!=[1,6,2,3,1]:raise ValueError('Named declaration type/dimensions differ: '+str(detail))
  tags=[evaluation,evaluation,compiler,compiler,compiler,evaluation,compiler,evaluation,0,0,evaluation,0]
  errors=[0,0,1,1,1,0,2,0,0,0,0,0];counts=[0,1,0,1,1,1,1,1,1,1,1,1]
  expected=[[tag,error,1,1,1,1,count,count,0,0,42,1] for tag,error,count in zip(tags,errors,counts)]
  if r['declaration_rows']!=expected:raise ValueError('Declaration ownership/state differs: '+str(r['declaration_rows']))
  if r['member_insert_row']!=[int.from_bytes(b'MemWarn','little'),1,1,1,1,0,42]:raise ValueError('Diagnostic insertion ownership differs: '+str(r['member_insert_row']))
 if args.joins:
  g.command('#include "C:/Probe/JoinErrors.HC"',timeout=600);g.wait('JOIN ERRORS DONE\n')
  data=(g.out/'join-errors.bin').read_bytes();(out/'join-errors.bin').write_bytes(data)
  values=list(struct.unpack('<156q',data));r['join_rows']=[values[i:i+12] for i in range(0,156,12)]
  warning=int.from_bytes(b'JoinWarn','little')
  tags=[evaluation,compiler,0,evaluation,evaluation,compiler,0,evaluation,compiler,0,warning,warning,warning]
  errors=[0,1,0,0,0,1,0,0,1,0,0,0,0];kinds=[-1]*10+[1,0,2];entries=[0]*7+[1]*6
  expected=[[tag,error,1,1,1,1,1,0,0,42,kind,entry] for tag,error,kind,entry in zip(tags,errors,kinds,entries)]
  if r['join_rows']!=expected:raise ValueError('Function/type join ownership differs: '+str(r['join_rows']))
 log=g.collect();r['parser_publications']=log.count('PUBLIC PARSER loaded\n')
 if r['parser_publications']!=1:raise ValueError('Expected one parser publication')
 g.command('6*7;');r['arithmetic_pixels']=g.result_pixels();g.close();g=None
 after=pack['snapshot']((out/'working.img').read_bytes())[1]
 if {n for n in set(before)|set(after) if before.get(n)!=after.get(n)}!=set(additions):raise ValueError('Unexpected filesystem changes')
 r['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](out/'working.img');r['result']='pass'
except BaseException as e:r.update(result='fail',error=str(e) or type(e).__name__);raise
finally:
 if g:g.close()
 r['inputs_unchanged']=all(sha(Path(n))==h for n,h in pins.items())
 if not r['inputs_unchanged']:r.update(result='fail',error='Inputs changed')
 (out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
if r['result']!='pass':raise ValueError(r.get('error','Expression errors failed'))
