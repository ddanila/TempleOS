#!/usr/bin/env python3
"""Reject diagnostic support, repair it in the guest, and retry without rebooting."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]
PROVIDER = '/Modules/I386/DocDiagnosticRuntime.t32m'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--fault', choices=('wrong-target', 'missing-import'), default='wrong-target')
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
    find_record = runpy.run_path(str(ROOT/'tools/test-i386-public-file-write.py'))['find_record']
    original = source.read_bytes()
    module = build['mutated_file_contents'](source, {PROVIDER})[PROVIDER]
    if args.fault == 'wrong-target':
        position, bad = 6, 4
        if module[position] != 3:
            raise ValueError('Input is not an i386 module')
    else:
        count, records = struct.unpack_from('<II', module, 20)
        positions = {name for i in range(count)
                     for kind, offset, name, length in [struct.unpack_from('<4I', module, records+16*i)]
                     if kind == 2 and module[name:name+length] == b'SysTry'}
        if not positions:
            raise ValueError('Missing exception import')
        position, bad = min(positions), ord('X')
    candidate = out/'working.img'
    changed = bytearray(original)
    entry = find_record(source, PROVIDER)
    changed[entry['block']*512+position] = bad
    candidate.write_bytes(changed)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in (source, Path(__file__).resolve(),
                                    ROOT/'tools/i386-kernel-input.py',
                                    ROOT/'tools/build-i386-kernel.py',
                                    ROOT/'tools/test-i386-public-file-write.py')}
    report = dict(result='running', fault=args.fault, mutation_offset=position,
                  input_sha256=pins,
                  scope='Optional diagnostic rejection, guest repair and repeated public retry; forced exit, reentrancy and service-version faults remain separate gates')
    commands = [
        ('DocAllocationCheck;', ['-1']), ('DocAllocationCheck;', ['-1']), ('6*7;', ['42']),
        (f'Bool RepairDiagnostic(){{I64 n=0;U8 *p=FileRead("C:{PROVIDER}",&n);'
         f'Bool ok=p&&n=={len(module)};if(ok){{p[{position}]={module[position]};'
         'ok=FileWrite("C:'+PROVIDER+'",p,n)>0;}Free(p);return ok;}', []),
        ('RepairDiagnostic();', ['1']), ('DocAllocationCheck;', ['13']),
        ('DocAllocationCheck;', ['13']), ('6*7;', ['42'])]
    if any(len(source)>255 for source, _ in commands):
        raise ValueError('Repair fixture exceeds command limit')
    try:
        report['behavior'] = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
            candidate, out/'qemu', snapshot=False, ram_mib=64, cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status':'ok', 'answers':[], 'commands':commands,
                                         'command_timeout':120, 'rejection_prefixes':('INPUT REJECT ',)})
        log = (out/'qemu/debug.log').read_text()
        if log.count('DOC DIAGNOSTIC loaded\n') != 2 or log.count('DOC DIAGNOSTIC unloaded\n') != 2:
            raise ValueError('Repaired support must load and unload twice')
        persisted = build['mutated_file_contents'](candidate, {PROVIDER})[PROVIDER]
        if persisted != module:
            raise ValueError('Guest repair did not restore the module byte identically')
        report.update(result='pass', rejected_attempts=2, successful_invocations=2,
                      provider_restored_byte_identically=True)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == h for p,h in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
