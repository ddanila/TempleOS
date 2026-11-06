#!/usr/bin/env python3
"""Compare the original menu stack, real file loading and failed-parse rollback."""
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
    fixture = ROOT/'tests/guest/i386-menu-stack/Contract.HC'
    core = ROOT/'Adam/MenuStackCore.HC'
    original = subprocess.check_output(['git', 'show',
        'c26482bb6ad3f80106d28504ec5db3c6a360732c:Adam/Menu.HC'], cwd=ROOT)
    original_core = original[original.index(b'public CMenu *MenuPush('):original.index(b'U0 DrawMenu(')]
    if core.read_bytes() != original_core:
        raise ValueError('Shared menu stack differs from complete original bodies')
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
                info.get('mask') != 511 or (gold/'menu-stack.bin').read_bytes() != struct.pack('<q', 511)):
            raise ValueError('Passing original menu stack reference required')
        paths += [args.disk.resolve(), gold/'result.json', gold/'menu-stack.bin']
    out.mkdir(parents=True)
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', mode='native' if args.disk else 'pinned-original',
        expected_mask=1023 if args.disk else 511, input_sha256=pins,
        scope='Actual MenuPush/MenuFilePush/MenuPop: nested stack links, parsed message/64-bit args, caller ownership, exact normal heap recovery, empty pop and malformed parse preserving the old menu. Pinned original leaks on malformed parsing; native must recover its heap exactly. Original waits for actual Adam server readiness. Not drawing, mouse activation, allocation injection or whole menu qualification.')
    try:
        if args.disk:
            image = out/'working.img'
            source = fixture.read_bytes()+b'\nU0 MenuStackWrite(){I64 mask=MenuStackContract("C:/MenuStack.HC");FileWrite("C:/MenuStack.DATA",&mask,8);}\n'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            report['packaging'] = pack['package'](args.disk.resolve(), image,
                additions={'/Probe/MenuStack.HC': source})
            commands = ['#include "C:/Probe/MenuStack.HC"', 'MenuStackWrite;', '6*7;']
            report['commands'] = commands
            runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](
                image, out/'guest', commands, 64, True, accel='kvm', allow_inner_rejection=True)
            build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
            data = build['mutated_file_contents'](image, {'/MenuStack.DATA'})['/MenuStack.DATA']
            report['filesystem'] = build['verify_mutated_volume'](image)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            once = fixture.read_bytes()+b'\nU0 MenuStackLog(U8 *s){while(*s)OutU8(0xE9,*s++);}\n'
            once += b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;I64 menu_mask=MenuStackContract("B:/MenuStack.HC");U8 *menu_notice=MStrPrint("EXPORT menu-stack.bin %X %X\\n",&menu_mask,8);MenuStackLog(menu_notice);menu_notice=MStrPrint("EXPORT menu-observation.bin %X %X\\n",menu_stack_observation,48);MenuStackLog(menu_notice);MenuStackLog("DONE menu stack\\n");\n'
            (overlay/'Once.HC').write_bytes(once)
            iso = out/'original.iso'
            subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
            report['iso_sha256'] = sha(iso)
            subprocess.run(['python3', 'tools/guest-run.py', str(iso), '--out', str(out/'guest'), '--qmp-stdio', '--timeout', '120'], cwd=ROOT, check=True)
            data = (out/'guest/menu-stack.bin').read_bytes()
        (out/'menu-stack.bin').write_bytes(data)
        report['mask'] = struct.unpack('<q', data)[0]
        if report['mask'] != report['expected_mask']:
            raise ValueError('Menu stack differs: '+str(report['mask']))
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
