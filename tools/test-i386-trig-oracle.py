#!/usr/bin/env python3
"""Audit independent trig vectors against libm and exceptional-value contracts."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
from i386_trig_oracle import INF, MASK, ONE, QUIET, SIGN, trig_inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('vectors', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    data = args.vectors.read_bytes()
    report = dict(result='running', vector_sha256=hashlib.sha256(data).hexdigest(),
                  scope='Oracle audit only; not native provider qualification')
    try:
        if len(data) != 1024*24:
            raise AssertionError('Expected 1024 three-word vectors')
        rows = list(struct.iter_unpack('<3Q', data))
        if [row[0] for row in rows] != trig_inputs():
            raise AssertionError('Input corpus differs from the pinned generator')
        checked = worst = 0
        for bits, sine, cosine in rows:
            magnitude = bits & MASK
            if magnitude > INF:
                assert sine == cosine == bits | QUIET
                continue
            if magnitude == INF:
                assert sine == cosine == 0xFFF8000000000000
                continue
            if not magnitude:
                assert sine == bits and cosine == ONE
            x = struct.unpack('<d', struct.pack('<Q', bits))[0]
            for actual, function in ((sine, math.sin), (cosine, math.cos)):
                expected = struct.unpack('<Q', struct.pack('<d', function(x)))[0]
                if (actual ^ expected) & SIGN:
                    raise AssertionError(f'Sign differs for {bits:016X}')
                distance = abs(actual-expected)
                if distance > 1:
                    raise AssertionError(f'libm discrepancy for {bits:016X}: {distance} ULP')
                worst = max(worst, distance)
                checked += 1
        table = {bits: (sine, cosine) for bits, sine, cosine in rows}
        for bits, sine, cosine in rows:
            if bits & MASK < INF and bits ^ SIGN in table:
                other_sine, other_cosine = table[bits ^ SIGN]
                assert other_sine == sine ^ SIGN and other_cosine == cosine
        report.update(result='pass', finite_results=checked, maximum_libm_ulp=worst,
                      signed_zero=True, nan_payload_quieting=True, odd_even_symmetry=True)
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    print(f'PASS: {checked} finite results, <= {worst} ULP from host libm')


if __name__ == '__main__':
    main()
