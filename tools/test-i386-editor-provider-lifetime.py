#!/usr/bin/env python3
"""Load editor services in a child, retire it, and reuse from child and parent."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists(): parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    runner = ROOT/'tools/i386-kernel-input.py'
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in (source, runner, Path(__file__).resolve())}
    commands = [
        ('CTask*el_child;I64 el_result;', []),
        ('U0 ELRun(U8*unused){U8*s="xxcat";el_result=StrFind("cat",s)==s+2;}', []),
        ('Bool ELWait(){I64 end=cnts.jiffies+20000;while(TaskValidate(el_child)&&cnts.jiffies<end)Yield;return !TaskValidate(el_child)&&el_result==1;}', []),
        ('Bool ELStart(){el_result=-1;el_child=Spawn(&ELRun,NULL,"Editor child",-1,Fs);return el_child&&ELWait;}', []),
        ('Bool ELRepeat(){I64 n=Fs->data_heap->bp->used_u8s,r=Fs->data_heap->bp->alloced_u8s;return ELStart&&Fs->data_heap->bp->used_u8s==n&&Fs->data_heap->bp->alloced_u8s==r;}', []),
        ('ELStart;', ['1']), ('ELRepeat;', ['1']),
        ('U8*el_s="xxcat";StrFind("cat",el_s)==el_s+2;', ['1']),
        ('6*7;', ['42'])]
    if any(len(c)>255 for c, _ in commands): raise ValueError('Lifetime command too long')
    report = dict(result='running', input_sha256=pins, commands=commands,
                  scope='Child first use, two natural child exits, parent reuse, second child public pool recovery; not forced cancellation/reentrancy')
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64, cpu='486,-fpu', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'command_timeout':120, 'rejected_answers':['0'],
                           'rejection_prefixes':('INPUT REJECT ',)})
        log = (out/'qemu/debug.log').read_text()
        first = log.index('INPUT LINE ELStart;')
        if log.count('EDITOR loaded ') != 1 or 'EDITOR loaded ' in log[:first]:
            raise ValueError('Provider must first load in child and be reused')
        report.update(result='pass', first_use_task='child', natural_child_exits=2,
                      second_child_public_pool_restored=True, provider_loads=1)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == h for p, h in pins.items())
        if not report['inputs_unchanged']: report.update(result='fail', error='Lifetime inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__': main()
