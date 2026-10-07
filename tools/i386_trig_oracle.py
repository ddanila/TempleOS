"""Independent binary64 Sin/Cos expectations from high-precision Decimal series.

Machin's pi identity and direct Taylor sums deliberately differ from the
range-reduction tables and minimax polynomials used by a production provider.
Every finite result must round identically at two independent precisions.
"""
from decimal import Decimal, localcontext
from functools import lru_cache
import hashlib
import json
import struct

MASK = (1 << 63)-1
INF = 0x7FF0000000000000
QUIET = 1 << 51
SIGN = 1 << 63
ONE = 0x3FF0000000000000


def to_bits(value):
    return struct.unpack('<Q', struct.pack('<d', float(value)))[0]


@lru_cache(maxsize=None)
def decimal_pi(precision):
    with localcontext() as context:
        context.prec = precision + 20

        def atan_inverse(denominator):
            x = Decimal(1)/denominator
            square = x*x
            term = x
            total = term
            index = 1
            while True:
                term *= -square
                updated = total + term/(2*index+1)
                if updated == total:
                    return total
                total = updated
                index += 1

        value = 16*atan_inverse(5)-4*atan_inverse(239)
        context.prec = precision
        return +value


def rounded_trig(bits, precision):
    magnitude = bits & MASK
    if magnitude > INF:
        return bits | QUIET, bits | QUIET
    if magnitude == INF:
        return 0xFFF8000000000000, 0xFFF8000000000000
    if not magnitude:
        return bits, ONE
    value = struct.unpack('<d', struct.pack('<Q', bits))[0]
    with localcontext() as context:
        context.prec = precision
        pi = decimal_pi(precision)
        x = Decimal.from_float(value) % (2*pi)
        if x > pi:
            x -= 2*pi
        if x < -pi:
            x += 2*pi
        square = x*x
        sin_term = sin_sum = x
        cos_term = cos_sum = Decimal(1)
        index = 1
        while True:
            sin_term *= -square/((2*index)*(2*index+1))
            cos_term *= -square/((2*index-1)*(2*index))
            new_sin = sin_sum + sin_term
            new_cos = cos_sum + cos_term
            if new_sin == sin_sum and new_cos == cos_sum:
                return to_bits(new_sin), to_bits(new_cos)
            sin_sum, cos_sum = new_sin, new_cos
            index += 1


def trig_inputs():
    special = [0, 1, 2, (1 << 52)-1, 1 << 52, INF-1,
               INF, INF+1, INF+QUIET+0x1234, ONE, ONE-1, ONE+1]
    values = special + [v | SIGN for v in special]
    with localcontext() as context:
        context.prec = 400
        pi = decimal_pi(400)
        for multiplier in range(1, 65):
            center = to_bits(pi*multiplier/2)
            for offset in (-1, 0, 1):
                values += [center+offset, (center+offset) | SIGN]
    for exponent in range(0, 2047, 11):
        bits = (exponent << 52) | 0x5A5A5A5A5A5A5
        values += [bits, bits | SIGN]
    seed = 0x38651C05
    while len(values) < 1024:
        seed = (seed*6364136223846793005+1442695040888963407) & ((1 << 64)-1)
        values.append(seed)
    return values


def make_trig_oracle():
    rows = []
    for bits in trig_inputs():
        lower = rounded_trig(bits, 400)
        higher = rounded_trig(bits, 480)
        if lower != higher:
            raise ArithmeticError(f'Trig rounding did not stabilize for {bits:016X}')
        rows.append(struct.pack('<3Q', bits, *higher))
    return b''.join(rows)


if __name__ == '__main__':
    import argparse
    from pathlib import Path
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    data = make_trig_oracle()
    (args.out/'vectors.bin').write_bytes(data)
    report = dict(result='pass', count=len(data)//24,
                  vector_sha256=hashlib.sha256(data).hexdigest(),
                  generator_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  precision_digits=[400, 480],
                  scope='Independent oracle generation only; no native Sin/Cos qualification')
    (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    print(f'PASS: {report["count"]} stable trig vectors')
