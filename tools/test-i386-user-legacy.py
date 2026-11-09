#!/usr/bin/env python3
"""Exercise a real User terminal entering and leaving its retained editor view."""
import argparse,hashlib,json,runpy,time
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',required=True,type=Path);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 parent=ROOT/'tests/guest/i386-user-legacy/Parent.HC';child=parent.with_name('Child.HC');inputs=[a.disk.resolve(),parent,child,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ['test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','i386-kernel-input.py','package-i386-native-image.py','build-i386-kernel.py']]+[ROOT/'Kernel/FontStd.HC']
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();out.mkdir();pins={str(p):sha(p) for p in inputs};(out/'parent.HC').write_bytes(parent.read_bytes());(out/'child.HC').write_bytes(child.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None
 report=dict(result='running',input_sha256=pins,scope='Real User enters retained DocEd, exact full-screen font oracle before/after save, abc+cursor file bytes, original welcome/document-role restoration and Kill/fresh42; all prior files preserved. Native editor transition regression, not original editor/full desktop/resource qualification.')
 try:
  pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/UserLegacyParent.HC':parent.read_bytes(),'/Probe/UserLegacyChild.HC':child.read_bytes()});before=pack['snapshot'](image.read_bytes())[1]
  helper=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'));g=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'](image,out/'guest',True);g.wait('DONE native kernel startup\n');g.command('#include "C:/Probe/UserLegacyParent.HC"');g.command('ULPrepare;');g.wait('DOC EDIT begin\n')
  def frame(label,saved=False):
   rows=['TempleOS i386','DolDoc editor'+(' - Saved' if saved else ''),'C:/UserLegacy.DD','','abc'+bytes([0xDB]).decode('cp437')];want=helper['console_pixels'](rows);end=time.monotonic()+30
   while time.monotonic()<end:
    g.screenshot(label)
    if Image.open(g.out/(label+'.png')).convert('RGB').tobytes()==want:return
    time.sleep(.1)
   raise ValueError('Retained editor pixels differ: '+label)
  g.type('abc');frame('typed')
  g.key('ctrl',True);g.press('s');g.key('ctrl',False);frame('saved',True)
  g.press('esc');g.wait('USER LEGACY DONE\n')
  if 'USER LEGACY MASK 3\n' not in g.collect():raise ValueError('Original User document/role restoration failed')
  g.command('ULFinish;');g.command('6*7;');report['fresh_result']=g.result_pixels();g.close();g=None
  after=pack['snapshot'](image.read_bytes())[1]
  if any(after.get(n)!=v for n,v in before.items()) or set(after)-set(before)!={'/UserLegacy.DD'}:raise ValueError('Prior files changed or unexpected output files')
  data=after['/UserLegacy.DD'][2];(out/'UserLegacy.DD').write_bytes(data)
  if data!=b'abc\x05':raise ValueError('Saved editor bytes differ')
  report.update(result='pass',pixels=2*640*480,files_preserved=len(before),mask=3)
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
