#!/usr/bin/env python3
"""Check required public task/debug names; presence alone does not prove their behavior."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = ('Spawn', 'Exit', 'Yield', 'Sleep', 'Dbg')
CONTROLS = ('MAlloc', 'Dir')
SERVICE_DEFINITION = ('U0 M7Service(U8 *n){U8 *p=n;Bool v=HashFind(n,Fs->hash_table,HTT_FUN)!=0;'
                      'p="M7 SERVICE ";while(*p)OutU8(0xE9,*p++);p=n;while(*p)OutU8(0xE9,*p++);'
                      'OutU8(0xE9,32);OutU8(0xE9,48+v);OutU8(0xE9,10);}')


def observation_commands(names=CONTROLS + REQUIRED):
    return [(SERVICE_DEFINITION, []),
            (''.join(f'M7Service("{name}");' for name in names), [])]


def assess(log):
    values = {}
    for name in CONTROLS + REQUIRED:
        matches = re.findall(r'^M7 SERVICE ' + name + r' ([01])$', log, re.M)
        if len(matches) != 1:
            return {'result': 'invalid', 'reason': f'Missing or repeated observation: {name}'}
        values[name] = int(matches[0])
    if any(values[name] != 1 for name in CONTROLS):
        return {'result': 'invalid', 'reason': 'Known public function controls were not found'}
    missing = [name for name in REQUIRED if not values[name]]
    return {'result': 'fail' if missing else 'pass', 'missing': missing,
            'public_functions': values,
            'scope': 'Required public function publication only; not task/terminal or debugging behavior'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    disk_hash = hashlib.sha256(args.disk.read_bytes()).hexdigest()
    runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    console = runner(args.disk, out / 'console', cpu='486,-fpu', qmp_stdio=True,
                     startup_check={'status': 'ok', 'answers': [], 'commands':
                                    observation_commands()})
    report = assess((out / 'console/debug.log').read_text())
    report.update(disk_sha256=disk_hash, cpu='486,-fpu', ram_mib=8, accel='tcg',
                  console_result=console,
                  checker_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
    if hashlib.sha256(args.disk.read_bytes()).hexdigest() != disk_hash:
        raise ValueError('Publication check changed the source disk')
    report['source_disk_unchanged'] = True
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if report['result'] == 'pass' else 1 if report['result'] == 'fail' else 2)


if __name__ == '__main__':
    main()
