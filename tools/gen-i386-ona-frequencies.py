#!/usr/bin/env python3
"""Generate native Ona2Freq lookup bits from the captured original byte domain."""
from pathlib import Path
import argparse
import hashlib
import struct

ROOT = Path(__file__).resolve().parents[1]
ORACLE = ROOT / 'tests/i386/ona-frequency-reference.bin'
OUTPUT = ROOT / 'Kernel/I386/OnaFrequencies.HC'
EXPECTED_SHA256 = 'ed8c0e8dd358b79c74f536fabfb10d0eeedf484830e2938d41a21a757ff7a1eb'


def render():
    data = ORACLE.read_bytes()
    if len(data) != 2048 or hashlib.sha256(data).hexdigest() != EXPECTED_SHA256:
        raise ValueError('Original Ona2Freq capture is not the pinned 256-value oracle')
    words = struct.unpack('<256Q', data)
    lines = ['//Original x87 Ona2Freq results indexed by the raw I8 note byte.',
             'U64 native_ona_frequency_bits[256]={']
    for offset in range(0, 256, 4):
        lines.append('  ' + ','.join(f'0x{value:016X}' for value in words[offset:offset+4]) + ',')
    lines += ['};', 'public F64 Ona2Freq(I8 ona)',
              '{ return native_ona_frequency_bits[ona&255](F64); }', '']
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    expected = render()
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text() != expected:
            raise ValueError('Generated Ona2Freq table differs from the original capture')
    else:
        OUTPUT.write_text(expected)


if __name__ == '__main__':
    main()
