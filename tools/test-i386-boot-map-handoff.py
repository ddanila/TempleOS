#!/usr/bin/env python3
"""Test the E820 loader handoff with a previously built kernel as a reader."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import shutil

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', required=True, type=Path)
    parser.add_argument('--out', required=True, type=Path)
    parser.add_argument('--force-unavailable', action='store_true')
    args = parser.parse_args()
    build, out = args.build.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    disk, flat = build/'kernel.img', build/'exports/Kernel32.BIN'
    manifest = json.loads((build/'result.json').read_text())
    if sha(disk) != manifest['disk_sha256'] or sha(flat) != manifest['kernel_sha256']:
        raise ValueError('Reference kernel differs from build manifest')
    stage = ROOT/'tools/i386-extended-stage.asm'
    bios = ROOT/'tools/i386-bios.inc'
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [disk, flat, stage, bios, runner, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    checksum = 2166136261
    for byte in flat.read_bytes():
        checksum = ((checksum ^ byte)*16777619) & 0xFFFFFFFF
    image, listing = out/'stage.img', out/'stage.lst'
    command = ['nasm', '-f', 'bin', f'-DPAYLOAD_FNV={checksum}',
               f'-DKERNEL_FILE="{flat}"', '-l', str(listing),
               *(['-DBOOT_MAP_FAIL=1'] if args.force_unavailable else []),
               str(stage), '-o', str(image)]
    subprocess.run(command, cwd=ROOT, check=True)
    audit = runpy.run_path(str(ROOT/'tools/audit-i386-boot.py'))['audit'](image.read_bytes(), listing.read_text())
    working = out/'working.img'
    shutil.copyfile(disk, working)
    data = bytearray(working.read_bytes())
    data[:4608] = image.read_bytes()[:4608]
    if data[4608:4608+flat.stat().st_size] != flat.read_bytes():
        raise ValueError('Loader fixture changed retained kernel payload')
    working.write_bytes(data)
    expected = '0' if args.force_unavailable else '1'
    commands = [('U32 *BootMapWords=0x5040;', []),
                ('BootMapWords[0]==0x50324D49&&BootMapWords[1]==1;', ['1']),
                ('BootMapWords[3];', [expected]),
                ('BootMapWords[2]>0&&BootMapWords[2]<=32;', [expected]),
                ('6*7;', ['42'])]
    report = dict(result='running', scope='BIOS E820 transport and 386 loader audit using an unchanged prior kernel; not new-kernel allocator qualification',
                  force_unavailable=args.force_unavailable, input_sha256=pins, boot_instruction_audit=audit)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            accel='tcg', cpu='486,-fpu', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands})
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Test inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
