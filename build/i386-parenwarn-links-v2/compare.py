"""Compare warning text, token context, and file/line targets across the two guests."""
import argparse
import hashlib
import json
from pathlib import Path
import re

WARNING = re.compile(
    rb'(?P<stack>.*?)\$FG,4\$\$BK,1\$WARNING:\$FG\$\$BK,0\$ '
    rb'Unnecessary parenthesis "(?P<token>[^"]+)" '
    rb'\$LK,"(?P<label_drive>[A-Z]):/Demo/ParenWarn\.HC,(?P<label_line>\d{4})",'
    rb'A="FL:(?P<target_drive>[A-Z]):/Demo/ParenWarn\.HC,(?P<target_line>\d+)"\$ '
    rb'(?P<source>.*)'
)


def read_warnings(path, drive):
    data = path.read_bytes()
    if not data.endswith(b'\x05'):
        raise ValueError(f'Missing DolDoc end marker in {path}')
    warnings = []
    for line in data[:-1].splitlines():
        match = WARNING.fullmatch(line)
        if not match:
            raise ValueError(f'Unexpected warning format in {path}: {line!r}')
        if bool(match['stack']) != (drive == b'T'):
            raise ValueError(f'Unexpected compiler call-chain annotation in {path}: {line!r}')
        label, target = int(match['label_line']), int(match['target_line'])
        if label != target or match['label_drive'] != drive or match['target_drive'] != drive:
            raise ValueError(f'Incorrect source link in {path}: {line!r}')
        warnings.append({'line': target, 'token': match['token'].decode(),
                         'source': match['source'].decode()})
    return hashlib.sha256(data).hexdigest(), warnings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('batch', type=Path)
    args = parser.parse_args()
    receipt = args.batch / 'result.json'
    data = json.loads(receipt.read_text())
    if not data['inputs_unchanged'] or 'error' in data:
        raise ValueError('The full guest workflow did not reach the comparison')
    entry = data['entries']['Demo/ParenWarn.HC']
    original_sha, original = read_warnings(args.batch/'original'/entry['output_file'], b'T')
    native_sha, native = read_warnings(args.batch/'native'/entry['output_file'], b'C')
    if original_sha != entry['original_sha256'] or native_sha != entry['native_sha256']:
        raise ValueError('DolDoc files differ from batch receipt')
    if original != native or [(w['line'], w['token']) for w in native] != [
            (6, ';'), (8, ';'), (9, '('), (10, ';'), (14, ';')]:
        raise ValueError(f'Warning differences: {original!r} versus {native!r}')
    print(json.dumps({'result': 'pass', 'image_sha256': data['input_sha256'],
                      'original_sha256': original_sha, 'native_sha256': native_sha,
                      'batch_receipt_sha256': hashlib.sha256(receipt.read_bytes()).hexdigest(),
                      'scope': 'Identical warning colors, tokens, source snippets and navigable file/line targets. Drive letters are guest-specific. The native host callback has no HolyC parser call chain.',
                      'warnings': native}, indent=2))


if __name__ == '__main__':
    main()
