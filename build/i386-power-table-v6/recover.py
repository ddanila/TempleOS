"""Check that a missing power provider can be restored and retried."""

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
    image = args.out / 'working.img'
    packer = runpy.run_path('tools/package-i386-native-image.py')
    fixture = b'F64 RecoverPow(F64 a,F64 b){return a`b;}\n'
    report = {'result': 'fail', 'package': packer['package'](
        args.disk, image, additions={'/RecoverPow.HC': fixture})}
    report['input_sha256'] = hashlib.sha256(args.disk.read_bytes()).hexdigest()
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = guest_type(image, args.out / 'guest', True)
    path = 'C:/Kernel/I386/FloatPower.HC'
    saved = 'C:/Kernel/I386/PowSaved.HC'
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/RecoverPow.HC"')
        guest.command(f'if(!FileMove("{path}","{saved}"))throw(\'Move\',TRUE);')
        try:
            guest.command('RecoverPow(3,2);')
        except ValueError as error:
            report['first_rejection'] = str(error)
            if 'INPUT REJECT exception 0064616F4C776F50' not in report['first_rejection']:
                raise
        else:
            raise ValueError('The missing provider did not reject the expression')
        guest.command(f'if(!FileMove("{saved}","{path}"))throw(\'Move\',TRUE);')
        guest.command("if(RecoverPow(3,2)(U64)!=0x4021FFFFFFFFFFFF)throw('Bits',TRUE);")
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
