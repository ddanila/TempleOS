import argparse
import hashlib
import json
import math
import struct
from pathlib import Path
import runpy

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
root = Path('build/span-reference-persistence-v1')
fixture = (root / 'Probe.HC').read_bytes().replace(b'B:/SpanProbe.DATA', b'C:/SpanProbe.DATA')
expected = (root / 'ram-reference/steel-bridge.data').read_bytes()
fixture += b'\n' + Path('build/span-file-interchange-v1/Import.HC').read_bytes()
packer = runpy.run_path('tools/package-i386-native-image.py')
image = out / 'working.img'
report = {'result':'running','expected_sha256':hashlib.sha256(expected).hexdigest()}
report['package'] = packer['package'](args.disk,image,additions={
    '/SpanProbe.HC':fixture, '/IncomingBridge.DATA':expected,
})
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out / 'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    for command in (
        '#include "C:/Apps/Span/Load.HC"',
        '#include "C:/SpanProbe.HC"',
    ):
        report['command'] = command
        guest.command(command)
    guest.type('SpanProbe;')
    guest.press('ret')
    guest.wait('SPAN returned\n',120)
    captured = (out / 'guest/steel-bridge.data').read_bytes()
    report['capture_size'] = len(captured)
    report['capture_sha256'] = hashlib.sha256(captured).hexdigest()
    if len(captured) != len(expected):
        raise ValueError('Native Span bridge record size differs')
    masked = bytearray(captured)
    report['computed_fields'] = {}
    for offset in (232,264,272,280,288,296):
        left = struct.unpack_from('<d', expected, offset)[0]
        right = struct.unpack_from('<d', captured, offset)[0]
        if not math.isclose(left,right,rel_tol=4e-15):
            raise ValueError(f'Native spring coefficient differs at byte {offset}')
        masked[offset:offset+8] = expected[offset:offset+8]
        report['computed_fields'][str(offset)] = [left,right]
    if masked != expected:
        raise ValueError('Native file differs outside the computed spring fields')
    guest.command('BridgeImportProbe;')
    guest.wait('SPAN interchange returned\n',15)
    if 'FAIL Span' in guest.collect():
        raise ValueError('Bridge interchange failed in the guest')
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    guest.close()
    if report['result']=='pass':
        returned = packer['snapshot'](image.read_bytes())[1]['/ReturnedBridge.DATA'][2]
        report['returned_sha256'] = hashlib.sha256(returned).hexdigest()
        if returned != expected:
            report.update(result='fail',error='Native disk did not preserve original bytes')
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
if report['result'] != 'pass':
    raise ValueError(report['error'])
