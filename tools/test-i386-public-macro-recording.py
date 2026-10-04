#!/usr/bin/env python3
"""Compare original/native TaskMsg macro-copy eligibility, FIFO and metadata."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CASES = ('MacroDisabled', 'MacroOnlyDown', 'MacroFIFO', 'MacroOwn',
         'MacroPair', 'MacroReject')


def definitions():
    return [
        'Bool MacroEmpty(){return sys_macro_head.next==&sys_macro_head&&sys_macro_head.last==&sys_macro_head;}',
        'U0 MacroOn(){LBts(&sys_semas[SEMA_RECORD_MACRO],0);}',
        'U0 MacroOff(){LBtr(&sys_semas[SEMA_RECORD_MACRO],0);}',
        'U0 MacroPost(I64 code,I64 a){TaskMsg(Fs,Fs,code,a,~a,1<<JOBf_WAKE_MASTER);}',
        'Bool MacroMeta(CJob *j,I64 a){return j->job_code==JOBT_MSG&&j->msg_code==MSG_KEY_DOWN&&j->aux1==a&&j->aux2==~a&&j->master_task==Fs&&j->flags==(1<<JOBf_WAKE_MASTER)&&!j->ctrl;}',
        'Bool MacroPop(I64 a){CJob *h=&sys_macro_head,*j=h->next;Bool ok;if(j==h)return FALSE;ok=MacroMeta(j,a);QueRem(j);Free(j);return ok;}',
        'Bool MacroDisabled(){Bool ok;MacroOff;MacroPost(MSG_KEY_DOWN,11);ok=MacroEmpty;FlushMsgs;return ok;}',
        'Bool MacroOnlyDown(){Bool ok;MacroOn;MacroPost(MSG_KEY_UP,11);MacroPost(MSG_CMD,12);MacroOff;ok=MacroEmpty;FlushMsgs;return ok;}',
        'Bool MacroFIFO(){Bool ok;MacroOn;MacroPost(MSG_KEY_DOWN,11);MacroPost(MSG_KEY_DOWN,22);MacroOff;ok=MacroPop(11)&&MacroPop(22)&&MacroEmpty;FlushMsgs;return ok;}',
        'Bool MacroOwn(){CTask *old=sys_macro_task;Bool ok;sys_macro_task=Fs;MacroOn;MacroPost(MSG_KEY_DOWN,11);MacroOff;sys_macro_task=old;ok=MacroEmpty;FlushMsgs;return ok;}',
        'Bool MacroPair(){Bool ok;MacroOn;MacroPost(-MSG_KEY_DOWN,11);MacroOff;ok=MacroEmpty;FlushMsgs;return ok;}',
        'Bool MacroReject(){Bool ok;MacroOn;ok=!TaskMsg(NULL,Fs,MSG_KEY_DOWN,11,12,0)&&MacroEmpty;MacroOff;return ok;}',
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, nargs='?')
    parser.add_argument('--original', action='store_true')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.original == (args.disk is not None):
        parser.error('Specify either --original or an i386 disk')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker = sha(Path(__file__))
    source = '\n'.join(definitions()) + '\n'
    if any(len(line) > 255 for line in definitions()):
        raise ValueError('Macro contract exceeds the native input line limit')
    report = {'checker_sha256': checker, 'cases': len(CASES),
              'definitions_sha256': hashlib.sha256(source.encode()).hexdigest(),
              'scope': 'TaskMsg recording disabled/enabled, positive key-down eligibility, FIFO copied metadata, macro-task exclusion, negative pair and invalid target; not playback, UI or allocation failure'}
    disk_hash = None if args.original else sha(args.disk)
    if disk_hash:
        report['disk_sha256'] = disk_hash
    try:
        if args.original:
            overlay = out / 'overlay'
            overlay.mkdir(exist_ok=True)
            (overlay / 'Definitions.HC').write_text(source)
            cases = '&&'.join(CASES)
            (overlay / 'Once.HC').write_text(
                'U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}\n'
                '#include "T:/Definitions.HC"\n'
                'Report("START original macro recording\\n");\n'
                f'Bool ok=MacroEmpty&&{cases};\n'
                'if(ok)Report("PASS original macro recording\\n");\n'
                'else Report("FAIL original macro recording\\n");\n'
                'Report("DONE original macro recording\\n");\n')
            iso = out / 'original.iso'
            subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                            'build/rebuild-test/overlay', '--overlay', str(overlay),
                            '--output', str(iso)], cwd=ROOT, check=True)
            subprocess.run([sys.executable, 'tools/guest-run.py', str(iso),
                            '--out', str(out / 'original'), '--timeout', '90'],
                           cwd=ROOT, check=True)
            if 'PASS original macro recording\n' not in (out / 'original/debug.log').read_text():
                raise ValueError('Missing original macro verdict')
            report['platform'] = 'original x64 TempleOS'
        else:
            commands = [('HashFind("sys_macro_head",Fs->hash_table,HTT_GLBL_VAR)!=0;', ['1'])]
            commands += [(line, []) for line in definitions()]
            commands += [(name + ';', ['1']) for name in CASES]
            commands += [('6*7;', ['42'])]
            runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
            report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
                qmp_stdio=True, startup_check={'status': 'ok', 'answers': [], 'commands': commands})
        if sha(Path(__file__)) != checker:
            raise ValueError('Macro checker changed during execution')
        if disk_hash and sha(args.disk) != disk_hash:
            raise ValueError('Macro checker modified the input disk')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        if disk_hash:
            report['source_disk_unchanged'] = sha(args.disk) == disk_hash
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
