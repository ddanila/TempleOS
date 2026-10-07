"""Executable integer-limb design for the no-FPU trigonometric reducer.

This is a host model, not an OS provider. Multiplication uses exactly 32-bit
limbs and 64-bit accumulators, suitable for translation to the i386 backend.
"""
from decimal import Decimal, ROUND_HALF_EVEN, localcontext
from functools import lru_cache
import math
import struct
from i386_trig_oracle import decimal_pi, trig_inputs, MASK, INF

PRECISION_BITS = 1664
WORD_MASK = (1 << 32)-1


@lru_cache(maxsize=1)
def reciprocal_limbs():
    constants = []
    for precision in (600, 680):
        with localcontext() as context:
            context.prec = precision
            constants.append(int((Decimal(2)/decimal_pi(precision))*(1 << PRECISION_BITS)))
    if constants[0] != constants[1]:
        raise ArithmeticError('2/pi constant did not stabilize')
    return tuple((constants[0] >> (32*i)) & WORD_MASK for i in range(52))


def product_limbs(significand):
    product = [0]*54
    table = reciprocal_limbs()
    for j in range(2):
        word = (significand >> (32*j)) & WORD_MASK
        carry = 0
        for i in range(52):
            total = table[i]*word+product[i+j]+carry
            if total >= 1 << 64:
                raise ArithmeticError('64-bit accumulator overflow')
            product[i+j] = total & WORD_MASK
            carry = total >> 32
        product[52+j] = carry
    return product


def get_bit(words, index):
    if index < 0 or index >= len(words)*32:
        return 0
    return (words[index//32] >> (index%32)) & 1


def truncate(words, count):
    result = words.copy()
    for i in range(len(result)):
        remaining = count-32*i
        if remaining <= 0:
            result[i] = 0
        elif remaining < 32:
            result[i] &= (1 << remaining)-1
    return result


def fraction_chunks(words, binary_point):
    top = len(words)*32-1
    while top >= 0 and not get_bit(words, top):
        top -= 1
    if top < 0:
        return 0.0, 0.0
    chunks = []
    for offset in (0, 53):
        value = 0
        for index in range(53):
            value = (value << 1) | get_bit(words, top-offset-index)
        chunks.append(math.ldexp(float(value), top-offset-52-binary_point))
    return tuple(chunks)


def two_product(a, b):
    product = a*b
    splitter = 134217729.0
    split = splitter*a
    a_hi = split-(split-a)
    a_lo = a-a_hi
    split = splitter*b
    b_hi = split-(split-b)
    b_lo = b-b_hi
    error = ((a_hi*b_hi-product)+a_hi*b_lo+a_lo*b_hi)+a_lo*b_lo
    return product, error


def reduce_angle(bits):
    magnitude = bits & MASK
    if magnitude >= INF:
        raise ValueError('Special values are handled before range reduction')
    x = struct.unpack('<d', struct.pack('<Q', bits))[0]
    if abs(x) <= float.fromhex('0x1.921fb54442d18p-1'):
        return 0, x, 0.0
    significand = (magnitude & ((1 << 52)-1)) | (1 << 52)
    exponent = (magnitude >> 52)-1023-52
    point = PRECISION_BITS-exponent
    product = product_limbs(significand)
    quadrant = get_bit(product, point) | (get_bit(product, point+1) << 1)
    round_up = get_bit(product, point-1)
    fraction = truncate(product, point)
    if round_up:
        quadrant = (quadrant+1) & 3
        carry = 1
        for i in range(len(fraction)):
            value = (fraction[i] ^ WORD_MASK)+carry
            fraction[i] = value & WORD_MASK
            carry = value >> 32
        fraction = truncate(fraction, point)
    high, low = fraction_chunks(fraction, point)
    pi_high = float.fromhex('0x1.921fb54442d18p+0')
    pi_low = float.fromhex('0x1.1a62633145c07p-54')
    head, error = two_product(high, pi_high)
    error += high*pi_low+low*pi_high
    remainder = head+error
    tail = (head-remainder)+error
    if round_up:
        remainder, tail = -remainder, -tail
    if bits >> 63:
        quadrant = (-quadrant) & 3
        remainder, tail = -remainder, -tail
    return quadrant, remainder, tail


def audit_reduction():
    checked = 0
    worst = Decimal(0)
    with localcontext() as context:
        context.prec = 480
        half_pi = decimal_pi(480)/2
        for bits in trig_inputs():
            if bits & MASK >= INF:
                continue
            quadrant, head, tail = reduce_angle(bits)
            x = Decimal.from_float(struct.unpack('<d', struct.pack('<Q', bits))[0])
            quotient = (x/half_pi).to_integral_value(rounding=ROUND_HALF_EVEN)
            exact = x-quotient*half_pi
            assert quadrant == int(quotient) % 4, f'Quadrant: {bits:016X}'
            observed = Decimal.from_float(head)+Decimal.from_float(tail)
            assert abs(observed) <= half_pi/2+Decimal('1e-30')
            # Small values deliberately use the exact input with a zero tail.
            if abs(x) > Decimal.from_float(float.fromhex('0x1.921fb54442d18p-1')):
                relative = abs((observed-exact)/exact)
                worst = max(worst, relative)
                assert relative < Decimal('2e-31'), f'Remainder: {bits:016X}: {relative}'
            else:
                assert observed == exact
            checked += 1
    return dict(finite_inputs=checked, maximum_relative_remainder_error=str(worst),
                scope='Host integer-limb reducer design only; not native qualification')


if __name__ == '__main__':
    import argparse
    import hashlib
    import json
    from pathlib import Path
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    report = audit_reduction()
    report.update(result='pass', source_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
    (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report))
