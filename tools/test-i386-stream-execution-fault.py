#!/usr/bin/env python3
"""Compare execution-fault stream unwinding and escaped literal storage."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
EXPECTED=struct.pack('<13Q',*([1]*13))
TREE={}
LITERAL=b'stream-execution-fault-owner-0123456789\0'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    modes=ap.add_mutually_exclusive_group()
    modes.add_argument('--runtime-block', action='store_true', help='Exercise the same escape in ordinary runtime code')
    modes.add_argument('--nested', action='store_true', help='Fault in nested streams with unfinished generated source')
    args = ap.parse_args()
    expected_bytes=EXPECTED
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-stream-execution-fault/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    if args.disk:
        paths.append(args.disk.resolve())
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins, runtime_block=args.runtime_block, nested=args.nested,
                  scope='Normal ExePutS execution fault after a literal store, in runtime or single/nested compile-time blocks; parent closure, subsequent compilation, heap reuse, no post-throw write and no unfinished declaration injection. Separate nonliteral exception used-byte control; not OutMem/cancellation/task-death qualification')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/StreamExecutionFault.HC': fixture.read_bytes(),**TREE}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+(b'\nsl_runtime=TRUE;' if args.runtime_block else b'\nsl_nested=TRUE;' if args.nested else b'')+b'\nSLCheck;\nSLNoLiteral;\nSLAfter;\n')
            for name,data in TREE.items():
                target=overlay/name.lstrip('/');target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/StreamExecutionFault.HC"')
            start=len(g.collect())
            g.type('sl_runtime=TRUE;SLCheck;' if args.runtime_block else 'sl_nested=TRUE;SLCheck;' if args.nested else 'SLCheck;');g.press('ret')
            deadline=time.monotonic()+240
            while g.p.poll() is None and time.monotonic()<deadline:
                segment=g.collect()[start:]
                if 'SL FAULT CHECK DONE\n' in segment and 'COMMAND OK\n' in segment:break
                time.sleep(.1)
            else:raise TimeoutError('Missing failed-input recovery marker')
            if segment.count('INPUT REJECT ')!=1 or 'errors 0000000000000000 ' not in segment or 'token stream_bad ' in segment:
                raise ValueError('Expected exactly one deliberate compiler rejection')
            start=len(g.collect());g.type('SLNoLiteral;');g.press('ret')
            deadline=time.monotonic()+240
            while g.p.poll() is None and time.monotonic()<deadline:
                segment=g.collect()[start:]
                if 'SL NO LITERAL DONE\n' in segment and 'COMMAND OK\n' in segment:break
                time.sleep(.1)
            else:raise TimeoutError('Missing repeated nonliteral-exception recovery')
            if segment.count('INPUT REJECT ')!=40 or 'token stream_bad ' in segment:
                raise ValueError('Unexpected nonliteral exception observations')
            g.command('SLAfter;')
        g.wait('STREAM EXECUTION FAULT DONE\n')
        negative=(g.out/'stream-execution-fault-negative.bin').read_bytes()
        (out/'stream-execution-fault-negative.bin').write_bytes(negative)
        before_used,after_used=struct.unpack('<2q',negative)
        report['nonliteral_code_heap']=dict(before=before_used,after=after_used,delta=after_used-before_used,warmup=8,repetitions=32)
        if before_used<=0 or after_used<0:raise ValueError('Invalid code-heap observation')
        if args.disk and after_used!=before_used:raise ValueError('Nonliteral failures retained code-heap bytes')
        diagnostic=(g.out/'stream-execution-fault-error.DD').read_bytes()
        (out/'stream-execution-fault-error.DD').write_bytes(diagnostic)
        fault=(g.out/'stream-execution-fault-code.bin').read_bytes()
        (out/'stream-execution-fault-code.bin').write_bytes(fault)
        if fault!=b'Compiler':raise ValueError('Missing intended execution exception')
        if b'Undefined' in diagnostic:raise ValueError('Unexpected syntax failure')
        data=(g.out/'stream-execution-fault.bin').read_bytes()
        (out/'stream-execution-fault.bin').write_bytes(data)
        literal=(g.out/'stream-execution-fault.txt').read_bytes();(out/'stream-execution-fault.txt').write_bytes(literal)
        report['literal_sha256']=hashlib.sha256(literal).hexdigest()
        if data!=expected_bytes:
            actual=struct.unpack('<'+'Q'*(len(data)//8),data)
            expected=struct.unpack('<'+'Q'*(len(expected_bytes)//8),expected_bytes)
            report['mismatches']=[{'word':i,'actual':a,'expected':e} for i,(a,e) in enumerate(zip(actual,expected)) if a!=e]
            raise ValueError('Stream literal ownership differs; see raw records')
        if literal!=LITERAL:raise ValueError('Retained literal bytes differ')
        report['state']=list(struct.unpack('<13Q',data))
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
