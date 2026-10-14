#!/usr/bin/env python3
"""Exercise GetKey physical input, raw cursor and masked debugger polling."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('U0 KeyLog(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
    ('Bool KeyOldRaw,KeyOldDebug;I64 KeyFlags;', []),
    ('U0 KeyScreen(U8 *s){I64 i;for(i=0;i<60;i++)"\\n";"%s",s;}', []),
    ('U0 KeyStart(Bool polled){KeyOldRaw=Raw(TRUE);KeyOldDebug=DbgMode(polled);KeyFlags=GetRFlags;if(polled)SetRFlags(KeyFlags&~512);}', []),
    ('U0 KeyFinish(){SetRFlags(KeyFlags);Raw(KeyOldRaw);DbgMode(KeyOldDebug);KeyScreen("TempleOS i386\\nHolyC console\\n\\n");}', []),
    ('I64 KeyPhys(Bool polled){I64 ch,sc,ok;KeyStart(polled);KeyScreen("Key input raw\\n");KeyLog("GETKEY physical begin\\n");ch=GetKey(&sc,FALSE,TRUE);ok=ch==97&&(sc&255)==0x1E&&(!polled||!(GetRFlags&512));KeyFinish;KeyLog("GETKEY physical end\\n");return ok;}', []),
]
for polled in (False,True):
    title=['']*58+['Key input raw','']
    COMMANDS.append(('KeyPhys('+('TRUE' if polled else 'FALSE')+');',['1'],{
        'begin':'GETKEY physical begin\n','initial_rows':title,
        'events':[{'expect_rows':title[:-1]+[bytes([0xDB]).decode('cp437')],'label':'cursor-on'},
                  {'expect_rows':title,'label':'cursor-off'}],
        'return_rows':['']*55+['TempleOS i386','HolyC console','','1','> '],
        'final_rows':title,'exit_key':'a','end':'GETKEY physical end\n'}))
COMMANDS.append(('6*7;',['42']))


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
    report = dict(result='running', scope='Physical QEMU key delivery and raw cursor visible/erased frames in scheduled and IF-masked debugger modes, return scan code and interrupt-state restoration; not all debugger, echo or GetStr behavior',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',),
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
