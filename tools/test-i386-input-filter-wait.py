#!/usr/bin/env python3
"""Require executable InFile text routing and retired filter tasks for self and child recipients."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('CTask *df_task;I64 df_mask;', []), ('U0 DFStart(){df_mask=0;if(Bt(&Fs->task_flags,TASKf_INPUT_FILTER_TASK))df_mask|=128;InStr("%s","\\"AB\\";");df_task=Fs->last_input_filter_task;if(df_task!=Fs)df_mask|=1;if(TaskValidate(df_task))df_mask|=2;}', []), ('U0 DFFlags(){if(Bt(&df_task->task_flags,TASKf_INPUT_FILTER_TASK))df_mask|=4;if(Bt(&df_task->task_flags,TASKf_IDLE))df_mask|=8;}', []), ('U0 DFEnd(){I64 a,b;TaskWait;if(Fs->last_input_filter_task==Fs)df_mask|=16;if(ScanMsg(&a,&b)==2&&a==65&&!b&&ScanMsg(&a,&b)==2&&a==66&&!b)df_mask|=32;if(Fs->next_input_filter_task==Fs)df_mask|=64;}', []), ('I64 DFRun(){DFStart;DFFlags;DFEnd;return df_mask;}', []), ('DFRun;', ['115']), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, Path(__file__))}
    report = dict(result='running', input_sha256=pins, disk_policy='writable copy',
                  scope='Diagnostic self-input state: queued filter differs from recipient and validates, no pre-entry idle/filter flags, wait restores both links and two messages; bitmask expected 115')
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
            report.update(result='fail', error='Input-filter prerequisite fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Input-filter prerequisites failed'))


if __name__ == '__main__':
    main()
