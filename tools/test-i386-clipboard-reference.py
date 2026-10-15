#!/usr/bin/env python3
"""Record complete original clipboard and document insertion contracts."""
import argparse
import json
from pathlib import Path
import runpy
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
EXPECTED = [63]*6+[31]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--current-system',action='store_true',
                        help='Run the same oracle on the latest qualified x64 rebuild and current sources')
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    overlay = out/'reference-overlay'
    overlay.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-clipboard-reference'
    sha = REFERENCE['sha']
    inputs = [Path(__file__).resolve(), ROOT/'tools/test-i386-timeclock-reference.py',
              fixture/'Once.HC', fixture/'Clipboard.HC', ROOT/'Kernel/FontStd.HC', ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py']
    source_hashes = {}
    extra = [overlay]
    if args.current_system:
        manifest = ROOT/'build/rebuild-test/result.json'
        snapshot = json.loads(manifest.read_text())
        if snapshot.get('result') != 'pass':
            raise ValueError('Current-system control requires a passing rebuild')
        for name,digest in snapshot['source_sha256'].items():
            path = ROOT/name
            if sha(path) != digest:
                raise ValueError('Current-system source differs from rebuild: '+name)
            inputs.append(path)
        extra = [ROOT/'build/rebuild-test/overlay']
        for name,relative in [('Compiler.BIN','Compiler/Compiler.BIN'),
                              ('Kernel.BIN','0000Boot/0000Kernel.BIN.C')]:
            path = extra[0]/relative
            if sha(path) != snapshot['generations'][-1][name]:
                raise ValueError('Current-system binary differs from rebuild: '+name)
            inputs.append(path)
        inputs.append(manifest)
        source_hashes = snapshot['source_sha256']
    else:
        source_hashes = REFERENCE['restore_reference'](overlay)
    report = dict(result='running',
                  system='current-x64-rebuild' if args.current_system else 'pinned-original',
                  baseline_reference_revision=REFERENCE['REFERENCE'],
                  baseline_repair_revision=REFERENCE['REPAIRS'],
                  system_source_sha256=source_hashes,
                  input_sha256={str(p):sha(p) for p in inputs},
                  scope='Six clipboard/document cases require exact text, selection, locks and heaps; child-exit requires root ownership, reaping, surviving text and roles, with shared Adam heap deltas reported separately')
    try:
        iso = out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(extra[0]),
                        '--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256'] = sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),
                        '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        data = (out/'guest/clipboard.bin').read_bytes()
        values=list(struct.unpack('<11q',data))
        report['observed']=values[:7]
        report['heap_profile']=dict(zip(('control_caller','control_clip_owner','clipboard_caller','clipboard_clip_owner'),values[7:]))
        # Adam's heap is shared with original background tasks across Yield.
        # Its raw deltas are telemetry; native has a separate strict zero gate.
        report['portable_observed']=values[:6]+[values[6]&31]
        report['expected']=EXPECTED
        if report['portable_observed']!=EXPECTED:
            raise ValueError('Original clipboard behavior differs from explicit oracle')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p))==h for p,h in report['input_sha256'].items())
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Reference inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__ == '__main__':
    main()
