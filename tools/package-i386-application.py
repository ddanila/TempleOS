#!/usr/bin/env python3
"""Add one application source/asset tree to an immutable native image copy."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def main():
    inventory = json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())
    apps = sorted({e['path'].split('/')[1] for e in inventory['entries'] if e['category']=='Apps'})
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--app', choices=apps, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    paths = sorted(p for p in (ROOT/'Apps'/args.app).rglob('*') if p.is_file())
    required = {e['path'] for e in inventory['entries'] if e['path'].startswith('Apps/'+args.app+'/')}
    current = {str(p.relative_to(ROOT)):p for p in paths}
    if not required <= set(current):
        raise ValueError('Application source tree is missing original files')
    additions = {'/'+name:path.read_bytes() for name,path in current.items()}
    out.mkdir(parents=True)
    image = out/'candidate.img'
    packer = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package']
    tool_paths = [Path(__file__).resolve(), ROOT/'tools/package-i386-native-image.py',
                  ROOT/'tools/build-i386-kernel.py', ROOT/'docs/i386-compatibility-inventory.json']
    pins = {str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in tool_paths}
    report = packer(source, image, additions=additions)
    if any(hashlib.sha256(Path(p).read_bytes()).hexdigest()!=digest for p,digest in pins.items()):
        raise ValueError('Packaging tools or inventory changed during packaging')
    for name,path in current.items():
        if hashlib.sha256(path.read_bytes()).hexdigest() != report['added_files']['/'+name]:
            raise ValueError('Application source changed while packaging')
    reference = {e['path']:e['reference_sha256'] for e in inventory['entries'] if e['path'] in current}
    report.update(application=args.app, reference_revision=inventory['reference_revision'],
                  repair_revision=inventory['repair_revision'], reference_source_sha256=reference,
                  input_sha256=pins, additional_worktree_files=sorted(set(current)-required),
                  source_matches_reference=set(current)==required and all(report['added_files']['/'+name]==digest for name,digest in reference.items()))
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    print('PASS: packaged',len(additions),'application files; original image/tree preserved')


if __name__=='__main__':
    main()
