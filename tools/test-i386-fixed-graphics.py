#!/usr/bin/env python3
"""Check fixed VGA device-context capacity, ownership and graphics behavior."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('NativeGraphicsStart;', ['1']),
    ('gr.dc->width==640&&gr.dc->height==480&&gr.dc2->width==640&&gr.dc2->height==480;', ['1']),
    ('MHeapCtrl(gr.dc->body)==gr.dc->mem_task->data_heap&&MHeapCtrl(gr.dc2->body)==gr.dc2->mem_task->data_heap;', ['1']),
    ('MSize(gr.dc->body)>=307200&&MSize(gr.dc->body)<308224&&MSize(gr.dc2->body)>=307200&&MSize(gr.dc2->body)<308224;', ['1']),
    ('I64 FixedPixelsZero(){I64 i;for(i=0;i<307200;i++)if(gr.dc2->body[i])return 0;return 1;}', []),
    ('FixedPixelsZero;', ['1']),
    ('#include "/Kernel/I386/GraphicsContextCheck.HC"', []),
    ('GraphicsContextCheck;', ['20']),
    ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=8)
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
    report = dict(result='running', scope='Full-size fixed device-context dimensions, public ownership and bounded pixel capacity, plus original graphics-context behavior; not full desktop qualification',
                  input_sha256=pins, commands=commands, ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
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
