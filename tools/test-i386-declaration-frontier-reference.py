#!/usr/bin/env python3
"""Capture original compound-statement and failed-header declaration state."""
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
 fixture=ROOT/'tests/guest/i386-declaration-frontier-reference';helper=ROOT/'tools/test-i386-timeclock-reference.py'
 paths=[Path(__file__).resolve(),fixture/'Once.HC',helper,ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
 sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();pins={str(f):sha(f) for f in paths}
 out.mkdir(parents=True);report=dict(result='fail',input_sha256=pins,
  scope='Actual original ExePutS with flags 0/CCF_CMD_LINE: completed function/global in a throwing or malformed compound statement; failed function header retains two default arguments and real UndefinedExtern target; actual unresolved call. No routine substitution or native qualification.')
 try:
  overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(helper))['restore_reference'](overlay)
  subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--overlay',str(fixture),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
  subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
  if (out/'guest/debug.log').read_text().count('ADAM SERVER READY\n')!=1:raise ValueError('Missing real server readiness')
  data=(out/'guest/frontier.bin').read_bytes()
  if len(data)!=400:raise ValueError('Bad frontier record length')
  rows=[list(struct.unpack_from('<5q',data,n*40)) for n in range(10)];report['records']=rows
  expected=[[0,int.from_bytes(b'Delib','little'),23,1,99],[0,0,23,1,99],
   [0,int.from_bytes(b'Delib','little'),23,1,97],[0,0,23,1,127],
   [0,int.from_bytes(b'UndefExt','little'),23,1,127]]*2
  if rows!=expected:raise ValueError('Original declaration frontier differs')
  for n in range(10):
   text=(out/f'guest/frontier-{n}.DD').read_bytes()
   if n%5==1 and b'Undefined identifier' not in text:raise ValueError('Missing compound parse diagnostic')
   if n%5==3 and b'Invalid lval' not in text:raise ValueError('Missing failed-body diagnostic')
   if n%5==4 and b'Undefined Extern' not in text:raise ValueError('Missing actual UndefinedExtern diagnostic')
   if n%5 in (0,2) and text:raise ValueError('Unexpected automatic output')
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Original declaration frontier failed')


if __name__=='__main__':main()
