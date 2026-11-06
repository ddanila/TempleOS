#!/usr/bin/env python3
"""Compare public exception reporting and actual catch/propagation behavior."""
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
    ap.add_argument('--reference', type=Path)
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-put-except/Contract.HC'
    core = ROOT/'Kernel/PutExceptCore.HC'
    original = subprocess.check_output(['git', 'show',
        'c26482bb6ad3f80106d28504ec5db3c6a360732c:Kernel/KExcept.HC'], cwd=ROOT)
    original_core = original[original.index(b'U0 PutExcept('):original.index(b'#exe {Option')]
    if core.read_bytes() != original_core:
        raise ValueError('Shared PutExcept differs from complete original bodies')
    paths = [Path(__file__).resolve(), fixture, core] + [ROOT/n for n in (
        'tools/build-iso.py', 'tools/guest-run.py', 'tools/test-i386-timeclock-reference.py',
        'tools/package-i386-native-image.py', 'tools/build-i386-kernel.py',
        'tools/test-i386-timeclock-welcome.py', 'Kernel/FontStd.HC')]
    if args.disk:
        if not args.reference:
            ap.error('Native run requires --reference')
        gold = args.reference.resolve()
        info = json.loads((gold/'result.json').read_text())
        if (info.get('result') != 'pass' or not info.get('inputs_unchanged') or
                info.get('input_sha256', {}).get(str(fixture)) != sha(fixture) or
                info.get('mask') != 31 or (gold/'put-except.bin').read_bytes() != struct.pack('<q', 31)):
            raise ValueError('Passing original PutExcept reference required')
        paths += [args.disk.resolve(), gold/'result.json', gold/'put-except.bin', gold/'put-except.DD']
    out.mkdir(parents=True)
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', mode='native' if args.disk else 'pinned-original',
        expected_mask=31, input_sha256=pins,
        scope='Original PutExcept reporting with controlled caller addresses, default/false catch flag, actual handled and propagated exceptions; byte-identical DolDoc output. Not all symbolized caller stacks.')
    try:
        if args.disk:
            image = out/'working.img'
            source = fixture.read_bytes()+b'\nU0 PutExceptWrite(){I64 mask=PutExceptContract;FileWrite("C:/PutExcept.DATA",&mask,8);FileWrite("C:/PutExcept.DD",pe_output,pe_size);}\n'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            report['packaging'] = pack['package'](args.disk.resolve(), image,
                additions={'/Probe/PutExcept.HC': source})
            commands = ['#include "C:/Probe/PutExcept.HC"', 'PutExceptWrite;', '6*7;']
            report['commands'] = commands
            runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](
                image, out/'guest', commands, 64, True, accel='kvm', allow_inner_rejection=True)
            build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
            data = build['mutated_file_contents'](image, {'/PutExcept.DATA'})['/PutExcept.DATA']
            output = build['mutated_file_contents'](image, {'/PutExcept.DD'})['/PutExcept.DD']
            if output != (gold/'put-except.DD').read_bytes():
                raise ValueError('Exception document differs from original')
            report['filesystem'] = build['verify_mutated_volume'](image)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            once = fixture.read_bytes()+b'\nU0 PutExceptLog(U8 *s){while(*s)OutU8(0xE9,*s++);}\n'
            once += b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;I64 except_mask=PutExceptContract;U8 *except_notice=MStrPrint("EXPORT put-except.bin %X %X\\n",&except_mask,8);PutExceptLog(except_notice);except_notice=MStrPrint("EXPORT put-except.DD %X %X\\n",pe_output,pe_size);PutExceptLog(except_notice);PutExceptLog("DONE PutExcept\\n");\n'
            (overlay/'Once.HC').write_bytes(once)
            iso = out/'original.iso'
            subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
            report['iso_sha256'] = sha(iso)
            subprocess.run(['python3', 'tools/guest-run.py', str(iso), '--out', str(out/'guest'), '--qmp-stdio', '--timeout', '120'], cwd=ROOT, check=True)
            data = (out/'guest/put-except.bin').read_bytes()
            output = (out/'guest/put-except.DD').read_bytes()
        expected = (b'Except:PE:' + b':'.join(
            f'$LK,"{i}",A="AD:0x{i}"$'.encode() for i in range(1, 7)) + b'\n') * 4 + b'\x05'
        if output != expected:
            raise ValueError('Exception report differs from independent expected links')
        report['report_bytes'] = len(output)
        (out/'put-except.DD').write_bytes(output)
        (out/'put-except.bin').write_bytes(data)
        report['mask'] = struct.unpack('<q', data)[0]
        if report['mask'] != report['expected_mask']:
            raise ValueError('PutExcept differs: '+str(report['mask']))
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(p.is_file() and sha(p) == pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report['result'] = 'fail'
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
