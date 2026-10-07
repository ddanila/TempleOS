#!/usr/bin/env python3
"""Inject TaskMsg exception-registration failure and verify allocation cleanup."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    definitions = [
        '#include \"/Kernel/SymbolTypes.HH\"',
        'U0 MacroLog(U8 *s){while(*s)OutU8(0xE9,*s++);}',
        'Bool MacroEmpty(){return sys_macro_head.next==&sys_macro_head&&sys_macro_head.last==&sys_macro_head;}',
        'U0 MacroOn(){LBts(&sys_semas[SEMA_RECORD_MACRO],0);}',
        'U0 MacroOff(){LBtr(&sys_semas[SEMA_RECORD_MACRO],0);}',
        'U8 MacroSaved[5],*MacroPatch;I64 MacroBefore;',
        'U0 MacroFailRegistration(U8 *capture,U8 *resume){throw(\'OutMem\');}',
        'Bool MacroPatchStart(){CHashExport *s=HashFind("SysTry",Fs->hash_table,HTT_EXPORT_SYS_SYM);I64 i;if(!s)return FALSE;MacroPatch=s->val;for(i=0;i<5;i++)MacroSaved[i]=MacroPatch[i];return TRUE;}',
        'U0 MacroPatchApply(){I32 d=(&MacroFailRegistration+0)(U64)-(MacroPatch+0)(U64)-5;MacroPatch[0]=0xE9;(MacroPatch+1)(I32 *)[0]=d;}',
        'U0 MacroPatchRestore(){I64 i;for(i=0;i<5;i++)MacroPatch[i]=MacroSaved[i];}',
        'Bool MacroPatchRestored(){I64 i;for(i=0;i<5;i++)if(MacroPatch[i]!=MacroSaved[i])return FALSE;return TRUE;}',
        'U0 MacroCopySetup(){MacroBefore=Fs->parent_task->data_heap->used_u8s;MacroOn;}',
        'Bool MacroCopyTry(){Bool ok=FALSE;try{MacroPatchApply;TaskMsg(Fs,Fs,MSG_KEY_DOWN,11,12,0);}catch{MacroPatchRestore;ok=Fs->except_ch==\'OutMem\';Fs->catch_except=TRUE;MacroLog("MACRO REGISTER fault\\n");}return ok;}',
        'Bool MacroCopyClean(){return Fs->parent_task->data_heap->used_u8s==MacroBefore&&MacroEmpty&&MacroPatchRestored&&Fs->srv_ctrl.next_waiting==(&Fs->srv_ctrl.next_waiting)(CJob *)&&!Fs->srv_ctrl.flags;}',
        'Bool MacroCopyFail(){I64 f=GetRFlags;Bool ok;FlushMsgs;if(!MacroPatchStart)return FALSE;SetRFlags(f&~512);MacroCopySetup;ok=MacroCopyTry;MacroOff;MacroPatchRestore;SetRFlags(f);return ok&&MacroCopyClean;}',
    ]
    return [(source, []) for source in definitions] + [('MacroCopyFail;', ['1']), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--writable-copy',action='store_true',help='Use a fresh disk copy without QEMU snapshot temporary files')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    disk_hash, checker = sha(args.disk), sha(Path(__file__))
    report = {'disk_sha256': disk_hash, 'checker_sha256': checker,
              'scope': 'Handler registration throws OutMem after first allocation: exact root-heap recovery, empty/unlocked destination and recording rings, restored code and console arithmetic; not all allocation sites'}
    disk=args.disk
    if args.writable_copy:
        disk=out/'working.img'
        if disk.exists():
            raise ValueError('Use a fresh writable-copy output directory')
        shutil.copyfile(args.disk,disk)
    report['disk_policy']='writable copy' if args.writable_copy else 'QEMU snapshot'
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
            snapshot=not args.writable_copy,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands()})
        if sha(Path(__file__)) != checker:
            raise ValueError('Keyboard checker changed during execution')
        if sha(args.disk) != disk_hash:
            raise ValueError('Keyboard checker modified the input disk')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        log = out / 'behavior/debug.log'
        report['fault_injected'] = log.exists() and 'MACRO REGISTER fault\n' in log.read_text()
        report['source_disk_unchanged'] = sha(args.disk) == disk_hash
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
