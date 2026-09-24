#!/usr/bin/env python3
"""Mutation checks for native QEMU JIT byte capture and 386 auditing."""
from pathlib import Path
import runpy
import tempfile

ROOT=Path(__file__).resolve().parents[1]
audit=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['audit_live_jit']


def corpus(changes=None):
    changes=changes or {}
    rows=[]
    for phase in (0,1):
        for index in range(6):
            code=changes.get((phase,index),b'\xb8\x2a\x00\x00\x00\xc3')
            rows.append(f'JIT SPAN {phase:016X} {index:016X} {len(code):016X} {len(code):016X}')
            rows.append('JIT BYTES '+f'{phase:016X} {index:016X} '+' '.join(f'{byte:016X}' for byte in code))
    return '\n'.join(rows)+'\n'


with tempfile.TemporaryDirectory() as directory:
    out=Path(directory)
    assert len(audit(corpus(),out))==12
    literal=corpus({(0,3):b'\xb8\x2a\x00\x00\x00\xc3\x0f\xa2'})
    literal=literal.replace('JIT SPAN 0000000000000000 0000000000000003 0000000000000008 0000000000000008',
                            'JIT SPAN 0000000000000000 0000000000000003 0000000000000008 0000000000000006',1)
    assert len(audit(literal,out))==12  #Data bytes are outside the executable range.
    for name,source in (
            ('cpuid',corpus({(0,1):b'\x0f\xa2\xc3'})),
            ('bswap',corpus({(1,4):b'\x0f\xc8\xc3'})),
            ('wrong-data-boundary',literal.replace('JIT SPAN 0000000000000000 0000000000000003 0000000000000008 0000000000000006',
                                                   'JIT SPAN 0000000000000000 0000000000000003 0000000000000008 0000000000000008',1)),
            ('truncated',corpus().replace('JIT BYTES 0000000000000001 0000000000000005 ',
                                          'JIT BYTES 0000000000000001 0000000000000005 0000000000000000 ',1)),
            ('missing',corpus().replace('JIT SPAN 0000000000000000 0000000000000000 0000000000000006 0000000000000006\n','',1))):
        try: audit(source,out)
        except ValueError: pass
        else: raise AssertionError(f'{name} mutation passed live JIT audit')
print('PASS: live JIT capture and ISA audit reject five mutations')
