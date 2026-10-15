#!/usr/bin/env python3
"""Check protected original task-document updates before scheduled integration."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import struct

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT/'tools/test-i386-render-owner-retire.py'
COMMANDS = list(runpy.run_path(str(BASE))['COMMANDS'][:20])
COMMANDS[3] = ('U0 RTDraw(CDC *dc){DocUpdateTaskDocs(rt_owner);}', [])
COMMANDS += [(f'RTRun({mode});', ['63']) for mode in range(6)]
COMMANDS += [
    ('CDoc *tu_display,*tu_border,*tu_hidden;CD3I64 tu_scroll;Bool tu_called,tu_normal;', []),
    ('U8 *TUTag(CDoc *d,CDocEntry *e,CTask *t){tu_called=Fs!=rt_owner&&d->owning_task==Fs&&!rt_owner->scroll_x&&!rt_owner->scroll_y&&!rt_owner->scroll_z;if(tu_normal)return StrNew("alive",t);Exit;return NULL;}', []),
    ('U0 TUSetup(){RTReset(8);rt_owner=Fs;tu_called=FALSE;tu_display=Fs->display_doc;tu_border=Fs->border_doc;tu_scroll.x=Fs->scroll_x;tu_scroll.y=Fs->scroll_y;tu_scroll.z=Fs->scroll_z;}', []),
    ('U0 TUDocs(){tu_hidden=DocNew("Hidden.DD");tu_hidden->flags|=DOCF_DONT_SHOW;rt_doc=DocNew("Border.DD");rt_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;RTEntry(&TUTag);Fs->display_doc=tu_hidden;Fs->border_doc=rt_doc;}', []),
    ('U0 TUStart(){TUSetup;TUDocs;Fs->scroll_x=17;Fs->scroll_y=23;Fs->scroll_z=29;rt_worker=Spawn(&RTWorker,NULL,"Border update",-1,Fs,16384);while(TaskValidate(rt_worker))Yield;RTTurn;FlushMsgs;}', []),
    ('I64 TUState(){I64 m=0;if(tu_called&&!rt_returned&&!rt_error)m|=1;if(Fs->scroll_x==17&&Fs->scroll_y==23&&Fs->scroll_z==29)m|=2;if(!rt_doc->owning_task&&!Bt(&rt_doc->locked_flags,DOClf_LOCKED))m|=4;return m;}', []),
    ('U0 TURestore(){Fs->display_doc=tu_display;Fs->border_doc=tu_border;Fs->scroll_x=tu_scroll.x;Fs->scroll_y=tu_scroll.y;Fs->scroll_z=tu_scroll.z;DocDel(rt_doc);DocDel(tu_hidden);}', []),
    ('I64 TUFinish(){I64 m;TUStart;m=TUState;TURestore;if(Fs->data_heap->used_u8s==rt_before)m|=8;return RTRetry(m);}', []),
    ('TUFinish;', ['63']),
    ('I64 TUNormal(){I64 m;tu_normal=TRUE;TUStart;m=TUState;if(tu_called&&rt_returned&&!rt_error&&!StrCmp(rt_doc->head.next(CDocEntry *)->tag,"alive"))m|=1;TURestore;if(Fs->data_heap->used_u8s==rt_before)m|=8;return RTRetry(m);}', []),
    ('TUNormal;', ['63']),
    ('6*7;', ['42']),
]
if any(len(source)>255 for source, _ in COMMANDS):
    raise ValueError('Task-document fixture exceeds the interactive line limit')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--legacy-module', type=Path, help='Bind the pre-export internal function using DocNew-relative module offsets')
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    legacy = None
    if args.legacy_module:
        legacy = args.legacy_module.resolve()
        module = legacy.read_bytes()
        _, count, records = struct.unpack_from('<III', module, 16)
        symbols = {}
        for index in range(count):
            kind, offset, name, length = struct.unpack_from('<4I', module, records+16*index)
            if kind == 1:
                symbols[module[name:name+length].decode('ascii')] = offset
        delta = symbols['DocUpdateTaskDocs']-symbols['DocNew']
        binding = f'U0 (*TULegacyUpdate)(CTask *t)=(&DocNew+0)(U64)+({delta});'
        commands[3] = ('U0 RTDraw(CDC *dc){(*TULegacyUpdate)(rt_owner);}', [])
        commands.insert(1, (binding, []))
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve(), BASE]}
    if legacy:
        pins[str(legacy)] = sha(legacy)
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Original task document update under native target scope: independent owner retirement and border callback Exit/scroll recovery; not scheduled refresh',
                  input_sha256=pins, commands=commands, legacy_module=str(legacy) if legacy else None)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['61'],
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
