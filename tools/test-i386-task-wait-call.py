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
    return [('U8 *wa_entry,*wa_hook,wa_saved[5];CTask *wa_task;I64 wa_calls;Bool wa_prompt;', []), ('U0 WARestore(){I64 i;for(i=0;i<5;i++)wa_entry[i]=wa_saved[i];}', []), ('U0 WAApply(){I32 d=(wa_hook+0)(U64)-(wa_entry+0)(U64)-5;wa_entry[0]=0xE9;(wa_entry+1)(I32 *)[0]=d;}', []), ('U0 WAHook(CTask *task=0,Bool prompt=FALSE){wa_calls++;wa_task=task;wa_prompt=prompt;}', []), ('U0 WAStart(){I64 i;wa_entry=&TaskWait;wa_hook=&WAHook;for(i=0;i<5;i++)wa_saved[i]=wa_entry[i];wa_calls=0;wa_task=Fs;wa_prompt=TRUE;WAApply;}', []), ('U0 WAInvoke(Bool explicit){if(explicit)TaskWait(NULL,FALSE);else TaskWait;}', []), ('I64 WARun(Bool explicit){I64 f=GetRFlags,result,i;SetRFlags(f&~512);WAStart;try{WAInvoke(explicit);}catch{WARestore;SetRFlags(f);}WARestore;result=wa_calls==1&&!wa_task&&!wa_prompt;SetRFlags(f);return result;}', []), ('WARun(FALSE);', ['1']), ('WARun(TRUE);', ['1']), ('6*7;', ['42'])]


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
                  scope='TaskWait call ABI: patched hook observes exactly one call with null recipient and false prompt for implicit and explicit default invocation; allocator entry and IRQ flags restored; not wait completion')
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
