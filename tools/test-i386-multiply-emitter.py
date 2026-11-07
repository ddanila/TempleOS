#!/usr/bin/env python3
"""Execute the production 386 multiply chunks against independent integer math."""
import argparse
import ast
import hashlib
import json
from pathlib import Path
import random
import re
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def chunks(source):
    body = source[source.index('U0 I386Multiply('):source.index('U0 I386Binary(')]
    if 'if(!is_unsigned)' not in body or re.search(r'\bI386(?:Byte|Dword)\(', body):
        raise ValueError('Multiply emitter shape changed; review extraction')
    result = []
    pattern = r'I386Bytes\(out,((?:\s*"(?:[^"\\]|\\.)*")+),(\d+)\)'
    for match in re.finditer(pattern, body):
        data = b''.join(ast.literal_eval(s).encode('latin1')
                        for s in re.findall(r'"(?:[^"\\]|\\.)*"', match[1]))
        if len(data) != int(match[2]):
            raise ValueError('Incorrect emitter byte count')
        result.append(data)
    if len(result) != 4:
        raise ValueError('Expected common, signed correction and two result tails')
    common, correction, signed_tail, unsigned_tail = result
    return [common + unsigned_tail, common + correction + signed_tail]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--samples', type=int, default=4096)
    ap.add_argument('--seed', type=int, default=20261107)
    args = ap.parse_args()
    if args.samples < 1 or args.out.exists():
        ap.error('Use positive samples and a fresh output directory')
    out = args.out.resolve()
    out.mkdir(parents=True)
    backend = ROOT/'Compiler/I386/BackendCore.HC'
    pins = {str(p): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in (Path(__file__).resolve(), backend)}
    report = dict(result='running', input_sha256=pins, seed=args.seed,
                  scope='Literal production multiply chunks in a Linux i386 ELF, '
                        'register value and CF oracle; full guest compiler tested separately')
    try:
        code = chunks(backend.read_text(encoding='latin1'))
        patterns = [0, 1, 0x80000000, 0x100000000, 0x8000000000000000,
                    2**64-1, 0x89ABCDEF01234567, 0x0123456789ABCDEF]
        pairs = [(a, b) for a in patterns for b in patterns]
        rng = random.Random(args.seed)
        for i in range(args.samples):
            if i % 4 == 0:
                a, b = rng.getrandbits(64), rng.getrandbits(64)
            else:
                a = rng.getrandbits(rng.randrange(65))
                b = rng.getrandbits(rng.randrange(65))
                if i % 4 == 2:
                    a = (-a) % 2**64
                if i % 4 == 3:
                    b = (-b) % 2**64
            pairs.append((a, b))
        signed = lambda n: n if n < 2**63 else n-2**64
        assembly = ['.global _start', '.text', '_start:']
        expected = []
        counts = {}
        for kind in range(2):
            overflow_count = 0
            for a, b in pairs:
                offset = len(expected)*8
                product = a*b if not kind else signed(a)*signed(b)
                cf = int(product >= 2**64) if not kind else int(not -2**63 <= product < 2**63)
                overflow_count += cf
                expected.extend([product % 2**64, cf])
                assembly += [f'mov ${a & 0xFFFFFFFF},%eax', f'mov ${a >> 32},%edx',
                             f'mov ${b & 0xFFFFFFFF},%ecx', f'mov ${b >> 32},%ebx',
                             f'call mul{kind}', f'mov %eax,output+{offset}',
                             f'mov %edx,output+{offset+4}', 'setc %cl', 'movzbl %cl,%ecx',
                             f'mov %ecx,output+{offset+8}']
            counts['signed' if kind else 'unsigned'] = dict(overflow=overflow_count,
                                                          fits=len(pairs)-overflow_count)
        assembly += ['mov $4,%eax', 'mov $1,%ebx', 'mov $output,%ecx',
                     f'mov ${len(expected)*8},%edx', 'int $0x80',
                     'mov $1,%eax', 'xor %ebx,%ebx', 'int $0x80']
        for kind, data in enumerate(code):
            assembly += [f'mul{kind}:', '.byte '+','.join(str(b) for b in data+b'\xC3')]
        assembly += ['.bss', 'output:', f'.skip {len(expected)*8}']
        (out/'check.s').write_text('\n'.join(assembly)+'\n')
        subprocess.run(['as', '--32', str(out/'check.s'), '-o', str(out/'check.o')], check=True)
        subprocess.run(['ld', '-m', 'elf_i386', str(out/'check.o'), '-o', str(out/'check')], check=True)
        actual = subprocess.check_output([str(out/'check')])
        (out/'actual.bin').write_bytes(actual)
        oracle = struct.pack('<'+'Q'*len(expected), *expected)
        if actual != oracle:
            raise ValueError('Emitted multiply value/carry differs from mathematical oracle')
        report.update(result='pass', pairs=len(expected)//2, counts=counts,
                      template_sha256=[hashlib.sha256(data).hexdigest() for data in code])
    except BaseException as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(hashlib.sha256(Path(p).read_bytes()).hexdigest() == h
                                         for p, h in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed during ISA test')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise RuntimeError(report['error'])
    print(f"PASS: {report['pairs']} production multiply value/carry pairs")


if __name__ == '__main__':
    main()
