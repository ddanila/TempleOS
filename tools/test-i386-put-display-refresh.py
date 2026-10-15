#!/usr/bin/env python3
"""Require automatic frames when put_doc and display_doc name the same document."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('CDoc *ar_doc,*ar_display,*ar_put;I64 ar_calls=0,ar_attr;U8 ar_phase=65;', []),
    ('U0 ARLog(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
    ('U8 *ARTag(CDoc *d,CDocEntry *e,CTask *t){U8 s[2];ar_calls++;s[0]=ar_phase;s[1]=0;return StrNew(s,t);}', []),
    ('U0 AREntry(){CDocEntry *e=CAlloc(sizeof(CDocEntry));e->type=DOCT_TEXT;e->de_flags=DOCEF_TAG|DOCEF_TAG_CB;e->tag=StrNew("");e->tag_cb=&ARTag;DocInsEntry(ar_doc,e);}', []),
    ('U0 ARSetup(){ar_attr=Fs->text_attr;ar_display=Fs->display_doc;ar_put=Fs->put_doc;ar_doc=DocNew("Automatic.DD");ar_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;Fs->text_attr=0xF0;AREntry;Fs->display_doc=Fs->put_doc=ar_doc;}', []),
    ('U0 ARFinish(){Fs->display_doc=ar_display;Fs->put_doc=ar_put;Fs->text_attr=ar_attr;DocDel(ar_doc);NativeTextBaseRestore;}', []),
    ('I64 ARView(){I64 before,ok;ARSetup;Refresh(2);ARLog("DOC AUTO first\\n");GetKey;before=ar_calls;ar_phase=66;Refresh(2);ARLog("DOC AUTO second\\n");GetKey;ok=before>=2&&ar_calls>=before+2;ARFinish;ARLog("DOC AUTO end\\n");return ok;}', []),
]

COMMANDS.append(('ARView;',['1'],{
    'begin':'DOC AUTO first\n','initial_rows':['A'],
    'events':[{'key':'spc'},{'wait_log':'DOC AUTO second\n'}],
    'final_rows':['B'],'preserve_history':True,'exit_key':'esc','end':'DOC AUTO end\n'}))
COMMANDS.append(('6*7;',['42']))

if any(len(c[0])>255 for c in COMMANDS):
    raise ValueError("Put/display fixture exceeds native input limit")


def serializable(value):
    if isinstance(value,dict):
        return {str(key):serializable(item) for key,item in value.items()}
    if isinstance(value,(list,tuple)):
        return [serializable(item) for item in value]
    if isinstance(value,set):
        return [serializable(item) for item in sorted(value)]
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, ROOT/'Kernel/FontStd.HC', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Same document in put/display roles: public Refresh(2), two dynamic A/B evaluations, independent full-window glyphs, restore both pointers and continued input; not default transcript/editor composition',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':False,
                           'rejection_prefixes':('INPUT REJECT ',),
                           'command_timeout':30})
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
