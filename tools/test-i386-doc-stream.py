#!/usr/bin/env python3
"""Check the public streaming DolDoc output contract against original behavior."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [('I64 StreamLine(CDoc *d,U8 *wanted){U8 *s=DocScanLine(d,d->head.next);I64 ok=StrCmp(s,wanted)==0;Free(s);return ok;}', []), ('CDoc *StreamDoc=DocNew;', []), ('DocPrintPartial(StreamDoc,"left\\x24R");', []), ('StreamLine(StreamDoc,"left")&&(StreamDoc->flags&DOCF_IN_DOLLAR)&&StreamDoc->dollar_buf_ptr==2;', ['1']), ('DocPrintPartial(StreamDoc,"ED\\x24cash\\x24");', []), ('(StreamDoc->flags&DOCF_IN_DOLLAR)!=0&&StreamDoc->dollar_buf_ptr==1;', ['1']), ('DocPrintPartial(StreamDoc,"\\x24right");', []), ('StreamLine(StreamDoc,"leftcash\\x24right")&&!(StreamDoc->flags&DOCF_IN_DOLLAR)&&StreamDoc->dollar_buf_ptr==0;', ['1']), ('DocRst(StreamDoc,TRUE);StreamDoc->flags|=DOCF_PLAIN_TEXT;', []), ('DocPrintPartial(StreamDoc,"\\x24RED\\x24cash\\x24\\x24");', []), ('StreamLine(StreamDoc,"\\x24RED\\x24cash\\x24\\x24");', ['1']), ('DocRst(StreamDoc,TRUE);StreamDoc->flags&=~DOCF_PLAIN_TEXT;', []), ('DocPrintPartial(StreamDoc,"abcd");', []), ('StreamDoc->cur_entry=StreamDoc->head.next;StreamDoc->cur_col=2;', []), ('DocPrintPartial(StreamDoc,"%s","XY");', []), ('StreamLine(StreamDoc,"abXYcd");', ['1']), ('DocDel(StreamDoc);', []), ('6*7;', ['42'])]


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
    report = dict(result='running', scope='Explicit-document streaming output: partial markup, completion, split escape, plain-text bypass and middle insertion; not default console rendering or complete DocPrintPartial parity',
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
