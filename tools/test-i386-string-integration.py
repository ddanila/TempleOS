#!/usr/bin/env python3
"""Run existing scanner and DolDoc parser contracts on a native image."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();out=args.out.resolve();disk=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    scan=ROOT/'tests/guest/i386-str-scan/Contract.HC';dollar=ROOT/'tests/guest/i386-doc-dollar/Contract.HC'
    inputs=[Path(__file__).resolve(),scan,dollar,disk]+[ROOT/n for n in ('tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/i386-kernel-input.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC')]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    report=dict(result='running',input_sha256={str(p):sha(p) for p in inputs},scope='Existing eight-case string scanner and six-case DolDoc dollar parser contracts; not complete scanner or document qualification')
    try:
        working=out/'working.img';files={'/Probe/StringScan.HC':scan.read_bytes(),'/Probe/DollarParser.HC':dollar.read_bytes()}
        report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](disk,working,additions=files)
        commands=['#include "C:/Probe/StringScan.HC"',"if(StringScanContract!=255)throw('Scan',TRUE);",'#include "C:/Probe/DollarParser.HC"',"if(DollarParserContract!=63)throw('Dollar',TRUE);",'6*7;']
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](working,out/'guest',commands,64,True)
        delivered=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](working,set(files))
        if delivered!=files:raise ValueError('Delivered fixtures changed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
