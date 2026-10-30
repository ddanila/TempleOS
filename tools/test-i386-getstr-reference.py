#!/usr/bin/env python3
"""Check original GetStr input semantics before implementing the native binding."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('reference', ROOT/'tools/test-i386-timeclock-reference.py')
reference = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reference)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--shared-dollar-input', action='store_true',
                        help='Use the current extracted dollar-input core and original editor integration')
    parser.add_argument('--shared-getstr', action='store_true',
                        help='Use current shared GetStr wrapper and document-input cores')
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    overlay = out/'reference-overlay'
    overlay.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-getstr-reference'
    inputs = [Path(__file__).resolve(), Path(reference.__file__), fixture/'Once.HC',
              ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py']
    report = dict(result='running', reference_revision=reference.REFERENCE,
                  repair_revision=reference.REPAIRS,
                  reference_sha256=reference.restore_reference(overlay),
                  input_sha256={str(p):reference.sha(p) for p in inputs},
                  scope='Thirteen scripted GetStr cases including backspace, erased default, tabs, spaces, dollar commands/escaping and extended bytes; DocScanLine structure/cursor checks; physical keyboard, navigation/replay, prompt formatting and task exit remain open')
    report['mode'] = 'shared-dollar-input' if args.shared_dollar_input else 'pinned-original'
    report['source_overrides'] = {}
    if args.shared_dollar_input:
        for name in ('Adam/DolDoc/DocChar.HC', 'Adam/DolDoc/DocDollarInputCore.HC'):
            path = ROOT/name
            (overlay/name).write_bytes(path.read_bytes())
            report['source_overrides'][name] = reference.sha(path)
            report['input_sha256'][str(path)] = reference.sha(path)
    if args.shared_getstr:
        report['mode'] = 'shared-getstr'
        for name in ('Kernel/SerialDev/Message.HC', 'Kernel/GetStrCore.HC',
                     'Kernel/KeyGetCore.HC', 'Kernel/KeyScanCore.HC',
                     'Kernel/KeyDescFlag.HH', 'Kernel/GetStrFlags.HH', 'Adam/DolDoc/DocGet.HC',
                     'Adam/DolDoc/DocGetStrCore.HC', 'Adam/DolDoc/DocGetNumberCore.HC', 'Adam/DolDoc/DocGetKeyCore.HC',
                     'Adam/DolDoc/DocScanLineCore.HC'):
            path = ROOT/name
            (overlay/name).parent.mkdir(parents=True, exist_ok=True)
            (overlay/name).write_bytes(path.read_bytes())
            report['source_overrides'][name] = reference.sha(path)
            report['input_sha256'][str(path)] = reference.sha(path)
    expected = {'hook.bin':b'hook\0', 'hook-default.bin':b'fallback\0', 'single.bin':b'alpha\0', 'empty.bin':b'\0',
                'default.bin':b'fallback\0', 'multiline.bin':b'alpha\nbeta\n\0',
                'cancel.bin':b'\0', 'cancel-default.bin':b'fallback\0',
                'backspace.bin':b'abZ\0', 'erased-default.bin':b'fallback\0',
                'tab.bin':b'alpha\tbeta\0', 'spaces.bin':b'  alpha  \0',
                'markup.bin':b'cash$\0', 'dollars.bin':b'$RED$cash$$\0',
                'extended.bin':b'\x82\xa3\0',
                'dollar-keys.bin':b'cash$\0',
                'dollar-plain.bin':b'$RED$cash$$\0',
                'scan-empty.bin':b'\0', 'scan-first.bin':b'alpha\tbeta\0',
                'scan-second.bin':b'second\0', 'scan-shift.bin':b'$SX,-3$$SY,2$\0'}
    try:
        iso = out/'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',str(overlay),
                        '--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256'] = reference.sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),
                        '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        observed = {name:(out/'guest'/name).read_bytes() for name in expected}
        report['observed_hex'] = {name:data.hex() for name,data in observed.items()}
        if observed != expected:
            raise ValueError('Original GetStr differs from explicit byte expectations')
        if 'PASS original GetStr hook and prompt\n' not in (out/'guest/debug.log').read_text():
            raise ValueError('Original hook/prompt checks did not complete')
        if 'PASS original typed dollar state and growth\n' not in (out/'guest/debug.log').read_text():
            raise ValueError('Original typed dollar state/growth checks did not complete')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        if any(reference.sha(Path(p)) != digest for p,digest in report['input_sha256'].items()):
            report.update(result='fail', error='Reference fixture or tools changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
