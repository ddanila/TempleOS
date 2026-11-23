"""Extract the bodies shared by the original and native ToTheFront launchers."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('base', type=Path)
parser.add_argument('--source-candidate', type=Path, required=True)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
packer = runpy.run_path('tools/package-i386-native-image.py')
snapshot, package = packer['snapshot'], packer['package']
base = args.base.read_bytes()
_, original, _ = snapshot(base)
changed = {}
added = {}


def include(path):
    return f'#include "/{path}"\n'.encode('ascii')


def extract(path, first, next_body, destination):
    source = changed.get(path, Path(path).read_bytes())
    start = source.index(first)
    stop = source.index(next_body, start) if next_body else len(source)
    added[destination] = source[start:stop]
    changed[path] = source[:start] + include(destination) + source[stop:]


popups = 'Adam/DolDoc/DocPopUp.HC'
prompt = 'Adam/DolDoc/DocIntegerPromptCore.HC'
range_chooser = 'Adam/DolDoc/DocFloatRangeCore.HC'
extract(popups, b'public I64 PopUpGetI64(', b'public F64 PopUpGetF64(', prompt)
extract(popups, b'public F64 PopUpRangeF64(', b'public F64 PopUpRangeF64Exp(', range_chooser)
wrap = 'Adam/AngleWrapCore.HC'
extract('Adam/AMath.HC', b'public F64 Wrap(', b'#include "/Adam/DistSqrCore.HC"', wrap)
poll = 'Kernel/SerialDev/KeyCharPollCore.HC'
extract('Kernel/SerialDev/Message.HC', b'I64 ScanChar()', b'#include "/Kernel/KeyScanCore.HC"', poll)
saw = 'Adam/Snd/SawCore.HC'
extract('Adam/Snd/SndMath.HC', b'public F64 Saw(', b'public F64 FullSaw(', saw)

line = 'Adam/Gr/GrLineWalkCore.HC'
walkers = 'Adam/Gr/GrEllipseWalkCore.HC'
gr_math = 'Adam/Gr/GrMath.HC'
extract(gr_math, b'public Bool Line(', b'#help_index "Graphics/Math/3D Transformation"', line)
extract(gr_math, b'#define GR_SCALE1_BITS', b'public Bool RegPoly(', walkers)

plot = 'Adam/Gr/GrPlotCore.HC'
peek = 'Adam/Gr/GrPeekCore.HC'
point = 'Adam/Gr/GrPointClipCore.HC'
extract(point, b'public Bool GrPlot(', b'Bool GrPlot1(', plot)
extract(point, b'public I64 GrPeek(', None, peek)
curves = 'Adam/Gr/GrEllipse3Core.HC'
extract('Adam/Gr/GrCurves3Core.HC', b'#include "/Adam/Gr/GrDefaultContext.HH"',
        b'public Bool GrRegPoly3(', curves)

for unit in ('Load', 'TTFVis', 'TTFFire'):
    name = f'Apps/ToTheFront/{unit}.HC'
    changed[name] = (args.source_candidate / name).read_bytes()
load = changed['Apps/ToTheFront/Load.HC']
for old, new in {
    'NativeTTFIntegerPrompt.HC': prompt, 'NativeTTFRange.HC': range_chooser,
    'NativeTTFWrap.HC': wrap, 'NativeTTFKeyPoll.HC': poll,
}.items():
    before, after = include(f'Kernel/I386/{old}'), include(new)
    assert load.count(before) == 1
    load = load.replace(before, after)
changed['Apps/ToTheFront/Load.HC'] = load

added['Kernel/I386/NativeTTFGeometry.HC'] = b''.join(
    include(path) for path in ('Adam/Gr/Gr.HH', 'Adam/Gr/GrBlotCore.HC', 'Adam/Gr/GrPixelCoverageCore.HC')
) + b'\nBool IsPixCovered0(CTask *task,I64 x,I64 y) {return GrPixelCoveredCore(task,x,y);}\n\n' + b''.join(
    include(path) for path in (line, plot, peek))
added['Kernel/I386/NativeTTFCurves.HC'] = b''.join(
    include(path) for path in ('Adam/PolarCore.HC', saw, walkers, curves))

changed = {'/' + path: data for path, data in changed.items()}
added = {'/' + path: data for path, data in added.items()}


def updated_snapshot(raw):
    tree, files, directories = snapshot(raw)
    for path, data in changed.items():
        node = tree
        for component in path.strip('/').split('/')[:-1]:
            node = node[component][2]
        attributes, date, _ = files[path]
        files[path] = node[Path(path).name] = (attributes, date, data)
    return tree, files, directories


image = out/'kernel.img'
package.__globals__['snapshot'] = updated_snapshot
try:
    receipt = package(args.base, image, additions=added)
finally:
    package.__globals__['snapshot'] = snapshot
raw = image.read_bytes()
_, files, _ = snapshot(raw)
assert raw[:2048*512] == base[:2048*512]
assert files.keys() == original.keys() | added.keys()
assert all(files[name] == (attr, date, changed.get(name, data))
           for name, (attr, date, data) in original.items())
assert all(files[name][2] == data for name, data in added.items())
receipt['replaced_files'] = {name: hashlib.sha256(data).hexdigest() for name, data in changed.items()}
(out/'result.json').write_text(json.dumps(receipt, indent=2)+'\n')
for name, data in (changed | added).items():
    path = out/'sources'/name.removeprefix('/')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
