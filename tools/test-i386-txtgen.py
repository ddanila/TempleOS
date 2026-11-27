#!/usr/bin/env python3
"""Compare bundled TXTGen or HtmlGen output against the pinned original conversion."""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
DEMO_DIR = 'Demo/ToHtmlToTXTDemo/'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--html', action='store_true', help='Run HtmlGen instead of TXTGen')
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    out.mkdir()
    if args.html:
        name = 'DemoOutPage.html'
        reference = ROOT/'build/i386-htmlgen-reference-v1'
        includes = (DEMO_DIR+'HtmlGen.HC',)
        sources = (*includes, DEMO_DIR+'ToHtml.HC')
    else:
        name = 'DemoOutPage.TXT'
        reference = ROOT/'build/i386-txtgen-reference-ram-v1'
        includes = ('Adam/Opt/Utils/ToTXT.HC', DEMO_DIR+'TXTGen.HC')
        sources = includes
    sources = (*sources, DEMO_DIR+'DemoInPage.DD')
    fixture = b''.join(f'#include "/{source}"\n'.encode() for source in includes)
    output = '/Home/'+name
    report = dict(result='running', disk_sha256=sha(disk.read_bytes()))
    try:
        package = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        files = package['snapshot'](disk.read_bytes())[1]
        report['source_sha256'] = {source: sha(files['/'+source][2]) for source in sources}
        provenance = json.loads((reference/'result.json').read_text())
        if report['source_sha256'] != provenance['source_sha256']:
            raise ValueError('The packaged converter or sample differs from the pinned original')
        if output in files:
            raise ValueError('Expected a fresh home without a prior conversion')
        image = out/'working.img'
        package['package'](disk, image, additions={'/Probe/ConversionProbe.HC': fixture})
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        # The source document uses an age derived from the boot clock.
        rtc = '2026-11-27T00:00:00'
        report['rtc_base'] = rtc
        guest = Guest(image, out/'guest', True, native_options=('-rtc', 'base='+rtc))
        try:
            guest.wait('DONE native kernel startup\n')
            guest.command('#include "C:/Probe/ConversionProbe.HC"')
            guest.command('6*7;')
            report['fresh_arithmetic'] = guest.result_pixels()
        finally:
            guest.close()
        actual = package['snapshot'](image.read_bytes())[1][output][2]
        expected = base64.b64decode((reference/(name+'.b64')).read_bytes())
        report.update(bytes=len(actual), output_sha256=sha(actual), expected_sha256=sha(expected))
        (out/name).write_bytes(actual)
        if actual != expected:
            raise ValueError('Conversion output differs from the pinned original')
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
