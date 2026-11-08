#!/usr/bin/env python3
"""Compare complete AOT assembly fixups and parent-packet ownership."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = struct.pack('<32Q', *([1]*32))
NEGATIVE = struct.pack('<2q', -24, -0x10010)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--reference', type=Path)
    args = ap.parse_args()
    if args.disk and not args.reference:
        ap.error('Native runs require a passing original --reference')
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-aot-fixup/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py','test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py','build-iso.py')]
    if args.disk:
        paths += [args.disk.resolve(), ROOT/'Kernel/I386/PublicLoader.HH', ROOT/'Kernel/FontStd.HC',
                  ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py']
        if (ROOT/'Compiler/AOTFixupCore.HC').exists():
            paths.append(ROOT/'Compiler/AOTFixupCore.HC')
    if args.reference:
        paths += [args.reference.resolve()/'result.json', args.reference.resolve()/'aot-negative.bin']
    out.mkdir()
    pins = {str(p):sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Complete AOT fixups: eight absolute kinds, parent transfer and order, retained export/import/default records, grouped and forwarded local labels, negative I64 displacement, signed 8/16 bounds and 32 upper bound/backward cases, five first-record exceptions, record/string ownership and exact heap cleanup. Original consumed-name retention is measured then caller-cleaned; native must free the owned names. Partial-progress unwind and full assembler/AOT file generation remain open.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            header = b'#include "/Kernel/I386/PublicLoader.HH"\n'
            additions = {'/Probe/AOTFixup.HC':header+fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(),image,additions=additions)
        else:
            overlay = out/'overlay';overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            original = lambda name: subprocess.check_output(['git','show','c26482bb6ad3f80106d28504ec5db3c6a360732c:'+name],cwd=ROOT)
            code = original('Compiler/PrsLib.HC')
            graph = code[code.index(b'CIntermediateCode *ICAdd('):code.index(b'CCodeMisc *COCGoToLabelFind(')]
            graph += code[code.index(b'U0 COCDel('):code.index(b'U0 COCHeaderPut(')]
            label = code[code.index(b'CCodeMisc *COCGoToLabelFind('):code.index(b'I64 COCFloatConstFind(')]
            code = original('Compiler/OptLib.HC');forward = code[:code.index(b'CHashClass *OptClassFwd(')]
            code = original('Compiler/CMain.HC');fix = code[code.index(b'U0 CmpFixUpAOTAsm('):code.index(b'I64 Cmp(')]
            aliases = b'#define COCGoToLabelFind AFReferenceLabel\n#define OptLabelFwd AFReferenceForward\n#define CmpFixUpAOTAsm AFReferenceFixup\n'
            reference = aliases+graph+label+forward+fix
            (out/'reference-core.HC').write_bytes(reference)
            report['reference_core_sha256'] = hashlib.sha256(reference).hexdigest()
            (overlay/'Once.HC').write_bytes(reference+b'#define AF_REFERENCE 1\n'+fixture.read_bytes())
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image,out/'guest',bool(args.disk),reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/AOTFixup.HC"',timeout=900)
        g.wait('AOT FIXUP DONE\n',timeout=900)
        for name in ('aot-fixup.bin','aot-negative.bin','aot-heap.bin'):
            (out/name).write_bytes((g.out/name).read_bytes())
        data = (out/'aot-fixup.bin').read_bytes()
        report['state'] = list(struct.unpack('<32Q',data))
        report['heap_metrics'] = list(struct.unpack('<5q',(out/'aot-heap.bin').read_bytes()))
        if data != EXPECTED:
            report['mismatches'] = [{'word':i,'actual':v,'expected':1} for i,v in enumerate(report['state']) if v!=1]
            raise ValueError('AOT fixup contract differs; see raw records')
        negative = (out/'aot-negative.bin').read_bytes()
        if negative != NEGATIVE:
            raise ValueError('Backward I64 displacement or retained relative subtraction differs')
        if args.reference:
            gold = json.loads((args.reference/'result.json').read_text())
            if gold.get('result')!='pass' or not gold.get('inputs_unchanged'):
                raise ValueError('Passing original reference required')
            if negative != (args.reference/'aot-negative.bin').read_bytes():
                raise ValueError('Raw relative values differ from original')
        if args.disk:
            if report['heap_metrics'][3]!=0:
                raise ValueError('Cold system load retained caller heap bytes')
            report['system_loads'] = g.collect().count('PUBLIC JIT loaded\n')
            if report['system_loads']!=1:
                raise ValueError('Expected one normal system fixup implementation load')
            g.command('6*7;');report['arithmetic_pixels'] = g.result_pixels()
        g.close();g = None
        if args.disk:
            after = pack['snapshot'](image.read_bytes())[1]
            if {n for n in set(before)|set(after) if before.get(n)!=after.get(n)} != set(additions):
                raise ValueError('Unexpected filesystem changes')
            report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report['result'] = 'pass'
    except BaseException as exc:
        report.update(result='fail',error=str(exc))
        if g:g.screenshot('failure')
        raise
    finally:
        if g:g.close()
        report['inputs_unchanged'] = all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':
    main()
