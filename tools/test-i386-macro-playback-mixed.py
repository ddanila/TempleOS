#!/usr/bin/env python3
"""Require actual mixed character, non-character and key-up macro delivery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('U0 MPAdd(I64 ch,I64 code,I64 scan){CJob *j=CAlloc(sizeof(CJob));j->job_code=1;j->msg_code=code;j->aux1=ch;j->aux2=scan;QueIns(j,sys_macro_head.last);}', []), ("U0 MPBuild(){if(sys_macro_head.next!=&sys_macro_head)throw('MacroTst');MPAdd(65,2,0);MPAdd(0,2,0xC8);MPAdd(65,3,0x1E);}", []), ('MPBuild;', []), ('Bool MPState(){CJob *a=sys_macro_head.next,*b=a->next,*c=b->next;return a->msg_code==2&&a->aux1==65&&b->msg_code==2&&!b->aux1&&b->aux2==0xC8&&c->msg_code==3&&c->aux1==65&&c->aux2==0x1E&&c->next==&sys_macro_head;}', []), ('CTask *mp_focus,*mp_child;I64 mp_base,mp_before,mp_received[2];', []), ('U0 MPReceive(I64 *s){I64 a,b,code=ScanMsg(&a,&b,~1,Fs),i=s[0]%3;if(code){if(i==0&&(code!=2||a!=65||b)||i==1&&(code!=2||a||b!=0xC8)||i==2&&(code!=3||a!=65||b!=0x1E))s[1]++;s[0]++;LBtr(&Fs->task_flags,TASKf_IDLE);}else LBts(&Fs->task_flags,TASKf_IDLE);}', []), ('U0 MPRecipient(U8 *data){while(TRUE){MPReceive(data(I64 *));Sleep(1);}}', []), ('U0 MPSpawn(){mp_child=Spawn(&MPRecipient,mp_received,"Macro recipient",-1,Fs);}', []), ('MPSpawn;', []), ('Bool MPChildState(){return mp_child->last_input_filter_task==mp_child&&mp_child->next_input_filter_task==mp_child&&!Bt(&mp_child->task_flags,TASKf_FILTER_INPUT);}', []), ('U0 MPStart(){Sleep(100);FlushMsgs(Fs);mp_focus=sys_focus_task;sys_focus_task=mp_child;mp_before=mp_received[0];mp_base=Fs->data_heap->used_u8s;LBts(&sys_semas[SEMA_RECORD_MACRO],0);}', []), ('I64 MPEnd(I64 n){I64 ok=mp_received[0]==mp_before+3*n&&!mp_received[1]&&!Bt(&sys_semas[SEMA_RECORD_MACRO],0)&&MPState()&&MPChildState()&&Fs->data_heap->used_u8s==mp_base;sys_focus_task=mp_focus;return ok;}', []), ('I64 MPRun(I64 n){MPStart;PlaySysMacro(n);return MPEnd(n);}', []), ('MPRun(0);', ['1']), ('MPRun(1);', ['1']), ('MPRun(3);', ['1']), ('I64 MPRepeat(){I64 i;for(i=0;i<10;i++)if(!MPRun(1))return 0;return 1;}', []), ('MPRepeat;', ['1']), ('U0 MPFree(){CJob *j;while(sys_macro_head.next!=&sys_macro_head){j=sys_macro_head.next;QueRem(j);Free(j);}}', []), ('Kill(mp_child);', ['1']), ('TaskValidate(mp_child);', ['0']), ('MPFree;', []), ('6*7;', ['42'])]

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
                  scope='Mixed-event playback: exact ordered key-down A, arrow scan 0xC8, key-up A scan 0x1E; all-message child consumer, counts 0/1/3 and ten cycles, preserved ring, recording disabled and exact caller heap; Actual recorded-ring PlaySysMacro to a focused child, counts zero/one/three, ten further cycles, independently consumed AB sequence, exact caller heap recovery, both filter links, ring preservation, recording disabled and child retirement; not focus changes mid-playback, interruption, timing or editor undo')
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
