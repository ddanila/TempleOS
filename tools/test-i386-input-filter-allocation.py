#!/usr/bin/env python3
"""Inject a serializer temporary-allocation failure and require exact heap recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(fail_after=1):
    cases = [('#include "/Kernel/SymbolTypes.HH"', []), ('U8 *mfa_entry,*mfa_hook,mfa_saved[5];I64 mfa_calls,mfa_base;Bool mfa_caught;', []), ('U0 MFARestore(){I64 i;for(i=0;i<5;i++)mfa_entry[i]=mfa_saved[i];}', []), ('U0 MFAApply(){I32 d=(mfa_hook+0)(U64)-(mfa_entry+0)(U64)-5;mfa_entry[0]=0xE9;(mfa_entry+1)(I32 *)[0]=d;}', []), ("U8 *MFAHook(I64 size,CTask *task=0){U8 *p;if(++mfa_calls==1)throw('OutMem');MFARestore;p=CAlloc(size,task);MFAApply;return p;}", []), ('U0 MFAStart(){I64 i;mfa_hook=&MFAHook;mfa_entry=&CAlloc;for(i=0;i<5;i++)mfa_saved[i]=mfa_entry[i];mfa_calls=0;mfa_base=Fs->data_heap->used_u8s;MFAApply;}', []), ('U0 MFATry(){mfa_caught=FALSE;try{InStr("%s","\\"AB\\";");}catch{mfa_caught=Fs->except_ch==\'OutMem\';Fs->catch_except=TRUE;}}', []), ('Bool MFAState(){return Fs->last_input_filter_task==Fs&&Fs->next_input_filter_task==Fs&&!Bt(&Fs->task_flags,TASKf_FILTER_INPUT);}', []), ('Bool MFABytes(){I64 i;for(i=0;i<5;i++)if(mfa_entry[i]!=mfa_saved[i])return FALSE;return TRUE;}', []), ('Bool MFARun(){I64 f=GetRFlags;Bool ok;SetRFlags(f&~512);MFAStart;MFATry;MFARestore;ok=mfa_caught&&mfa_calls==1&&Fs->data_heap->used_u8s==mfa_base&&MFAState()&&MFABytes();SetRFlags(f);return ok;}', []), ('MFARun;', ['1']), ('6*7;', ['42'])]
    return [(source.replace("++mfa_calls==1", f"++mfa_calls=={fail_after}").replace("mfa_calls==1", f"mfa_calls=={fail_after}"), answers) for source, answers in cases]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--fail-after', type=int, choices=(1, 2), default=1)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, Path(__file__))}
    report = dict(result='running', fail_after=args.fail_after, input_sha256=pins, disk_policy='writable copy',
                  scope='Selected executable-input CAlloc call throws OutMem; exception/count, exact task heap recovery, unchanged filter links/bit and restored allocator entry bytes; not Spawn failure, cancellation or playback')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands(args.fail_after)})
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [path for path, digest in pins.items() if sha(Path(path)) != digest]
        if changed:
            report.update(result='fail', error='Macro-serialization fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Macro serialization failed'))


if __name__ == '__main__':
    main()
