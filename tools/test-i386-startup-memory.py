#!/usr/bin/env python3
"""Check startup, retained code/static data and VGA on a pinned candidate."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('I64 SPNext(){static I64 n=40;return ++n;}', []),
    ('SPNext();', ['41']), ('SPNext();', ['42']),
    ('U8 *SPText(){return "VGA";}', []),
    ('StrCmp(SPText(),"VGA")==0;', ['1']), ('6*7;', ['42']),
    ('NativeGraphicsStart;', ['1']),
    ('I64 gp_ok=NativeTextBasePresent;NativeTextBaseRestore;gp_ok;', ['1']),
    ('I64 gp_frame=NativeGraphicsPresent;NativeTextBaseRestore;gp_frame;', ['1']),
]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--diagnostics', action='store_true',
                        help='Use the diagnostic image and require all startup diagnostics')
    parser.add_argument('--ram-mib', type=int, choices=(8, 16), default=8,
                        help='16 MiB alone is a resource probe; use --diagnostics for startup diagnostics')
    args = parser.parse_args()
    disk = args.disk.resolve()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    manifest_path = disk.parent/'result.json'
    manifest = json.loads(manifest_path.read_text())
    expected = manifest['diagnostics']['disk_sha256'] if args.diagnostics else manifest['disk_sha256']
    if sha(disk) != expected:
        raise ValueError('Disk differs from its cross-build manifest')
    for name, digest in manifest['source_sha256'].items():
        if name.startswith(('Kernel/', 'Compiler/')) and sha(ROOT/name) != digest:
            raise ValueError(f'Stale candidate source: {name}')
    runner = ROOT/'tools/i386-kernel-input.py'
    if sha(runner) != manifest['build_inputs_sha256']['tools/i386-kernel-input.py']:
        raise ValueError('Input harness differs from the cross-build manifest')
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(disk, working)
    result = dict(status='running', cpu='486,-fpu', ram_mib=args.ram_mib,
                  qualification='diagnostic' if args.diagnostics else 'interactive' if args.ram_mib == 8 else 'resource-probe',
                  diagnostics=args.diagnostics,
                  scope='Startup diagnostics, retained static/function/literal behavior and exact VGA restoration; not complete OS acceptance' if args.diagnostics else 'Startup, retained static/function/literal behavior and exact VGA restoration; not complete OS acceptance',
                  input_sha256={str(disk): sha(disk), str(manifest_path): sha(manifest_path),
                                str(Path(__file__).resolve()): sha(Path(__file__).resolve()),
                                str(runner): sha(runner)}, commands=COMMANDS)
    try:
        result['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out, snapshot=False, cpu='486,-fpu', ram_mib=args.ram_mib,
            qmp_stdio=True, diagnostics=args.diagnostics, startup_timeout=90,
            startup_check={'status': 'ok', 'answers': [], 'commands': COMMANDS})
        log = (out/'debug.log').read_text()
        if 'BUILD PROVIDER loaded\n' in log:
            raise ValueError('Startup acquired build-only support')
        result['build_provider_loads'] = 0
        if args.diagnostics:
            markers = [f'PUBLICATION CASE {phase:016X} {case:016X}\n'
                       for phase in (0, 1) for case in range(11)]
            missing = [marker.strip() for marker in markers if marker not in log]
            if missing:
                raise ValueError(f'Missing publication diagnostics: {missing}')
            result['publication_cases'] = len(markers)
            program_markers = [f'PROGRAM CASE {phase:016X} {case:016X}\n'
                               for phase in (0, 1) for case in range(14)]
            missing = [marker.strip() for marker in program_markers if marker not in log]
            if missing:
                raise ValueError(f'Missing program publication diagnostics: {missing}')
            result['program_publication_cases'] = len(program_markers)

        seconds = result['behavior']['startup_seconds']
        result['interactive_budget_pass'] = not args.diagnostics and args.ram_mib == 8 and seconds <= 60
        if not args.diagnostics and args.ram_mib == 8 and seconds > 60:
            raise ValueError(f'Startup {seconds:.3f}s exceeds the 60-second target')
        result['status'] = 'pass'
    except Exception as exc:
        result['status'] = 'fail'
        result['error'] = str(exc)
        raise
    finally:
        (out/'result.json').write_text(json.dumps(result, indent=2)+'\n')
    print(f'PASS: {args.ram_mib} MiB {result["qualification"]} startup and storage/presentation checks')


if __name__ == '__main__':
    main()
