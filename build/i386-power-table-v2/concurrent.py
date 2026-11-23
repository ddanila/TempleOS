"""Run two first-use power calls from separate native guest tasks."""

import argparse
import hashlib
import json
from pathlib import Path
import runpy


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--single-publication', action='store_true')
    args = parser.parse_args()
    args.out.mkdir()
    source = Path(__file__).with_name('Concurrent.HC').read_bytes()
    image = args.out / 'working.img'
    packer = runpy.run_path('tools/package-i386-native-image.py')
    packer['package'](args.disk, image, additions={'/Concurrent.HC': source})
    report = {'result': 'fail', 'fixture_sha256': hashlib.sha256(source).hexdigest(),
              'input_sha256': hashlib.sha256(args.disk.read_bytes()).hexdigest()}
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = guest_type(image, args.out / 'guest', True)
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Concurrent.HC"')
        guest.command('PowerConcurrent;')
        guest.wait('POWER worker one exact\n', 45)
        guest.wait('POWER worker two exact\n', 45)
        guest.command('6*7;')
        report['arithmetic_pixels'] = guest.result_pixels()
        report['rejected_publications'] = guest.collect().count('TERMINAL publication rejected\n')
        if args.single_publication and report['rejected_publications']:
            raise ValueError('Concurrent first use rejected a publication')
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        guest.close()
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
