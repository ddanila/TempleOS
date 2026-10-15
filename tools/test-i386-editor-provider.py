#!/usr/bin/env python3
"""Require the real packaged editor provider and one lazy load through public search APIs."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PROVIDER = '/Modules/I386/EditorRuntime.t32m'
SOURCES = ('Kernel/I386/EditorRuntime.HC', 'Kernel/I386/EditorRuntime.HH', 'Kernel/I386/EditorDispatch.HC',
           'Kernel/StrFindCore.HC', 'Kernel/StringFindFlags.HH', 'Adam/DolDoc/DocEditorSearchCore.HC')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def layout(module):
    size, count, records = struct.unpack_from('<III', module, 16)
    exports, imports = {}, set()
    for index in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records+16*index)
        if kind in (1, 2, 3, 5):
            symbol = module[name:name+length].decode('ascii')
            if kind in (1, 3): exports[symbol] = (kind, offset)
            else: imports.add(symbol)
    if imports:
        raise ValueError('Editor provider must use its explicit persistent context')
    names = ('Main', 'EditorInit', 'StrFind', 'EdFindNext', 'EdSelAll', 'EdFindPaired', 'EdGoToFun', 'EdSelFun')
    for name in names:
        if exports.get(name, (0,))[0] != 1:
            raise ValueError('Missing real editor entry: '+name)
    if exports.get('editor_version', (0,))[0] != 3:
        raise ValueError('Missing editor version')
    if struct.unpack_from('<I', module, 32+exports['editor_version'][1])[0] != 1:
        raise ValueError('Wrong editor version')
    return dict(image_bytes=size+8, required_entries=list(names), imports=[])

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists(): parser.error('Use a fresh output directory')
    paths = [source, Path(__file__).resolve(), ROOT/'tools/build-i386-kernel.py',
             ROOT/'tools/test-i386-editor-search.py', ROOT/'tools/i386-kernel-input.py']
    pins = {str(p): sha(p) for p in paths}
    out.mkdir(parents=True)
    report = dict(result='running', scope='Packaged full editor services, exact source delivery, no boot load, first-use/reuse through the paired search suite; not failure/lifetime/generation qualification', input_sha256=pins)
    try:
        reader = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents']
        files = reader(source, {PROVIDER, *('/'+name for name in SOURCES)})
        if not files.get(PROVIDER): raise ValueError('Missing packaged editor provider')
        module = files[PROVIDER]
        report['layout'] = layout(module)
        report['module_sha256'] = hashlib.sha256(module).hexdigest()
        for name in SOURCES:
            path = ROOT/name
            pins[str(path)] = sha(path)
            if files.get('/'+name) != path.read_bytes():
                raise ValueError('Editor source delivery differs: '+name)
        report['delivered_sources'] = {name: sha(ROOT/name) for name in SOURCES}
        subprocess.run([sys.executable, 'tools/test-i386-editor-search.py', str(source),
                        '--out', str(out/'behavior')], cwd=ROOT, check=True)
        behavior = json.loads((out/'behavior/result.json').read_text())
        if behavior['result'] != 'pass' or not behavior['inputs_unchanged']:
            raise ValueError('Editor search behavior is not qualified')
        log = (out/'behavior/qemu/debug.log').read_text()
        marker = 'EDITOR loaded '
        first = log.index('INPUT LINE SFCheck(0,0);')
        if marker in log[:first] or log.count(marker) != 1:
            raise ValueError('Editor must load once, on first actual search use')
        report['behavior'] = behavior['behavior']
        report['provider_loads'] = 1
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p, digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Editor qualification inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')

if __name__ == '__main__': main()
