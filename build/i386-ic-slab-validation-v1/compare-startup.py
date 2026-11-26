"""Run the same 8 MiB startup checks on two pinned cross-build images."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('control', type=Path)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    args.out.mkdir()
    commands = runpy.run_path('tools/test-i386-startup-memory.py')['COMMANDS']
    path = Path('tools/i386-kernel-input.py')
    run_input = runpy.run_path(str(path))['run_input']
    builds = {name: json.loads((disk.parent / 'result.json').read_text())
              for name, disk in [('control', args.control), ('candidate', args.candidate)]}
    reports = {}
    for label, disk in [('control', args.control), ('candidate', args.candidate)]:
        expected = builds[label]
        assert sha(disk) == expected['disk_sha256']
        assert sha(path) == expected['build_inputs_sha256'][str(path)]
        out = args.out / label
        out.mkdir()
        try:
            result = run_input(disk.resolve(), out, cpu='486,-fpu', ram_mib=8, accel='kvm',
                               snapshot=True, qmp_stdio=True, managed_pointer=True,
                               welcome=True, startup_check=dict(status='ok', answers=[],
                                   commands=commands, pause_window_manager=False))
            assert 'BUILD PROVIDER loaded\n' not in (out / 'debug.log').read_text()
            reports[label] = dict(result='pass', behavior=result,
                                  budget_pass=result['startup_seconds'] <= 60)
        except Exception as exc:
            reports[label] = dict(result='fail', error=str(exc))
        assert sha(disk) == expected['disk_sha256']
        reports[label]['disk_sha256'] = expected['disk_sha256']
    a, b = (builds[side]['source_sha256'] for side in ('control', 'candidate'))
    changed = sorted(name for name in a.keys() | b.keys()
                     if name.startswith(('Kernel/', 'Compiler/', 'Adam/')) and a.get(name) != b.get(name))
    assert changed == ['Compiler/I386/Code.HC'], changed
    (args.out/'comparison.json').write_text(json.dumps(dict(
        runs=reports, changed_os_sources=changed, runner_sha256=sha(path),
        ram_mib=8, accel='kvm', cpu='486,-fpu'), indent=2)+'\n')


if __name__ == '__main__':
    main()
