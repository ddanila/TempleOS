#!/usr/bin/env python3
"""Qualify a replacement extended loader against an unchanged complete OS image."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path, required=True)
    parser.add_argument('--stage', type=Path, required=True)
    parser.add_argument('--audit', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    inputs = [args.disk, args.stage, args.audit, Path(__file__),
              ROOT/'tools/i386-bios.inc', ROOT/'tools/i386-kernel-input.py']
    pins = {str(p.resolve()): sha(p) for p in inputs}
    report = {'result': 'fail', 'input_sha256': pins,
              'scope': 'Replacement loader boots unchanged OS and executes HolyC; not full suite or installation'}
    try:
        original = args.disk.read_bytes()
        import struct
        magic, version, length, base = struct.unpack_from('<4I', original, 528)
        if (magic, version, base) != (0x42323345, 1, 0x100000) or not 8 <= length <= 2039*512:
            raise ValueError('Expected valid extended boot image')
        payload = original[4608:4608+length]
        if len(payload) != length:
            raise ValueError('Truncated payload')
        checksum = 2166136261
        for byte in payload:
            checksum = ((checksum ^ byte)*16777619) & 0xFFFFFFFF
        if checksum != struct.unpack_from('<I', original, 544)[0]:
            raise ValueError('Source payload checksum mismatch')
        payload_path = args.out.resolve()/'payload.bin'
        payload_path.write_bytes(payload)
        boot = args.out.resolve()/'boot.bin'
        listing = args.out.resolve()/'stage.lst'
        subprocess.run(['nasm', '-f', 'bin', f'-DPAYLOAD_FNV={checksum}',
                        f'-DKERNEL_FILE="{payload_path}"', '-l', str(listing),
                        str(args.stage.resolve()), '-o', str(boot)], cwd=ROOT, check=True)
        built = boot.read_bytes()
        if len(built) != 4608+length or built[4608:] != payload:
            raise ValueError('Replacement loader altered payload')
        candidate = args.out/'candidate.img'
        candidate.write_bytes(built+original[len(built):])
        if candidate.read_bytes()[4608:] != original[4608:]:
            raise ValueError('Replacement altered payload, padding or filesystem')
        subprocess.run(['python3', str(args.audit.resolve()), str(boot), str(listing),
                        '--out', str((args.out/'boot-audit.json').resolve())], check=True)
        report['behavior'] = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
            candidate, args.out/'interactive', cpu='486,-fpu', ram_mib=8,
            startup_check={'status': 'ok', 'answers': [], 'commands': [('6*7;', ['42'])]})
        if any(sha(Path(p)) != digest for p, digest in pins.items()):
            raise ValueError('Source input changed')
        report.update(result='pass', inputs_unchanged=True, payload_bytes=length)
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
