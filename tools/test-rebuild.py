#!/usr/bin/env python3
"""Rebuild in TempleOS, boot the generated binaries, and rebuild once again."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'build/rebuild-test'
OS_SNAPSHOT = 'c26482bb6ad3f80106d28504ec5db3c6a360732c'


def run(*args):
    subprocess.run(args, cwd=ROOT, check=True)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--qmp-stdio',action='store_true')
    args=parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT/'result.json').unlink(missing_ok=True)
    manifest = {'revision': subprocess.check_output(['git','rev-parse','HEAD'],
                cwd=ROOT, text=True).strip(), 'source_sha256': {}, 'generations': [],
                'qmp_stdio': args.qmp_stdio}
    names = subprocess.check_output(['git','ls-tree','-r','--name-only',OS_SNAPSHOT],
                                    cwd=ROOT,text=True).splitlines()
    os_dirs = {name.split('/')[0] for name in names if '/' in name}
    current = subprocess.check_output(['git','ls-files','--cached','--others',
                                       '--exclude-standard'],cwd=ROOT,text=True).splitlines()
    names = sorted(set(names) | {name for name in current
                                 if name.split('/')[0] in os_dirs})
    for name in names:
        manifest['source_sha256'][name] = sha(ROOT/name)
    overlay = OUT/'overlay'
    for generation in (1, 2):
        iso = OUT/f'generation-{generation}.iso'
        exports = OUT/f'generation-{generation}'
        cmd = [sys.executable, 'tools/build-iso.py', '--output', str(iso),
               '--overlay', 'tests/guest/rebuild']
        if generation == 2:
            cmd += ['--overlay', str(overlay)]
        run(*cmd)
        run(sys.executable, 'tools/guest-run.py', str(iso), '--out', str(exports),
            *(['--qmp-stdio'] if args.qmp_stdio else []))
        manifest['generations'].append({name: sha(exports/name)
                                       for name in ('Compiler.BIN','Kernel.BIN')})
        for name, dest in [('Compiler.BIN','Compiler/Compiler.BIN'),
                           ('Kernel.BIN','0000Boot/0000Kernel.BIN.C')]:
            target = overlay/dest
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(exports/name,target)
    manifest['differences'] = {}
    for name in ('Compiler.BIN','Kernel.BIN'):
        a=(OUT/'generation-1'/name).read_bytes()
        b=(OUT/'generation-2'/name).read_bytes()
        manifest['differences'][name] = {'sizes': [len(a),len(b)],
            'offsets': [i for i,(x,y) in enumerate(zip(a,b)) if x != y]}
    changed = [name for name, digest in manifest['source_sha256'].items()
               if not (ROOT/name).is_file() or sha(ROOT/name) != digest]
    manifest['result'] = 'fail' if changed else 'pass'
    if changed:
        manifest['changed_sources'] = changed
    manifest['scope'] = 'Two native x86-64 rebuilds, second running generated binaries; not bit reproducibility'
    (OUT/'result.json').write_text(json.dumps(manifest,indent=2)+'\n')
    if changed:
        raise RuntimeError('Rebuild inputs changed: ' + ', '.join(changed))
    print('PASS: rebuilt compiler/kernel booted and rebuilt themselves. See result.json for binary differences.')


if __name__ == '__main__':
    main()
