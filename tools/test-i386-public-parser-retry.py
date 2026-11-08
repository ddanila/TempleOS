#!/usr/bin/env python3
"""Fail and resume the actual normal parser loader on a writable native image copy."""
from pathlib import Path
import runpy,json,hashlib,time,argparse,struct
root=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True)
args=ap.parse_args();source=args.disk.resolve();out=args.out.resolve()
if out.exists():ap.error('Use a fresh output directory')
out.mkdir(parents=True)
fixture=root/'tests/guest/i386-public-expression/LoaderRetry.HC'
(out/'fixture.HC').write_bytes(fixture.read_bytes())
(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
paths=[source,Path(__file__).resolve(),fixture,root/'tools/test-i386-autocomplete-interaction.py',root/'tools/package-i386-native-image.py',root/'tools/build-i386-kernel.py']
paths += sorted(p for directory in ('Compiler','Kernel') for p in (root/directory).rglob('*') if p.is_file() and p.suffix in ('.HC','.HH'))
pins={str(p):sha(p) for p in paths}
r=dict(result='running',input_sha256=pins,scope='Actual failed normal stage 11 and retry: zero partial callback publication, stage resume, Adam namespace and caller heap restoration; one successful publication')
pack=runpy.run_path(str(root/'tools/package-i386-native-image.py'));before=pack['snapshot'](source.read_bytes())[1];g=None
try:
 for p in paths:
  if p.is_relative_to(root) and p.suffix in ('.HC','.HH'):
   n='/'+str(p.relative_to(root))
   if n in before and p.read_bytes()!=before[n][2]:raise ValueError('Delivered source differs: '+n)
 r['packaging']=pack['package'](source,out/'working.img',additions={'/Probe/ParserRetry.HC':fixture.read_bytes()})
 Guest=runpy.run_path(str(root/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(out/'working.img',out/'guest',True)
 g.wait('DONE native kernel startup\n');start=len(g.collect());g.type('#include "C:/Probe/ParserRetry.HC"');g.press('ret')
 #One nested AdamFile source execution is deliberately rejected. Require the
 #outer command to finish and the independent records to pass; never ignore
 #the failed stage or interpret its COMMAND OK parent as publication.
 end=time.monotonic()+600
 while g.p.poll() is None and time.monotonic()<end:
  log=g.collect()[start:]
  if 'COMMAND OK\n' in log or 'COMMAND ERROR\n' in log:break
  time.sleep(.1)
 else:raise TimeoutError('Outer retry contract did not finish')
 if 'PUBLIC PARSER RETRY DONE\n' not in log:raise ValueError(log[-2000:])
 import struct
 data=(g.out/'public-parser-retry.bin').read_bytes();(out/'public-parser-retry.bin').write_bytes(data);r['records']=list(struct.unpack('<13q',data))
 assert r['records']==[1]*13,r['records']
 r['parser_publications']=log.count('PUBLIC PARSER loaded\n');assert r['parser_publications']==1
 assert log.count('INPUT REJECT ')==1,log
 g.command('6*7;');r['arithmetic_pixels']=g.result_pixels();g.close();g=None
 after=pack['snapshot']((out/'working.img').read_bytes())[1];changed={n for n in set(before)|set(after) if before.get(n)!=after.get(n)}
 assert changed<= {'/Probe/ParserRetry.HC','/Compiler/I386/PublicPrsStream.HC'},changed
 n='/Compiler/I386/PublicPrsStream.HC';assert before[n][0]==after[n][0] and before[n][2]==after[n][2]
 r['changed_paths']=sorted(changed);r['restored_stage_sha256']=hashlib.sha256(after[n][2]).hexdigest()
 r['filesystem']=runpy.run_path(str(root/'tools/build-i386-kernel.py'))['verify_mutated_volume'](out/'working.img');r['result']='pass'
except BaseException as e:r.update(result='fail',error=str(e) or type(e).__name__);raise
finally:
 if g:g.close()
 r['inputs_unchanged']=all(sha(Path(n))==h for n,h in pins.items())
 if not r['inputs_unchanged']:r.update(result='fail',error='Inputs changed')
 (out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
if r['result']!='pass':raise ValueError(r.get('error','Parser retry failed'))
