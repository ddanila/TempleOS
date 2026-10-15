#!/usr/bin/env python3
"""Require safe displayed-document replacement and fresh renderer recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT/'tools/test-i386-render-owner-retire.py'
COMMANDS = list(runpy.run_path(str(BASE))['COMMANDS'][:-1])
COMMANDS += [
    ('CDoc *rp_old,*rp_saved;Bool rp_replaced;', []),
    ('U0 RPReplace(U8 *data){rp_old=rt_doc;rt_doc=DocNew("Replacement.DD",rt_owner);rt_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;RTEntry(&RTTag);rt_owner->display_doc=rt_doc;DocDel(rp_old);rp_replaced=TRUE;}', []),
    ('U0 RPSetup(){rp_saved=Fs->display_doc;rp_replaced=FALSE;RTDocSetup(8);Fs->display_doc=rt_doc;rt_deleter=Spawn(&RPReplace,NULL,"Replace document",-1,Fs,8192);RTTurn;}', []),
    ('I64 RPBegin(){I64 m=0;RPSetup;if(rt_live&&rt_worker!=Fs)m|=1;if(rp_replaced&&!TaskValidate(rt_worker))m|=2;else Kill(rt_worker,TRUE,FALSE);while(TaskValidate(rt_deleter))Yield;RTTurn;FlushMsgs;if(!rt_returned&&!rt_error)m|=4;return m;}', []),
    ('U0 RPStartFresh(){rt_mode=7;rt_stage=0;rt_returned=FALSE;RTStartWorker;while(TaskValidate(rt_worker))Yield;RTTurn;FlushMsgs;}', []),
    ('I64 RPCheck(I64 m){if(rt_returned&&!rt_error&&rt_live&&!rt_doc->owning_task&&!StrCmp(rt_doc->head.next(CDocEntry *)->tag,"alive"))m|=16;return m;}', []),
    ('I64 RPFresh(I64 m){if(Fs->display_doc==rt_doc&&rt_doc!=rp_old&&rt_doc->doc_signature==DOC_SIGNATURE_VAL)m|=8;RPStartFresh;return RPCheck(m);}', []),
    ('I64 RPFinish(I64 m){Fs->display_doc=rp_saved;DocDel(rt_doc);if(Fs->data_heap->used_u8s==rt_before)m|=32;if(NativeGraphicsPresent())m|=64;if(NativeTextBasePresent())m|=128;NativeTextBaseRestore;return m;}', []),
    ('RPFinish(RPFresh(RPBegin));', ['255']),
    ('6*7;', ['42']),
]


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
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve(), BASE]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Displayed document replacement during an independent yielding render, cancellation and fresh renderer recovery with exact heap; includes owner-retirement regression; not scheduled refresh',
                  input_sha256=pins, commands=commands)
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
