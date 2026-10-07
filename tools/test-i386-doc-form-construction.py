#!/usr/bin/env python3
"""Require bound DolDoc form fields and action buttons for the original macro utility."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def commands(construction_only=False):
    checks = [('#include "/Kernel/SymbolTypes.HH"', []), ('I64 DFPrereq(){I64 m=0;if(HashFind("DocPrint",Fs->hash_table,~0))m|=1;if(HashFind("DocDataFmt",Fs->hash_table,~0))m|=2;if(HashFind("DocMenu",Fs->hash_table,~0))m|=4;return m;}', []), ('DFPrereq;', ['7']), ('CDoc *df_doc=DocNew("C:/Form.DD",Fs);CDocEntry *df_name,*df_repeat,*df_button;U8 df_value[STR_LEN];StrCpy(df_value,"386");I64 df_n=3;', []), ('df_name=DocPrint(df_doc,"$$DA-P,LEN=STR_LEN-1,A=\\"Name:%%s\\"$$");', []), ('df_name!=NULL&&df_name->type_u8==DOCT_DATA&&df_name->len==STR_LEN-1;', ['1']), ('df_name->data=df_value;DocDataFmt(df_doc,df_name);StrCmp(df_name->tag,"Name:386_")==0;', ['1']), ('df_repeat=DocPrint(df_doc,"\\n$$DA,A=\\"Repeat N:%%d\\"$$");', []), ('df_repeat->data=&df_n;DocDataFmt(df_doc,df_repeat);StrCmp(df_repeat->tag,"Repeat N:3_")==0;', ['1']), ('df_button=DocPrint(df_doc,"\\n$$BT,\\"PLAY\\",LE=2$$");', []), ('df_button!=NULL&&df_button->type_u8==DOCT_BTTN&&df_button->left_exp==2&&StrCmp(df_button->tag,"PLAY")==0;', ['1']), ('StrCpy(df_value,"VGA");df_n=7;DocDataFmt(df_doc,df_name);DocDataFmt(df_doc,df_repeat);', []), ('StrCmp(df_name->tag,"Name:VGA_")==0&&StrCmp(df_repeat->tag,"Repeat N:7_")==0;', ['1']), ('DocDel(df_doc);', []), ('6*7;', ['42'])]
    checks.insert(-2, ('U8 *df_plain=StrNew("plain");', []))
    checks.insert(-2, ('DocPutS(df_doc,df_plain)==NULL;', ['1']))
    checks.insert(-2, ('Free(df_plain);', []))
    checks.insert(-2, ('CDocEntry *df_last=DocPrint(df_doc,"$$BT,\\\"FIRST\\\",LE=1$$text$$BT,\\\"LAST\\\",LE=7$$");', []))
    checks.insert(-2, ('df_last!=NULL&&df_last->left_exp==7&&StrCmp(df_last->tag,"LAST")==0;', ['1']))
    #Use void helpers so the console does not print assignment pointers.
    expanded = []
    for command, answers in checks:
        if not answers and command.startswith(('df_name=DocPrint(', 'df_repeat=DocPrint(', 'df_button=DocPrint(')):
            helper_name = 'DFSet' + command.split('=')[0].removeprefix('df_').capitalize()
            expanded += [('U0 ' + helper_name + '(){' + command + '}', []), (helper_name + ';', [])]
        else:
            expanded.append((command, answers))
    normalized = []
    for index, (command, answers) in enumerate(expanded):
        if command.startswith(('df_name->data=', 'df_repeat->data=', 'StrCpy(df_value,')):
            prefix, expression = command.rstrip(';').rsplit(';', 1) if answers else (command.rstrip(';'), '')
            name = f'DFSetup{index}'
            normalized += [('U0 ' + name + '(){' + prefix + ';}', []), (name + ';', [])]
            if answers:
                normalized.append((expression + ';', answers))
        else:
            normalized.append((command, answers))
    checks = normalized
    if construction_only:
        checks[1] = (checks[1][0].replace('if(HashFind("DocMenu",Fs->hash_table,~0))m|=4;', ''), [])
        checks[2] = ('DFPrereq;', ['3'])
    return checks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, nargs='?')
    parser.add_argument('--original', action='store_true')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--construction-only', action='store_true',
                        help='Require DocPrint and DocDataFmt; leave the separate DocMenu gate open')
    args = parser.parse_args()
    if args.original == bool(args.disk):
        parser.error('Choose --original or a native disk')
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    files = [Path(__file__)]
    if args.original:
        files += [ROOT / p for p in ('Adam/DolDoc/DocPutS.HC', 'Adam/DolDoc/DocPutSCore.HC', 'Adam/DolDoc/DocPlain.HC', 'Adam/DolDoc/DocDollarParseCore.HC', 'Adam/DolDoc/DocDollarFlagsCore.HC', 'Adam/DolDoc/DocDollarServices.HH', 'Adam/DolDoc/DocFormDataCore.HC', 'tools/build-iso.py', 'tools/guest-run.py')]
    else:
        files += [args.disk, helper]
    pins = {str(p.resolve()): sha(p) for p in files}
    report = dict(result='running', input_sha256=pins, disk_policy='writable copy',
                  scope='Bound DolDoc name/repeat data fields and PLAY button: original commands, pointer binding, formatting and refresh after value changes; prerequisite DocPrint/DocDataFmt/DocMenu; chooser interaction and resource faults not covered')
    report['construction_only'] = args.construction_only
    if args.construction_only:
        report['scope'] = report['scope'].replace('DocPrint/DocDataFmt/DocMenu', 'DocPrint/DocDataFmt')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        if args.original:
            overlay = args.out / 'overlay'
            overlay.mkdir()
            source = 'U0 DFReport(U8 *s){while(*s)OutU8(0xE9,*s++);}' + chr(10)
            assertions = 0
            for command, answers in commands(args.construction_only):
                if not answers:
                    source += command + chr(10)
                else:
                    prefix, expression = command.rstrip(';').rsplit(';', 1) if ';' in command.rstrip(';') else ('', command.rstrip(';'))
                    if prefix:
                        source += prefix + ';' + chr(10)
                    assertions += 1
                    source += f'if(({expression})!={answers[0]})DFReport("FAIL construction check {assertions}\\n");' + chr(10)
            source += 'DFReport("DONE construction oracle\\n");' + chr(10)
            (overlay / 'Once.HC').write_text(source)
            iso = args.out / 'original.iso'
            subprocess.run([sys.executable, str(ROOT/'tools/build-iso.py'), '--overlay', str(ROOT/'build/rebuild-test/overlay'), '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
            subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(iso), '--out', str(args.out/'behavior'), '--timeout', '90', '--qmp-stdio'], cwd=ROOT, check=True)
            log = (args.out/'behavior/debug.log').read_text()
            if 'DONE construction oracle\n' not in log or 'FAIL construction check' in log:
                raise ValueError('Original construction assertions did not pass')
            report['behavior'] = dict(result='pass', assertions=assertions, scope='Original construction only; no chooser interaction')
        else:
            disk = args.out / 'working.img'
            shutil.copyfile(args.disk, disk)
            report['behavior'] = runpy.run_path(str(helper))['run_input'](
                disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
                startup_check={'status': 'ok', 'answers': [], 'commands': commands(args.construction_only)})
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [path for path, digest in pins.items() if sha(Path(path)) != digest]
        if changed:
            report.update(result='fail', error='Macro-playback fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Macro-playback prerequisites failed'))


if __name__ == '__main__':
    main()
