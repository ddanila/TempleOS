#!/usr/bin/env python3
"""Check same-run and separated-run undo with explicit keyboard injection mode."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(batch=True):
    cursor = bytes([0xDB]).decode('cp437')
    heading = ['TempleOS i386', 'DolDoc editor', 'C:/UndoTiming.HC', '']
    rows = lambda text: heading + [text + cursor]
    return [
        ('CDoc *undo_timing=DocNew("C:/UndoTiming.HC",Fs);', []),
        ('DocEd(undo_timing);', ['1'], dict(
            begin='DOC EDIT begin\n', end='DOC EDIT end\n', initial_rows=rows(''),
            events=[{'batch_text' if batch else 'text':'abc'},
                    {'expect_rows':rows('abc'), 'label':'typing-run'},
                    {'alt_key':'backspace'},
                    {'expect_rows':rows(''), 'label':'typing-run-undone'},
                    {'text':'a'}, {'delay':2.0}, {'text':'b'},
                    {'expect_rows':rows('ab'), 'label':'separated-runs'},
                    {'alt_key':'backspace'},
                    {'expect_rows':rows('a'), 'label':'second-run-undone'},
                    {'alt_key':'backspace'},
                    {'expect_rows':rows(''), 'label':'first-run-undone'}], final_rows=rows(''))),
        ('DocDel(undo_timing);', []), ('6*7;', ['42'])]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--serialized',action='store_true',help='Use separate QMP calls for each key')
    parser.add_argument('--writable-copy',action='store_true',help='Run on a fresh disk copy without QEMU snapshot temporary files')
    args=parser.parse_args()
    if args.out.exists():parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
    helper=ROOT/'tools/i386-kernel-input.py'
    inputs={str(path.resolve()):sha(path) for path in (args.disk,helper,Path(__file__))}
    report=dict(result='running',input_sha256=inputs,
                injection='serialized' if args.serialized else 'single QMP batch',
                scope='Continuous typing undo and two-second-separated runs, exact VGA; not all undo behavior or resource qualification')
    disk=args.disk
    if args.writable_copy:
        disk=args.out/'working.img'
        shutil.copyfile(args.disk,disk)
    report['disk_policy']='writable copy' if args.writable_copy else 'QEMU snapshot'
    try:
        report['behavior']=runpy.run_path(str(helper))['run_input'](
            disk,args.out/'behavior',cpu='486,-fpu',qmp_stdio=True,
            snapshot=not args.writable_copy,
            startup_check={'status':'ok','answers':[],'commands':commands(not args.serialized)})
        report['result']='pass'
    except Exception as error:
        report.update(result='fail',error=str(error))
        raise
    finally:
        if any(sha(Path(p))!=digest for p,digest in inputs.items()):
            report.update(result='fail',error='Undo fixture inputs changed')
        (args.out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
