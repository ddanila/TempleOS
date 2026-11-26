"""Independently derive the Lex1 token report for the NullCase fixture."""
import argparse
import hashlib
import json
from pathlib import Path
import re

TOKENS = re.compile(
    rb'(?P<skip>\s+|//[^\n]*)|(?P<ident>[A-Za-z_]\w*)|(?P<integer>\d+)'
    rb'|(?P<string>"(?:[^"\\]|\\n)*")|(?P<increment>\+\+)'
    rb'|(?P<punctuation>[(){};=:<])'
)


def expected_report(source):
    report = []
    offset = 0
    while offset < len(source):
        match = TOKENS.match(source, offset)
        if not match:
            raise ValueError(f'Unexpected token near {source[offset:offset + 16]!r}')
        offset = match.end()
        value = match[0]
        if match.lastgroup == 'ident':
            report.append(b'256:IDENT:' + value + b'\n')
        elif match.lastgroup == 'integer':
            report.append(b'258:I64:' + str(int(value)).encode('ascii') + b'\n')
        elif match.lastgroup == 'string':
            report.append(b'257:STR:' + value[1:-1].replace(b'\\n', b'\n') + b'\n')
        elif match.lastgroup == 'increment':
            report.append(b'261:\n')
        elif match.lastgroup == 'punctuation':
            report.append(f'{value[0]:03d}:\n'.encode('ascii'))
    return b''.join(report) + b'\x05', len(report)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('report', type=Path)
    args = parser.parse_args()
    source = Path('Demo/NullCase.HC').read_bytes()
    expected, count = expected_report(source)
    data = args.report.read_bytes()
    if data != expected:
        raise ValueError('Lex1 output differs from the derived NullCase tokens')
    print(json.dumps(dict(result='pass', token_count=count,
                          fixture_sha256=hashlib.sha256(source).hexdigest(),
                          document_sha256=hashlib.sha256(data).hexdigest()), indent=2))


if __name__ == '__main__':
    main()
