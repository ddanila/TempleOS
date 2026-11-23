"""Measure original power reduction and compare it with a wide host calculation."""

import argparse
from decimal import Decimal, localcontext
from fractions import Fraction
import hashlib
import json
import math
from pathlib import Path
import re
import runpy
import struct
import subprocess
import sys


def from_bits(bits):
    return struct.unpack('>d', struct.pack('>Q', bits))[0]


def to_bits(value):
    return struct.unpack('>Q', struct.pack('>d', value))[0]


def truncate_binary64(value):
    nearest = float(value)
    if abs(Decimal.from_float(nearest)) > abs(value):
        nearest = math.nextafter(nearest, 0)
    return nearest


def corpus():
    bases = [0.125, 0.5, 0.75, 1.25, 1.5, 2.0, 3.0, 9.0]
    exponents = [-3.0, -0.5, 0.5, 2.0, 3.25]
    pairs = [(to_bits(base), to_bits(exponent)) for base in bases for exponent in exponents]
    for base in (0x3FEFFFFFFFFFFFFD, 0x3FEFFFFFFFFFFFFF,
                 0x3FF0000000000001, 0x3FF0000000000003):
        for exponent in (-2.0, 0.5, 2.0, float(1 << 40)):
            pairs.append((base, to_bits(exponent)))
    return pairs


def fixture(pairs):
    trace = Path('build/i386-power-reduction-v1/Trace.HC').read_bytes()
    reduction = trace[:trace.index(b'U0 PowerReductionProbe()')]
    rows = '\n'.join(f'  PowerCase({i},0x{base:016X}(F64),0x{exponent:016X}(F64));'
                     for i, (base, exponent) in enumerate(pairs))
    helper = r'''
U0 PowerCase(I64 index,F64 base,F64 exponent)
{
  F64 reduced=PowerReduced(base,exponent),result=base`exponent;
  U8 line[128],*p;
  StrPrint(line,"POWER case %d %016X %016X\n",index,*(&reduced)(U64 *),*(&result)(U64 *));
  p=line;
  while (*p) OutU8(0xE9,*p++);
}

U0 PowerWideProbe()
{
''' + rows + r'''
  U8 *p="POWER cases done\n";
  while (*p) OutU8(0xE9,*p++);
}
PowerWideProbe;
'''
    return reduction + helper.encode()



def fixed_log2(value):
    # Normalize to [1, 2), then extract binary logarithm bits by squaring.
    significand, exponent = math.frexp(value)
    fractional_bits = 116
    precision = 126
    significand = int(math.ldexp(significand, precision + 1))
    fraction = 0
    for _ in range(fractional_bits):
        significand = significand * significand >> precision
        fraction <<= 1
        if significand >= 1 << (precision + 1):
            significand >>= 1
            fraction |= 1
    return Fraction(exponent - 1) + Fraction(fraction, 1 << fractional_bits)


def truncate_fraction(value):
    nearest = float(value)
    if abs(Fraction(nearest)) > abs(value):
        nearest = math.nextafter(nearest, 0)
    return nearest


def compare(pairs, original):
    cases = []
    with localcontext() as ctx:
        ctx.prec = 100
        ln2 = Decimal(2).ln()
        for index, ((base_bits, exponent_bits), (reduced, result)) in enumerate(
                zip(pairs, original, strict=True)):
            base, exponent = map(from_bits, (base_bits, exponent_bits))
            significand, binary_exponent = math.frexp(base)
            if significand == 0.5:
                product = Decimal(binary_exponent - 1) * Decimal.from_float(exponent)
            else:
                product = Decimal.from_float(base).ln() * Decimal.from_float(exponent) / ln2
            fixed_reduced = to_bits(truncate_fraction(fixed_log2(base) * Fraction(exponent)))
            wide_reduced = to_bits(truncate_binary64(product))
            # Original stores the product, then subtracts the integer selected
            # from its wider intermediate before raising two to the fraction.
            original_reduced = Decimal.from_float(from_bits(reduced))
            integer = int(product)
            fraction = original_reduced - integer
            fraction_result = truncate_binary64((fraction * ln2).exp())
            wide_result = to_bits(math.ldexp(fraction_result, int(original_reduced)))
            cases.append({
                'index': index,
                'base': f'{base_bits:016X}',
                'exponent': f'{exponent_bits:016X}',
                'original_reduced': f'{reduced:016X}',
                'wide_reduced': f'{wide_reduced:016X}',
                'fixed_reduced': f'{fixed_reduced:016X}',
                'original_result': f'{result:016X}',
                'replayed_result': f'{wide_result:016X}',
            })
    return cases


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path)
    parser.add_argument('--reference', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    if bool(args.disk) != bool(args.reference):
        parser.error('--disk and --reference must be supplied together')
    out = args.out.resolve()
    out.mkdir()
    pairs = corpus()
    source = fixture(pairs)
    original_source_hash = hashlib.sha256(source).hexdigest()
    if args.disk:
        original = json.loads(args.reference.read_text())
        if original['result'] != 'pass' or original['fixture_sha256'] != original_source_hash:
            raise ValueError('Reference receipt does not match the corpus')
        reduced = Path('Kernel/I386/FloatExp.HC').read_bytes().split(b'\nF64 Exp(', 1)[0]
        fixed = Path(__file__).with_name('Fixed.HC').read_bytes()
        power = Path('build/i386-power-reduction-v1/Candidate.HC').read_bytes()
        reconstruct = power.split(b'\nF64 PowerSoftware(', 1)[0]
        cases = source[source.index(b'U0 PowerCase('):]
        cases = cases.replace(b'PowerReduced(base,exponent),result=base`exponent;',
                              b'PowerWideReduced(base,exponent),result=PowerReconstruct(reduced);')
        source = b'\n'.join((reduced, fixed, reconstruct, cases))
        packer = runpy.run_path('tools/package-i386-native-image.py')
        image = out / 'working.img'
        packer['package'](args.disk, image, additions={'/PowerWideProbe.HC': source})
    else:
        reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
        overlay = out / 'overlay'
        reference['restore_reference'](overlay)
        (overlay / 'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n' + source)
        image = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', str(overlay),
                        '--output', str(image)], check=True)
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = guest_type(image, out / 'guest', bool(args.disk))
    report = {'result': 'fail', 'fixture_sha256': hashlib.sha256(source).hexdigest(),
              'input_sha256': hashlib.sha256((args.disk or image).read_bytes()).hexdigest()}
    try:
        if args.disk:
            guest.wait('DONE native kernel startup\n')
            guest.command('#include "C:/PowerWideProbe.HC"')
        log = guest.wait('POWER cases done\n', 90)
        rows = re.findall(r'^POWER case (\d+) ([0-9A-F]{16}) ([0-9A-F]{16})$', log, re.M)
        if [int(index) for index, *_ in rows] != list(range(len(pairs))):
            raise ValueError('Incomplete original power trace')
        if args.disk:
            reference_cases = original['cases']
            report['reference_sha256'] = hashlib.sha256(args.reference.read_bytes()).hexdigest()
            report['reduction_mismatches'] = [
                int(index) for (index, reduced, _), reference in zip(rows, reference_cases, strict=True)
                if reduced != reference['original_reduced']]
            report['result_mismatches'] = [
                {'index': int(index), 'native': actual, 'original': reference['original_result']}
                for (index, _, actual), reference in zip(rows, reference_cases, strict=True)
                if actual != reference['original_result']]
            report['cases'] = len(rows)
            if report['reduction_mismatches'] or report['result_mismatches']:
                raise ValueError('Native power corpus differs from original')
            report['result'] = 'pass'
        else:
            cases = compare(pairs, [(int(a, 16), int(b, 16)) for _, a, b in rows])
            report.update(result='pass', cases=cases,
                          reduction_mismatches=[case['index'] for case in cases
                                                if case['original_reduced'] != case['wide_reduced']],
                          fixed_mismatches=[case['index'] for case in cases
                                            if case['original_reduced'] != case['fixed_reduced']],
                          reconstruction_mismatches=[case['index'] for case in cases
                                                     if case['original_result'] != case['replayed_result']])
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        guest.close()
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
