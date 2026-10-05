#!/usr/bin/env python3
"""Require an extent-preserving move to grow a full destination directory."""
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
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    inputs = [args.disk, Path(__file__), ROOT/'tools/i386-kernel-input.py',
              ROOT/'tools/test-i386-transfer-recovery.py', ROOT/'tools/build-i386-kernel.py']
    pins = {str(p.resolve()): digest(p) for p in inputs}
    report = {'result': 'fail', 'input_sha256': pins,
              'scope': 'Directory growth during extent transfer and persistent reboot; not interrupted growth writes'}
    disk = args.out/'candidate.img'
    shutil.copyfile(args.disk, disk)
    runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
    locate = runpy.run_path(str(ROOT/'tools/test-i386-transfer-recovery.py'))['locate']
    services = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
    try:
        setup = [('DirMk("C:/GrowthSource",8)&&DirMk("C:/GrowthTarget",8);', ['1']),
                 ('FileWrite("C:/GrowthSource/Move.HC","MOVE",4)>0;', ['1'])]
        setup += [(f'FileWrite("C:/GrowthTarget/F{i}.HC","F",1)>0;', ['1']) for i in range(5)]
        report['prepare'] = runner(disk, args.out/'prepare', snapshot=False, accel='kvm',
                                   startup_check={'status': 'ok', 'answers': [], 'commands': setup})
        before = disk.read_bytes()
        source = locate(before, '/GrowthSource/Move.HC')
        parent = locate(before, '/GrowthTarget')
        if not source or not parent or parent[4] != 512:
            raise ValueError('Expected full one-sector destination fixture')
        report['move'] = runner(disk, args.out/'move', snapshot=False, accel='kvm',
            startup_check={'status': 'ok', 'answers': [], 'commands': [
                ('FileMove("C:/GrowthSource/Move.HC","C:/GrowthTarget/Move.HC");', ['1'])]})
        after = disk.read_bytes()
        target = locate(after, '/GrowthTarget/Move.HC')
        grown = locate(after, '/GrowthTarget')
        if locate(after, '/GrowthSource/Move.HC') or not target or target[2:] != source[2:]:
            raise ValueError('Move changed payload extent or metadata')
        if not grown or grown[4] != 1024 or grown[3] == parent[3]:
            raise ValueError('Destination directory did not grow to a fresh extent')
        wanted = {'/GrowthTarget/Move.HC': b'MOVE'}
        wanted.update({f'/GrowthTarget/F{i}.HC': b'F' for i in range(5)})
        if services['mutated_file_contents'](disk, set(wanted)) != wanted:
            raise ValueError('Moved payload or existing directory files changed')
        report['filesystem'] = services['verify_mutated_volume'](disk)
        stable = digest(disk)
        report['reboot'] = runner(disk, args.out/'reboot', snapshot=False, accel='kvm',
            startup_check={'status': 'ok', 'answers': [], 'commands': [('6*7;', ['42'])]})
        if digest(disk) != stable or any(digest(Path(p)) != h for p, h in pins.items()):
            raise ValueError('Read-only reboot or test changed qualified inputs')
        report.update(result='pass', inputs_unchanged=True, original_extent=source[3])
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
