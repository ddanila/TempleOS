"""Compare the traced BallGen vertices with both product rounding models."""
import argparse
from fractions import Fraction
from functools import lru_cache
import json
import math
from pathlib import Path
import struct
import sys

from vertex_trace import read

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tools'))
from i386_trig_oracle import rounded_trig, to_bits


@lru_cache(None)
def trig(angle_index):
    value = angle_index * (math.pi / 8)
    return [struct.unpack('<d', struct.pack('<Q', bits))[0]
            for bits in rounded_trig(to_bits(value), 400)]


def trunc_product(left, right, precision):
    product = Fraction(left) * Fraction(right)
    if not product:
        return 0
    exponent = abs(product.numerator).bit_length() - product.denominator.bit_length()
    if abs(product) < Fraction(2) ** exponent:
        exponent -= 1
    step = Fraction(2) ** (exponent + 1 - precision)
    return int(round(product / step) * step)


def vertices(precision):
    result = []
    for ring in range(-4, 4):
        for i in range(8):
            angle = 2 * i + ring
            for row, step in ((ring, angle), (ring, angle + 2),
                              (ring + 1, angle + 1), (ring + 1, angle + 3)):
                sine, cosine = trig(row)
                radius = 20 * cosine
                y, x = trig(step)
                result.append((trunc_product(radius, x, precision),
                               trunc_product(radius, y, precision), int(20 * sine)))
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('original', type=Path)
    parser.add_argument('native', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    original, native = read(args.original), read(args.native)
    models = {}
    for precision in (53, 64):
        predicted = vertices(precision)
        models[str(precision)] = {
            'mismatches_original': sum(a != b for a, b in zip(predicted, original)),
            'mismatches_native': sum(a != b for a, b in zip(predicted, native)),
        }
    report = {'calls': len(original), 'product_significand_bits': models}
    args.out.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
