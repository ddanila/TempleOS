#!/usr/bin/env python3
"""Verify recorded macro copies discard private keyboard arrival timestamps."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    rows = runpy.run_path(str(ROOT / 'tools/test-i386-key-arrival-messages.py'))['commands'](macro=True)
    rows.insert(0, ('class AMTimedCopy:CJob{I64 arrival;U64 signature;};', []))
    index = next(i for i, (source, _) in enumerate(rows) if source.startswith('CJob *am_job='))
    rows[index + 1:index + 1] = [
        ('MSize(am_job)>=sizeof(AMTimedCopy);', ['1']),
        ('AMTimedCopy *am_copy=am_job;am_copy->arrival==-1&&am_copy->signature==0x54494D454B455931;', ['1']),
    ]
    if any(len(source.encode('ascii')) > 255 for source, _ in rows):
        raise ValueError('Macro copy fixture exceeds interactive line limit')
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    fixture = ROOT / 'tools/test-i386-key-arrival-messages.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, fixture, Path(__file__))}
    report = dict(result='running', input_sha256=pins, disk_policy='writable copy',
                  scope='Recorded key payload/ring and private tail arrival -1/signature; original timed delivery and public replay fallback; not playback scheduling')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands()})
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [path for path, digest in pins.items() if sha(Path(path)) != digest]
        if changed:
            report.update(result='fail', error='Macro-copy fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Macro-copy qualification failed'))


if __name__ == '__main__':
    main()
