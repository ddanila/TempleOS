#!/usr/bin/env python3
"""Verify expression #if behavior through the native HolyC compiler."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
SOURCE = '''#define CONDITIONAL_TEST_VALUE 3
#if CONDITIONAL_TEST_VALUE*2==6
I64 IfTrue(){return 11;}
#else
invalid skipped syntax @@@
#endif
#if 0
invalid skipped syntax @@@
#if 1
nested invalid skipped syntax @@@
#endif
#else
I64 IfFalse(){return 12;}
#endif
#if 1
#if sizeof(U8 *)==4
I64 IfPointer(){return 13;}
#else
invalid pointer branch @@@
#endif
#else
invalid outer branch @@@
#endif
#if 1
#if 0
invalid inner branch @@@
#else
I64 IfNested(){return 14;}
#endif
#else
invalid outer branch @@@
#endif
#if 0.5
I64 IfFloat(){return 15;}
#else
invalid floating branch @@@
#endif
I64 IfTail(){return 16;}
'''
BAD_SOURCE = '#if MissingConditionalName\nI64 IfBad(){return 0;}\n#endif\n'


def stage(source, label):
    name = f'if_{label}_source'
    doc = f'if_{label}_doc'
    result = [(f'U8 *{name}=CAlloc({len(source)+1});', [])]
    for offset in range(0, len(source), 140):
        chunk = json.dumps(source[offset:offset+140]).replace('@', chr(92)+'x40')
        fun = f'IfChunk{label}{offset}'
        result.append((f'U0 {fun}(){{StrCpy({name}+{offset},{chunk});}}{fun};', []))
    result.extend([
        (f'CDoc *{doc}=DocNew("C:/If{label}.HC",Fs);', []),
        (f'I64 IfEntry{label}(){{CDocEntry *e=DocEntryNewTag({doc},&{doc}->head,{name});e->type=DOCT_TEXT;DocInsEntry({doc},e);return StrLen(e->tag)=={len(source)};}}IfEntry{label};', ['1']),
        (f'DocWrite({doc});', ['1']),
        (f'DocDel({doc});Free({name});', []),
    ])
    return result


def commands():
    result = stage(SOURCE, 'Good') + [
        ('#include "C:/IfGood.HC"', []),
        ('IfTrue+IfFalse+IfPointer+IfNested+IfFloat+IfTail;', ['81']),
        ('6*7;', ['42']),
    ]
    result += stage(BAD_SOURCE, 'Bad') + [
        ('#include "C:/IfBad.HC"', ['Error: Undefined identifier at ']),
        ('6*7;', ['42']),
        ('IfTrue+IfTail;', ['27']),
        ('HashFind("IfBad",Fs->hash_table,HTT_FUN)==0;', ['1']),
    ]
    assert all(len(source)<=255 for source, _ in result)
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    path=args.out/'result.json';path.unlink(missing_ok=True)
    sha=lambda file:hashlib.sha256(file.read_bytes()).hexdigest()
    before=sha(args.disk)
    checker=sha(Path(__file__))
    report=dict(result='fail',disk_sha256=before,checker_sha256=checker,
                fixture_sha256=hashlib.sha256(SOURCE.encode()).hexdigest(),
                cpu='486,-fpu',ram_mib=8,accel='tcg',
                scope='Native JIT expression conditionals and recovery; not AOT parity or allocation-failure cleanup')
    runner=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
    try:
        report['console']=runner(args.disk,args.out/'console',cpu='486,-fpu',qmp_stdio=True,
                                 startup_check={'status':'ok','answers':[],'commands':commands()})
        report['result']='pass'
    except Exception as exc:
        report['error']=str(exc)
    report['source_disk_unchanged']=sha(args.disk)==before
    report['checker_unchanged']=sha(Path(__file__))==checker
    if not report['source_disk_unchanged'] or not report['checker_unchanged']:
        report['result']='fail'
    path.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
    raise SystemExit(0 if report['result']=='pass' else 1)


if __name__=='__main__':
    main()
