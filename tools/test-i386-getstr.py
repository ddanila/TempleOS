#!/usr/bin/env python3
"""Check public GetStr against observed original-system input semantics."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('U8 *(*InputSaved)(I64 flags);I64 InputFlags;CDoc *InputOld=Fs->put_doc,*InputDoc=DocNew;', []),
    ('U8 *InputHook(I64 flags){InputFlags=flags;if(flags&1)return StrNew("hook");return StrNew("");}', []),
    ('Bool InputHookRead(U8 *msg,U8 *dft,I64 flags,U8 *expected){Fs->put_doc=InputDoc;U8 *s=GetStr(msg,dft,flags);Fs->put_doc=InputOld;Bool ok=InputFlags==flags&&!StrCmp(s,expected);Free(s);return ok;}', []),
    ('Bool InputPrompt(){U8 *s=DocScanLine(InputDoc,InputDoc->head.next);Bool ok=!StrCmp(s,"promptfallback:");Free(s);return ok;}', []),
    ('U0 InputHookStart(){InputSaved=fp_getstr2;fp_getstr2=&InputHook;}', []),
    ('InputHookStart;', []),
    ('InputHookRead("prompt%s:","fallback",0x1235,"hook");', ['1']),
    ('InputPrompt;', ['1']),
    ('InputHookRead(NULL,"fallback",0x1234,"fallback");', ['1']),
    ('U0 InputHookEnd(){fp_getstr2=InputSaved;DocDel(InputDoc);}', []),
    ('InputHookEnd;', []),
    ('I64 InputCheck(U8 *keys,U8 *expected,U8 *dft=NULL,I64 flags=0){U8 *result;I64 ok;In("%s",keys);result=GetStr(NULL,dft,flags);ok=StrCmp(result,expected)==0;Free(result);return ok;}', []),
    ('InputCheck("alpha\\n","alpha");', ['1']),
    ('InputCheck("\\n","");', ['1']),
    ('InputCheck("\\n","fallback","fallback");', ['1']),
    ('InputCheck("alpha\\nbeta\\n\\x1B","alpha\\nbeta\\n",NULL,GSF_WITH_NEW_LINE);', ['1']),
    ('InputCheck("discard\\x1C","");', ['1']),
    ('InputCheck("discard\\x1C","fallback","fallback");', ['1']),
    ('InputCheck("abc\\x08Z\\n","abZ");', ['1']),
    ('InputCheck("abc\\x08\\x08\\x08\\n","fallback","fallback");', ['1']),
    ('InputCheck("alpha\\tbeta\\n","alpha\\tbeta");', ['1']),
    ('InputCheck("  alpha  \\n","  alpha  ");', ['1']),
    ('InputCheck("\\x24RED\\x24cash\\x24\\x24\\n","cash\\x24");', ['1']),
    ('InputCheck("\\x24\\x24RED\\x24\\x24cash\\x24\\x24\\x24\\x24\\n","\\x24RED\\x24cash\\x24\\x24");', ['1']),
    ('InputCheck("\\x82\\xA3\\n","\\x82\\xA3");', ['1']),
    ('6*7;', ['42'])]


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
    report = dict(result='running', scope='Original GetStr hook, flag forwarding, formatted prompt and thirteen scripted-input cases including backspace, erased default, tabs, spaces, dollar commands/escaping and extended bytes; physical keyboard, navigation/replay and task exit remain open',
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
