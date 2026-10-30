#!/usr/bin/env python3
"""Compare complete original and native progress-bar framebuffers."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path)
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args(); out = args.out.resolve(); disk = args.disk.resolve()
    if out.exists(): ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    contract = ROOT/'tests/guest/i386-progress-frame-compare/Contract.HC'
    once = ROOT/'tests/guest/i386-progress-frame-compare/Once.HC'
    inputs = [Path(__file__).resolve(), contract, once, disk] + [ROOT/n for n in (
        'tools/test-i386-timeclock-reference.py', 'tools/build-iso.py', 'tools/guest-run.py',
        'tools/package-i386-native-image.py', 'tools/build-i386-kernel.py',
        'tools/i386-kernel-input.py', 'tools/test-i386-timeclock-welcome.py', 'Kernel/FontStd.HC')]
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    report = dict(result='running', input_sha256={str(p):sha(p) for p in inputs},
                  scope='Four exact 640x480 framebuffers: half-filled, capped and custom label, fixed completion time, all four bars; not elapsed-time or concurrent rendering')
    try:
        reference = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
        overlay = out/'overlay'; overlay.mkdir()
        report['reference_sha256'] = reference['restore_reference'](overlay)
        (overlay/'Probe').mkdir(); (overlay/'Probe/ProgressCompare.HC').write_bytes(contract.read_bytes())
        (overlay/'Once.HC').write_bytes(once.read_bytes())
        iso = out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'original'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        expected = [(out/'original'/f'frame{i}.bin').read_bytes() for i in range(4)]
        if any(len(frame) != 640*480 for frame in expected): raise ValueError('Incorrect reference frame size')
        working = out/'working.img'
        report['packaging'] = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](disk,working,additions={'/Probe/ProgressCompare.HC':contract.read_bytes()})
        commands = ['#include "C:/Probe/ProgressCompare.HC"', "if(!CaptureProgressFrames)throw('Bars',TRUE);"]
        commands += [f'if(FileWrite("C:/frame{i}.bin",progress_frames[{i}],640*480)<=0)throw(\'Bars\',TRUE);' for i in range(4)]
        commands += ['FreeProgressFrames;', '6*7;']
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](working,out/'native',commands,64,True)
        files = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](working,{f'/frame{i}.bin' for i in range(4)})
        observed = [files[f'/frame{i}.bin'] for i in range(4)]
        report['frames'] = [dict(reference_sha256=hashlib.sha256(a).hexdigest(), native_sha256=hashlib.sha256(b).hexdigest(), differing_bytes=sum(x!=y for x,y in zip(a,b))+abs(len(a)-len(b))) for a,b in zip(expected,observed)]
        if observed != expected: raise ValueError('Native progress frame differs from original')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc)); raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
