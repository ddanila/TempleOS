#!/usr/bin/env python3
"""Verify that a native image delivers the candidate's complete packaged source tree."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

ROOT = Path(__file__).resolve().parents[1]
DIRECTORIES = ('Kernel', 'Compiler', 'Adam/DolDoc', 'Adam/Gr', 'Adam/Ctrls', 'Doc')
SUFFIXES = ('.HC', '.HH', '.DD', '.PRJ')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def audit(disk, repository):
    repository = repository.resolve()
    expected = {}
    for directory in DIRECTORIES:
        for path in (repository / directory).rglob('*'):
            if path.is_file() and path.suffix.upper() in SUFFIXES:
                expected['/' + str(path.relative_to(repository))] = path
    required = {'/Kernel/I386/Kernel.HC', '/Compiler/I386/Frontend.HC'}
    if not required <= set(expected):
        raise ValueError('Repository lacks required kernel/compiler source')
    identities = {name: sha(path) for name, path in sorted(expected.items())}
    helper = ROOT / 'tools/build-i386-kernel.py'
    packer = ROOT / 'tools/package-i386-native-image.py'
    pins = {str(path.resolve()): sha(path) for path in (disk, helper, packer)}
    build = runpy.run_path(str(helper))
    filesystem = build['verify_mutated_volume'](disk)
    # Inspect all live names too: a removed source must not remain in the image.
    snapshot = runpy.run_path(str(packer))['snapshot']
    _, all_files, _ = snapshot(disk.read_bytes())
    delivered = {name for name in all_files
                 if any(name.startswith('/' + directory + '/') for directory in DIRECTORIES)
                 and Path(name).suffix.upper() in SUFFIXES}
    if delivered != set(expected):
        raise ValueError('Delivered source path set differs: missing=' +
                         repr(sorted(set(expected) - delivered)) + ' extra=' +
                         repr(sorted(delivered - set(expected))))
    files = build['mutated_file_contents'](disk, set(expected))
    for name, digest in identities.items():
        if hashlib.sha256(files[name]).hexdigest() != digest:
            raise ValueError('Delivered source bytes differ: ' + name)
    if any(sha(path) != identities[name] for name, path in expected.items()):
        raise ValueError('Candidate source changed during audit')
    if any(sha(Path(path)) != digest for path, digest in pins.items()):
        raise ValueError('Disk or source-audit helper changed')
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repository, text=True).strip()
    changes = subprocess.run(['git', 'diff', '--quiet', 'HEAD', '--', *DIRECTORIES],
                             cwd=repository, check=False).returncode
    if changes not in (0, 1):
        raise ValueError('Cannot inspect candidate source revision')
    untracked = subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard',
                                        '--', *DIRECTORIES], cwd=repository, text=True).splitlines()
    return dict(result='pass', disk_sha256=pins[str(disk.resolve())],
                repository=str(repository), base_revision=revision,
                candidate_has_source_changes=bool(changes or untracked),
                source_files=len(expected), source_sha256=identities,
                source_identity_sha256=hashlib.sha256(json.dumps(identities, sort_keys=True).encode()).hexdigest(),
                input_sha256=pins, filesystem=filesystem,
                scope='Complete packaged source/doc tree matches candidate; dirty candidate is identified, not claimed as a clean release revision')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path, required=True)
    parser.add_argument('--repository', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh report')
    result = audit(args.disk, args.repository)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, indent=2) + '\n')
    print('PASS: ' + str(result['source_files']) + ' delivered source/doc files match candidate')


if __name__ == '__main__':
    main()
