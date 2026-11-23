"""Build and install an experimental memory backing policy."""

import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--small-public-pages', action='store_true')
parser.add_argument('disk', type=Path)
parser.add_argument('--out', required=True, type=Path)
args = parser.parse_args()
args.out.mkdir()
if args.small_public_pages:
    source = Path('Kernel/I386/Memory.HC')
    text = source.read_bytes()
    anchor = b'(span+16*MEM_PAG_SIZE-1)>>MEM_PAG_BITS'
    if text.count(anchor) != 1:
        raise ValueError('Unexpected small-allocation page request')
    text = text.replace(anchor, b'(span+8*MEM_PAG_SIZE-1)>>MEM_PAG_BITS')
else:
    source = Path('Kernel/I386/MemoryBacking.HC')
    text = source.read_bytes()
    anchor = b'  if(!I386MemBackingFits(source,request))return FALSE;\n  before=source->used;'
    if text.count(anchor) != 1:
        raise ValueError('Unexpected backing selection code')
    text = text.replace(anchor, b'''  if(!I386MemBackingFits(source,request))return FALSE;
  if(pool->fallback && source==pool->heap && pool->owned_count &&
      size==I386_NATIVE_BACKING_QUANTUM &&
      I386MemBackingFits(source,request+I386_NATIVE_BACKING_QUANTUM)) {
    size+=I386_NATIVE_BACKING_QUANTUM;
    request+=I386_NATIVE_BACKING_QUANTUM;
  }
  before=source->used;''')
    anchor = b'if(pool->owned_count && size==I386_NATIVE_BACKING_QUANTUM)'
    if text.count(anchor) != 1:
        raise ValueError('Unexpected backing placement code')
    text = text.replace(anchor, b'''if(pool->owned_count && (size==I386_NATIVE_BACKING_QUANTUM ||
      pool->fallback && source==pool->heap && size==2*I386_NATIVE_BACKING_QUANTUM))''')
overlay = args.out / 'overlay'
changed = overlay / source
changed.parent.mkdir(parents=True)
changed.write_bytes(text)
iso = args.out / 'compiler.iso'
exports = args.out / 'exports'
subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                'build/sound-delay-production-v1/bootstrap/overlay', '--overlay',
                'tools/guest/i386-kernel', '--overlay', str(overlay),
                '--output', str(iso)], check=True)
subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--qmp-stdio',
                '--timeout', '240', '--out', str(exports)], check=True)
builder = runpy.run_path('tools/build-i386-kernel.py')
memory = (exports / 'MemoryRuntime.t32m').read_bytes()
builder['memory_runtime_layout'](memory)
builder['audit'](exports, args.out)
packer = runpy.run_path('tools/package-i386-native-image.py')
replace = runpy.run_path('build/tothefront-original-v1/fire_trace.py')['package_replacements']
disk = args.out / 'candidate.img'
receipt = replace(args.disk, disk, b'', packer['snapshot'], packer['package'],
                  {'/' + source.as_posix(): text, '/Modules/I386/MemoryRuntime.t32m': memory},
                  additions={})
receipt.update(result='pass', memory_runtime_sha256=hashlib.sha256(memory).hexdigest(),
               replaced_sha256={'/' + source.as_posix(): hashlib.sha256(text).hexdigest(),
                                '/Modules/I386/MemoryRuntime.t32m': hashlib.sha256(memory).hexdigest()})
(args.out / 'result.json').write_text(json.dumps(receipt, indent=2) + '\n')
