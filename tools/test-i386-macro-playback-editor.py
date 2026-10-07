#!/usr/bin/env python3
"""Require original macro serialization and playback services in the installed guest."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('class MDRecorded:CJob{I64 arrival;U64 signature;};', []), ('CTask *md_owner=Fs,*md_worker;CDoc *md_doc;', []), ('U0 MDAdd(I64 ch,I64 when){MDRecorded *j=CAlloc(sizeof(MDRecorded));j->job_code=1;j->msg_code=2;j->aux1=ch;j->arrival=when;j->signature=0x54494D454B455931;QueIns(j,sys_macro_head.last);}', []), ("U0 MDBuild(){if(sys_macro_head.next!=&sys_macro_head)throw('MacroTst');MDAdd(65,0x100000001);MDAdd(66,0x200000001);sys_focus_task=Fs;}", []), ('MDBuild;', []), ('I64 MDTextLenUnlocked(CDoc *d){CDocEntry *e;I64 n=0;for(e=d->head.next;e!=d;e=e->next){if(e->type_u8==DOCT_TEXT&&e->tag)n+=StrLen(e->tag);if(e->type_u8==DOCT_NEW_LINE)n++;}return n;}', []), ('I64 MDTextLen(CDoc *d){Bool unlock=DocLock(d);I64 n=MDTextLenUnlocked(d);if(unlock)DocUnlock(d);return n;}', []), ('U0 MDWorker(U8 *data){CDoc *doc=data;while(md_owner->display_doc!=doc)Sleep(1);while(MDTextLen(doc)==0)Sleep(1);Sleep(2000);PlaySysMacro(1);}', []), ('U0 MDStart(){md_doc=DocNew("C:/MacroUndo.HC",Fs);md_worker=Spawn(&MDWorker,md_doc,"Macro undo playback",-1,Fs);}', []), ('MDStart;', []), ('DocEd(md_doc);', ['1'], {'begin': 'DOC EDIT begin\n', 'end': 'DOC EDIT end\n', 'initial_rows': ['TempleOS i386', 'DolDoc editor', 'C:/MacroUndo.HC', '', '█'], 'events': [{'text': 'x'}, {'expect_rows': ['TempleOS i386', 'DolDoc editor', 'C:/MacroUndo.HC', '', 'x█'], 'label': 'baseline-input'}, {'expect_rows': ['TempleOS i386', 'DolDoc editor', 'C:/MacroUndo.HC', '', 'xAB█'], 'label': 'macro-replayed'}, {'alt_key': 'backspace'}, {'expect_rows': ['TempleOS i386', 'DolDoc editor', 'C:/MacroUndo.HC', '', 'x█'], 'label': 'macro-group-undone'}, {'alt_key': 'backspace'}, {'expect_rows': ['TempleOS i386', 'DolDoc editor', 'C:/MacroUndo.HC', '', '█'], 'label': 'baseline-undone'}], 'final_rows': ['TempleOS i386', 'DolDoc editor', 'C:/MacroUndo.HC', '', '█']}), ('TaskValidate(md_worker);', ['0']), ('MDTextLen(md_doc);', ['0']), ('sys_macro_head.next(MDRecorded *)->arrival==0x100000001&&sys_macro_head.last(MDRecorded *)->arrival==0x200000001;', ['1']), ('U0 MDFree(){CJob *j;DocDel(md_doc);while(sys_macro_head.next!=&sys_macro_head){j=sys_macro_head.next;QueRem(j);Free(j);}}', []), ('MDFree;', []), ('6*7;', ['42'])]


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
                  scope='Actual PlaySysMacro into active DolDoc editor; stale separated private timestamps remain in stored jobs while replay AB undoes as one group, separate from earlier host x; exact VGA, worker retirement, empty document and continued console use; not full resource qualification')
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
            report.update(result='fail', error='Macro-playback fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Macro-playback prerequisites failed'))


if __name__ == '__main__':
    main()
