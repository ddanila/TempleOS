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
    bases = words[12:24]
    corrections = []
    for raw in range(256):
        note = raw if raw < 128 else raw - 256
        if note == 0:
            corrections.append(8)
            continue
        remainder = note % 12
        octave = (note - 12 - remainder) // 12
        delta = words[raw] - bases[remainder] - (octave << 52)
        if not -8 <= delta <= 7:
            raise ValueError(f'Note {note} correction {delta} does not fit')
        corrections.append(delta + 8)
    packed = [corrections[i] | corrections[i+1] << 4 for i in range(0, 256, 2)]
    lines = ['//Original x87 Ona2Freq bits: octave bases and signed nibble corrections.',
             'U64 native_ona_frequency_bases[12]={']
    for offset in range(0, 12, 4):
        lines.append('  ' + ','.join(f'0x{value:016X}' for value in bases[offset:offset+4]) + ',')
    lines += ['};', 'U8 native_ona_frequency_corrections[128]={']
    for offset in range(0, 128, 16):
        lines.append('  ' + ','.join(f'0x{value:02X}' for value in packed[offset:offset+16]) + ',')
    lines += ['};', 'public F64 Ona2Freq(I8 ona)', '{',
              '  I64 note=ona,index=note&255,remainder,octave,correction;',
              '  if(!note) return 0.0;',
              '  remainder=(note+132)%12;octave=(note-12-remainder)/12;',
              '  correction=native_ona_frequency_corrections[index>>1];',
              '  if(index&1)correction>>=4;',
              '  correction=(correction&15)-8;',
              '  return (native_ona_frequency_bases[remainder]+(octave<<52)+correction)(F64);',
              '}', '']
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
