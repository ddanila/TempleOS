"""Compare executable HolyC power expressions on original and native guests."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys


# Exact values observed under the pinned original SYS_POW implementation.
EXPECTED = ['4021FFFFFFFFFFFF', '4020000000000000',
            '4007FFFFFFFFFFFF', '3FD0000000000000']

EXPECTED_EDGES = [
    'C020000000000000', '4030000000000000', '4000000000000000',
    'C020000000000000', '0000000000000000', '3FF0000000000000',
    'FFF8000000000000', '7FEFFFFFFFFFFFFF', '0000000000000001',
    '0000000000000000',
]


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--wide-reduction', action='store_true')
parser.add_argument('--replay-reduction', type=Path)
parser.add_argument('--trace-reduction', action='store_true')
parser.add_argument('--edges', action='store_true')
parser.add_argument('--reduction-candidate', action='store_true')
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', required=True, type=Path)
args = parser.parse_args()
if args.wide_reduction and not args.reduction_candidate:
    parser.error('--wide-reduction requires --reduction-candidate')
if args.replay_reduction and (not args.reduction_candidate or args.edges):
    parser.error('--replay-reduction requires the four-case native candidate')
if args.trace_reduction and (args.disk or args.edges):
    parser.error('--trace-reduction requires the four-case original workflow')
if args.reduction_candidate and not args.disk:
    parser.error('--reduction-candidate requires --disk')
out = args.out.resolve()
out.mkdir()
probe = Path(__file__).with_name('Edges.HC' if args.edges else 'Probe.HC').read_bytes()
reference_probe = probe
if args.reduction_candidate:
    core = Path('Kernel/I386/FloatExp.HC').read_bytes()
    reduced = core[:core.index(b'\nF64 Exp(')]
    experiment = Path('build/i386-power-reduction-v1/Candidate.HC').read_bytes()
    if args.wide_reduction:
        fixed = Path('build/i386-power-wide-reference-v1/Fixed.HC').read_bytes()
        expression = b'Log2(Abs(base))*exponent'
        if experiment.count(expression) != 1:
            raise ValueError('Unexpected candidate reduction expression')
        experiment = fixed + b'\n' + experiment.replace(expression, b'PowerWideReduced(base,exponent)')
    probe = reduced + b'\n' + experiment + b'\n' + probe.replace(
        b'base`2;', b'PowerSoftware(base,2);').replace(
        b'base`exponent;', b'PowerSoftware(base,exponent);')
if args.replay_reduction:
    reference = json.loads(args.replay_reduction.read_text())
    if (reference['result'] != 'pass' or
            reference['reference_fixture_sha256'] != hashlib.sha256(reference_probe).hexdigest()):
        raise ValueError('Wrong original reduction source')
    calls = (b'PowerSquare(3)', b'PowerDynamic(2,3)', b'PowerDynamic(9,0.5)', b'PowerDynamic(2,-2)')
    for call, bits in zip(calls, reference['reduced'], strict=True):
        if not re.fullmatch(r'[0-9A-F]{16}', bits) or probe.count(call) != 1:
            raise ValueError('Invalid original reduction input')
        probe = probe.replace(call, f'PowerReconstruct(0x{bits}(F64))'.encode())
if args.trace_reduction:
    trace = Path('build/i386-power-reduction-v1/Trace.HC').read_bytes()
    probe = trace + b'\n' + probe
if args.disk:
    packer = runpy.run_path('tools/package-i386-native-image.py')
    image = out / 'working.img'
    packer['package'](args.disk, image, additions={'/PowerProbe.HC': probe})
else:
    reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
    overlay = out / 'overlay'
    reference['restore_reference'](overlay)
    (overlay / 'Once.HC').write_bytes(
        b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n' + probe)
    image = out / 'original.iso'
    subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', str(overlay),
                    '--output', str(image)], check=True)
guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = guest_type(image, out / 'guest', bool(args.disk))
report = {'result': 'fail',
          'reference_fixture_sha256': hashlib.sha256(reference_probe).hexdigest(),
          'fixture_sha256': hashlib.sha256(probe).hexdigest(),
          'input_sha256': hashlib.sha256((args.disk or image).read_bytes()).hexdigest()}
try:
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/PowerProbe.HC"')
    log = guest.wait('POWER values ', 80)
    values = re.search(r'^POWER values ([0-9A-F ]+)$', log, re.M)
    if values is None:
        raise ValueError('Missing power results')
    report['values'] = values[1].split()
    if args.reduction_candidate and not args.replay_reduction:
        report['native_reduced'] = re.findall(r'^POWER native-reduced ([0-9A-F]{16})$', log, re.M)
    expected = EXPECTED_EDGES if args.edges else EXPECTED
    count = len(expected)
    if len(report['values']) != count or any(len(value) != 16 for value in report['values']):
        raise ValueError('Incomplete power results')
    if report['values'] != expected:
        raise ValueError('Power values differ from the pinned original')
    if args.trace_reduction:
        reduced = re.search(r'^POWER reduced ([0-9A-F ]+)$', log, re.M)
        if reduced is None or len(reduced[1].split()) != len(EXPECTED):
            raise ValueError('Incomplete original reduction trace')
        report['reduced'] = reduced[1].split()
    report['result'] = 'pass'
except Exception as error:
    report['error'] = str(error)
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
