#!/usr/bin/env python3
"""Run the selected macro contract against one immutable guest image."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CASES = (
    ('public-api', 'test-i386-macro-playback.py', ()),
    ('input-api', 'test-i386-input-filter-prerequisites.py', ()),
    ('serialization', 'test-i386-macro-serialization.py', ()),
    ('format-parity', 'test-i386-macro-format-parity.py', ()),
    ('self', 'test-i386-macro-playback-self.py', ()),
    ('child', 'test-i386-macro-playback-child.py', ()),
    ('mixed-events', 'test-i386-macro-playback-mixed.py', ()),
    ('focus', 'test-i386-macro-playback-focus.py', ()),
    ('invalid-focus', 'test-i386-macro-playback-retired.py', ()),
    ('recipient-exit', 'test-i386-macro-playback-recipient-exit.py', ()),
    ('editor-undo', 'test-i386-macro-playback-editor.py', ()),
    ('cancel-queued', 'test-i386-macro-playback-cancel-queued.py', ()),
    ('cancel-active', 'test-i386-macro-playback-cancel-active.py', ()),
    ('interrupt-repeat', 'test-i386-macro-playback-interrupt.py', ()),
    ('allocation-job', 'test-i386-macro-playback-allocation.py', ('--fail-after', '3')),
    ('allocation-context', 'test-i386-macro-playback-allocation.py', ('--fail-after', '4')),
)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--repository', type=Path, default=ROOT,
                        help='Repository providing the frozen behavioral fixtures')
    parser.add_argument('--original', type=Path, required=True,
                        help='Independently exported original-x64 MacroExtended.HC oracle')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    disk, repo, original, out = [p.resolve() for p in
                                (args.disk, args.repository, args.original, args.out)]
    if out.exists():
        parser.error('Use a fresh output directory; prior evidence is preserved')
    if not original.read_bytes():
        parser.error('Original serialization oracle must not be empty')
    paths = {disk, original, Path(__file__).resolve(),
             repo / 'Kernel/FontStd.HC',
             repo / 'tools/i386-kernel-input.py', repo / 'tools/build-i386-kernel.py'}
    paths.update(repo / 'tools' / tool for _, tool, _ in CASES)
    pins = {str(p): sha(p) for p in sorted(paths)}
    out.mkdir(parents=True)
    report = dict(result='running', stage='preflight', input_sha256=pins,
                  cpu='486,-fpu', ram_mib=8, disk_policy='independent writable copies',
                  scope='Selected serialization and actual macro playback contract; '
                        'not full OS, native origin, release readiness, all allocation '
                        'sites or all interruption sites', cases={})

    def save():
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')

    def unchanged():
        changed = [p for p, digest in pins.items() if sha(Path(p)) != digest]
        if changed:
            raise ValueError('Qualification inputs changed: ' + ', '.join(changed))

    try:
        save()
        for name, tool, extra in CASES:
            unchanged()
            report['stage'] = name
            save()
            command = [sys.executable, str(repo / 'tools' / tool), str(disk),
                       '--out', str(out / name), *extra]
            if name == 'format-parity':
                command += ['--original', str(original)]
            with (out / (name + '.log')).open('w') as log:
                subprocess.run(command, cwd=repo, stdout=log,
                               stderr=subprocess.STDOUT, check=True)
            path = out / name / 'result.json'
            result = json.loads(path.read_text())
            if result.get('result') != 'pass':
                raise ValueError(name + ' has no passing terminal report')
            if result.get('input_sha256', {}).get(str(disk)) != pins[str(disk)]:
                raise ValueError(name + ' did not test the pinned image')
            behavior = result.get('behavior', {})
            if (behavior.get('result') != 'pass' or behavior.get('cpu') != '486,-fpu'
                    or behavior.get('ram_mib') != 8):
                raise ValueError(name + ' does not qualify the required runtime')
            report['cases'][name] = dict(result_sha256=sha(path), result=result)
            unchanged()
            save()
        report.update(result='pass', stage='complete')
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        try:
            unchanged()
        except Exception as error:
            report.update(result='fail', error=str(error))
        save()
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Macro qualification failed'))


if __name__ == '__main__':
    main()
