#!/usr/bin/env python3
"""Execute the complete original terminal constructor on original and native systems."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-terminal-constructor/Contract.HC'
    helper=ROOT/'tools/test-i386-timeclock-welcome.py'
    paths=[Path(__file__).resolve(),fixture,helper,ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',ROOT/'tools/build-i386-kernel.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC',ROOT/'Adam/DolDoc/DocTermNewCore.HC',ROOT/'Adam/DolDoc/TermRightClickLinkCore.HC',ROOT/'Doc/EdPullDown.DD']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    if args.disk:paths.append(args.disk.resolve())
    else:
        manifest=ROOT/'build/rebuild-test/result.json';snapshot=json.loads(manifest.read_text())
        if snapshot.get('result')!='pass':raise ValueError('Qualified original rebuild required')
        paths.append(manifest)
        for name,relative in [('Kernel.BIN','0000Boot/0000Kernel.BIN.C'),('Compiler.BIN','Compiler/Compiler.BIN')]:
            p=ROOT/'build/rebuild-test/overlay'/relative
            if sha(p)!=snapshot['generations'][-1][name]:raise ValueError('Rebuild binary mismatch')
            paths.append(p)
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',mode='native' if args.disk else 'rebuilt-original',input_sha256=pins,scope='Execute complete DocTermNew: document ownership/limit/description, callback presence, border callbacks/title, actual editor menu, scroll controls, Raw OFF and existing-control reuse. No right-click action, autocomplete, pixel or exact heap qualification.')
    suffix='U0 TCReport(U8*s){while(*s)OutU8(0xE9,*s++);}\nU0 TCRun(){I64 mask=TerminalConstructorContract;U8 *line=MStrPrint("OBS TERMINAL CTOR %d\\n",mask);TCReport(line);Free(line);if(mask!=1023)throw(\'Ctor\',TRUE);TCReport("PASS TERMINAL CTOR\\n");}\n'
    try:
        if args.disk:
            image=out/'working.img';build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
            runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),image,additions={'/TermContract.HC':fixture.read_bytes()+suffix.encode()})
            runpy.run_path(str(helper))['guest'](image,out/'guest',['#include "C:/TermContract.HC"','TCRun;','6*7;'],64,True,accel='kvm')
            report['filesystem_integrity']=build['verify_mutated_volume'](image)
        else:
            overlay=out/'overlay';overlay.mkdir()
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+suffix.encode()+b'TCRun;TCReport("DONE TERMINAL CTOR\\n");\n')
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        log=(out/'guest/debug.log').read_text()
        if 'OBS TERMINAL CTOR 1023\n' not in log or 'PASS TERMINAL CTOR\n' not in log:raise ValueError('Constructor contract did not pass')
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(Path(p).is_file() and sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])
    print('PASS: complete terminal constructor; inputs unchanged')

if __name__=='__main__':main()
