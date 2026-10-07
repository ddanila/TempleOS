#!/usr/bin/env python3
"""Require original macro serialization and playback services in the installed guest."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('U0 MPAdd(I64 ch){CJob *j=CAlloc(sizeof(CJob));j->job_code=1;j->msg_code=2;j->aux1=ch;QueIns(j,sys_macro_head.last);}', []), ("U0 MPBuild(){if(sys_macro_head.next!=&sys_macro_head)throw('MacroTst');MPAdd(65);MPAdd(66);}", []), ('MPBuild;', []), ('Bool MPState(){return sys_macro_head.next->aux1==65&&sys_macro_head.last->aux1==66&&sys_macro_head.next->next==sys_macro_head.last&&sys_macro_head.last->next==&sys_macro_head&&!Bt(&sys_semas[SEMA_RECORD_MACRO],0);}', []), ('CTask *mp_focus,*mp_child;I64 mp_base,mp_before,mp_received[2];', []), ('U0 MPReceive(I64 *s){I64 a,b,expected=65;if(s[0]&1)expected=66;if(ScanMsg(&a,&b,1<<2,Fs)==2){if(a!=expected||b)s[1]++;s[0]++;if(s[0]==2)Exit;LBtr(&Fs->task_flags,TASKf_IDLE);}else LBts(&Fs->task_flags,TASKf_IDLE);}', []), ('U0 MPRecipient(U8 *data){while(TRUE){MPReceive(data(I64 *));Sleep(1);}}', []), ('U0 MPSpawn(){mp_received[0]=mp_received[1]=0;mp_child=Spawn(&MPRecipient,mp_received,"Macro recipient",-1,Fs);}', []), ('MPSpawn;', []), ('Bool MPChildState(){return mp_child->last_input_filter_task==mp_child&&mp_child->next_input_filter_task==mp_child&&!Bt(&mp_child->task_flags,TASKf_FILTER_INPUT);}', []), ('U0 MPStart(){mp_focus=sys_focus_task;sys_focus_task=mp_child;mp_before=mp_received[0];mp_base=Fs->data_heap->used_u8s;LBts(&sys_semas[SEMA_RECORD_MACRO],0);}', []), ('I64 MPEnd(I64 n){I64 ok=mp_received[0]==mp_before+2&&!mp_received[1]&&!TaskValidate(mp_child)&&MPState()&&Fs->data_heap->used_u8s==mp_base;sys_focus_task=mp_focus;return ok;}', []), ('I64 MPRun(I64 n){MPStart;PlaySysMacro(n);return MPEnd(n);}', []), ('MPRun(3);', ['1']), ('TaskValidate(mp_child);', ['0']), ('MPSpawn;', []), ('MPRun(-1);', ['1']), ('TaskValidate(mp_child);', ['0']), ('U0 MPFree(){CJob *j;while(sys_macro_head.next!=&sys_macro_head){j=sys_macro_head.next;QueRem(j);Free(j);}}', []), ('MPFree;', []), ('6*7;', ['42'])]


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
                  scope='Recipient exits after first AB during requested three-repeat and original negative-count playback; later iterations stop on invalid target, ring preserved, recording disabled and exact caller heap recovered; not external cancellation, replay timing or editor undo')
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
            report.update(result='fail', error='Macro-playback fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Macro-playback prerequisites failed'))


if __name__ == '__main__':
    main()
