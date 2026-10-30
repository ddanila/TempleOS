#!/usr/bin/env python3
"""Compare original file mask vectors."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / 'tests/guest/i386-files-find-match/Contract.HC'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, nargs='?')
    parser.add_argument('--original', action='store_true')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.original == bool(args.disk):
        parser.error('Choose --original or a native disk')
    fixture = FIXTURE
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    files = [Path(__file__).resolve(), fixture]
    if args.original:
        files += [ROOT / p for p in ('Kernel/BlkDev/DskStrA.HC', 'Kernel/StrA.HC', 'Kernel/KernelA.HH', 'Kernel/FileMaskTypes.HH', 'Kernel/WildMatchCore.HC', 'Kernel/BlkDev/FilesFindMatchCore.HC', 'tools/build-iso.py', 'tools/guest-run.py', 'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C', 'build/rebuild-test/overlay/Compiler/Compiler.BIN')]
    else:
        files += [args.disk.resolve()] + [ROOT / p for p in ('tools/i386-kernel-input.py', 'tools/build-i386-kernel.py', 'tools/package-i386-native-image.py', 'tools/test-i386-timeclock-welcome.py', 'Kernel/FontStd.HC')]
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in files}
    report = dict(result='running', input_sha256=pins, scope='File masks: case sensitivity, basename/full path, exclusion ordering, wildcard and all six type filters, direct WildMatch calls; exact caller heap recovery')
    (out / 'result.json').write_text(json.dumps(report, indent=2)+'\n')
    try:
        if args.original:
            overlay = out / 'overlay'
            overlay.mkdir()
            source = fixture.read_text() + '\nU0 DPReport(U8 *s){while(*s)OutU8(0xE9,*s++);}\n'
            source += 'I64 dp_mask=JRContract(84);U8 *dp_line=MStrPrint("OBS file mask vectors mask %d\\n",dp_mask);DPReport(dp_line);Free(dp_line);\n'
            source += 'if(dp_mask==127)DPReport("PASS original file mask vectors\\n");else DPReport("FAIL original file mask vectors\\n");\nDPReport("DONE file mask vectors\\n");\n'
            (overlay / 'Once.HC').write_text(source)
            iso = out / 'original.iso'
            subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', 'build/rebuild-test/overlay', '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
            subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out', str(out / 'behavior'), '--timeout', '90', '--qmp-stdio'], cwd=ROOT, check=True)
            log = (out / 'behavior/debug.log').read_text()
            if 'OBS file mask vectors mask 127\n' not in log or 'PASS original file mask vectors\n' not in log:
                raise ValueError('Original parser contract did not pass all seven checks')
        else:
            disk = out / 'working.img'
            files = {'/Probe/FileMaskContract.HC': fixture.read_bytes()}
            report['packaging'] = runpy.run_path(str(ROOT / 'tools/package-i386-native-image.py'))['package'](args.disk.resolve(), disk, additions=files)
            commands = ['#include "C:/Probe/FileMaskContract.HC"', "if(JRContract(67)!=127)throw('FileMask',TRUE);", '6*7;']
            runpy.run_path(str(ROOT / 'tools/test-i386-timeclock-welcome.py'))['guest'](disk, out / 'behavior', commands, 64, True)
            saved = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents'](disk, set(files))
            if saved != files:
                raise ValueError('Guest fixture differs byte-for-byte from the pinned source')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [p for p, digest in pins.items() if sha(Path(p)) != digest]
        report['inputs_unchanged'] = not changed
        if changed:
            report.update(result='fail', error='Parser contract inputs changed', changed_inputs=changed)
        (out / 'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise RuntimeError(report['error'])


if __name__ == '__main__':
    main()
