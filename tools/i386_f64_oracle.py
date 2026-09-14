"""Deterministic binary64 arithmetic vectors; host arithmetic is the oracle.

NaN payload selection is an explicit runtime policy, checked separately from
host NaN propagation. Finite results use Python's binary64 float operations;
truncating remainders use exact rational arithmetic.
"""
import math
import random
import struct
import sys

SIGN = 1 << 63
INF = 0x7FF0000000000000
QUIET = 1 << 51
MASK = SIGN-1


def expected(a, b, operation):
    if a & MASK > INF:
        return a | QUIET
    if b & MASK > INF:
        return b | QUIET
    if operation == "mul" and ((a & MASK == INF and b & MASK == 0) or
                               (b & MASK == INF and a & MASK == 0)):
        return INF | QUIET
    if operation == "div":
        if (a & MASK == 0 and b & MASK == 0) or (a & MASK == INF and b & MASK == INF):
            return INF | QUIET
        if b & MASK == 0:
            return ((a ^ b) & SIGN) | INF
    effective_b = b ^ (SIGN if operation == "sub" else 0)
    if operation in ("add", "sub") and a & MASK == INF and effective_b & MASK == INF and (a ^ effective_b) & SIGN:
        return INF | QUIET
    x, = struct.unpack('<d', struct.pack('<Q', a))
    y, = struct.unpack('<d', struct.pack('<Q', b))
    result = x/y if operation == "div" else x*y if operation == "mul" else x-y if operation == "sub" else x+y
    return struct.unpack('<Q', struct.pack('<d', result))[0]


def make_oracle(count):
    if sys.float_info.radix != 2 or sys.float_info.mant_dig != 53 or sys.float_info.max_exp != 1024:
        raise RuntimeError('Binary64 host float required')
    boundaries = [0, 1, 2, (1 << 52)-1, 1 << 52, (1 << 52)+1,
                  0x3FE0000000000000, 0x3FF8000000000000, 0x4000000000000000,
                  0x3FEFFFFFFFFFFFFF, 0x3FF0000000000000,
                  0x3FF0000000000001, 0x3CA0000000000000,
                  INF-1, INF, INF+1, INF+QUIET+0x1234]
    boundaries += [value | SIGN for value in boundaries]
    pairs = [(a, b) for a in boundaries for b in boundaries]
    # Deliberately exercise alignment distances and half-ulp neighbors.
    for exp in (1, 2, 54, 1023, 2045, 2046):
        for gap in (0, 1, 2, 3, 51, 52, 53, 54, 55, 63, 64, 65):
            if exp > gap:
                for low in (0, 1, (1 << 52)-1):
                    a = (exp << 52) | low
                    b = ((exp-gap) << 52) | 1
                    pairs.extend(((a, b), (a, b | SIGN), (b, a | SIGN)))
    # Products around underflow and overflow thresholds, both operand orders.
    for a in (1, 3, (1 << 52)-1, 1 << 52, INF-1):
        for b in (0x3FDFFFFFFFFFFFFF, 0x3FE0000000000000, 0x3FE0000000000001,
                  0x3FEFFFFFFFFFFFFF, 0x3FF0000000000001, 0x4000000000000000):
            pairs.extend(((a, b), (b, a), (a | SIGN, b)))
    rng = random.Random(0x386F64)
    if len(pairs) > count:
        raise ValueError('Oracle capacity omits boundary cases')
    while len(pairs) < count:
        a, b = rng.getrandbits(64), rng.getrandbits(64)
        if len(pairs) % 3 == 0:
            # Nearby magnitudes expose cancellation rather than only absorption.
            b = (a ^ SIGN) + rng.randrange(-16, 17)
            b &= (1 << 64)-1
        pairs.append((a, b))
    return b''.join(struct.pack('<6Q', a, b, *(expected(a, b, op) for op in ('add', 'sub', 'mul', 'div')))
                    for a, b in pairs)


def make_conversion_oracle(count):
    if sys.float_info.radix != 2 or sys.float_info.mant_dig != 53 or sys.float_info.max_exp != 1024:
        raise RuntimeError('Binary64 host float required')
    values = {0, SIGN-1, SIGN, (1 << 64)-1}
    for bit in range(64):
        for delta in (-2, -1, 0, 1, 2):
            value = (1 << bit)+delta
            if 0 <= value < 1 << 64:
                values.add(value)
                values.add(-value & ((1 << 64)-1))
    # Both parities of the retained significand, at and beside half-ulp ties.
    for bit in range(53, 64):
        ulp = 1 << (bit-52)
        for parity in (0, 1):
            for delta in (-1, 0, 1):
                value = (1 << bit)+parity*ulp+ulp//2+delta
                values.add(value)
                values.add(-value & ((1 << 64)-1))
    if len(values) > count:
        raise ValueError('Conversion oracle capacity omits boundary cases')
    rng = random.Random(0x386C64)
    while len(values) < count:
        values.add(rng.getrandbits(64))
    def bits(value):
        return struct.unpack('<Q', struct.pack('<d', float(value)))[0]
    return b''.join(struct.pack('<3Q', value, bits(value),
                                bits(value-(1 << 64) if value & SIGN else value))
                    for value in sorted(values))


def make_comparison_oracle(count):
    boundaries = [0, 1, (1 << 52)-1, 1 << 52, 0x3FEFFFFFFFFFFFFF,
                  0x3FF0000000000000, 0x3FF0000000000001,
                  INF-1, INF, INF+1, INF+QUIET+0x1234]
    boundaries += [value | SIGN for value in boundaries]
    pairs = [(a, b) for a in boundaries for b in boundaries]
    if len(pairs) > count:
        raise ValueError('Comparison oracle capacity omits boundary cases')
    rng = random.Random(0x386CC)
    while len(pairs) < count:
        a, b = rng.getrandbits(64), rng.getrandbits(64)
        if len(pairs) % 3 == 0:
            b = (a+rng.randrange(-1, 2)) & ((1 << 64)-1)
        pairs.append((a, b))
    def compare(a, b):
        x, = struct.unpack('<d', struct.pack('<Q', a))
        y, = struct.unpack('<d', struct.pack('<Q', b))
        if x != x or y != y:
            return 2
        return -1 if x < y else 1 if x > y else 0
    return b''.join(struct.pack('<QQq', a, b, compare(a, b)) for a, b in pairs)


def make_to_int_oracle(count):
    if count != 1024:
        raise ValueError('x64 compatibility fixture requires 1024 inputs')
    special = [0, 1, (1 << 52)-1, 1 << 52, INF-1, INF, INF+1, INF+QUIET+0x1234]
    seed = 0x386F64C
    records = []
    for i in range(count):
        seed = (seed*6364136223846793005+1442695040888963407) & ((1 << 64)-1)
        if i < 768:
            value = ((1023+i//12) << 52)+(i%6)-2
            if i%12 >= 6:
                value |= SIGN
        elif i < 784:
            value = special[(i-768)%8] | (SIGN if i >= 776 else 0)
        else:
            value = seed
        x, = struct.unpack('<d', struct.pack('<Q', value))
        if value & MASK >= INF:
            result = -SIGN
        else:
            result = int(x)
            if not -SIGN <= result < SIGN:
                result = -SIGN
        records.append(struct.pack('<Qq', value, result))
    return b''.join(records)


def expected_sqrt(value):
    magnitude = value & MASK
    if magnitude > INF:
        return value | QUIET
    if magnitude == 0:
        return value
    if value & SIGN:
        return SIGN | INF | QUIET
    if magnitude == INF:
        return value
    exponent = value >> 52
    significand = value & ((1 << 52)-1)
    if exponent:
        significand |= 1 << 52
        power = exponent-1023-52
    else:
        power = -1074
    result_exp = (significand.bit_length()-1+power)//2
    radicand = significand << (power+104-2*result_exp)
    root = math.isqrt(radicand)
    #Compare against the exact half-way point using arbitrary-precision integers.
    if 4*radicand > (2*root+1)**2:
        root += 1
    if root == 1 << 53:
        root >>= 1
        result_exp += 1
    return ((result_exp+1023) << 52) | (root & ((1 << 52)-1))


def expected_integral(value, mode):
    magnitude = value & MASK
    if magnitude >= INF:
        return value | (QUIET if magnitude > INF else 0)
    #Exact rational input and Python integer rounding, independent of bit masking.
    number = struct.unpack('<d', struct.pack('<Q', value))[0]
    numerator, denominator = number.as_integer_ratio()
    if mode == 'floor':
        integer = numerator // denominator
    elif mode == 'ceil':
        integer = -((-numerator) // denominator)
    elif mode == 'trunc':
        integer = abs(numerator) // denominator * (-1 if numerator < 0 else 1)
    else:
        integer = round(number)
    if not integer:
        return value & SIGN
    return struct.unpack('<Q', struct.pack('<d', float(integer)))[0]


def make_unary_oracle(count):
    if count != 1024:
        raise ValueError('Unary compatibility fixture requires 1024 inputs')
    special = [0, 1, 2, (1 << 52)-1, 1 << 52,
               0x1E5FFFFFFFFFFFFF, 0x1E60000000000000, 0x1E60000000000001,
               0x3FE0000000000000, 0x3FF8000000000000,
               0x5FEFFFFFFFFFFFFF, 0x5FF0000000000000,
               INF-1, INF, INF+1, INF+QUIET+0x1234,
               0x3FDFFFFFFFFFFFFF,0x3FE0000000000001,0x3FF7FFFFFFFFFFFF,0x3FF8000000000001,
               0x4003FFFFFFFFFFFF,0x4004000000000000,0x4004000000000001,0x400C000000000000,
               0x432FFFFFFFFFFFFF,0x4330000000000000,0x4330000000000001,0x3FF0000000000000,
               0x3FEFFFFFFFFFFFFF,0x3FF0000000000001,0x4000000000000000,0x4012000000000000]
    seed = 0x386F64A
    records = []
    for i in range(count):
        seed = (seed*6364136223846793005+1442695040888963407) & ((1 << 64)-1)
        if i < 768:
            value = (((i//6)*16 << 52)+(i%3)-1) & ((1 << 64)-1)
            if i%6 >= 3:
                value |= SIGN
        elif i < 832:
            value = special[(i-768)%32] | (SIGN if i >= 800 else 0)
        else:
            value = seed
        magnitude = value & MASK
        absolute = magnitude | (QUIET if magnitude > INF else 0)
        records.append(struct.pack('<8Q', value, absolute, expected(value, value, 'mul'), expected_sqrt(value),
                                   *(expected_integral(value, mode) for mode in ('round', 'trunc', 'floor', 'ceil'))))
    #Decimal parsing is independent of the table generator's Fraction conversion.
    records.extend(struct.pack('<d', float(f'1e{exponent}')) for exponent in range(-308, 309))
    return b''.join(records)


def make_mod_oracle(count=2048):
    """Exact rational truncating remainders, independently of runtime reduction."""
    from fractions import Fraction
    if count < 1536:
        raise ValueError('Remainder corpus must retain all boundary/exponent cases')
    special = [0, 1, 2, 3, 0x000FFFFFFFFFFFFF, 0x0010000000000000,
               0x0010000000000001, 0x3FD5555555555555, 0x3FE0000000000000,
               0x3FF0000000000000, 0x3FF8000000000000, 0x4008000000000000,
               INF-1, INF, INF+1, INF+QUIET+0x1234]
    seed = 0x386F64D
    rows = []
    for i in range(count):
        seed = (seed*6364136223846793005+1442695040888963407) & ((1 << 64)-1)
        a = seed
        seed = (seed*6364136223846793005+1442695040888963407) & ((1 << 64)-1)
        b = seed
        if i < 1024:
            a, b = special[i//32 % 16], special[i % 16]
            if i//32 >= 16: a |= SIGN
            if i % 32 >= 16: b |= SIGN
        elif i < 1536:
            j = i-1024
            a = ((1+j//8*32) << 52) | (a & ((1 << 52)-1))
            b = j % 4*2+1
            if j & 4: a |= SIGN
            if j & 2: b |= SIGN
        x, y = a & MASK, b & MASK
        if x > INF: result = a | QUIET
        elif y > INF: result = b | QUIET
        elif x == INF or y == 0: result = SIGN | INF | QUIET
        elif y == INF: result = a
        else:
            left = Fraction.from_float(struct.unpack('<d', struct.pack('<Q', x))[0])
            right = Fraction.from_float(struct.unpack('<d', struct.pack('<Q', y))[0])
            remainder = left - (left // right)*right
            value = float(remainder)
            if Fraction.from_float(value) != remainder:
                raise AssertionError('Finite binary64 remainder must be exactly representable')
            result = struct.unpack('<Q', struct.pack('<d', value))[0] | (a & SIGN)
        rows.append(struct.pack('<3Q', a, b, result))
    return b''.join(rows)
