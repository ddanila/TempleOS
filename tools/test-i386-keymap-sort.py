#!/usr/bin/env python3
"""Compare key-map label sorting using fixed-width pointer slots."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path,nargs='?')
    ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--shared',action='store_true',help='Use shared current visibility source on original')
    args=ap.parse_args();out=args.out.resolve()
    if args.disk and args.shared:ap.error('--shared applies only to original')
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-keymap-sort/Once.HC'
    contract=ROOT/'tests/guest/i386-keymap-sort/Contract.HC'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    files={'/Probe/KeyMapSortContract.HC':contract.read_bytes()}
    if args.disk:files['/Probe/KeyMapSort.HC']=(ROOT/'Adam/KeyMapSortCore.HC').read_bytes()
    inputs=[Path(__file__).resolve(),fixture,contract,ROOT/'Adam/KeyMapSortCore.HC']
    report=dict(result='running',mode='native' if args.disk else 'shared-original' if args.shared else 'pinned-original',scope='Original key-map comparator and fixed-width pointer slots, ordering, identity and boundary canaries; not key-map collection or UI')
    if args.disk:
        inputs += [args.disk.resolve()]+[ROOT/n for n in ('tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/i386-kernel-input.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC')]
    else:
        inputs += [ROOT/n for n in ('tools/test-i386-timeclock-reference.py','tools/build-iso.py','tools/guest-run.py')]
        reference=runpy.run_path(str(inputs[-3]));overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=reference['restore_reference'](overlay)
        if args.shared:
            for name in ('Adam/Training.HC','Adam/KeyMapSortCore.HC'):
                source=ROOT/name;inputs.append(source)
                target=overlay/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(source.read_bytes())
    report['input_sha256']={str(p):sha(p) for p in inputs}
    try:
        if args.disk:
            disk=out/'working.img'
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions=files)
            commands=['#include "C:/Probe/KeyMapSort.HC"','#include "C:/Probe/KeyMapSortContract.HC"',"if(KeyMapSortContract!=7)throw('KeySort',TRUE);",'6*7;']
            runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](disk,out/'guest',commands,64,True)
            delivered=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,set(files))
            if delivered!=files:raise ValueError('Delivered include files changed')
        else:
            for name,data in files.items():
                path=overlay/name.lstrip('/');path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes())
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if 'KEY MAP SORT MASK 7\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original key-map sort contract failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==d for p,d in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
