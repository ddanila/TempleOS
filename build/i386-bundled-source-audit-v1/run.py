"""Verify all pinned inventory files delivered on a native RedSea disk."""

import argparse
import hashlib
import io
import json
from pathlib import Path
import runpy
import subprocess
import tarfile


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git(*args):
    return subprocess.check_output(['git', *args])


def audit(disk, revision):
    revision = git('rev-parse', '--verify', f'{revision}^{{commit}}').decode().strip()
    inventory_path = 'docs/i386-compatibility-inventory.json'
    inventory = json.loads(git('show', f'{revision}:{inventory_path}'))
    paths = [entry['path'] for entry in inventory['entries']]
    reference = git('ls-tree', '-rz', '--name-only', inventory['reference_revision'])
    if set(paths) != set(reference.decode().rstrip('\0').split('\0')) or len(paths) != len(set(paths)):
        raise ValueError('Inventory paths differ from the pinned original tree')

    archive = git('archive', revision, '--', *paths)
    with tarfile.open(fileobj=io.BytesIO(archive)) as tree:
        expected = {member.name: digest(tree.extractfile(member).read())
                    for member in tree if member.isfile()}
    if set(expected) != set(paths):
        raise ValueError('Candidate revision omits an inventoried regular file')

    raw = disk.read_bytes()
    snapshot = runpy.run_path('tools/package-i386-native-image.py')['snapshot']
    _, delivered, _ = snapshot(raw)
    missing = [name for name in sorted(expected) if '/' + name not in delivered]
    changed = [name for name in sorted(expected) if '/' + name in delivered
               and expected[name] != digest(delivered['/' + name][2])]
    return {
        'result': 'fail' if missing or changed else 'pass',
        'disk': str(disk),
        'disk_sha256': digest(raw),
        'candidate_revision': revision,
        'reference_revision': inventory['reference_revision'],
        'inventory_files': len(expected),
        'inventory_contents_sha256': digest(json.dumps(expected, sort_keys=True).encode()),
        'missing': missing,
        'changed': changed,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('revision')
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    result = audit(args.disk, args.revision)
    with args.out.open('x') as out:
        out.write(json.dumps(result, indent=2) + '\n')
    return 0 if result['result'] == 'pass' else 1


if __name__ == '__main__':
    raise SystemExit(main())
