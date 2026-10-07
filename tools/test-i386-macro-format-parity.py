#!/usr/bin/env python3
"""Compare native macro serialization with an original x64 byte oracle."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [
        ('#include "/Kernel/SymbolTypes.HH"', []),
        ('CJob *mf_head;U8 *mf_text;', []),
        ('U0 MFAdd(I64 ch,I64 code,I64 scan){CJob *j=CAlloc(sizeof(CJob));j->job_code=1;j->msg_code=code;j->aux1=ch;j->aux2=scan;QueIns(j,mf_head->last);}', []),
        ('U0 MFBuild(){I64 i;mf_head=CAlloc(sizeof(CJob));QueInit(mf_head);for(i=0;i<256;i++)MFAdd(i,2,i|256);MFAdd(65,3,0x1E);}', []),
        ('U0 MFSave(){mf_text=SysMacro2Str(mf_head);FileWrite("/MacroExtended.HC",mf_text,StrLen(mf_text));}', []),
        ('U0 MFFree(){CJob *j;while(mf_head->next!=mf_head){j=mf_head->next;QueRem(j);Free(j);}Free(mf_head);Free(mf_text);}', []),
        ('MFBuild;MFSave;MFFree;', []),
        ('6*7;', ['42']),
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--original', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    if any(len(s.encode('ascii')) > 255 for s, _ in commands()):
        raise ValueError('Macro parity command exceeds interactive line limit')
    helper = ROOT / 'tools/i386-kernel-input.py'
    reader = ROOT / 'tools/build-i386-kernel.py'
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, args.original, helper, reader, Path(__file__))}
    args.out.mkdir(parents=True)
    report = dict(result='running', input_sha256=pins,
                  scope='All byte-valued key-down characters and one key-up, original/native exact serialization; not playback or allocation faults')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands()})
        actual = runpy.run_path(str(reader))['mutated_file_contents'](disk, {'/MacroExtended.HC'})['/MacroExtended.HC']
        (args.out / 'MacroExtended.HC').write_bytes(actual)
        expected = args.original.read_bytes()
        if not expected or actual != expected:
            raise ValueError('Native macro serialization differs from original oracle')
        report.update(result='pass', bytes=len(actual), serialized_events=257,
                      output_sha256=hashlib.sha256(actual).hexdigest())
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [p for p, digest in pins.items() if sha(Path(p)) != digest]
        if changed:
            report.update(result='fail', error='Macro parity inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report['error'])


if __name__ == '__main__':
    main()
