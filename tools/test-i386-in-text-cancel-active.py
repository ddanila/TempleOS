#!/usr/bin/env python3
"""Cancel active In execution paused at the public message service."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('U8 *ia_entry,ia_saved[5];CTask *ia_filter;Bool ia_entered;I64 ia_base,ia_root,ia_delta,ia_root_delta;', []), ('U0 IARestore(){I64 i;for(i=0;i<5;i++)ia_entry[i]=ia_saved[i];}', []), ('U0 IAHook(I64 code,I64 a,I64 b,I64 flags=0){ia_filter=Fs;ia_entered=TRUE;Sleep(10000);}', []), ('U0 IAPatch(){I64 i;I32 d;ia_entry=&Msg;for(i=0;i<5;i++)ia_saved[i]=ia_entry[i];d=(&IAHook+0)(U64)-(ia_entry+0)(U64)-5;ia_entry[0]=0xE9;(ia_entry+1)(I32 *)[0]=d;}', []), ('Bool IAState(){return Fs->last_input_filter_task==Fs&&Fs->next_input_filter_task==Fs&&!Bt(&Fs->task_flags,TASKf_FILTER_INPUT);}', []), ('Bool IABytes(){I64 i;for(i=0;i<5;i++)if(ia_entry[i]!=ia_saved[i])return FALSE;return TRUE;}', []), ('U0 IAStart(){Sleep(100);FlushMsgs(Fs);ia_base=Fs->data_heap->used_u8s;ia_root=adam_task->data_heap->used_u8s;ia_entered=FALSE;IAPatch;In("%s","Active");while(!ia_entered)Yield;}', []), ('U0 IACancel(){Kill(ia_filter);IARestore;}', []), ('U0 IARun(){I64 i;IAStart;IACancel;for(i=0;i<8;i++)Yield;FlushMsgs(Fs);ia_delta=Fs->data_heap->used_u8s-ia_base;ia_root_delta=adam_task->data_heap->used_u8s-ia_root;}', []), ('Bool IAOne(){IARun;return ia_entered&&!TaskValidate(ia_filter)&&IAState&&IABytes&&!ia_delta&&!ia_root_delta;}', []), ('Bool IARepeat(){I64 i;for(i=0;i<10;i++)if(!IAOne)return FALSE;return TRUE;}', []), ('IAOne;', ['1']), ('IARepeat;', ['1']), ('6*7;', ['42'])]


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
                  scope='Active In cancellation: message hook pauses executing print, Kill retires filter, initial plus ten repetitions, exact caller/root heap after draining, restored Msg bytes and filter state; only this active execution checkpoint')
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
