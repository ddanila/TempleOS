#!/usr/bin/env python3
"""Capture a function header when lexing its following include throws."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--out',type=Path,required=True)
 args=p.parse_args();out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 fixture=ROOT/'tests/guest/i386-include-header-reference';helper=ROOT/'tools/test-i386-timeclock-reference.py'
 paths=[Path(__file__).resolve(),fixture/'Once.HC',fixture/'Abort.HC',helper,ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
 sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();pins={str(f):sha(f) for f in paths}
 out.mkdir(parents=True);report=dict(result='fail',input_sha256=pins,
  scope='Actual original function body followed by an include whose real overlength identifier fails during lexing. ExePutS consumes Compiler; inspect retained Cf_EXTERN header, real UndefinedExtern address, actual unresolved call and preserved answer. No routine substitution; not an original ATA cancellation timing comparison or native qualification.')
 try:
  overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(helper))['restore_reference'](overlay)
  subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--overlay',str(fixture),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
  subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
  if (out/'guest/debug.log').read_text().count('ADAM SERVER READY\n')!=1:raise ValueError('Missing real server readiness')
  data=(out/'guest/include-header.bin').read_bytes()
  if len(data)!=56:raise ValueError('Bad include-header record length')
  report['records']=list(struct.unpack('<7q',data))
  expected=[0,23,1,1,1,int.from_bytes(b'UndefExt','little'),23]
  if report['records']!=expected:raise ValueError('Original include header differs')
  if b'Undefined Extern' not in (out/'guest/include-header.DD').read_bytes():raise ValueError('Missing real unresolved diagnostic')
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Original include header failed')


if __name__=='__main__':main()
