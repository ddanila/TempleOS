#!/usr/bin/env python3
"""Run the production stack operand emitters and frame-fold guards on the pinned original OS."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    overlay = out / 'overlay'
    overlay.mkdir(parents=True)
    helper = ROOT / 'tools/test-i386-timeclock-reference.py'
    reference = runpy.run_path(str(helper))
    fixture = ROOT / 'tests/guest/i386-esp-displacement/Contract.HC'
    types = ROOT / 'Compiler/I386/Emit.HH'
    core = ROOT / 'Compiler/I386/EmitCore.HC'
    backend = ROOT / 'Compiler/I386/BackendCore.HC'
    backend_types = ROOT / 'Compiler/I386/Backend.HH'
    guards = fixture.with_name('FrameGuard.HC')
    paths = [Path(__file__).resolve(), helper, fixture, types, core, backend, backend_types, guards,
             ROOT / 'tools/build-iso.py', ROOT / 'tools/guest-run.py']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in paths}
    sources = reference['restore_reference'](overlay)
    def extract(path, start):
        text = path.read_text()
        a = text.index(start)
        b = text.index('\n}\n', a) + 3
        return text[a:b]
    logic_text = backend_types.read_text()
    a = logic_text.index('class CI386Logic\n')
    logic_source = logic_text[a:logic_text.index('};', a)+2] + '\n'
    source = types.read_text() + core.read_text().replace('#include "/Compiler/I386/Emit.HH"', '') + logic_source + extract(backend, 'CIntermediateCode *I386FrameAddressEnd(') + fixture.read_text() + guards.read_text()
    (overlay / 'Once.HC').write_text(source)
    report = dict(result='running', input_sha256=pins, reference_sha256=sources,
                  generated_source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  scope='Exact production emitter on original x64; encoding and measure/write agreement, not native runtime qualification')
    try:
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out', str(out / 'guest'), '--qmp-stdio', '--timeout', '90'], cwd=ROOT, check=True)
        rows = [s for s in (out / 'guest/debug.log').read_text().splitlines() if s.startswith('OBS ESP ')]
        expected = []
        for displacement in (0, 1, 127, 128, 0xFFFFFF7F, 0xFFFFFF80, 0xFFFFFFFF, 0x7FFFFFFF, 0x80000000):
            signed = struct.unpack('<i', struct.pack('<I', displacement))[0]
            for opcode in (0x8B, 0x89, 0xFF):
                for reg in (range(8) if opcode != 0xFF else (2,)):
                    if signed == 0:
                        mod, suffix = 0, b''
                    elif -128 <= signed <= 127:
                        mod, suffix = 1, struct.pack('b', signed)
                    else:
                        mod, suffix = 2, struct.pack('<i', signed)
                    code = bytes((opcode, (mod << 6) | (reg << 3) | 4, 0x24)) + suffix
                    expected.append(f'OBS ESP {opcode:X} {reg} {displacement:X} {len(code)} {len(code)} {code.hex().upper()}')
        expected.append('OBS ESP REJECT 1 0')
        if rows != expected:
            raise ValueError('ESP encodings, measure/write sizes, or invalid-register rejection differ; inspect guest log')
        ebp_rows = [s for s in (out / 'guest/debug.log').read_text().splitlines() if s.startswith('OBS EBP ')]
        ebp_expected = []
        for displacement in (0, 1, 127, 128, 0xFFFFFF7F, 0xFFFFFF80, 0xFFFFFFFF, 0x7FFFFFFF, 0x80000000):
            signed = struct.unpack('<i', struct.pack('<I', displacement))[0]
            code = (bytes((0x8D, 0x45)) + struct.pack('b', signed) if -128 <= signed <= 127
                    else bytes((0x8D, 0x85)) + struct.pack('<i', signed))
            ebp_expected.append(f'OBS EBP {displacement:X} {len(code)} {len(code)} {code.hex().upper()}')
        if ebp_rows != ebp_expected:
            raise ValueError('EBP encodings or measure/write lengths differ')
        log = (out / 'guest/debug.log').read_text()
        if log.count('OBS FRAME GUARD 1023\n') != 1:
            raise ValueError('Frame fold acceptance/rejection guards failed')
        report.update(result='pass', encodings=len(expected)-1, ebp_encodings=len(ebp_expected),
                      frame_guard_mask=1023, invalid_register_rejected_before_write=True)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == h for p, h in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
