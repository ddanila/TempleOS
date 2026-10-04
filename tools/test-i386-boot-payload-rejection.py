#!/usr/bin/env python3
"""Reject malformed boot payloads without changing a blank-boot target."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
BOOT_AREA = 2048 * 512
PAYLOAD_LIMIT = 960 * 512 - 4096


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    source, target = out / 'source.img', out / 'target.img'
    if args.disk.resolve() in (source, target):
        parser.error('outputs must not overwrite input disk')
    original = args.disk.read_bytes()
    source.write_bytes(original)
    initial = bytes(BOOT_AREA) + original[BOOT_AREA:]
    target.write_bytes(initial)
    commands = [(f'U8 *RejectPayload=CAlloc({PAYLOAD_LIMIT+1});U0 RejectInit(){{RejectPayload[0]=0xE9;RejectPayload[1]=3;}}RejectInit;', [])]
    cases = [('oversized', PAYLOAD_LIMIT+1, None),
             ('short-header', 7, None), ('entry-past-end', 8, None),
             ('bad-jump', 16, 'RejectPayload[0]=0;'),
             ('reserved-byte', 16, 'RejectPayload[0]=0xE9;RejectPayload[5]=1;'),
             ('entry-in-header', 16, 'RejectPayload[5]=0;RejectPayload[1]=0;')]
    for name, size, setup in cases:
        if setup:
            commands.append((f'U0 RejectSetup{size}{len(commands)}(){{{setup}}}RejectSetup{size}{len(commands)};', []))
        commands.extend([(f'FileWrite("C:/Probe/RejectBoot.bin",RejectPayload,{size})>0;', ['1']),
                         ('I386InstallBootImage("C:/","D:/","C:/Probe/RejectBoot.bin");', ['0'])])
    commands.extend([('Free(RejectPayload);', []), ('6*7;', ['42'])])
    report = dict(result='fail', cases=[row[0] for row in cases],
                  source_disk_sha256=hashlib.sha256(original).hexdigest(),
                  scope='Guest installer size/header/entry rejection and exact target preservation; not truncated executable integrity or maximum valid installation')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(source, out / 'behavior', target_disk=target,
            snapshot=False, ram_mib=16, cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok','answers':[], 'command_timeout':90,'commands':commands})
        if target.read_bytes() != initial:
            raise ValueError('Rejected publication changed target bytes')
        report.update(result='pass', target_bytes_unchanged=True,
                      target_sha256=hashlib.sha256(initial).hexdigest())
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        report['source_disk_unchanged'] = args.disk.read_bytes() == original
        if not report['source_disk_unchanged']:
            report.update(result='fail', error='Preserved source changed')
        (out / 'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
