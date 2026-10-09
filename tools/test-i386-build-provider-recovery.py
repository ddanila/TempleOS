#!/usr/bin/env python3
"""Reject a bad lazy provider, repair it in the guest, and build without rebooting."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]
PROVIDER = '/Modules/I386/BuildRuntime.t32m'
OUTPUTS = ('/Probe/RecoveredStartup.t32m', '/Probe/ReusedStartup.t32m')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--fault', choices=('service-version', 'wrong-target', 'missing-import'),
                        default='service-version')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    candidate = out/'candidate.img'
    if candidate == args.disk.resolve():
        parser.error('candidate must not overwrite source')
    build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
    find_record = runpy.run_path(str(ROOT/'tools/test-i386-public-file-write.py'))['find_record']
    original = args.disk.read_bytes()
    module = build['mutated_file_contents'](args.disk, {PROVIDER})[PROVIDER]
    build['build_runtime_layout'](module)
    count, records = struct.unpack_from('<II', module, 20)
    rows = [struct.unpack_from('<4I', module, records+16*i) for i in range(count)]
    if args.fault == 'service-version':
        positions = {32+offset for kind, offset, name, length in rows
                     if kind == 3 and module[name:name+length] == b'build_runtime_version'}
        if len(positions) != 1 or struct.unpack_from('<I', module, next(iter(positions)))[0] != 2:
            raise ValueError('Missing current provider service version')
        position = positions.pop()
        bad_byte = 0
    elif args.fault == 'wrong-target':
        position = 6
        if module[position] != 3:
            raise ValueError('Provider does not target i386')
        bad_byte = 4
    else:
        positions = {name for kind, offset, name, length in rows
                     if kind == 2 and module[name:name+length] == b'KernelLog'}
        if not positions:
            raise ValueError('Missing provider KernelLog import name')
        position = min(positions)
        bad_byte = ord('X')
    good_byte = module[position]
    entry = find_record(args.disk, PROVIDER)
    changed = bytearray(original)
    changed[entry['block']*512+position] = bad_byte
    candidate.write_bytes(changed)
    report = dict(result='running', source_disk_sha256=hashlib.sha256(original).hexdigest(),
                  fault=args.fault, mutation_offset=position,
                  scope='Lazy provider rejection, in-guest repair, retry and reuse at 16 MiB')
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    commands = [
        ('I386BuildModule("C:/Kernel/I386/Startup.HC","C:/Probe/RejectedStartup.t32m",TRUE);', ['-1']),
        ('I386BuildModule("C:/Kernel/I386/Startup.HC","C:/Probe/RejectedStartup.t32m",TRUE);', ['-1']),
        (f'Bool RepairProvider(){{I64 n=0;U8 *p=FileRead("C:{PROVIDER}",&n);'
         f'Bool ok=p&&n=={len(module)};if(ok){{p[{position}]={good_byte};'
         f'ok=FileWrite("C:{PROVIDER}",p,n)>0;}}Free(p);return ok;}}', []),
        ('RepairProvider();', ['1']),
        *[(f'I386BuildModule("C:/Kernel/I386/Startup.HC","C:{path}",TRUE)>0;', ['1'])
          for path in OUTPUTS],
        ('6*7;', ['42'])]
    try:
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        runner(candidate, out/'qemu', snapshot=False, ram_mib=16, accel='tcg',
               cpu='486,-fpu', qmp_stdio=True, startup_timeout=180,
               startup_check={'status':'ok', 'answers':[], 'commands':commands,
                              'command_timeout':600,
                              'rejection_prefixes':()})
        log = (out/'qemu/debug.log').read_text()
        if (log.count('BUILD PROVIDER loaded\n') != 1 or
                log.find('BUILD PROVIDER loaded\n') < log.find('READY native kernel')):
            raise ValueError('Repaired provider must load once and be reused')
        paths = {PROVIDER, *OUTPUTS, '/Probe/RejectedStartup.t32m'}
        persisted = build['mutated_file_contents'](candidate, paths)
        if persisted.get(PROVIDER) != module or '/Probe/RejectedStartup.t32m' in persisted:
            raise ValueError('Provider repair or rejection filesystem contract failed')
        audit = runpy.run_path(str(ROOT/'tools/test-i386-retained-build.py'))['exports_of']
        reference = build['mutated_file_contents'](args.disk, {'/Modules/I386/Startup.t32m'})
        _, expected = audit(reference['/Modules/I386/Startup.t32m'])
        for path in OUTPUTS:
            _, exports = audit(persisted.get(path))
            if set(exports) != set(expected):
                raise ValueError('Recovered startup export contract differs from installed source')
        if persisted[OUTPUTS[0]] != persisted[OUTPUTS[1]]:
            raise ValueError('Retry and reuse produced different startup modules')
        report.update(result='pass', rejected_attempts=2, successful_builds=2,
                      build_provider_loads=1, provider_restored_byte_identically=True)
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        if args.disk.read_bytes() != original:
            report.update(result='fail', error='Input disk changed during recovery test')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
