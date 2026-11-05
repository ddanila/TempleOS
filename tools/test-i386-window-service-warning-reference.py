#!/usr/bin/env python3
"""Capture original diagnostics for the unchanged window-service fixture include."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/'Kernel/I386/WindowServiceCheck.HC'


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--out',type=Path,required=True);args=p.parse_args();out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 out.mkdir(parents=True);sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
 paths=[Path(__file__).resolve(),FIXTURE,ROOT/'tools/test-i386-timeclock-reference.py',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
 pins={str(f):sha(f) for f in paths};report=dict(result='fail',input_sha256=pins,scope='Actual original ExePutS include of the complete unchanged WindowServiceCheck.HC; saved diagnostic for unused WindowCheckInside parameter. Does not run or qualify the window workflows.')
 try:
  overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(paths[2]))['restore_reference'](overlay)
  (overlay/'WindowServiceCheck.HC').write_bytes(FIXTURE.read_bytes())
  source='''U0 WReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
WReport("ADAM SERVER READY\\n");
CDoc *old=Fs->put_doc,*doc=DocNew;Fs->put_doc=doc;
ExePutS("#include \\"T:/WindowServiceCheck.HC\\"");
I64 size;U8 *text=DocSave(doc,&size),*notice=MStrPrint("EXPORT warning.DD %X %X\\n",text,size);WReport(notice);
Fs->put_doc=old;WReport("DONE original window fixture warning\\n");
'''
  (overlay/'Once.HC').write_text(source)
  subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
  subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
  data=(out/'guest/warning.DD').read_bytes()
  if data.count(b'WARNING:')!=1 or any(part not in data for part in [b'Unused var',b"'c' in 'WindowCheckInside'"]):raise ValueError('Original window fixture diagnostic differs')
  report['diagnostic_sha256']=hashlib.sha256(data).hexdigest();report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Original fixture warning failed')


if __name__=='__main__':main()
