"""High-precision logarithm expectations independent of the fdlibm polynomial."""
from decimal import Decimal, localcontext
import struct

MASK = (1 << 63)-1
INF = 0x7FF0000000000000
QUIET = 1 << 51


def log_inputs():
    values = []
    for i in range(768):
        bits = (((i//3)*8 << 52)+(i%3)-1) & ((1 << 64)-1)
        values.append(bits)
    special = [0, 1, 2, (1 << 52)-1, 1 << 52, INF-1, INF, INF+1,
               INF+QUIET+0x1234, 0x3FEFFFFFFFFFFFFF, 0x3FF0000000000000,
               0x3FF0000000000001, 0x3FF6A09E667F3BCC, 0x3FF6A09E667F3BCD,
               0x4024000000000000, 0x4059000000000000]
    values += special+[v | (1 << 63) for v in special]
    seed = 0x386F64D
    while len(values) < 1024:
        seed = (seed*6364136223846793005+1442695040888963407) & ((1 << 64)-1)
        values.append(seed & MASK)
    return values


def rounded_log(bits, base, precision):
    magnitude = bits & MASK
    if magnitude > INF:
        return bits | QUIET
    if not magnitude:
        return INF | (1 << 63)
    if bits >> 63:
        return 0xFFF8000000000000
    if magnitude == INF:
        return bits
    value = struct.unpack('<d', struct.pack('<Q', bits))[0]
    with localcontext() as context:
        context.prec = precision
        exact_input = Decimal.from_float(value)
        if base == 'ln':
            result = exact_input.ln()
        elif base == 'log2':
            result = exact_input.ln()/Decimal(2).ln()
        else:
            result = exact_input.log10()
        return struct.unpack('<Q', struct.pack('<d', float(result)))[0]


def make_log_oracle():
    rows = []
    for bits in log_inputs():
        results = []
        for base in ('ln', 'log10', 'log2'):
            result = rounded_log(bits, base, 160)
            if result != rounded_log(bits, base, 220):
                raise ValueError('Logarithm rounding unstable at two oracle precisions')
            results.append(result)
        rows.append(struct.pack('<4Q', bits, *results))
    return b''.join(rows)
