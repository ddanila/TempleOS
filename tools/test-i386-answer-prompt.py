#!/usr/bin/env python3
"""Check deferred native console answers against original prompt semantics."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]
COMMANDS=[
    ('#include "/Kernel/I386/PublicUser.HH"',[]),
    ('11;22;',['22']),
    ('Fs->answer==22 && !Fs->new_answer;',['1']),
    ('#include "C:/Probe/PromptValues.HC"',['22']),
    ('Fs->answer==22 && !Fs->new_answer;',['1']),
    ('#include "C:/Probe/PromptVoid.HC"',[]),
    ('Fs->answer==0 && !Fs->new_answer;',['1']),
    ('U0 PromptExplicit(){"MARK\\n";}PromptExplicit;',['MARK']),
    ('Fs->answer==0 && !Fs->new_answer;',['1']),
    ('U0 PromptNested(){CDoc *d=DocNew;DocPrint(d,"11;22;");ExeDoc(d);DocDel(d);}PromptNested;',[]),
    ('Fs->answer==0 && !Fs->new_answer;',['1']),
    ('ExePutS("11;22;");',['22']),
    ('22;',['22']),
    ('I64 PromptDeclarationOnly;',[]),
    ('Fs->answer==22 && !Fs->new_answer;',['1']),
    ('1.5+2.25;',['3.75']),
    ('0(U8 *);',['0x0']),
    ('0xFFFFFFFFFFFFFFFF(U64);',['18446744073709551615']),
    ('-1;',['-1']),
    ('41;Unknown prompt_bad;',['Error: Undefined identifier at ','41']),
    ('Fs->answer==41 && !Fs->new_answer;',['1']),
    ('CDoc *PromptInitDoc=DocNew;',[]),
    ('DocPrint(PromptInitDoc,"11;22;");I64 PromptInitValue=ExeDoc(PromptInitDoc);',['22']),
    ('PromptInitValue==22 && Fs->answer==22 && !Fs->new_answer;',['1']),
    ('DocDel(PromptInitDoc);',[]),
    ('CDoc *PromptInitFloatDoc=DocNew;',[]),
    ('DocPrint(PromptInitFloatDoc,"1.5+2.25;");F64 PromptInitFloat=ExeDoc(PromptInitFloatDoc)(F64);',['3.75']),
    ('PromptInitFloat==3.75 && Fs->answer(F64)==3.75 && !Fs->new_answer;',['1']),
    ('DocDel(PromptInitFloatDoc);',[]),
    ('CDoc *PromptInitPointerDoc=DocNew;',[]),
    ('DocPrint(PromptInitPointerDoc,"0(U8 *);");U8 *PromptInitPointer=ExeDoc(PromptInitPointerDoc)(U8 *);',['0x0']),
    ('PromptInitPointer==0 && Fs->answer==0 && !Fs->new_answer;',['1']),
    ('DocDel(PromptInitPointerDoc);',[]),
    ('6*7;',['42']),
]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path);parser.add_argument('--reference',type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True);args=parser.parse_args()
    source=args.disk.resolve();ref=args.reference.resolve();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    if any(len(c[0])>255 for c in COMMANDS):raise ValueError('Input exceeds native buffer')
    reference=json.loads((ref/'result.json').read_text())
    if reference.get('result')!='pass' or not reference.get('inputs_unchanged') or len(reference.get('records',[]))!=9:raise ValueError('Invalid original reference')
    fixture=ROOT/'tests/guest/i386-answer-prompt-reference'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    for name in ['Values.HC','VoidEnd.HC']:
        keys=[k for k in reference['input_sha256'] if k.endswith('/i386-answer-prompt-reference/'+name)]
        if len(keys)!=1 or sha(fixture/name)!=reference['input_sha256'][keys[0]]:raise ValueError('Fixture differs from original capture')
    paths=[source,ref/'result.json',Path(__file__).resolve(),fixture/'Values.HC',fixture/'VoidEnd.HC',
        ROOT/'tools/i386-kernel-input.py',ROOT/'tools/build-i386-kernel.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths};out.mkdir(parents=True);working=out/'working.img'
    report=dict(result='fail',input_sha256=pins,commands=COMMANDS,
        scope='Original-derived final-answer/include/void/explicit-output/nested-document semantics, prompt task state, declaration-only preservation and scalar formatting at 8 MiB; native numeric answer format retained, not original timing/header formatting')
    try:
        package=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package']
        report['packaging']=package(source,working,additions={'/Probe/PromptValues.HC':(fixture/'Values.HC').read_bytes(),'/Probe/PromptVoid.HC':(fixture/'VoidEnd.HC').read_bytes()})
        report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
            working,out/'qemu',snapshot=False,ram_mib=8,cpu='486,-fpu',accel='kvm',qmp_stdio=True,
            welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],
                'commands':COMMANDS,'pause_window_manager':False})
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        saved=build['mutated_file_contents'](working,{'/Probe/PromptValues.HC','/Probe/PromptVoid.HC'})
        if saved!={'/Probe/PromptValues.HC':(fixture/'Values.HC').read_bytes(),'/Probe/PromptVoid.HC':(fixture/'VoidEnd.HC').read_bytes()}:raise ValueError('Persisted fixture differs')
        report.update(result='pass',filesystem=build['verify_mutated_volume'](working))
    except Exception as exc:
        report['error']=str(exc);raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Answer prompt workflow failed')


if __name__=='__main__':main()
