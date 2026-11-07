#!/usr/bin/env python3
"""Verify original and native raw register panels with font-derived pixel oracles."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-raw-registers/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    if args.disk:
        paths.append(args.disk.resolve())
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='RawDr with supplied register values, exact architecture-specific register/EIP pixels, compiler-off/on instruction row, raw mode/cursor/flags/document restoration; not full debugger lifecycle.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/RawRegisters.HC': fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+b'\nRRCheck;\n')
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/RawRegisters.HC"')
            g.command('RRCheck;')
        if 'RAW REGISTERS UNAVAILABLE\n' in g.collect():
            raise ValueError('RawDr is not bound in the native public symbol chain')
        g.wait('RAW REGISTERS DONE\n')
        names=['raw-registers-state.bin','raw-registers-0.bin','raw-registers-1.bin']
        for name in names:(out/name).write_bytes((g.out/name).read_bytes())
        report['state']=list(struct.unpack('<8q',(out/'raw-registers-state.bin').read_bytes()))
        if report['state']!=[17,0,0,1]*2:raise ValueError('Raw state or document roles differ')
        glyphs=[int(x,16) for x in re.findall(rb'0x([0-9A-Fa-f]{16})', (ROOT/'Kernel/FontStd.HC').read_bytes())]
        if len(glyphs)!=256:raise ValueError('Unexpected font')
        font=b''.join(struct.pack('<Q',v) for v in glyphs)
        def glyph(ch,y):return int(f'{font[ch*8+y]:08b}'[::-1],2)
        regs=['EAX','ECX','EDX','EBX','ESP','EBP','ESI','EDI'] if args.disk else ['RAX','RCX','RDX','RBX','RSP','RBP','RSI','RDI']+[f'R{i}' for i in range(8,16)]
        width=8 if args.disk else 16
        lines=[b'\xba'+f'{reg:>3}:{0x10203040+i:0{width}X}'.encode() for i,reg in enumerate(regs)]
        lines.append(b'\xba'+(('EIP' if args.disk else 'RIP')+f':{0x12345678:0{width}X}').encode())
        for case in range(2):
            raw=(out/f'raw-registers-{case}.bin').read_bytes()
            if len(raw)!=38400:raise ValueError('Raw image extent differs')
            for row,line in enumerate(lines):
                for x,ch in enumerate(line):
                    for y in range(8):
                        if raw[(row*8+y)*80+40+x]!=glyph(ch,y):
                            raise ValueError(f'Register pixels differ at case={case} row={row} char={x} scan={y}')
            instruction=bytes(raw[((len(regs)+2)*8+y)*80+41+x] for y in range(8) for x in range(38))
            if bool(any(instruction))!=bool(case):raise ValueError('Compiler flag did not control instruction row')
        report['register_rows_checked']=len(lines)
        if args.disk:
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
