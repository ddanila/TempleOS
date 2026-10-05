#!/usr/bin/env python3
"""Require malformed extent-transfer journals to stop mount without disk writes."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    helper = ROOT/'tools/test-i386-transfer-recovery.py'
    pins = {str(p.resolve()): sha(p) for p in (args.disk, Path(__file__), helper)}
    locate = runpy.run_path(str(helper))['locate']
    original = args.disk.read_bytes()
    source = locate(original, '/Kernel/I386/TextFrameDemo.HC')
    directory = locate(original, '/Probe')
    if not source or not directory:raise ValueError('Missing fixture namespace')
    parent = directory[3]
    slots = [parent*512+i*64 for i in range(2, directory[4]//64-1)
             if not original[parent*512+i*64+2] or original[parent*512+i*64+1] & 1]
    if not slots:raise ValueError('No destination fixture slot')
    report = {'result': 'fail', 'input_sha256': pins, 'cases': {},
              'scope': 'Malformed transfer mount rejection and unchanged backing bytes; not all IO errors'}
    try:
        for case in ('checksum', 'version', 'source-size', 'source-block', 'destination-block'):
            image = bytearray(original)
            header = 2048*512
            if any(image[header+48:header+192]):raise ValueError('Existing journal')
            struct.pack_into('<6Q', image, header+56, source[0], parent,
                             source[3], source[4], source[5], source[2])
            image[header+104:header+142] = b'TextFrameDemo.HC'.ljust(38, b'\0')
            image[header+142:header+180] = b'RejectTransfer.HC'.ljust(38, b'\0')
            magic = 0x3245564F4D323349
            if case == 'version':magic = 0x3345564F4D323349
            if case == 'source-size':struct.pack_into('<Q', image, header+80, source[4]+1)
            if case == 'source-block':struct.pack_into('<Q', image, header+72, source[3]+1)
            if case == 'destination-block':
                struct.pack_into('<H38sqqQ', image, slots[0], source[2],
                                 b'RejectTransfer.HC'.ljust(38, b'\0'),
                                 source[3]+1, source[4], source[5])
            checksum = 0xCBF29CE484222325
            for byte in image[header+56:header+184]:
                checksum = ((checksum ^ byte)*0x100000001B3) & 0xFFFFFFFFFFFFFFFF
            if case == 'checksum':checksum ^= 1
            struct.pack_into('<Q', image, header+184, checksum)
            struct.pack_into('<Q', image, header+48, magic)
            disk = args.out/(case+'.img')
            disk.write_bytes(image)
            digest = sha(disk)
            log = args.out/(case+'.debug.log')
            with (args.out/(case+'.qemu.log')).open('wb') as errors:
                process = subprocess.Popen(['qemu-system-i386', '-machine', 'pc',
                    '-accel', 'tcg', '-cpu', '486,-fpu', '-m', '8', '-nic', 'none',
                    '-drive', f'file={disk.resolve()},format=raw,if=ide', '-display', 'none',
                    '-no-reboot', '-debugcon', f'file:{log.resolve()}'],
                    stdout=subprocess.DEVNULL, stderr=errors)
                try:
                    deadline = time.monotonic()+30
                    while time.monotonic() < deadline:
                        text = log.read_text() if log.exists() else ''
                        if 'REDSEA ' in text:raise ValueError(case+' incorrectly mounted')
                        if 'FAIL native kernel\n' in text:
                            if 'START native kernel\n' not in text:raise ValueError('Not native mount rejection')
                            break
                        if process.poll() is not None:raise ValueError('QEMU exited before rejection')
                        time.sleep(.1)
                    else:raise TimeoutError(case+' did not reject')
                finally:
                    process.terminate()
                    try:process.wait(timeout=5)
                    except subprocess.TimeoutExpired:process.kill();process.wait()
            if sha(disk) != digest:raise ValueError(case+' rejection wrote to disk')
            report['cases'][case] = dict(result='pass', disk_sha256=digest, log=text)
        if any(sha(Path(p)) != h for p, h in pins.items()):raise ValueError('Inputs changed')
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:(args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':main()
