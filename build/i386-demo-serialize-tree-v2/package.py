"""Package the shared directory tools and their startup entry for a guest run."""
import argparse
from pathlib import Path
import runpy

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('base', type=Path)
parser.add_argument('candidate', type=Path)
args = parser.parse_args()
packer = runpy.run_path('tools/package-i386-native-image.py')
snapshot = packer['snapshot']
startup = '/Kernel/I386/StartOS.HC'
changed_sources = [
    startup, '/Adam/ABlkDev/ADskB.HC', '/Adam/Opt/Utils/LineRep.HC', '/Kernel/KDbg.HC',
]
new_sources = [
    '/Kernel/I386/MakeDirectoryDiagnostics.HC', '/Kernel/MemoryDumpCore.HC',
    '/Adam/Opt/Utils/LineRepTreeCore.HC', '/Adam/ABlkDev/DirTreeSerializationCore.HC',
]


def read_source(path):
    return Path(path[1:]).read_bytes()


def updated(raw):
    tree, files, directories = snapshot(raw)
    for path in changed_sources:
        *parents, name = path[1:].split('/')
        node = tree
        for part in parents:
            node = node[part][2]
        attr, date, _ = files[path]
        node[name] = files[path] = (attr, date, read_source(path))
    return tree, files, directories


packer['package'].__globals__['snapshot'] = updated
packer['package'](args.base, args.candidate, additions={path: read_source(path) for path in new_sources})
before = snapshot(args.base.read_bytes())[1]
after = snapshot(args.candidate.read_bytes())[1]
if set(before) - set(after) or {path for path in after if after[path] != before.get(path)} != set(changed_sources + new_sources):
    raise ValueError('Unexpected file changes in the directory diagnostics image')
