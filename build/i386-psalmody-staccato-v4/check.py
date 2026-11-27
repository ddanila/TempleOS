"""Check the captured factor, bias, formatter scale and text for every slider position."""
from fractions import Fraction
from pathlib import Path
import struct


def from_bits(bits):
    return Fraction(struct.unpack('>d', bytes.fromhex(bits))[0])


def to_bits(value):
    return struct.pack('>d', float(value)).hex().upper()


def nearest(value, precision):
    if not value:
        return value
    exponent = value.numerator.bit_length() - value.denominator.bit_length()
    if value < Fraction(2)**exponent:
        exponent -= 1
    unit = Fraction(2)**(exponent - precision + 1)
    return round(value / unit) * unit


def check(target, precisions, constants):
    trace = Path(__file__).with_name(f'{target}.txt')
    slope, offset, bias, power = map(from_bits, constants)
    records = trace.read_text().splitlines()
    assert len(records) == 80
    for setting, line in enumerate(records):
        product = slope * setting
        if precisions:
            mul, div, add = precisions
            product = nearest(product, mul)
            quotient = nearest(product / 80, div)
            factor = nearest(nearest(quotient + offset, add), 53)
        else:
            factor = nearest(product / 80 + offset, 53)
        biased = nearest(factor + bias, 53)
        scaled = nearest(biased * power, 53)
        rounded = round(scaled)
        expected = ['PSM', 'SWEEP', str(setting), to_bits(power), to_bits(factor),
                    to_bits(biased), to_bits(scaled), str(rounded),
                    f'{rounded // 1000}.{rounded % 1000:03d}']
        assert line.split() == expected, (target, setting, line, expected)


if __name__ == '__main__':
    original = ('3FEC28F5C28F5C2A', '3FBEB851EB851EBA', '3F40624DD2F1A9FE',
                '408F3FFFFFFFFFFF')
    native = ('3FEC28F5C28F5C29', '3FBEB851EB851EB8', '3F40624DD2F1A9FC',
              '408F400000000000')
    check('original', (64, 64, 64), original)
    check('original', None, original)
    check('native', (53, 53, 53), native)
    print('Both traces match across all 80 staccato positions; the rational path matches the original.')
