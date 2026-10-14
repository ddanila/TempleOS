#!/usr/bin/env python3
"""Check streaming output callback consumption, ordering and exceptional heap recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('I64 sh_mode,sh_calls;Bool sh_text,sh_data,sh_locked;CDoc *sh_doc;', []),
    ('Bool SHHook(CDoc *d,U8 *data,U8 *s){sh_calls++;sh_text=StrCmp(s,"abc7")==0;sh_data=data==&sh_mode;sh_locked=Bt(&d->locked_flags,DOClf_LOCKED);if(sh_mode==2)throw(\'HookFail\');return sh_mode==1;}', []),
    ('U0 SHArm(I64 mode){sh_mode=mode;sh_calls=0;sh_text=sh_data=sh_locked=FALSE;sh_doc->user_put_s=&SHHook;sh_doc->user_put_data=&sh_mode;}', []),
    ('U0 SHPrint(){DocPrintPartial(sh_doc,"%s%d","abc",7);}', []),
    ('I64 SHState(){U8 *s=DocScanLine(sh_doc,sh_doc->head.next),*want="abc7";if(sh_mode==1)want="";I64 ok=StrCmp(s,want)==0;Free(s);return ok&&sh_calls==1&&sh_text&&sh_data&&!sh_locked&&!sh_doc->owning_task;}', []),
    ("Bool SHThrow(){I64 base=Fs->data_heap->used_u8s;Bool caught=FALSE;try{SHPrint;}catch{caught=Fs->except_ch=='HookFail';Fs->catch_except=TRUE;}return caught&&Fs->data_heap->used_u8s==base&&!sh_doc->owning_task;}", []),
    ('U0 SHNew(){sh_doc=DocNew;}', []),
    ('SHNew;', []),
    ('SHArm(1);SHPrint;', []),
    ('SHState;', ['1']),
    ('SHArm(0);SHPrint;', []),
    ('SHState;', ['1']),
    ('SHArm(2);', []),
    ('SHThrow;', ['1']),
    ('DocDel(sh_doc);', []),
    ('6*7;', ['42']),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='DocPrintPartial callback formatted text/user data, pre-lock call, consume/pass-through and throwing-hook heap recovery; not every allocation failure or callback reentrancy',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['0'],
                           'command_timeout':120})
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Native fixture inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':
        raise ValueError(report['error'])


if __name__=='__main__':
    main()
