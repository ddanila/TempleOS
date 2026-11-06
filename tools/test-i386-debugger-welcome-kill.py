#!/usr/bin/env python3
"""Kill a CPU-stopped terminal and recover its welcome-document parent."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path)
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    paths = [Path(__file__).resolve(), args.disk.resolve(), ROOT/'Kernel/FontStd.HC']
    paths += [ROOT/'tools'/name for name in (
        'test-i386-cpu-debug-kill.py', 'test-i386-terminals.py',
        'i386-kernel-input.py', 'package-i386-native-image.py', 'build-i386-kernel.py')]
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
        scope='8 MiB welcome session: kill a child at INT3, debug/resume in its survivor, recover parent public heap and exact document raster, clear debugger mode and fresh arithmetic; not all private resources or all debugger exits.')
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        checks = runpy.run_path(str(ROOT/'tools/test-i386-cpu-debug-kill.py'))['commands']()
        #Load setup definitions from a file. The actual child trap, keyboard
        #inspection, focus switch, kill and survivor interaction stay unchanged.
        definitions = [check[0] for i, check in enumerate(checks[:11]) if i not in (0, 9)]
        source = ('\n'.join(definitions)+'\n').encode()
        (out/'DebuggerKill.HC').write_bytes(source)
        working = out/'working.img'
        report['packaging'] = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
            args.disk.resolve(), working, additions={'/Probe/DebuggerKill.HC': source})
        checks = [('#include "C:/Probe/DebuggerKill.HC"', []), checks[0], checks[9], checks[11],
                  ('IsDbgMode;', ['0'])] + checks[12:]
        report['commands'] = checks
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(working, out/'behavior', cpu='486,-fpu', accel='kvm',
            ram_mib=8, welcome=True, qmp_stdio=True,
            startup_check={'status': 'ok', 'answers': [], 'commands': checks})
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Debugger kill inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
