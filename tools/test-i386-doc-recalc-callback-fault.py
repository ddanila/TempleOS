#!/usr/bin/env python3
"""Check document recalculation callback exceptions, retained tag, lock/alias cleanup and retry."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('CDoc *dr_doc;CDocEntry *dr_entry;U8 *dr_tag;I64 dr_mode;Bool dr_caught;', []),
    ('U8 *DRTag(CDoc *d,CDocEntry *e,CTask *t){if(dr_mode)throw(\'TagFail\');return StrNew("ready",t);}', []),
    ('U0 DREntry(){dr_entry=CAlloc(sizeof(CDocEntry));dr_entry->type=DOCT_TEXT;dr_entry->de_flags=DOCEF_TAG|DOCEF_TAG_CB;dr_entry->tag=StrNew("keep");dr_entry->tag_cb=&DRTag;DocInsEntry(dr_doc,dr_entry);}', []),
    ('U0 DRSetup(){dr_doc=DocNew("RenderFault.DD");dr_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;DREntry;dr_tag=dr_entry->tag;dr_mode=1;}', []),
    ("U0 DRTry(){dr_caught=FALSE;try{DocRecalc(dr_doc,RECALCt_TO_SCRN);}catch{dr_caught=Fs->except_ch=='TagFail';Fs->catch_except=TRUE;}}", []),
    ('I64 DRState(I64 base){I64 m=0;if(!Bt(&dr_doc->locked_flags,DOClf_LOCKED))m|=1;if(!dr_doc->owning_task)m|=2;if(dr_entry->tag==dr_tag)m|=4;if(Fs->data_heap->used_u8s==base)m|=8;return m;}', []),
    ('Bool DRRetry(){dr_mode=0;DocRecalc(dr_doc,RECALCt_TO_SCRN);return !StrCmp(dr_entry->tag,"ready")&&!dr_doc->owning_task;}', []),
    ('I64 DRRun(){I64 before=Fs->data_heap->used_u8s,base,m;DRSetup;base=Fs->data_heap->used_u8s;DRTry;m=DRState(base);if(!dr_caught)return -1;if(m!=15)return m;if(!DRRetry)return -2;DocDel(dr_doc);if(Fs->data_heap->used_u8s==before)m|=16;return m;}', []),
    ('DRRun;', ['31']),
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
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='TO_SCRN dynamic tag throws: old tag pointer preserved, lock/owner and drawing-alias heap recovery; successful retry and exact caller heap after DocDel; not every renderer fault or worker lifecycle',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['4'],
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
