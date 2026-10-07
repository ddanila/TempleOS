#!/usr/bin/env python3
"""Independently verify a saved loaded-ROM evidence directory."""
import argparse
import hashlib
import json
from pathlib import Path


def sha(data):
    return hashlib.sha256(data).hexdigest()


def verify(directory, disk=None):
    directory = Path(directory)
    report = json.loads((directory / 'result.json').read_text())
    if (report.get('format'), report.get('result'), report.get('stage'),
            report.get('method'), report.get('cpu'), report.get('ram_mib'),
            report.get('pci_registers_restored'), report.get('source_disk_unchanged')) != (
            1, 'pass', 'complete', 'loaded ROM byte comparison', '486,-fpu', 8, True, True):
        raise ValueError('Incomplete loaded-firmware qualification')
    expected = {'system-rom.bin', 'vga-rom.bin', 'qmp.log',
                'behavior/command.json', 'behavior/result.json'}
    if set(report.get('artifact_sha256', {})) != expected:
        raise ValueError('Incomplete firmware artifact set')
    for name, digest in report['artifact_sha256'].items():
        if sha((directory / name).read_bytes()) != digest:
            raise ValueError('Firmware artifact changed: ' + name)
    refs = report['firmware_references']
    if set(refs) != {'system', 'vga'}:
        raise ValueError('Incomplete firmware references')
    for ref in refs.values():
        if report['input_sha256'].get(ref['path']) != ref['sha256']:
            raise ValueError('Firmware reference was not pinned')
    system = (directory / 'system-rom.bin').read_bytes()
    vga = (directory / 'vga-rom.bin').read_bytes()
    if (len(system) != 262144 or refs['system']['bytes'] != 262144
            or sha(system) != refs['system']['sha256']
            or sha(system) != report['system_rom_sha256']):
        raise ValueError('System ROM differs from pinned reference')
    length = refs['vga']['bytes']
    if (len(vga) != 65536 or not 0 < length <= 65536
            or length != report['vga_reference_bytes']
            or sha(vga[:length]) != refs['vga']['sha256']
            or sha(vga) != report['vga_dump_sha256']):
        raise ValueError('VGA ROM differs from pinned reference')
    behavior = json.loads((directory / 'behavior/result.json').read_text())
    if (behavior.get('result'), behavior.get('cpu'), behavior.get('ram_mib'),
            behavior.get('commands'), behavior.get('vga')) != (
            'pass', '486,-fpu', 8, 10, 'all pixels matched at each checkpoint'):
        raise ValueError('Missing guest probe/restoration qualification')
    if behavior != report.get('behavior'):
        raise ValueError('Guest report differs from recorder observation')
    command = json.loads((directory / 'behavior/command.json').read_text())
    for flag, value in (('-machine', 'pc'), ('-accel', 'tcg'),
                        ('-cpu', '486,-fpu'), ('-m', '8'), ('-nic', 'none')):
        if command.count(flag) != 1 or command[command.index(flag) + 1] != value:
            raise ValueError('Guest command does not match firmware profile')
    source_hash = report['source_disk_sha256']
    if report['input_sha256'].get(report['source_disk']) != source_hash:
        raise ValueError('Source image was not pinned')
    if disk is not None and sha(Path(disk).read_bytes()) != source_hash:
        raise ValueError('Firmware evidence belongs to a different image')
    return {'result': 'pass', 'source_disk_sha256': source_hash,
            'system_reference_sha256': refs['system']['sha256'],
            'vga_reference_sha256': refs['vga']['sha256'],
            'scope': 'Saved loaded-ROM identities and guest probe evidence; '
                     'not a fresh execution or complete release verification'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('evidence', type=Path)
    parser.add_argument('--disk', type=Path,
                        help='Also require the evidence to belong to this exact image')
    args = parser.parse_args()
    print(json.dumps(verify(args.evidence, args.disk), indent=2))


if __name__ == '__main__':
    main()
