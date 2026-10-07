#!/usr/bin/env python3
"""Compile bare assembly mixed with HolyC and verify interrupt flag restoration."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
CASES = (
    ('Block', 'public I64 BlockCheck(){I64 before=GetRFlags,off;\nasm {PUSHFD CLI}\noff=GetRFlags;\nasm {POPFD}\nNOP\nreturn !(off&512)&&((GetRFlags&512)==(before&512));}\n', 'BlockCheck', '1'),
    ('Bare', 'public I64 BareCheck(){I64 before=GetRFlags,off;\nPUSHFD\nCLI\noff=GetRFlags;\nPOPFD\nreturn !(off&512)&&((GetRFlags&512)==(before&512));}\n', 'BareCheck', '1'),
)



def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib', type=int, choices=(8, 16), default=16)
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    candidate = disk.parent/'result.json'
    manifest = json.loads(candidate.read_text())
    if sha(disk) != manifest['disk_sha256']:
        raise ValueError('Disk differs from its cross-build manifest')
    for name, digest in manifest['source_sha256'].items():
        if name.startswith(('Kernel/', 'Compiler/')) and sha(ROOT/name) != digest:
            raise ValueError(f'Stale compiler candidate: {name}')
    out.mkdir(parents=True)
    working = out/'source.img'
    shutil.copyfile(disk, working)
    report = {'status':'fail', 'cpu':'486,-fpu', 'ram_mib':args.ram_mib,
              'scope':'Bare and block PUSHFD/CLI/POPFD AOT compilation, persisted relocation-free module execution and included HolyC interrupt-state check',
              'disk_sha256':sha(disk), 'checker_sha256':sha(Path(__file__)), 'cases':{}}
    try:
        commands = [
            ('I64 BAInvoke(U8 *p){I64(*f)();if(p(U32*)[0]!=0x4D323354||p(U32*)[5]!=1)return 0;U32 *r=p+p(U32*)[6];if(r[0]!=1||r[1])return 0;f=p+32;return (*f)();}', []),
            ('I64 BAF(U8 *path){U8 *m=FileRead(path);I64 r;if(!m)return 0;r=BAInvoke(m);Free(m);return r;}', []),
        ]
        for label, source, function, answer in CASES:
            encoded = source.encode('ascii')
            commands.extend([
                (f'FileWrite("C:/Probe/{label}.HC",{json.dumps(source)},{len(encoded)})>0;', ['1']),
                (f'I386BuildModule("C:/Probe/{label}.HC","C:/Probe/{label}.t32m",TRUE)>0;', ['1']),
                (f'BAF("C:/Probe/{label}.t32m");', [answer]),
                (f'#include "C:/Probe/{label}.HC"', []),
                (f'{function};', [answer]),
            ])
        commands.append(('6*7;', ['42']))
        if any(len(command)>255 for command, _ in commands):
            raise ValueError('Fixture exceeds interactive line limit')
        report['behavior'] = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib, accel='tcg',
            cpu='486,-fpu', qmp_stdio=True, startup_timeout=180,
            startup_check={'status':'ok', 'answers':[], 'command_timeout':180, 'commands':commands})
        wanted = {f'/Probe/{label}.{suffix}' for label, *_ in CASES for suffix in ('HC','t32m')}
        files = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](working, wanted)
        exports_of = runpy.run_path(str(ROOT/'tools/test-i386-retained-build.py'))['exports_of']
        for label, source, function, answer in CASES:
            if files.get(f'/Probe/{label}.HC') != source.encode('ascii'):
                raise ValueError(f'Persisted {label} source differs')
            module = files.get(f'/Probe/{label}.t32m')
            count, exports = exports_of(module)
            if function not in exports:
                raise ValueError(f'Missing {label} function export')
            (out/f'{label}.t32m').write_bytes(module)
            report['cases'][label] = {'module_bytes':len(module), 'module_sha256':hashlib.sha256(module).hexdigest(), 'record_count':count, 'exports':exports, 'answer':answer}
        report['status'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    print('PASS: bare assembly compilation, persistence and interrupt-state restoration')


if __name__ == '__main__':
    main()
