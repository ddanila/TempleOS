"""Independent Python expectations for native integer math intrinsics."""
import struct

INPUTS = (
    0x0000000000000000, 0x0000000000000001, 0x0000000000000002, 0x0000000000000003,
    0x000000000000007F, 0x0000000000000080, 0x00000000000000FF, 0x0000000000000100,
    0x0000000000007FFF, 0x0000000000008000, 0x000000000000FFFF, 0x0000000000010000,
    0x000000007FFFFFFF, 0x0000000080000000, 0x00000000FFFFFFFF, 0x0000000100000000,
    0x0000000100000001, 0x7FFFFFFFFFFFFFFF, 0x8000000000000000, 0x8000000000000001,
    0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFF00000000, 0xFFFFFFFF00000001,
    0x4000000000000000, 0x4000000000000001, 0x0000000200000001, 0x123456789ABCDEF0,
    0xFEDCBA9876543210, 0xAAAAAAAAAAAAAAAA, 0x5555555555555555, 0x000000010000FFFF,
)


def make_integer_math_oracle():
    mask = (1 << 64) - 1
    records = []
    for a in INPUTS:
        signed_a = a - (1 << 64) if a >> 63 else a
        for b in INPUTS:
            signed_b = b - (1 << 64) if b >> 63 else b
            quotient, remainder = divmod(a, b) if b else (0, 0)
            values = (a, b, abs(signed_a), (signed_a > 0) - (signed_a < 0),
                      min(signed_a, signed_b), max(signed_a, signed_b),
                      min(a, b), max(a, b), signed_a * signed_a, a * a, quotient, remainder)
            records.append(struct.pack('<12Q', *(value & mask for value in values)))
    #Preserve the production routines' wrapping and truncating remainder semantics.
    def signed(value):
        value &= mask
        return value-(1 << 64) if value >> 63 else value

    def remainder(value, step):
        return (abs(value) % step) * (-1 if value < 0 else 1)

    for value in (-(1 << 63), -(1 << 32), -17, -1, 0, 17, 1 << 32, (1 << 63)-1):
        for step in (1, 2, 3, 7, 8, 16, 1 << 32, (1 << 63)-1):
            unsigned = value & mask
            rounded = value-remainder(value, step)
            adjusted = signed(value+1) if value < 0 else value
            floor = adjusted-remainder(adjusted, step)-(step if value < 0 else 0)
            adjusted = signed(value+step-1)
            ceil = adjusted-remainder(adjusted, step)-(step if value < 0 else 0)
            unsigned_adjusted = (unsigned+step-1) & mask
            values = (value, step, rounded, floor, ceil, unsigned-unsigned%step,
                      unsigned_adjusted-unsigned_adjusted%step)
            records.append(struct.pack('<7Q', *(item & mask for item in values)))
    return b''.join(records)
