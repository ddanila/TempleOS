#!/usr/bin/env python3
"""Compare full JIT assembly fixups, signed branches, labels and actual trace output."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import re
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
EXPECTED=struct.pack('<40Q',*([1]*40))
TREE={}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--reference',type=Path)
    args = ap.parse_args()
    if args.disk and not args.reference:ap.error('Native runs require a passing original --reference')
    expected_bytes=EXPECTED
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-jit-fixup/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.extend([ROOT/'Kernel/FontStd.HC',ROOT/'Compiler/JITFixupCore.HC',ROOT/'Compiler/LabelForwardCore.HC',ROOT/'Compiler/CodeLabel.HC'])
    if args.disk:
        paths.extend([args.disk.resolve(),ROOT/'Kernel/I386/PublicLoader.HH'])
    if args.reference:paths.extend([args.reference.resolve()/'result.json',args.reference.resolve()/'normalized-trace.txt'])
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Complete shared JIT fixups: absolute add/sub widths, exports/deferred imports, relative/immediate groups, forward labels, function/global addresses, six range failures and caller-owned first-failure metadata, real trace disassembly, exact heap cleanup. Partial-progress error unwind and full assembler remain open.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/JITFixup.HC': b'#include \"/Kernel/I386/PublicLoader.HH\"\n'+fixture.read_bytes(),**{'/'+name:data for name,data in TREE.items()}}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            original=lambda name:subprocess.check_output(['git','show','c26482bb6ad3f80106d28504ec5db3c6a360732c:'+name],cwd=ROOT)
            load=original('Kernel/KLoad.HC');load=load[:load.index(b'U0 LoadPass1(')]
            load=load.replace(b'U0 SysSymImportsResolve(U8 *st_ptr,I64 ld_flags)',b'U0 SysSymImportsResolve(U8 *st_ptr,I64 ld_flags=0)')
            code=original('Compiler/PrsLib.HC');label=code[code.index(b'CCodeMisc *COCGoToLabelFind('):code.index(b'I64 COCFloatConstFind(')]
            code=original('Compiler/OptLib.HC');forward=code[:code.index(b'CHashClass *OptClassFwd(')]
            code=original('Compiler/CMain.HC');fix=code[code.index(b'U0 CmpFixUpJITAsm('):code.index(b'U0 CmpFixUpAOTAsm(')]
            aliases=b'#define LoadOneImport JFReferenceLoadOneImport\n#define SysSymImportsResolve JFReferenceSysSymImportsResolve\n#define COCGoToLabelFind JFReferenceLabelFind\n#define OptLabelFwd JFReferenceLabelFwd\n#define CmpFixUpJITAsm JFReferenceFixup\n'
            code=original('Compiler/PrsLib.HC')
            graph=code[code.index(b'CIntermediateCode *ICAdd('):code.index(b'CCodeMisc *COCGoToLabelFind(')]
            graph+=code[code.index(b'U0 COCDel('):code.index(b'U0 COCHeaderPut(')]
            reference=aliases+load+graph+label+forward+fix
            (out/'reference-core.HC').write_bytes(reference)
            report['reference_core_sha256']=hashlib.sha256(reference).hexdigest()
            (overlay/'Once.HC').write_bytes(reference+fixture.read_bytes())
            for name,data in TREE.items():
                target=overlay/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/JITFixup.HC"',timeout=900)
        g.wait('JIT FIXUP DONE\n',timeout=900)
        if args.disk:
            report['system_loads']=g.collect().count('PUBLIC JIT loaded\n')
            if report['system_loads']!=1:raise ValueError('Expected one normal system implementation load')
        data=(g.out/'jit-fixup.bin').read_bytes()
        (out/'jit-fixup.bin').write_bytes(data)
        heap=(g.out/'jit-heap.bin').read_bytes();(out/'jit-heap.bin').write_bytes(heap);report['heap_metrics']=list(struct.unpack('<9q',heap))
        trace=(g.out/'jit-trace.txt').read_bytes();(out/'jit-trace.txt').write_bytes(trace)
        base_bytes=(g.out/'jit-trace-base.bin').read_bytes();(out/'jit-trace-base.bin').write_bytes(base_bytes)
        base=struct.unpack('<Q',base_bytes)[0]
        normalized=trace
        for i in (0,1):
            value=('%X'%(base+i)).encode()
            normalized=re.sub(rb'(?<![0-9A-Fa-f])0*'+value+rb'(?![0-9A-Fa-f])',('<PC%d>'%i).encode(),normalized)
        (out/'normalized-trace.txt').write_bytes(normalized)
        report['trace']={'bytes':len(trace),'normalized_sha256':hashlib.sha256(normalized).hexdigest()}
        if args.reference:
            gold=json.loads((args.reference/'result.json').read_text())
            if gold.get('result')!='pass' or not gold.get('inputs_unchanged'):raise ValueError('Passing original reference required')
            if normalized!=(args.reference/'normalized-trace.txt').read_bytes():raise ValueError('Full trace differs after exact address normalization')
        words=struct.unpack('<40Q',data)
        report['state']=list(words)
        if data!=expected_bytes:
            report['mismatches']=[{'word':i,'actual':v,'expected':1} for i,v in enumerate(words) if v!=1]
            raise ValueError('JIT fixup differs; see raw records')
        report['outputs']={'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
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
        if g:g.screenshot('failure')
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
