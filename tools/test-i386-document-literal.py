#!/usr/bin/env python3
"""Require quoted DolDoc source entries to survive actual file compilation."""
import argparse,hashlib,json,runpy,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
EXPECTED={'literal-link.bin':b'Use $LK,"msg_code",A="MN:MSG_CMD"$ defines.\0','literal-text.bin':b'Use underlined text.\0'}
def verify(out):
 for n,v in EXPECTED.items():
  actual=(out/n).read_bytes()
  if actual!=v:raise ValueError('Quoted source serialization differs: '+repr((n,v,actual)))
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 if a.disk and not a.reference:ap.error('Native requires passing original')
 source=ROOT/'tests/guest/i386-document-literal/Source.HC';fixture=ROOT/'tests/guest/i386-document-literal/Contract.HC'
 paths=[source,fixture,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ['build-iso.py','test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py']]+[ROOT/'Kernel/FontStd.HC']
 if a.disk:
  r=json.loads((a.reference/'result.json').read_text());assert r['result']=='pass' and r['inputs_unchanged'] and r['source_sha256']==sha(source) and r['fixture_sha256']==sha(fixture);verify(a.reference)
  paths += [a.disk.resolve(),a.reference/'result.json']+[a.reference/n for n in EXPECTED]
 out.mkdir();pins={str(p):sha(p) for p in paths};(out/'source.HC').write_bytes(source.read_bytes());(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None
 report=dict(result='running',input_sha256=pins,source_sha256=sha(source),fixture_sha256=sha(fixture),scope='Actual source file compilation preserves a link inside a quoted literal; ordinary underlined text projects its tag as in the original. Exact expected bytes and original comparison. Not all dollar entries, compiler ownership or complete MsgLoop/C1-C5 qualification.')
 try:
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/DocumentLiteral.HC':source.read_bytes(),'/Probe/DocumentLiteralContract.HC':fixture.read_bytes()});before=pack['snapshot'](image.read_bytes())[1]
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Literal.HC').write_bytes(source.read_bytes());(overlay/'Once.HC').write_bytes(b'#include "T:/Literal.HC"\n'+fixture.read_bytes());image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(a.disk))
  if a.disk:
   g.wait('DONE native kernel startup\n');g.command('#include "C:/Probe/DocumentLiteral.HC"');g.type('#include "C:/Probe/DocumentLiteralContract.HC"');g.press('ret')
  g.wait('DL DONE\n')
  for n in EXPECTED:(out/n).write_bytes((g.out/n).read_bytes())
  verify(out)
  if a.disk:
   assert all((out/n).read_bytes()==(a.reference/n).read_bytes() for n in EXPECTED);g.command('6*7;');report['fresh_result']=g.result_pixels()
  g.close();g=None
  if a.disk:assert pack['snapshot'](image.read_bytes())[1]==before;report['files_unchanged']=True
  report['result']='pass'
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  report['inputs_unchanged']=all(p.is_file() and sha(p)==h for p,h in ((Path(n),h) for n,h in pins.items()))
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
