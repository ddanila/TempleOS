#!/usr/bin/env python3
"""Capture original persistent extern identity and late caller binding."""
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
 fixture=ROOT/'tests/guest/i386-extern-binding-reference';helper=ROOT/'tools/test-i386-timeclock-reference.py'
 paths=[Path(__file__).resolve(),fixture/'Once.HC',helper,ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
 sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();pins={str(f):sha(f) for f in paths}
 out.mkdir(parents=True);report=dict(result='fail',input_sha256=pins,
  scope='Actual original extern prototype, unresolved compiled caller, first definition and later shadowing. Integer default 7, both ExePutS flag modes, real UndefinedExtern, persistent descriptor identity and real documents; string-default lifetime remains separate. No routine substitution or native qualification.')
 try:
  overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(helper))['restore_reference'](overlay)
  subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--overlay',str(fixture),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
  subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
  if (out/'guest/debug.log').read_text().count('ADAM SERVER READY\n')!=1:raise ValueError('Missing real server readiness')
  data=(out/'guest/binding.bin').read_bytes()
  if len(data)!=640:raise ValueError('Bad frontier record length')
  rows=[list(struct.unpack_from('<5q',data,n*40)) for n in range(16)];report['records']=rows
  expected=[[0,0,23,1,1],[0,0,23,1,1],
   [0,int.from_bytes(b'UndefExt','little'),23,1,1],[0,0,23,1,1],
   [97,0,97,1,1],[0,0,23,1,0],[97,0,97,1,0],[101,0,101,1,0]]*2
  if rows!=expected:raise ValueError('Original extern binding differs')
  for n in range(16):
   text=(out/f'guest/binding-{n}.DD').read_bytes()
   if n%8==2 and b'Undefined Extern' not in text:raise ValueError('Missing real UndefinedExtern diagnostic')
   if n%8==5 and b'Unused var' not in text:raise ValueError('Missing actual unused-argument warning')
   if n%8 not in (2,5) and text:raise ValueError('Unexpected automatic output')
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Original extern binding failed')


if __name__=='__main__':main()
