#!/usr/bin/env python3
"""Verify loaded firmware bytes for the ordinary pc/486,-fpu QEMU profile."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', type=Path)
    parser.add_argument('--repository', type=Path, default=ROOT)
    parser.add_argument('--system-rom', type=Path, required=True)
    parser.add_argument('--vga-rom', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    repo = args.repository.resolve()
    helper = repo / 'tools/i386-kernel-input.py'
    reader = repo / 'tools/build-i386-kernel.py'
    profiler = ROOT / 'tools/record-i386-qemu-environment.py'
    argv = json.loads(args.command.read_text())
    selected, disks = runpy.run_path(str(profiler))['profile'](argv, True)
    values = {selected[i]: selected[i+1] for i in range(0, len(selected), 2)}
    expected = {'-machine': 'pc', '-accel': 'tcg', '-cpu': '486,-fpu',
                '-m': '8', '-nic': 'none'}
    if (any(values.get(k) != v for k, v in expected.items()) or len(disks) != 1
            or set(values) != set(expected) | {'-drive'}):
        parser.error('Requires default pc/TCG/486,-fpu/8 MiB, no NIC, one raw IDE disk')
    qemu = Path(shutil.which(argv[0])).resolve()
    if qemu != Path(shutil.which('qemu-system-i386')).resolve():
        parser.error('Recorded executable differs from guest helper executable')
    system, vga = args.system_rom.resolve(), args.vga_rom.resolve()
    if system.stat().st_size != 262144 or not 0 < vga.stat().st_size <= 65536:
        parser.error('Expected 256 KiB system ROM and VGA ROM at most 64 KiB')
    paths = [args.command.resolve(), disks[0], qemu, system, vga, helper, reader,
             profiler, Path(__file__).resolve()]
    pins = {str(p): sha(p) for p in paths}
    out.mkdir(parents=True)
    report = dict(format=1, result='running', stage='system', input_sha256=pins,
                  source_disk=str(disks[0]), source_disk_sha256=pins[str(disks[0])],
                  firmware_references={'system': {'path': str(system), 'bytes': system.stat().st_size, 'sha256': pins[str(system)]},
                                       'vga': {'path': str(vga), 'bytes': vga.stat().st_size, 'sha256': pins[str(vga)]}},
                  original_command=argv, cpu='486,-fpu', ram_mib=8,
                  method='loaded ROM byte comparison',
                  scope='System ROM on paused ordinary profile and raw VGA PCI ROM '
                        'on a separate boot copy; VGA BAR temporarily mapped and '
                        'restored; not file-open tracing, latency or full OS qualification')
    try:
        system_disk = out / 'system-probe.img'
        shutil.copyfile(disks[0], system_disk)
        if sha(system_disk) != pins[str(disks[0])]:
            raise ValueError('System probe copy differs from pinned image')
        index = selected.index('-drive') + 1
        selected[index] = f'file={system_disk},format=raw,if=ide'
        probe = [str(qemu), *selected, '-S', '-display', 'none', '-qmp', 'stdio']
        dump = out / 'system-rom.bin'
        requests = [('cap', 'qmp_capabilities', {}),
                    ('version', 'query-version', {}), ('pci', 'query-pci', {}),
                    ('roms', 'human-monitor-command', {'command-line': 'info roms'}),
                    ('dump', 'pmemsave', {'val': 0xfffc0000, 'size': 262144,
                                         'filename': str(dump)}), ('quit', 'quit', {})]
        data = ''.join(json.dumps(dict(id=n, execute=e, arguments=a))+'\n'
                       for n, e, a in requests)
        result = subprocess.run(probe, input=data, text=True, capture_output=True, timeout=30)
        (out / 'qmp.log').write_text(result.stdout)
        (out / 'stderr.log').write_text(result.stderr)
        report['paused_command'] = probe
        if result.returncode:
            raise ValueError('Paused system probe failed: ' + result.stderr)
        replies = {r['id']: r for r in map(json.loads, result.stdout.splitlines()) if 'id' in r}
        if set(replies) != {n for n, _, _ in requests} or any('error' in r for r in replies.values()):
            raise ValueError('Incomplete or failed QMP probe')
        if dump.read_bytes() != system.read_bytes():
            raise ValueError('Loaded system ROM differs from reference')
        report.update(system_rom_sha256=sha(dump), qmp_version=replies['version']['return'],
                      pci=replies['pci']['return'], rom_mappings=replies['roms']['return'], stage='vga')
        disk = out / 'vga-probe.img'
        shutil.copyfile(disks[0], disk)
        if sha(disk) != pins[str(disks[0])]:
            raise ValueError('VGA probe copy differs from pinned image')
        commands = [
            ('U32 vr_saved,vr_cfg;', []),
            ('Bool VRDevice(){U32 a=InU32(0xCF8),v;OutU32(0xCF8,0x80001000);v=InU32(0xCFC);OutU32(0xCF8,a);return v==0x11111234;}', []),
            ('VRDevice;', ['1']),
            ('U0 VRRestore(){I64 f=GetRFlags;SetRFlags(f&~512);OutU32(0xCF8,0x80001030);OutU32(0xCFC,vr_saved);OutU32(0xCF8,vr_cfg);SetRFlags(f);}', []),
            ('U0 VRMap(){I64 f=GetRFlags;SetRFlags(f&~512);vr_cfg=InU32(0xCF8);OutU32(0xCF8,0x80001030);vr_saved=InU32(0xCFC);OutU32(0xCFC,0xF0000001);SetRFlags(f);}', []),
            ('I64 VRDump(){I64 n;VRMap;try{n=FileWrite("/VgaPciRom.bin",0xF0000000(U8 *),65536);}catch{VRRestore;}VRRestore;return n;}', []),
            ('VRDump>0;', ['1']),
            ('Bool VRRestored(){U32 a=InU32(0xCF8),v;I64 f=GetRFlags;SetRFlags(f&~512);OutU32(0xCF8,0x80001030);v=InU32(0xCFC);OutU32(0xCF8,a);SetRFlags(f);return v==vr_saved&&a==vr_cfg;}', []),
            ('VRRestored;', ['1']), ('6*7;', ['42']),
        ]
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands})
        contents = runpy.run_path(str(reader))['mutated_file_contents'](disk, {'/VgaPciRom.bin'})['/VgaPciRom.bin']
        (out / 'vga-rom.bin').write_bytes(contents)
        if len(contents) != 65536 or contents[:vga.stat().st_size] != vga.read_bytes():
            raise ValueError('Loaded VGA PCI ROM differs from reference')
        report.update(result='pass', stage='complete', vga_dump_sha256=sha(out/'vga-rom.bin'),
                      vga_reference_bytes=vga.stat().st_size, pci_registers_restored=True,
                      artifact_sha256={name: sha(out/name) for name in
                                       ('system-rom.bin', 'vga-rom.bin', 'qmp.log',
                                        'behavior/command.json', 'behavior/result.json')})
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [p for p, digest in pins.items() if sha(Path(p)) != digest]
        if changed:
            report.update(result='fail', error='Inputs changed', changed_inputs=changed)
        report['source_disk_unchanged'] = sha(disks[0]) == pins[str(disks[0])]
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Firmware qualification failed'))


if __name__ == '__main__':
    main()
