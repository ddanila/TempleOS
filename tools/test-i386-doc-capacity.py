#!/usr/bin/env python3
"""Check reuse of owned DolDoc text capacity without changing edit results."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('I64 Cap(){CDoc *d=DocNew;CDocEntry *e;U8 *old;I64 ok;DocPutKey(d,97);e=d->head.next;old=e->tag;d->cur_entry=e;d->cur_col=1;DocPutKey(d,98);ok=e->tag==old&&e->max_col==2&&d->cur_col==2&&StrCmp(e->tag,"ab")==0;DocDel(d);return ok;}', []),
    ('Cap;', ['1']),
    ('I64 Mid(){CDoc *d=DocNew;CDocEntry *e;U8 *p;I64 ok;DocPutS(d,"abcd");e=d->head.next;p=e->tag;d->cur_entry=e;d->cur_col=2;DocPutKey(d,88);ok=e->tag==p&&d->cur_col==3&&StrCmp(e->tag,"abXcd")==0;DocDel(d);return ok;}', []),
    ('Mid;', ['1']),
    ('I64 Grow(){CDoc *d=DocNew;CDocEntry *e;U8 *p;I64 ok;DocPutS(d,"abc");e=d->head.next;p=e->tag;d->cur_entry=e;d->cur_col=3;DocPutKey(d,100);ok=e->tag!=p&&d->cur_col==4&&StrCmp(e->tag,"abcd")==0;DocDel(d);return ok;}', []),
    ('Grow;', ['1']),
    ('CDoc *AlignedDoc(){CDoc *d=DocNew;CDocEntry *e;DocPutKey(d,97);e=d->head.next;Free(e->tag);e->tag=MAllocAligned(4,8);StrCpy(e->tag,"abc");e->max_col=3;d->cur_entry=e;d->cur_col=3;return d;}', []),
    ('I64 Al(){CDoc *d=AlignedDoc;CDocEntry *e=d->head.next;U8 *p=e->tag;I64 ok;DocPutKey(d,100);ok=e->tag!=p&&StrCmp(e->tag,"abcd")==0;DocDel(d);return ok;}', []),
    ('Al;', ['1']),
    ('DocAllocationCheck;', ['13']),
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
    report = dict(result='running', scope='Owned text-capacity reuse, insertion contents/cursor and existing allocation-unwind checks; not complete document or OS qualification',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejected_answers':['0'], 'rejection_prefixes':('INPUT REJECT ',),
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
