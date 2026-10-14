#!/usr/bin/env python3
"""Check typed DolDoc dollar state required by original inline input."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('U0 DollarFeed(CDoc *d,U8 *s){while(*s)DocPutKey(d,*s++);}', []),
    ('I64 DollarLine(CDoc *d,U8 *wanted){U8 *s=DocScanLine(d,d->head.next);I64 ok=StrCmp(s,wanted)==0;Free(s);return ok;}', []),
    ('U0 DollarGrow(CDoc *d){I64 i;DocPutKey(d,36);for(i=0;i<200;i++)DocPutKey(d,120);}', []),
    ('U0 DollarPlain(CDoc *d){DocRst(d,TRUE);d->flags|=DOCF_PLAIN_TEXT;DollarFeed(d,"\\x24RED\\x24cash\\x24\\x24");}', []),
    ('CDoc *DollarDoc=DocNew;', []),
    ('DollarFeed(DollarDoc,"\\x24R");', []),
    ('(DollarDoc->flags&DOCF_IN_DOLLAR)!=0&&DollarDoc->dollar_buf_ptr==2&&DollarLine(DollarDoc,"");', ['1']),
    ('DollarFeed(DollarDoc,"ED\\x24cash\\x24\\x24");', []),
    ('DollarLine(DollarDoc,"cash\\x24")&&!(DollarDoc->flags&DOCF_IN_DOLLAR)&&DollarDoc->dollar_buf_ptr==0;', ['1']),
    ('DollarDoc->head.next->type_u8==DOCT_FOREGROUND&&DollarDoc->head.next(CDocEntry *)->attr==RED;', ['1']),
    ('#define FG 123', []),
    ('DocRst(DollarDoc,TRUE);DollarFeed(DollarDoc,"\\x24FG,RED\\x24");', []),
    ('DollarDoc->head.next->type_u8==DOCT_FOREGROUND&&DollarDoc->head.next(CDocEntry *)->attr==RED;', ['1']),
    ('DocRst(DollarDoc,TRUE);', []),
    ('DollarFeed(DollarDoc,"\\x24\\x24RED\\x24\\x24cash\\x24\\x24\\x24\\x24");', []),
    ('DollarLine(DollarDoc,"\\x24RED\\x24cash\\x24\\x24");', ['1']),
    ('DollarPlain(DollarDoc);', []),
    ('DollarLine(DollarDoc,"\\x24RED\\x24cash\\x24\\x24")&&!(DollarDoc->flags&DOCF_IN_DOLLAR);', ['1']),
    ('DocRst(DollarDoc,TRUE);DollarGrow(DollarDoc);', []),
    ('DollarDoc->dollar_buf_ptr==201&&DollarDoc->dollar_buf_size>=203&&DollarLine(DollarDoc,"");', ['1']),
    ('DocDel(DollarDoc);', []), ('6*7;', ['42'])]


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
    report = dict(result='running', scope='Typed dollar partial state, parsed foreground entry, command-name macro suppression with attribute expression expansion, escaped dollars, plain-text bypass and buffer growth; not GetStr or complete DocPutKey compatibility',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['0'],
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
