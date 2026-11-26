"""Validate a TreeDemo document against the pinned demo inventory."""
import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
INDENT = re.compile(rb'\$ID,(-?\d+)\$')
DIRECTORY = re.compile(rb'\$TR,""\$\$MA,"([^"]+)",LM="Cd\(\\"([A-Z]):(/[^"\\]+)\\"\);Dir;\\n"\$')
FILE = re.compile(rb'\$LK,"([^"]+)",A="FI:([A-Z]):(/[^"]+)"\$')


def inspect_tree(data, drive):
    header, *lines = data.splitlines()
    if header != b'$TR-C,""$' or not lines or not lines[-1].endswith(b'\x05'):
        raise ValueError('Missing collapsed tree header or closing DolDoc marker')
    indentation = 0
    files = set()
    directories = set()
    for number, line in enumerate(lines, 2):
        while match := INDENT.match(line):
            indentation += int(match[1])
            line = line[match.end():]
        if number == len(lines) + 1:
            if line != b'\x05' or indentation != 0:
                raise ValueError('Tree did not return to the original indentation')
            break
        directory = DIRECTORY.fullmatch(line)
        match = directory or FILE.fullmatch(line)
        if not match:
            raise ValueError(f'Unexpected tree entry on line {number}')
        label, entry_drive, path = match.groups()
        parent, name = path.rsplit(b'/', 1)
        if (entry_drive != drive or label != name or indentation != 2 * path.count(b'/')
                or (parent and parent not in directories)
                or path in files or path in directories):
            raise ValueError(f'Invalid tree entry on line {number}: {path!r}')
        (directories if directory else files).add(path)
    return files, directories


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('document', type=Path)
    parser.add_argument('drive', choices=('C', 'T'))
    args = parser.parse_args()
    inventory = ROOT / 'docs/i386-compatibility-inventory.json'
    pinned = {('/' + row['path']).encode('ascii')
              for row in json.loads(inventory.read_text())['entries']
              if row['category'] == 'Demo'}
    data = args.document.read_bytes()
    files, directories = inspect_tree(data, args.drive.encode('ascii'))
    actual = {path for path in files if path.startswith(b'/Demo/')}
    if actual != pinned:
        raise ValueError(f'Demo links differ. Missing {sorted(pinned - actual)!r}. Extra {sorted(actual - pinned)!r}.')
    print(json.dumps(dict(result='pass', drive=args.drive,
                          document_sha256=hashlib.sha256(data).hexdigest(),
                          directories=len(directories), file_links=len(files),
                          pinned_demo_links=len(pinned)), indent=2))


if __name__ == '__main__':
    main()
