"""Build an isolated full image with added original Adam startup dependencies."""
import argparse
from pathlib import Path
import runpy
import struct

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
here = Path(__file__).resolve().parent
root = here.parents[1]
package = runpy.run_path(str(root / 'tools/package-i386-native-image.py'))
startup = '/Kernel/I386/StartOS.HC'
suffix = (here / 'append.HC').read_bytes()
prior = package['snapshot'](args.disk.read_bytes())[1][startup][2]
package['package'](args.disk, args.out, additions={'/Probe/OldStartup.HC': prior + suffix})

image = bytearray(args.out.read_bytes())
volume = struct.unpack_from('<q', image, 2048 * 512 + 24)[0]


def slot(path):
    block = volume
    parts = path.strip('/').split('/')
    for part in parts:
        start = block * 512
        size = struct.unpack_from('<q', image, start + 48)[0]
        for offset in range(start + 128, start + size, 64):
            name, pointer = struct.unpack_from('<38sq', image, offset + 2)
            if name.split(b'\0', 1)[0].decode('ascii') == part:
                block = pointer
                break
        else:
            raise ValueError(f'Missing directory slot: {path}')
    return offset


old = slot(startup)
new = slot('/Probe/OldStartup.HC')
#Swap only extent and length so both allocations remain reachable.
image[old + 40:old + 56], image[new + 40:new + 56] = image[new + 40:new + 56], image[old + 40:old + 56]
args.out.write_bytes(image)
runpy.run_path(str(root / 'tools/build-i386-kernel.py'))['verify_mutated_volume'](args.out)
