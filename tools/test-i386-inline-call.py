#!/usr/bin/env python3
"""Exercise native inline assembly needed by the actual NativeCallArgs body."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-inline-call/Contract.HC'
    runtime=ROOT/'Kernel/I386/CallExtStrRuntime.HC'
    paths=[Path(__file__).resolve(),fixture,runtime,args.disk.resolve()]+[ROOT/('tools/'+n) for n in ['test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py']]+[ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths};out.mkdir()
    report=dict(result='running',input_sha256=pins,scope='Actual NativeCallArgs with zero/one/three arguments and 64-bit results; scales 1/2/4/8, register/memory DEC carry/zero flags, indirect memory CALL, exact opcode subsequences and invalid operand recovery. Not full native self-hosting.')
    # Preserve the complete helper verbatim, excluding the runtime-dependent wrapper.
    marker=b'I64 CallExtStr(U8 *name,...)'
    if marker not in runtime.read_bytes():raise ValueError('NativeCallArgs boundary changed')
    source=runtime.read_bytes().split(marker)[0]
    (out/'NativeCallArgs.HC').write_bytes(source);(out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
    image=out/'working.img';g=None
    try:
        report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/NativeCallArgs.HC':source,'/Probe/InlineCall.HC':fixture.read_bytes()})
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g=Guest(image,out/'guest',True);g.wait('DONE native kernel startup\n')
        g.command('#include "C:/Probe/InlineCall.HC"');g.command('InlineCallCheck;')
        g.wait('INLINE CALL MASK 63\n')
        patterns={'call-code.bin':['49ff74ce04ff34ce','ffd0'],
                  'scales-code.bin':['8b040e','03044e','03048e','0304ce']}
        for name,values in patterns.items():
            data=(g.out/name).read_bytes()
            for value in values:
                if bytes.fromhex(value) not in data:raise ValueError('Missing encoding '+name+': '+value)
        report['encoding_patterns']=patterns
        bad=['MOV EAX,U32 [ESI+ECX*0]','MOV EAX,U32 [ESI+ECX*3]',
             'MOV EAX,U32 [ESI+ECX*16]','MOV EAX,U32 [ESI+ESP*2]',
             'PUSH U8 [ESI]','CALL U8 [ESI]','DEC U8 [ESI]']
        report['rejected_operands']=[]
        for i,op in enumerate(bad):
            command=f'I64 ICBad{i}(){{asm {{{op}}}return 0;}}'
            start=len(g.collect());g.type(command);g.press('ret');g.wait('INPUT REJECT ',start=start)
            report['rejected_operands'].append(op);g.command('6*7;');g.result_pixels()
        g.close();g=None
        report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report.update(result='pass',mask=63)
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
