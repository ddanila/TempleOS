#!/usr/bin/env python3
"""Require actual In text delivery and retired input filters."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(without_in=False):
    rows = [
        ('I64 ie_started,ie_delta,ie_ok;', []),
        ('U0 IEChild(U8 *data){ie_started++;In("%s","ORPHAN");Exit;}', []),
        ('U0 IEOne(){CTask *t=Spawn(&IEChild,0,"Input exit",-1,Fs);while(TaskValidate(t))Yield;}', []),
        ('U0 IEDrain(){I64 i;for(i=0;i<8;i++)Yield;FlushMsgs(Fs);}', []),
        ('I64 IERun(){I64 i,base,n;IEOne;IEDrain;base=adam_task->data_heap->used_u8s;n=ie_started;for(i=0;i<10;i++){IEOne;IEDrain;}ie_delta=adam_task->data_heap->used_u8s-base;return ie_started==n+10&&!ie_delta;}', []),
        ('U0 IEStart(){ie_ok=IERun;}', []),
        ('IEStart;', []),
        ('"Input exit started:%d root delta:%d\\n",ie_started,ie_delta;', ['Input exit started:11 root delta:0']),
        ('ie_ok;', ['1']), ('6*7;', ['42']),
    ]
    if without_in:
        rows[1] = ('U0 IEChild(U8 *data){ie_started++;Exit;}', [])
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--without-in', action='store_true', help='Control: retire identical children without submitting input')
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, Path(__file__))}
    report = dict(result='running', input_sha256=pins, disk_policy='writable copy', without_in=args.without_in,
                  scope='In lifetime: submitting task exits immediately after queuing text, ten retired tasks and exact root heap after draining; no successful child delivery or active cancellation coverage')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands(args.without_in)})
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
