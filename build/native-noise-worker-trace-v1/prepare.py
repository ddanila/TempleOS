"""Cross-build a bounded trace of the native sound-effect worker."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('base', type=Path)
parser.add_argument('--fix-delay', action='store_true')
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
source_path = Path('Adam/Snd/SndEffects.HC')
source = source_path.read_bytes()
if args.fix_delay:
    old = b'\tif (t+tS>timeout)\n\t  t=timeout-tS;\n\tSleep(t);'
    new = b'\tif (t>1000.0*(timeout-tS))\n\t  t=1000.0*(timeout-tS);\n\tif (t>0) Sleep(ToI64(Ceil(t)));'
    assert source.count(old) == 2
    src = source.replace(old, new)
else:
    start = source.index(b'U0 SoundEffectTask(')
    end = source.index(b'    case SE_SWEEP:', start)
    worker = source[start:end]
    worker = worker.replace(b'  I64 i,ona;', b'  I64 i,ona,trace_count=0;\n  U8 trace_line[128],*trace;')
    needle = b'\tSleep(t);'
    assert worker.count(needle) == 1
    worker = worker.replace(needle, b'''        if (trace_count<24) {
              StrPrint(trace_line,"NOISE step %d note %d jiffy %d delay %X ms %d\\n",
                  trace_count,ona,cnts.jiffies,t(U64),ToI64(t));
              for (trace=trace_line;*trace;trace++) OutU8(0xE9,*trace);
            }
            trace_count++;
    ''' + needle)
    src = source[:start] + worker + source[end:]
overlay = out / 'overlay'
path = overlay / source_path
path.parent.mkdir(parents=True)
path.write_bytes(src)
subprocess.run(['python3','tools/build-iso.py',
                '--overlay','build/tothefront-production-v1/bootstrap/overlay',
                '--overlay','tools/guest/i386-kernel','--overlay',str(overlay),
                '--output',str(out/'compiler.iso')],check=True)
subprocess.run(['python3','tools/guest-run.py',str(out/'compiler.iso'),'--qmp-stdio',
                '--timeout','240','--out',str(out/'exports')],check=True)

packer = runpy.run_path('tools/package-i386-native-image.py')
package, snapshot = packer['package'], packer['snapshot']
console = (out/'exports/ConsoleRuntime.t32m').read_bytes()
builder = runpy.run_path('tools/build-i386-kernel.py')
builder['console_runtime_layout'](console)
replacements = {'/Modules/I386/ConsoleRuntime.t32m':console, '/'+str(source_path):src}
base = args.base.read_bytes()
original = snapshot(base)[1]

def updated_snapshot(raw):
    tree, files, directories = snapshot(raw)
    for path,data in replacements.items():
        node = tree
        for part in path.strip('/').split('/')[:-1]:
            node = node[part][2]
        attributes, date, _ = files[path]
        files[path] = node[Path(path).name] = (attributes, date, data)
    return tree, files, directories

image = out/'kernel.img'
package.__globals__['snapshot'] = updated_snapshot
try:
    receipt = package(args.base, image)
finally:
    package.__globals__['snapshot'] = snapshot
final = image.read_bytes()
files = snapshot(final)[1]
assert final[:2048 * 512] == base[:2048 * 512] and original.keys() == files.keys()
assert all(files[path] == (attr, date, replacements.get(path,data))
           for path,(attr,date,data) in original.items())
receipt['replacements'] = {path: hashlib.sha256(data).hexdigest()
                           for path,data in replacements.items()}
(out/'result.json').write_text(json.dumps(receipt,indent=2)+'\n')
