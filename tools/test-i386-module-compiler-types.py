#!/usr/bin/env python3
"""Build a native module using the complete shared compiler-type header."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/'tests/guest/i386-module-compiler-types/LexType.HC'


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    image,out=args.disk.resolve(),args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[image,FIXTURE,Path(__file__).resolve()]+[ROOT/name for name in (
        'tools/test-i386-timeclock-welcome.py','tools/package-i386-native-image.py',
        'tools/build-i386-kernel.py','tools/test-i386-retained-build.py')]
    pins={str(p):sha(p) for p in inputs}
    report={'result':'running','scope':'Native module includes the complete compiler types header and uses CLexFile after its in-class assertions',
            'input_sha256':pins}
    try:
        disk=out/'working.img'
        report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
            image,disk,additions={'/LexType.HC':FIXTURE.read_bytes()})
        command='I386BuildModule("C:/LexType.HC","C:/Probe/LexType.t32m",TRUE);'
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](
            disk,out/'guest',[command,'6*7;'],16,True,command_timeout=600,allow_inner_rejection=True)
        log=(out/'guest/debug.log').read_text()
        if 'BUILD MODULE REJECT ' in log:raise ValueError('Native module compilation rejected; inspect guest debug log')
        paths={'/LexType.HC','/Probe/LexType.t32m'}
        files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,paths)
        if files['/LexType.HC']!=FIXTURE.read_bytes():raise ValueError('Delivered fixture changed')
        module=files['/Probe/LexType.t32m']
        count,exports=runpy.run_path(str(ROOT/'tools/test-i386-retained-build.py'))['exports_of'](module)
        if 'I386LexTypeProbe' not in exports:raise ValueError('Missing probe export')
        report.update(result='pass',module_sha256=hashlib.sha256(module).hexdigest(),records=count,exports=exports)
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(Path(p).is_file() and sha(Path(p))==digest for p,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
