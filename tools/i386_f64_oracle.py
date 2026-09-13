"""Deterministic binary64 arithmetic vectors; host arithmetic is the oracle.

NaN payload selection is an explicit runtime policy, checked separately from
host NaN propagation. Finite results use Python's binary64 float operations.
"""
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
