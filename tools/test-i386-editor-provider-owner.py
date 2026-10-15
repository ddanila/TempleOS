#!/usr/bin/env python3
"""Resolve editor services from permanent Console exports despite a first-caller shadow."""
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
    fixture=ROOT/'tests/guest/i386-editor-provider-owner/Owner.HC'
    packaging=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
        source,working,additions={'/EditorOwner.HC':fixture.read_bytes()})
    runner = ROOT/'tools/i386-kernel-input.py'
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in (source, runner, fixture, ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py', Path(__file__).resolve())}
    commands = [
        ('#include "C:/EditorOwner.HC"', []),
        ('ELSetup;', []),
        ('ELStart;', ['1']), ('ELRepeat;', ['1']), ('ELUse;', ['1']),
        ('!el_poison&&HashFind("_DOC_NEW",Fs->hash_table,HTT_EXPORT_SYS_SYM)==el_parent_export;', ['1']),
        ('6*7;', ['42'])]
    if any(len(c)>255 for c, _ in commands): raise ValueError('Lifetime command too long')
    report = dict(result='running', input_sha256=pins, commands=commands,
                  packaging=packaging, scope='Real DocForm allocation under a first-child export shadow, two natural child exits, exact per-call heap/roles, parent reuse, second-child public pool recovery; not forced cancellation/reentrancy')
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
        report.update(result='pass', first_use_task='child-with-shadow', natural_child_exits=2, shadow_poison_calls=0,
                      second_child_public_pool_restored=True, provider_loads=1)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == h for p, h in pins.items())
        if not report['inputs_unchanged']: report.update(result='fail', error='Lifetime inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__': main()
