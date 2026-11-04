#!/usr/bin/env python3
"""Exercise real stack-call normalization at short and full ESP displacements."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, nargs='?')
    parser.add_argument('--original', action='store_true')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.original == bool(args.disk):
        parser.error('Choose --original or a native disk')
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture = ROOT / 'tests/guest/i386-esp-displacement/Calls.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT / p for p in (
        'tools/test-i386-timeclock-reference.py', 'tools/build-iso.py', 'tools/guest-run.py',
        'tools/package-i386-native-image.py', 'tools/i386-kernel-input.py',
        'tools/build-i386-kernel.py', 'Compiler/I386/EmitCore.HC', 'Compiler/I386/BackendCore.HC')]
    if args.disk:
        paths.append(args.disk.resolve())
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in paths}
    (out / 'fixture.HC').write_bytes(fixture.read_bytes())
    report = dict(result='running', input_sha256=pins, original=args.original,
                  scope='17 narrow/pointer arguments across ESP +128, direct/indirect/nested calls, zero-slot indirect call, variadic fixed normalization and frame canary')
    try:
        if args.original:
            overlay = out / 'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT / 'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            source = fixture.read_text() + '\nU0 ESReport(U8*s){while(*s)OutU8(0xE9,*s++);}\n'
            source += 'I64 es_mask=ESContract;U8*es_line=MStrPrint("OBS stack call %d\\n",es_mask);ESReport(es_line);Free(es_line);es_mask=ESFrameContract;es_line=MStrPrint("OBS frame runtime %d\\n",es_mask);ESReport(es_line);Free(es_line);ESReport("DONE stack call\\n");\n'
            (overlay / 'Once.HC').write_text(source)
            iso = out / 'original.iso'
            subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
            subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out', str(out / 'guest'), '--qmp-stdio', '--timeout', '120'], cwd=ROOT, check=True)
            log = (out / 'guest/debug.log').read_text()
            if log.count('OBS stack call 63\n') != 1 or log.count('OBS frame runtime 255\n') != 1:
                raise ValueError('Original stack-call contract failed')
        else:
            disk = out / 'working.img'
            report['packaging'] = runpy.run_path(str(ROOT / 'tools/package-i386-native-image.py'))['package'](args.disk.resolve(), disk, additions={'/StackCall.HC': fixture.read_bytes()})
            report['behavior'] = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input'](
                disk, out / 'guest', cpu='486,-fpu', ram_mib=8, accel='kvm', qmp_stdio=True,
                snapshot=False, welcome=True, keep_window_manager=True,
                startup_check=dict(status='ok', answers=[], pause_window_manager=False,
                                   commands=[('#include "C:/StackCall.HC"', []), ('ESContract;', ['63']), ('ESFrameContract;', ['255']), ('6*7;', ['42'])]))
            build = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))
            report['filesystem'] = build['verify_mutated_volume'](disk)
            contents = build['mutated_file_contents'](disk, {'/StackCall.HC'})
            if contents['/StackCall.HC'] != fixture.read_bytes():
                raise ValueError('Delivered fixture differs')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == h for p, h in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
