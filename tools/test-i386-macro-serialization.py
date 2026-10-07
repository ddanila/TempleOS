#!/usr/bin/env python3
"""Check original macro serialization and stripping in the native guest."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('#include "/Kernel/SymbolTypes.HH"', []), ('CJob *ms_head=CAlloc(sizeof(CJob)),*ms_a,*ms_arrow;QueInit(ms_head);U8 *ms_text;', []), ('U0 MSRecord(){LBts(&sys_semas[SEMA_RECORD_MACRO],0);}', []), ('U0 MSConvert(){ms_text=SysMacro2Str(ms_head);}', []), ('MSRecord;MSConvert;!*ms_text&&!Bt(&sys_semas[SEMA_RECORD_MACRO],0);', ['1']), ('Free(ms_text);', []), ('U0 MSChar(){ms_a=CAlloc(sizeof(CJob));ms_a->job_code=1;ms_a->msg_code=2;ms_a->aux1=65;QueIns(ms_a,ms_head->last);}', []), ('MSChar;', []), ('MSConvert;StrCmp(ms_text,"\\"A\\";")==0&&ms_head->next==ms_a&&ms_head->last==ms_a;', ['1']), ('Free(ms_text);', []), ('U0 MSArrow(){ms_arrow=CAlloc(sizeof(CJob));ms_arrow->job_code=1;ms_arrow->msg_code=2;ms_arrow->aux2=0xC8;QueIns(ms_arrow,ms_head->last);}', []), ('MSArrow;', []), ('MSConvert;StrCmp(ms_text,"\\"A\\";Msg(0x2,0x0,0xC8);")==0&&ms_a->next==ms_arrow&&ms_arrow->next==ms_head;', ['1']), ('Free(ms_text);SysMacroStripKey(ms_head,65,0);ms_head->next==ms_arrow&&ms_head->last==ms_arrow;', ['1']), ('SysMacroStripKey(ms_head,0,0xC8);ms_head->next==ms_head&&ms_head->last==ms_head;', ['1']), ('Free(ms_head);(GetRFlags&512)!=0;', ['1']), ('6*7;', ['42'])]


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
                  scope='Empty/character/mixed serialization, recording disable, ring preservation and key stripping; not allocation faults or executable playback')
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
            report.update(result='fail', error='Macro-serialization fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Macro serialization failed'))


if __name__ == '__main__':
    main()
