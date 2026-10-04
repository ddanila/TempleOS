#!/usr/bin/env python3
"""Observe public and bootstrap allocation ownership across native User retirement."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy

ROOT = Path(__file__).resolve().parents[1]
DEPENDENCIES = ['observe-i386-user-recovery.py', 'test-i386-user-recovery.py',
                'test-i386-user-create.py', 'test-i386-public-task-accounting.py']


def read_observations(log):
    result = {}
    for tag, name, fields in [('POOL', 'pool', 6), ('BOOT', 'bootstrap', 3)]:
        rows = [list(map(int, m.split())) for m in re.findall(
            r'^USER '+tag+r' ((?:-?\d+ ?)+)$', log, re.M)]
        if any(len(row) != fields for row in rows):
            raise ValueError('Malformed '+tag+' observation')
        result[name+'_observations'] = rows
    result['pool_columns'] = ['cycle', 'root_children', 'pool_used', 'pool_reserved', 'caller_heap_used', 'root_heap_used']
    result['bootstrap_columns'] = ['cycle', 'heap_used', 'allocations']
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    hashes = {name: sha(ROOT/'tools'/name) for name in DEPENDENCIES}
    checker, disk_hash = sha(Path(__file__)), sha(args.disk)
    report = {'result': 'fail', 'checker_sha256': checker, 'disk_sha256': disk_hash,
              'dependencies_sha256': hashes,
              'scope': 'Observation only: nine User create/kill cycles, public-pool and bootstrap heap counters; not resource recovery acceptance'}
    try:
        accounting = runpy.run_path(str(ROOT/'tools/test-i386-public-task-accounting.py'))
        layouts, headers = accounting['accounting_layouts'](args.disk)
        observer = runpy.run_path(str(ROOT/'tools/observe-i386-user-recovery.py'))
        definitions = [s.replace('U0 UserObserve(', 'U0 UserPublicObserve(')
                       for s in observer['DEFINITIONS']]
        commands = layouts + [(s, []) for s in definitions] + [
            ('CBootHeap *UserBootHeap(){CBootBacking *p=Fs->data_heap->bp;return p->heap;}', []),
            ("Bool UserBootValid(){CBootBacking *p=Fs->data_heap->bp;return p->backing_signature=='B32S'&&p->heap->signature==0x48323349&&I386HeapValid(p->heap);}", []),
            ('U0 UserBootObserve(I64 step){U8 s[128];CBootHeap *h=UserBootHeap;StrPrint(s,"USER BOOT %d %d %d\\n",step,h->used,h->allocations);UserObserveLog(s);}', []),
            ('U0 UserObserve(I64 step){UserPublicObserve(step);UserBootObserve(step);}', []),
            ('UserBootValid;', ['1']),
        ] + observer['CASES']
        if any(len(s.encode('ascii')) > 255 for s, _ in commands):
            raise ValueError('Bootstrap observer exceeds interactive line limit')
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, args.out/'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands, 'command_timeout': 120})
        report.update(read_observations((args.out/'behavior/debug.log').read_text()))
        for tag in ('pool', 'bootstrap'):
            rows = report[tag+'_observations']
            if len(rows) != 10 or [r[0] for r in rows] != list(range(10)):
                raise ValueError('Missing or unordered '+tag+' observations')
        report['layout_headers_sha256'] = headers
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        log = args.out/'behavior/debug.log'
        if report['result'] != 'pass' and log.exists():
            try:
                report.update(read_observations(log.read_text()))
                checkpoint = args.out/'behavior/checkpoint.json'
                if checkpoint.exists():
                    report['last_checkpoint'] = json.loads(checkpoint.read_text())
            except Exception as observation_error:
                report['observation_error'] = str(observation_error)
        report['source_disk_unchanged'] = sha(args.disk) == disk_hash
        if not report['source_disk_unchanged'] or sha(Path(__file__)) != checker or any(sha(ROOT/'tools'/n) != h for n, h in hashes.items()):
            report.update(result='fail', error='Disk or checker changed during observation')
        (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise SystemExit(1)


if __name__ == '__main__':
    main()
