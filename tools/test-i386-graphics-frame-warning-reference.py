#!/usr/bin/env python3
"""Capture original diagnostics for the unchanged graphics-frame throw callback."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/'Kernel/I386/GraphicsFrameCheck.HC'


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--out',type=Path,required=True);args=p.parse_args();out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 out.mkdir(parents=True);sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
 paths=[Path(__file__).resolve(),FIXTURE,ROOT/'tools/test-i386-timeclock-reference.py',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
 pins={str(f):sha(f) for f in paths};report=dict(result='fail',input_sha256=pins,scope='Actual original ExePutS include of the exact GraphicsFrameThrow callback prefix; native-only GraphicsFrameCheck body is not compiled and no stand-in functions are supplied. Saved unused-parameter diagnostic, not graphics workflow qualification.')
 try:
  overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(paths[2]))['restore_reference'](overlay)
  captured=FIXTURE.read_bytes().split(b'I64 GraphicsFrameCheck()',1)[0]
  if not captured.startswith(b'U0 GraphicsFrameThrow('):raise ValueError('Unexpected fixture callback boundary')
  report['captured_source']=captured.decode();report['captured_sha256']=hashlib.sha256(captured).hexdigest()
  (overlay/'GraphicsFrameThrow.HC').write_bytes(captured)
  source='''U0 WReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
WReport("ADAM SERVER READY\\n");
CDoc *old=Fs->put_doc,*doc=DocNew;Fs->put_doc=doc;
ExePutS("#include \\"T:/GraphicsFrameThrow.HC\\"");
I64 size;U8 *text=DocSave(doc,&size),*notice=MStrPrint("EXPORT warning.DD %X %X\\n",text,size);WReport(notice);
Fs->put_doc=old;WReport("DONE original graphics callback warning\\n");
'''
  (overlay/'Once.HC').write_text(source)
  subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
  subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
  data=(out/'guest/warning.DD').read_bytes()
  if data.count(b'WARNING:')!=1 or any(part not in data for part in [b'Unused var',b"'dc' in 'GraphicsFrameThrow'"]):raise ValueError('Original graphics callback diagnostic differs')
  report['diagnostic_sha256']=hashlib.sha256(data).hexdigest();report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Original fixture warning failed')


if __name__=='__main__':main()
