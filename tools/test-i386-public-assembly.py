#!/usr/bin/env python3
"""Exercise complete normal lazy assembly/join services and inline HolyC assembly."""
from pathlib import Path
import argparse
import hashlib
import json
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-public-assembly/Contract.HC'
    paths = [Path(__file__).resolve(), source, fixture, ROOT/'Compiler/OpCodes.DD']
    paths += [ROOT/'tools'/name for name in (
        'test-i386-autocomplete-interaction.py', 'package-i386-native-image.py',
        'build-i386-kernel.py', 'test-i386-timeclock-welcome.py')]
    paths += sorted(p for directory in ('Compiler', 'Kernel')
                    for p in (ROOT/directory).rglob('*')
                    if p.is_file() and p.suffix in ('.HC', '.HH'))
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Normal lazy complete shared PrsAsmBlk/CmpJoin, opcode table, exact data/instruction bytes, executable forward/local branches, import metadata, eight inline/bare HolyC assembly cases including an unreachable block, canonical type identity, caller context, retained expected warning text with owned output cleanup, fresh normal expression recovery and heap recovery. Not complete AOT/release or assembly error/OOM/cancellation qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    guest = None
    try:
        pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        before = pack['snapshot'](source.read_bytes())[1]
        for path in paths:
            if path.is_relative_to(ROOT) and path.suffix in ('.HC', '.HH', '.DD'):
                name = '/'+str(path.relative_to(ROOT))
                if name in before and path.read_bytes() != before[name][2]:
                    raise ValueError('Delivered source differs: '+name)
        additions = {'/Probe/Assembly.HC': fixture.read_bytes()}
        report['packaging'] = pack['package'](source, out/'working.img', additions=additions)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        guest = Guest(out/'working.img', out/'guest', True)
        guest.wait('DONE native kernel startup\n')
        guest.command('CCmpCtrl *warm=CmpCtrlNew(StrNew("6*7"));Lex(warm);LexExpressionI64(warm);CmpCtrlDel(warm);', timeout=600)
        if 'PUBLIC ASM loaded\n' in guest.collect():
            raise ValueError('Expression use eagerly loaded assembly')
        guest.command('#include "C:/Probe/Assembly.HC"', timeout=900)
        guest.wait('PUBLIC ASSEMBLY DONE\n')
        data = (guest.out/'public-assembly.bin').read_bytes()
        (out/'public-assembly.bin').write_bytes(data)
        report['records'] = list(struct.unpack('<24q', data))
        expected = [1,1,1,42,1,42,1,15,17,17,12,23,29,42,0,0,1,1,1,42,31,1,42,1]
        if report['records'] != expected:
            raise ValueError('Assembly/join contract differs: '+str(report['records']))
        warning = (guest.out/'assembly-warning.bin').read_bytes()
        (out/'assembly-warning.bin').write_bytes(warning)
        if b'could use I8 displacement' not in warning or b'@@done' not in warning:
            raise ValueError('Expected short-displacement warning is missing')
        report['warning_sha256'] = hashlib.sha256(warning).hexdigest()
        log = guest.collect()
        report['publications'] = {name: log.count('PUBLIC '+name+' loaded\n')
                                  for name in ('LEX', 'OPT', 'PARSER', 'BACKEND', 'JIT', 'ASM')}
        if any(count != 1 for count in report['publications'].values()):
            raise ValueError('Unexpected publication count: '+str(report['publications']))
        guest.command('6*7;')
        report['arithmetic_pixels'] = guest.result_pixels()
        guest.close()
        guest = None
        after = pack['snapshot']((out/'working.img').read_bytes())[1]
        if {n for n in set(before)|set(after) if before.get(n) != after.get(n)} != set(additions):
            raise ValueError('Unexpected filesystem changes')
        report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](out/'working.img')
        report['result'] = 'pass'
    except BaseException as error:
        report.update(result='fail', error=str(error) or type(error).__name__)
        raise
    finally:
        if guest:
            guest.close()
        report['inputs_unchanged'] = all(sha(Path(name)) == digest for name, digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report.get('error', 'Assembly contract failed'))
    print('PASS normal public assembly/join contract')


if __name__ == '__main__':
    main()
