#!/usr/bin/env python3
"""Check automatic terminal scroll controls and real wheel dispatch against original."""
import argparse,hashlib,json,re,runpy,struct,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',required=True,type=Path);ap.add_argument('--reference',type=Path);ap.add_argument('--lifecycle',action='store_true');ap.add_argument('--initialize-scrolls',action='store_true',help='Diagnostic explicit initialization, not automatic-terminal qualification');a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 fixture=ROOT/'tests/guest/i386-terminal-scrolls/Contract.HC';inputs=[fixture,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ('test-i386-autocomplete-interaction.py','test-i386-timeclock-reference.py','build-iso.py','package-i386-native-image.py','test-i386-timeclock-welcome.py','build-i386-kernel.py','i386-kernel-input.py')] + [ROOT/'Kernel/FontStd.HC']
 lifecycle=fixture.with_name('Lifecycle.HC')
 if a.lifecycle:inputs.append(lifecycle)
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
 if a.disk:
  if not a.reference:ap.error('Native requires a passing matching original reference')
  inputs += [a.disk.resolve(),a.reference/'result.json',a.reference/'terminal-scroll.bin']
  r=json.loads((a.reference/'result.json').read_text());assert r['result']=='pass' and r['inputs_unchanged'] and not r['explicit_initialization']
  assert r['input_sha256'][str(fixture)]==sha(fixture) and r.get('lifecycle',False)==a.lifecycle
  if a.lifecycle:
   assert r['input_sha256'][str(lifecycle)]==sha(lifecycle)
   inputs.append(a.reference/'terminal-scroll-lifecycle.bin')
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
 pins={str(p):sha(p) for p in inputs};out.mkdir();(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None
 report=dict(result='running',input_sha256=pins,explicit_initialization=a.initialize_scrolls,lifecycle=a.lifecycle,scope='Root automatic horizontal/vertical scroll controls, state/owner/callback binding, actual QMP wheel delivery with hidden scrollbars, document cursor observation and exact caller heap/document restoration. Explicit-init mode isolates a missing default; optional three User create/reuse/kill cycles require control ownership, idempotence and exact caller data/code heaps (4095); not failed initialization/full MsgLoop or C1-C5 qualification.')
 try:
  code=fixture.read_bytes()+(lifecycle.read_bytes() if a.lifecycle else b'')+f'\nTSProbe({"TRUE" if a.initialize_scrolls else "FALSE"});\n'.encode()+(b'TSLifecycle;\n' if a.lifecycle else b'')
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/TerminalScroll.HC':code});before=pack['snapshot'](image.read_bytes())[1]
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay);(overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+code);image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  g=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'](image,out/'guest',bool(a.disk))
  if a.disk:g.wait('DONE native kernel startup\n');g.type('#include "C:/Probe/TerminalScroll.HC"');g.press('ret')
  g.wait('TERMINAL SCROLL READY\n');time.sleep(.5)
  for down in (True,False):g.call('input-send-event',events=[{'type':'btn','data':{'button':'wheel-down','down':down}}])
  time.sleep(1);g.press('q');g.wait('TERMINAL SCROLL DONE\n')
  if a.lifecycle:
   g.wait('TERMINAL SCROLL LIFECYCLE DONE\n');text=g.collect();m=re.search(r'TERMINAL SCROLL LIFECYCLE (\d+)\n',text);report['lifecycle_mask']=int(m[1]) if m else None
   (out/'terminal-scroll-lifecycle.bin').write_bytes((g.out/'terminal-scroll-lifecycle.bin').read_bytes())
   if report['lifecycle_mask']!=4095:raise ValueError('Child control ownership/idempotence/retirement/heap contract failed')
  g.screenshot('final')
  raw=(g.out/'terminal-scroll.bin').read_bytes();(out/'terminal-scroll.bin').write_bytes(raw);values=struct.unpack('<9q',raw);report['values']=values
  if values[2:]!=(1,1,5,2,0,1,1):raise ValueError('Wheel binding/dispatch or caller restoration differs: '+repr(values))
  if not a.initialize_scrolls and values[:2]!=(1,1):raise ValueError('Automatic terminal controls missing')
  if a.disk:
   expected=struct.unpack('<9q',(a.reference/'terminal-scroll.bin').read_bytes())
   if values[2:]!=expected[2:] or not a.initialize_scrolls and values!=expected:raise ValueError('Original scalar state differs')
   g.command('6*7;');report['fresh_result']=g.result_pixels()
  g.close();g=None
  if a.disk:assert pack['snapshot'](image.read_bytes())[1]==before;report['files_unchanged']=True
  report['result']='pass'
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
