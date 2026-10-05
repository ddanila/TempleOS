#!/usr/bin/env python3
"""Measure live and peak document-session heap use in an 8 MiB QEMU guest."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy

ROOT = Path(__file__).resolve().parent.parent
FIELDS = ('doc_session_data_used', 'doc_session_code_used',
          'doc_session_data_reserved', 'doc_session_code_reserved',
          'doc_session_heap_base', 'doc_session_heap_peak',
          'doc_session_heap_reserved_peak')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/selfhost-install-fixed/target.img')
    parser.add_argument('--out', type=Path, default=ROOT / 'build/i386-kernel/resource-profile')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    parser.add_argument('--parse-only', action='store_true',
                        help='Parse a completed run without starting QEMU again')
    args = parser.parse_args()
    out = args.out.resolve()
    identity = {'disk': str(args.disk.resolve()),
                'disk_sha256': hashlib.sha256(args.disk.read_bytes()).hexdigest(),
                'cpu': '486,-fpu', 'accel': args.accel, 'ram_mib': 8}
    provenance = out / 'resource-input.json'
    if args.parse_only:
        if not provenance.exists() or json.loads(provenance.read_text()) != identity:
            raise ValueError('Resource input identity missing or differs; run fresh qualification')
    else:
        out.mkdir(parents=True, exist_ok=True)
        (out / 'resource-result.json').unlink(missing_ok=True)
        provenance.write_text(json.dumps(identity, indent=2) + '\n')
    commands = [('#include "/Kernel/I386/DocSessionResourceCheck.HC"', []),
                ('DocSessionResourceCheck;', ['Exception'] * 21 + ['21']),
                ("U0 ResourceHex(I64 v){I64 i,n;for(i=60;i>=0;i-=4){n=(v>>i)&15;if(n<10)OutU8(0xE9,'0'+n);else OutU8(0xE9,'A'+n-10);}}", []),
                ('U0 ResourceLine(U8 *name,I64 value){while(*name)OutU8(0xE9,*name++);ResourceHex(value);OutU8(0xE9,10);}', [])]
    for field in FIELDS:
        commands.append((f'ResourceLine("RESOURCE {field} ",{field});', []))
    if not args.parse_only:
        run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        run_input(args.disk, out, accel=args.accel, cpu='486,-fpu', ram_mib=8,
                  startup_timeout=180, startup_check={
                      'status': 'ok', 'answers': [], 'command_timeout': 180,
                      'commands': commands})
    elif json.loads((out / 'result.json').read_text())['result'] != 'pass':
        raise ValueError('No passing QEMU run to parse')
    if hashlib.sha256(args.disk.read_bytes()).hexdigest() != identity['disk_sha256']:
        raise ValueError('Resource source disk changed')
    command = json.loads((out / 'command.json').read_text())
    for flag, expected in [('-machine', 'pc'), ('-cpu', identity['cpu']),
                           ('-accel', args.accel), ('-m', '8')]:
        if command.count(flag) != 1 or command[command.index(flag)+1] != expected:
            raise ValueError('Resource QEMU profile differs: ' + flag)
    drives = [command[i+1] for i, value in enumerate(command) if value == '-drive']
    if drives != ['file=' + identity['disk'] + ',format=raw,if=ide'] or '-snapshot' not in command:
        raise ValueError('Resource QEMU disk or snapshot profile differs')
    log = (out / 'debug.log').read_text()
    arena = re.findall(r'^ARENA ([0-9A-Fa-f]{16}) ([0-9A-Fa-f]{16})$', log, re.M)
    if len(arena) != 1:
        raise ValueError('Missing or repeated guest heap arena')
    arena_start, arena_bytes = (int(value, 16) for value in arena[0])
    if not arena_start or not arena_bytes or arena_start + arena_bytes > 8 * 1024 * 1024:
        raise ValueError('Guest heap arena exceeds installed 8 MiB RAM')
    values = {}
    for field in FIELDS:
        matches = re.findall(rf'^RESOURCE {field} ([0-9A-Fa-f]{{16}})$', log, re.M)
        if len(matches) != 1:
            raise ValueError(f'Missing or repeated guest resource value: {field}')
        values[field] = int(matches[0], 16)
    if (values['doc_session_data_used'] != values['doc_session_code_used'] or
            values['doc_session_heap_base'] != values['doc_session_data_used'] or
            not values['doc_session_heap_base'] < values['doc_session_heap_peak'] <=
            values['doc_session_heap_reserved_peak']):
        raise ValueError('Guest resource values violate shared-heap accounting')
    result = {'result': 'pass', 'cpu': '486,-fpu', 'ram_mib': 8,
              'disk_sha256': identity['disk_sha256'], 'accel': args.accel,
              'source_disk_unchanged': True,
              'arena_start': arena_start, 'arena_bytes': arena_bytes,
              'document_development_cycles': 20, 'bytes': values,
              'temporary_live_growth': values['doc_session_heap_peak'] -
              values['doc_session_heap_base']}
    (out / 'resource-result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(result)


if __name__ == '__main__':
    main()
