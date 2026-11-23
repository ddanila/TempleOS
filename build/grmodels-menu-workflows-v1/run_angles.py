"""Capture the angle and fixed-point stages used by the default Man mesh."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    fixture = Path(__file__).with_name('Angles.HC').read_bytes()
    report = {'fixture_sha256':hashlib.sha256(fixture).hexdigest()}
    if args.disk:
        image = out/'working.img'
        pack = runpy.run_path('tools/package-i386-native-image.py')['package']
        report['package'] = pack(args.disk,image,additions={'/ManAngles.HC':fixture})
    else:
        image = out/'original.iso'
        overlay = out/'overlay'
        reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
        reference['restore_reference'](overlay)
        (overlay/'Once.HC').write_bytes(fixture)
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),
                        '--output',str(image)],check=True)
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = Guest(image,out/'guest',bool(args.disk))
    try:
        if args.disk:
            guest.wait('DONE native kernel startup\n')
            guest.command('#include "C:/ManAngles.HC"')
        guest.wait('MAN angles ready\n',90)
        data = (guest.out/'ManAngles.bin').read_bytes()
        if len(data) != 32*8:
            raise ValueError('Unexpected angle sample size')
        report.update(result='pass',sample_sha256=hashlib.sha256(data).hexdigest())
    except Exception as error:
        report.update(result='fail',error=str(error))
        raise
    finally:
        guest.close()
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__ == '__main__':
    main()
