"""Repack a disk to verify the original vertical map spacing."""

import argparse
from pathlib import Path
import runpy


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--shared-source', action='store_true')
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    packer = runpy.run_path('tools/package-i386-native-image.py')
    repack = runpy.run_path(str(Path(__file__).with_name('fire_trace.py')))['package_replacements']
    name = '/Apps/ToTheFront/TTFInit.HC'
    source = packer['snapshot'](args.source.read_bytes())[1][name][2]
    anchor = b'y=DSIN*(j+1);'
    if source.count(anchor) != 1:
        raise ValueError('Expected one vertical center assignment')
    candidate = source.replace(anchor, b'y=0x40230D747FBFE4F5(F64)*(j+1);')
    if args.shared_source:
        candidate = Path(name.lstrip('/')).read_bytes()
    repack(args.source, args.output, b'', packer['snapshot'], packer['package'],
           {name: candidate}, additions={})


if __name__ == '__main__':
    main()
