#!/usr/bin/env python3
"""Check canonical DolDoc line extraction needed by original GetStr."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('CDoc *ScanDoc=DocNew;U8 *ScanResult;CDocEntry *ScanEnd;I64 ScanColumn;', []),
    ('U0 ScanEmpty(){ScanResult=DocScanLine(ScanDoc,ScanDoc,&ScanColumn,&ScanEnd);}', []),
    ('ScanEmpty;', []),
    ('StrLen(ScanResult)==0&&ScanEnd==ScanDoc&&ScanColumn==0;', ['1']),
    ('U0 ScanFill(){Free(ScanResult);DocPutS(ScanDoc,"alpha\\tbeta\\nsecond");ScanResult=DocScanLine(ScanDoc,ScanDoc->head.next,NULL,&ScanEnd);}', []),
    ('ScanFill;', []),
    ('StrCmp(ScanResult,"alpha\\tbeta")==0&&ScanEnd->type_u8==DOCT_NEW_LINE;', ['1']),
    ('U0 ScanSecond(){Free(ScanResult);ScanResult=DocScanLine(ScanDoc,ScanEnd->next,NULL,&ScanEnd);}', []),
    ('ScanSecond;', []),
    ('StrCmp(ScanResult,"second")==0&&ScanEnd==ScanDoc;', ['1']),
    ('U0 ScanCursor(){Free(ScanResult);ScanDoc->cur_entry=ScanDoc->head.next;ScanDoc->cur_col=2;ScanResult=DocScanLine(ScanDoc,ScanDoc->head.next,&ScanColumn,&ScanEnd);}', []),
    ('ScanCursor;', []),
    ('ScanColumn==2;', ['1']),
    ('U0 ScanShift(){Free(ScanResult);DocRst(ScanDoc,TRUE);DocPutS(ScanDoc,"$$SX,-3$$$$SY,2$$");ScanResult=DocScanLine(ScanDoc,ScanDoc->head.next,NULL,&ScanEnd);}', []),
    ('ScanShift;', []),
    ('StrCmp(ScanResult,"$SX,-3$$SY,2$")==0&&ScanEnd==ScanDoc;', ['1']),
    ('Free(ScanResult);DocDel(ScanDoc);6*7;', ['42'])]


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
    report = dict(result='running', scope='DocScanLine empty/text/tab/newline/end-entry and cursor extraction; not full GetStr qualification',
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
