#!/usr/bin/env python3
"""Test the exact frontend helper pre-scan against pre-optimization union poison."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
reference=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))

def extract(path,start,end):
    text=path.read_text();a=text.index(start);b=text.index(end,a)+len(end)
    return text[a:b]+'\n'

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    overlay=out/'overlay';overlay.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-helper-scan-reference/Contract.HC'
    frontend=ROOT/'Compiler/I386/Frontend.HC';backend=ROOT/'Compiler/I386/BackendCore.HC';types=ROOT/'Compiler/I386/Backend.HH'
    files=[Path(__file__).resolve(),fixture,frontend,backend,types,ROOT/'Compiler/ICInfo.HC',ROOT/'Compiler/CompilerA.HH',ROOT/'tools/test-i386-timeclock-reference.py',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
    sha=reference['sha'];pins={str(p):sha(p) for p in files}
    sources=reference['restore_reference'](overlay)
    source=extract(ROOT/'Compiler/CompilerA.HH','class CIntermediateStruct','};')
    source+=(ROOT/'Compiler/ICInfo.HC').read_text()+'\nICInfoInit;\n'
    source+='extern class CI386Out;extern class CI386Call;extern class CI386Logic;extern class CI386Chain;extern class CI386BackendStatus;\n'
    source+=extract(types,'class CI386Backend {','};')
    source+=extract(backend,'Bool I386IsF64(', '\n}\n')
    source+=extract(backend,'CHashClass *I386ValueClass(', '\n}\n')
    source+=extract(frontend,'Bool I386FrontendNeedsHelpers(', '\n}\n')
    source+=fixture.read_text()
    source+='\nU0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}\nI64 helper_mask=HelperScanContract;U8*helper_line=MStrPrint("OBS helper scan %d\\n",helper_mask);Report(helper_line);Free(helper_line);Report("DONE helper scan\\n");\n'
    (overlay/'Once.HC').write_text(source)
    report=dict(result='running',input_sha256=pins,reference_sha256=sources,scope='Exact production pre-scan bodies on original x64 with synthetic pre-optimization IR; not native compiler/full module qualification',expected=63,generated_source_sha256=hashlib.sha256(source.encode()).hexdigest())
    try:
        iso=out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','90'],cwd=ROOT,check=True)
        log=(out/'guest/debug.log').read_text()
        rows=[line for line in log.splitlines() if line.startswith('OBS helper scan ')]
        if len(rows)!=1:raise ValueError('Missing helper scan observation')
        report['observed']=int(rows[0].split()[-1])
        if report['observed']!=63:raise ValueError('Pre-scan consumed pre-optimization tree/code union or missed required F64 detection')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Probe inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
