#!/usr/bin/env python3
"""Compare bundled TXTGen output against the pinned original conversion."""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT/'build/i386-txtgen-reference-ram-v1/DemoOutPage.TXT.b64'
FILES = ('Adam/Opt/Utils/ToTXT.HC',
         'Demo/ToHtmlToTXTDemo/TXTGen.HC',
         'Demo/ToHtmlToTXTDemo/DemoInPage.DD')
FIXTURE = b''.join(f'#include "/{name}"\n'.encode() for name in FILES[:2])
OUTPUT = '/Home/DemoOutPage.TXT'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    out.mkdir()
    report = dict(result='running', disk_sha256=sha(disk.read_bytes()))
    try:
        package = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        files = package['snapshot'](disk.read_bytes())[1]
        report['source_sha256'] = {name: sha(files['/'+name][2]) for name in FILES}
        provenance = json.loads(REFERENCE.with_name('result.json').read_text())
        if report['source_sha256'] != provenance['source_sha256']:
            raise ValueError('The packaged converter or sample differs from the pinned original')
        if OUTPUT in files:
            raise ValueError('Expected a fresh home without a prior conversion')
        image = out/'working.img'
        package['package'](disk, image, additions={'/Probe/TXTGenProbe.HC': FIXTURE})
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        # The source document uses an age derived from the boot clock.
        rtc = '2026-11-27T00:00:00'
        report['rtc_base'] = rtc
        guest = Guest(image, out/'guest', True, native_options=('-rtc', 'base='+rtc))
        try:
            guest.wait('DONE native kernel startup\n')
            guest.command('#include "C:/Probe/TXTGenProbe.HC"')
            guest.command('6*7;')
            report['fresh_arithmetic'] = guest.result_pixels()
        finally:
            guest.close()
        actual = package['snapshot'](image.read_bytes())[1][OUTPUT][2]
        expected = base64.b64decode(REFERENCE.read_bytes())
        report.update(bytes=len(actual), output_sha256=sha(actual), expected_sha256=sha(expected))
        (out/'DemoOutPage.TXT').write_bytes(actual)
        if actual != expected:
            raise ValueError('TXTGen output differs from the pinned original')
        if sha(disk.read_bytes()) != report['disk_sha256']:
            raise ValueError('Source disk changed')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
