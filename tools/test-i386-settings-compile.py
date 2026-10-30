#!/usr/bin/env python3
"""Compile shared settings code with an explicitly rejecting autocomplete probe."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();out=args.out.resolve();disk=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    probe=ROOT/'tests/guest/i386-settings-compile/Probe.HC'
    core=ROOT/'Adam/TaskSettingsCore.HC'
    inputs=[Path(__file__).resolve(),probe,core,disk]+[ROOT/n for n in ('tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/i386-kernel-input.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC')]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    report=dict(result='running',input_sha256={str(p):sha(p) for p in inputs},scope='Compile original shared settings bodies with a deliberately throwing autocomplete test provider; no settings execution or autocomplete qualification')
    try:
        working=out/'working.img';files={'/Probe/SettingsProbe.HC':probe.read_bytes(),'/Probe/TaskSettingsCore.HC':core.read_bytes()}
        report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](disk,working,additions=files)
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](working,out/'guest',['#include "C:/Probe/SettingsProbe.HC"','6*7;'],64,True)
        delivered=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](working,set(files))
        if delivered!=files:raise ValueError('Delivered probe source changed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
