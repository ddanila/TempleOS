"""Check the unchanged bundled X-Caliber loader on a normal i386 image."""

import argparse
import hashlib
import json
from pathlib import Path
import runpy


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    args.out.mkdir()
    path = '/Apps/X-Caliber/Load.HC'
    image = args.out / 'working.img'
    pack = runpy.run_path('tools/package-i386-native-image.py')
    before = pack['snapshot'](args.disk.read_bytes())[1]
    package = pack['package'](args.disk, image)
    report = dict(result='fail', command=f'#include "C:{path}"', package=package,
                  loader_sha256=hashlib.sha256(before[path][2]).hexdigest())
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = guest_type(image, args.out / 'guest', True)
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command(report['command'])
        guest.command('6*7;')
        report['arithmetic_pixels'] = guest.result_pixels()
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        guest.close()
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
