#!/usr/bin/env python3
"""Check per-task UserStartUp override through the real UserCmdLine entry."""
import argparse,hashlib,json,runpy,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',required=True,type=Path);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 fixture=ROOT/'tests/guest/i386-user-startup-hook/Contract.HC';inputs=[fixture,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-timeclock-welcome.py','build-iso.py','guest-run.py','build-i386-kernel.py','package-i386-native-image.py']]+[ROOT/'Kernel/FontStd.HC']
 if a.disk:inputs.append(a.disk.resolve())
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();out.mkdir();pins={str(p):sha(p) for p in inputs};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
 suffix=b'\nU0 UHLog(U8*s){while(*s)OutU8(0xE9,*s++);}\nU0 UHRun(){I64 mask=UserHookContract;U8 *s=MStrPrint("USER HOOK MASK %d\\n",mask);UHLog(s);Free(s);if(mask!=63)throw(\'UserHook\',TRUE);UHLog("PASS USER HOOK\\n");}\n'
 report=dict(result='running',input_sha256=pins,scope='Local UserStartUp override inherited by explicitly parented Spawn(UserCmdLine): exactly one invocation in child, custom document prefix without default/native heading, terminal roles/controls and successful Kill. Not full prompt/pixels/all custom callbacks/resource/C1-C5 qualification.')
 try:
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/UserHook.HC':fixture.read_bytes()+suffix});before=pack['snapshot'](image.read_bytes())[1]
   report['behavior']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](image,out/'guest',['#include "C:/Probe/UserHook.HC"','UHRun;','6*7;'],64,True,accel='kvm')
   if pack['snapshot'](image.read_bytes())[1]!=before:raise ValueError('Files changed')
   report['files_unchanged']=True
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay);(overlay/'Once.HC').write_bytes(fixture.read_bytes()+suffix+b'UHRun;UHLog("DONE USER HOOK\\n");\n');iso=out/'original.iso'
   subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True);subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
  text=(out/'guest/debug.log').read_text()
  if 'USER HOOK MASK 63\n' not in text or 'PASS USER HOOK\n' not in text:raise ValueError('User startup override contract failed')
  report['result']='pass'
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
