"""Check the bundled one-CPU Palindrome run against an independent Bible scan."""
import hashlib
import json
from pathlib import Path
import re

BATCH = Path(__file__).resolve().parent / 'comparison'


def oracle(text):
    letters = re.sub(rb'[^a-zA-Z]', b'', text).upper()
    bordered = b'[' + letters + b']'
    best, found = 0, []
    for center in range(1, len(bordered) - 1):
        for left, right in ((center - 1, center + 1), (center, center + 1)):
            while bordered[left] == bordered[right]:
                left -= 1
                right += 1
            if right - left - 1 > best:
                best = right - left - 1
                found.append(bordered[left + 1:right].decode('ascii'))
    return found


def observe(data, expected):
    if not data.endswith(b'\x05'):
        raise ValueError('Missing DolDoc end marker')
    *lines, last = data[:-1].splitlines()
    found = []
    for line in lines:
        match = re.fullmatch(rb'CPU00 Len: *(\d+) ([A-Z]+)', line)
        if not match or int(match[1]) != len(match[2]):
            raise ValueError(f'Invalid palindrome diagnostic: {line!r}')
        found.append(match[2].decode('ascii'))
    if found != expected:
        raise ValueError(f'Wrong record sequence: {found!r}')
    elapsed = re.fullmatch(rb'Time: *(\d+\.\d{5})', last)
    if not elapsed:
        raise ValueError(f'Invalid elapsed time: {last!r}')
    return {'sha256': hashlib.sha256(data).hexdigest(),
            'records': found, 'elapsed_seconds': float(elapsed[1])}


def main():
    bible = (BATCH / 'original-source/Misc/Bible.TXT').read_bytes()
    report = json.loads((BATCH/'result.json').read_text())
    entry = report['entries']['Demo/MultiCore/Palindrome.HC']
    if not report['inputs_unchanged'] or 'error' in report:
        raise ValueError('The native workflow did not complete')
    expected = oracle(bible)
    runs = {n: observe((BATCH/n/entry['output_file']).read_bytes(), expected)
            for n in ('original', 'native')}
    for name, record in runs.items():
        if record['sha256'] != entry[name + '_sha256']:
            raise ValueError(f'{name} output differs from batch receipt')
    print(json.dumps({'result': 'pass', 'image_sha256': report['input_sha256'],
                      'source_sha256': entry['source_sha256'],
                      'bible_sha256': hashlib.sha256(bible).hexdigest(),
                      'runs': runs, 'scope': 'Both one-CPU guests produced the complete independent record sequence. Time may vary.'},
                     indent=2))


if __name__ == '__main__':
    main()
