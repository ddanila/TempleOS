#!/usr/bin/env python3
"""Compare complete public scan decoding, inverse mapping, and names."""
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
    ap.add_argument('--rebuilt-original',action='store_true',help='Use current rebuilt original kernel rather than pinned original')
    args=ap.parse_args();out=args.out.resolve()
    if args.disk and args.rebuilt_original:ap.error('--rebuilt-original applies only without a disk')
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-public-scan-translation/Contract.HC';once=fixture.parent/'Once.HC'
    inputs=[Path(__file__).resolve(),fixture,once]+[ROOT/n for n in ('tools/test-i386-timeclock-reference.py','tools/build-iso.py','tools/guest-run.py','tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/i386-kernel-input.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC')]
    if args.disk:inputs.append(args.disk.resolve())
    if args.rebuilt_original:
        inputs += [ROOT/n for n in ('build/rebuild-test/result.json','build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C','build/rebuild-test/overlay/Compiler/Compiler.BIN','Kernel/SerialDev/Keyboard.HC','Kernel/SerialDev/KeyScanTranslateCore.HC','Kernel/SerialDev/KeyScanNameCore.HC')]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    report=dict(result='running',input_sha256={str(p):sha(p) for p in inputs},scope='256 scan codes and 256 character inputs across ten modifier cases, exact key-name strings; not hardware keyboard delivery or key-map UI')
    try:
        ref=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'));overlay=out/'overlay';overlay.mkdir()
        if not args.rebuilt_original:report['reference_sha256']=ref['restore_reference'](overlay)
        else:report['mode']='rebuilt-original'
        (overlay/'Probe').mkdir();(overlay/'Probe/KeyTranslate.HC').write_bytes(fixture.read_bytes());(overlay/'Once.HC').write_bytes(once.read_bytes())
        iso=out/'original.iso'
        cmd=[sys.executable,'tools/build-iso.py']
        if args.rebuilt_original:cmd+=['--overlay','build/rebuild-test/overlay']
        cmd+=['--overlay',str(overlay),'--output',str(iso)]
        subprocess.run(cmd,cwd=ROOT,check=True)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'original'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        expected=(out/'original/keys.bin').read_bytes()
        if len(expected)!=10*256*(1+8+64):raise ValueError('Bad original table size')
        report['original_sha256']=hashlib.sha256(expected).hexdigest()
        if args.disk:
            working=out/'working.img';pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package']
            report['packaging']=pack(args.disk.resolve(),working,additions={'/Probe/KeyTranslate.HC':fixture.read_bytes()})
            commands=['#include "C:/Probe/KeyTranslate.HC"',"if(!BuildKeyTable)throw('Keys',TRUE);",'if(FileWrite("C:/keys.bin",key_table,KEY_TABLE_BYTES)<=0)throw(\'Keys\',TRUE);','6*7;']
            runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](working,out/'native',commands,64,True)
            got=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](working,{'/keys.bin'})['/keys.bin']
            report.update(native_sha256=hashlib.sha256(got).hexdigest(),differing_bytes=sum(a!=b for a,b in zip(expected,got))+abs(len(expected)-len(got)))
            if got!=expected:raise ValueError('Native scan translation differs from original')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
