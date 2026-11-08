#!/usr/bin/env python3
"""Compare original 32-bit disassembly and preserve pointer-free opcode tables."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--ram-mib', type=int, default=64, help='Native guest RAM; original reference remains unchanged')
    args = ap.parse_args()
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-unassemble/Contract.HC'
    tables_fixture = fixture.with_name('Tables.HC')
    capacity_fixture = fixture.with_name('NativeCapacity.HC')
    paths = [Path(__file__).resolve(), fixture, tables_fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    catalog=ROOT/'Compiler/I386/UAsmTables.DATA'
    paths.append(catalog)
    if args.disk: paths.append(capacity_fixture)
    if args.disk:
        paths.append(args.disk.resolve())
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Twelve explicit 32-bit Ui cases: exact instruction text, consumed lengths and relative destinations; native fixed catalog buffer capacities. Not full opcode, symbol-link or raw-register qualification.', ram_mib=args.ram_mib if args.disk else 2048)
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'tables-fixture.HC').write_bytes(tables_fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/Unassemble.HC': fixture.read_bytes(),
                         '/Probe/UAsmCapacity.HC': capacity_fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+tables_fixture.read_bytes()+b'\nUATables;UACheck;\n')
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), ram_mib=args.ram_mib, reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/Unassemble.HC"')
            g.command('UACheck;')
        if 'UNASSEMBLE UNAVAILABLE\n' in g.collect():
            raise ValueError('Ui is not bound in the native public symbol chain')
        g.wait('UNASSEMBLE DONE\n')
        names=['unassemble-state.bin','unassemble-addresses.bin']+[f'unassemble-{i}.txt' for i in range(12)]
        if not args.disk:names.append('unassemble-tables.bin')
        for name in names:(out/name).write_bytes((g.out/name).read_bytes())
        report['state']=list(struct.unpack('<24q',(out/'unassemble-state.bin').read_bytes()))
        lengths=[1,1,1,5,2,4,4,1,1,3,5,2]
        expected=[v for i,n in enumerate(lengths) for v in [n,5 if i==10 else 0 if i==11 else -1]]
        if report['state']!=expected:raise ValueError('Instruction length or destination differs')
        addresses=struct.unpack('<12q',(out/'unassemble-addresses.bin').read_bytes())
        expected_text=[
            'XCHG\tU32 EAX,U32 EAX\n', 'RET\n', 'INT3\n',
            'MOV\tU32 EAX,I32 12345678\n', 'MOV\tU32 EAX,U32 EBX\n',
            'MOV\tU32 EAX,U32 10[EBP+ECX*4]\n', 'MOV\tU16 AX,I16 1234\n',
            'REX2\n', 'PUSH\tU32 EAX\n', 'ADD\tU32 EAX,I8 07\n']
        for i,bits,offset in [(10,32,5),(11,8,0)]:
            address=f'{addresses[i]+offset:X}'
            expected_text.append(f'JMP\tI{bits} $LK,"{address}",A="AD:0x{address}"$ \n')
        report['instructions']=[(out/f'unassemble-{i}.txt').read_text() for i in range(12)]
        if report['instructions']!=expected_text:raise ValueError('Instruction text differs')
        if not args.disk:
            generated=(out/'unassemble-tables.bin').read_bytes()
            if generated!=catalog.read_bytes():raise ValueError('Original opcode catalog is not reproduced')
            report['catalog_sha256']=hashlib.sha256(generated).hexdigest()
            report['catalog_counts']=list(struct.unpack('<2q',generated[:16]))
        if args.disk:
            g.command('#include "C:/Probe/UAsmCapacity.HC"')
            g.command('UANativeCapacity;')
            g.wait('UNASSEMBLE CAPACITIES DONE\n')
            (out/'unassemble-capacities.bin').write_bytes((g.out/'unassemble-capacities.bin').read_bytes())
            sizes=list(struct.unpack('<6q',(out/'unassemble-capacities.bin').read_bytes()))
            count32,count64=struct.unpack_from('<2q',catalog.read_bytes())
            wanted=[count32*4,count64*4,(count32+count64)*72]
            if sizes[::2]!=wanted:raise ValueError('Native catalog sizes differ from the complete original catalog')
            for requested,capacity in zip(sizes[::2],sizes[1::2]):
                #A fixed-size catalog buffer may have less than one native
                #page of spare capacity, independent of allocator header layout.
                if not requested<=capacity<requested+512:
                    raise ValueError('Catalog buffer retained an optional larger page allocation')
            report['native_catalog_capacities']=sizes
            report['catalog_entries']=count32+count64
            g.command('6*7;');report['arithmetic_pixels']=g.result_pixels()
        g.close()
        g = None
        if args.disk:
            after = pack['snapshot'](image.read_bytes())[1]
            if {n for n in set(before)|set(after) if before.get(n)!=after.get(n)} != set(additions):
                raise ValueError('Unexpected filesystem changes')
            report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report['result'] = 'pass'
    except BaseException as exc:
        report.update(result='fail',error=str(exc))
        raise
    finally:
        if g:
            try:
                g.close()
            except Exception as exc:
                report.update(result='fail',cleanup_error=str(exc))
        report['inputs_unchanged'] = all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__ == '__main__':
    main()
