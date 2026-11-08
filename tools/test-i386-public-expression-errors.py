#!/usr/bin/env python3
"""Check normal expression failure cleanup, outer graphs, flags and repeated execution."""
from pathlib import Path
import argparse,hashlib,json,runpy,struct
ROOT=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True)
args=ap.parse_args();source=args.disk.resolve();out=args.out.resolve()
if out.exists():ap.error('Use a fresh output directory')
out.mkdir(parents=True)
fixture=ROOT/'tests/guest/i386-public-expression/Errors.HC'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
paths=[Path(__file__).resolve(),source,fixture]+[ROOT/'tools'/n for n in ('test-i386-autocomplete-interaction.py','package-i386-native-image.py','build-i386-kernel.py')]
paths+=sorted(p for directory in ('Compiler','Kernel') for p in (ROOT/directory).rglob('*') if p.is_file() and p.suffix in ('.HC','.HH'))
pins={str(p):sha(p) for p in paths}
r=dict(result='running',input_sha256=pins,scope='Nine normal API cases: three syntax failures, successful flag preservation, backend precondition failure, raw/I64/F64 evaluation exceptions and a nested array-bound evaluation throw. Exact exception and error counters, graph/flag restoration, zero caller heap deltas, NULL/result ownership and continued execution. Not all error/OOM/cancellation paths.')
(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));g=None
try:
 before=pack['snapshot'](source.read_bytes())[1]
 for p in paths:
  if p.is_relative_to(ROOT) and p.suffix in ('.HC','.HH'):
   n='/'+str(p.relative_to(ROOT))
   if n in before and p.read_bytes()!=before[n][2]:raise ValueError('Delivered source differs: '+n)
 r['packaging']=pack['package'](source,out/'working.img',additions={'/Probe/Errors.HC':fixture.read_bytes()})
 Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(out/'working.img',out/'guest',True)
 g.wait('DONE native kernel startup\n');g.command('#include "C:/Probe/Errors.HC"',timeout=600);g.wait('EXPRESSION ERRORS DONE\n')
 data=(g.out/'expression-errors.bin').read_bytes();(out/'expression-errors.bin').write_bytes(data)
 records=list(struct.unpack('<81q',data));r['records']=[records[i:i+9] for i in range(0,len(records),9)]
 compiler=int.from_bytes(b'Compiler','little');evaluation=int.from_bytes(b'EvalFail','little')
 expected=[[compiler,2,1,1,1,0,0,1,42]]*3+[[0,0,1,1,1,0,0,0,42],[compiler,0,1,1,1,0,0,1,42]]+[[evaluation,0,1,1,1,0,0,1,42]]*4
 if r['records']!=expected:raise ValueError('Expression error state differs: '+str(r['records']))
 log=g.collect();r['parser_publications']=log.count('PUBLIC PARSER loaded\n')
 if r['parser_publications']!=1:raise ValueError('Expected one parser publication')
 g.command('6*7;');r['arithmetic_pixels']=g.result_pixels();g.close();g=None
 after=pack['snapshot']((out/'working.img').read_bytes())[1]
 if {n for n in set(before)|set(after) if before.get(n)!=after.get(n)}!={'/Probe/Errors.HC'}:raise ValueError('Unexpected filesystem changes')
 r['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](out/'working.img');r['result']='pass'
except BaseException as e:r.update(result='fail',error=str(e) or type(e).__name__);raise
finally:
 if g:g.close()
 r['inputs_unchanged']=all(sha(Path(n))==h for n,h in pins.items())
 if not r['inputs_unchanged']:r.update(result='fail',error='Inputs changed')
 (out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
if r['result']!='pass':raise ValueError(r.get('error','Expression errors failed'))
