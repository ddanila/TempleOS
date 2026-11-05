#!/usr/bin/env python3
"""Capture the original unused-argument diagnostic for the retained PubDraw source."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
ROOT=Path(__file__).resolve().parents[1]
SOURCE='U0 PubDraw(CTask *t,CDC *d){t->user_data=42;}'


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--out',type=Path,required=True);args=p.parse_args();out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 out.mkdir(parents=True);sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
 paths=[Path(__file__).resolve(),ROOT/'tools/test-i386-timeclock-reference.py',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
 pins={str(f):sha(f) for f in paths};report=dict(result='fail',input_sha256=pins,source=SOURCE,scope='Actual original ExePutS of unchanged retained compiler PubDraw declaration, saved document unused-argument warning; not native full warning byte/style qualification.')
 try:
  overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(paths[1]))['restore_reference'](overlay)
  source='''U0 WReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
WReport("ADAM SERVER READY\\n");
CDoc *old=Fs->put_doc,*doc=DocNew;Fs->put_doc=doc;
'''
  source+='ExePutS('+json.dumps(SOURCE)+');\n'
  source+='''I64 size;U8 *text=DocSave(doc,&size),*notice=MStrPrint("EXPORT warning.DD %X %X\\n",text,size);WReport(notice);
Fs->put_doc=old;WReport("DONE original unused argument\\n");
'''
  (overlay/'Once.HC').write_text(source)
  subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
  subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
  text=(out/'guest/warning.DD').read_bytes()
  if any(part not in text for part in [b'WARNING:',b'Unused var',b"'d' in 'PubDraw'"]):raise ValueError('Missing actual unused argument warning')
  report['diagnostic_sha256']=hashlib.sha256(text).hexdigest();report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Original compiler warning failed')


if __name__=='__main__':main()
