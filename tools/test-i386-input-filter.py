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
    return [('#include "/Kernel/SymbolTypes.HH"', []), ('I64 IFPrereq(){I64 m=0;if(HashFind("Print",Fs->hash_table,~0))m|=1;if(HashFind("InStr",Fs->hash_table,~0))m|=2;if(HashFind("XTalkStrWait",Fs->hash_table,~0))m|=4;return m;}', []), ('IFPrereq;', ['7']), ('I64 IFMessages(CTask *task=0){I64 a,b;if(ScanMsg(&a,&b,1<<2,task)!=2||a!=65||b)return 0;if(ScanMsg(&a,&b,1<<2,task)!=2||a!=66||b)return 0;return ScanMsg(&a,&b,1<<2,task)==0;}', []), ('I64 IFSelf(){FlushMsgs(Fs);InStr("%s","\\"AB\\";");TaskWait;return IFMessages && Fs->last_input_filter_task==Fs && Fs->next_input_filter_task==Fs && !Bt(&Fs->task_flags,TASKf_FILTER_INPUT);}', []), ('IFSelf;', ['1']), ('I64 IFRepeat(){I64 i,base=Fs->data_heap->used_u8s;for(i=0;i<10;i++){if(!IFSelf)return 0;Yield;}return Fs->data_heap->used_u8s==base;}', []), ('IFRepeat;', ['1']), ('U0 IFReceive(I64 *s){I64 a,b,expected=65;if(s[0]&1)expected=66;if(ScanMsg(&a,&b,1<<2,Fs)==2){if(a!=expected||b)s[1]++;s[0]++;LBtr(&Fs->task_flags,TASKf_IDLE);}else LBts(&Fs->task_flags,TASKf_IDLE);}', []), ('U0 IFRecipient(U8 *data){while(TRUE){IFReceive(data(I64 *));Sleep(1);}}', []), ('CTask *if_child;I64 if_received[2];', []), ('U0 IFChildStart(){if_received[0]=if_received[1]=0;if_child=Spawn(&IFRecipient,if_received,"Input recipient",-1,Fs);}', []), ('IFChildStart;', []), ('I64 IFChildState(){return if_child->last_input_filter_task==if_child&&if_child->next_input_filter_task==if_child&&!Bt(&if_child->task_flags,TASKf_FILTER_INPUT);}', []), ('I64 IFChild(){I64 n=if_received[0];XTalkStrWait(if_child,"%s","\\"AB\\";");return if_received[0]==n+2&&!if_received[1]&&IFChildState();}', []), ('IFChild;', ['1']), ('Kill(if_child);', ['1']), ('TaskValidate(if_child);', ['0']), ('6*7;', ['42'])]


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
                  scope='Public API mask, actual quoted-source self/child routing with key-down-only self scans and child receipt recorded before idle, ten self cycles with exact task heap recovery, filter links/bits restored and child retirement; not macro playback or fault coverage')
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
