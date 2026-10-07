#!/usr/bin/env python3
"""Diagnose rectangle color and XOR pixels with direct command checkpoints."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(diagnostic=False):
    return [
      ('CDC *rp=DCNew(16,16);',[]),
      ('U0 RPFill(){DCFill(rp,BLACK);rp->color=RED;GrRect(rp,2,3,4,5);}RPFill;',[]),
      ('rp->body[3*rp->width_internal+2];',['4']),
      ('rp->color;', ['4']),
      ('U0 RPXor(){rp->color=ROP_XOR|GREEN;GrRect(rp,2,3,4,5);}RPXor;',[]),
      ('rp->color;', ['258']),
      ('rp->body[3*rp->width_internal+2];',['6']),
      ('6*7;',['42']),
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--diagnostic', action='store_true',
                        help='Print phase boundaries without changing the heap assertions')
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, Path(__file__))}
    report = dict(result='running', input_sha256=pins, disk_policy='writable copy',
                  diagnostic=args.diagnostic,
                  scope='Single actual spawned task: separate derived-state and move-to-top phase markers, then retirement and console continuation; diagnostic isolation, not complete ordering or heap coverage')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands(args.diagnostic)})
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [path for path, digest in pins.items() if sha(Path(path)) != digest]
        if changed:
            report.update(result='fail', error='Input-filter prerequisite fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Input-filter prerequisites failed'))


if __name__ == '__main__':
    main()
