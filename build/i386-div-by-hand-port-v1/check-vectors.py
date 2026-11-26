import hashlib
import json
from pathlib import Path
import runpy
import sys

image, out = (Path(arg).resolve() for arg in sys.argv[1:])
demo = Path('Demo/Asm/DivByHand.HC')
out.mkdir()
vectors = [
    (0, 1), (123456, 10), (0xffffffffffffffff, 1),
    (0xffffffffffffffff, 0x8000000000000000),
    (0xffffffffffffffff, 0x180000001),
    (0x8000000000000000, 0x100000000),
    (0x100000000, 0xffffffffffffffff),
    (0xffffffffffffffff, 0xffffffffffffffff),
    (0xffffffffffffffff, 3), (8, 0),
]
lines = ['U0 TestDivision(){']
for dividend, divisor in vectors:
    expected = dividend // divisor if divisor else 0xffffffffffffffff
    lines.append(f'  if(DivU64ByU64(0x{dividend:X},0x{divisor:X})!=0x{expected:X})throw("Division",TRUE);')
lines.extend(['}', 'TestDivision;', ''])
fixture = demo.read_bytes() + '\n'.join(lines).encode()
(out/'fixture.HC').write_bytes(fixture)

def sha(path):
    return hashlib.file_digest(path.open('rb'), 'sha256').hexdigest()

pins = {str(path): sha(path) for path in (image, demo)}
report = {'result': 'fail', 'inputs': pins, 'vector_count': len(vectors)}
try:
    working = out/'working.img'
    runpy.run_path('tools/package-i386-native-image.py')['package'](
        image, working, additions={'/Probe/DivVectors.HC': fixture})
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = Guest(working, out/'guest', True)
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/DivVectors.HC"')
        guest.command('6*7;')
        report['arithmetic_pixels'] = guest.result_pixels()
    finally:
        guest.close()
    report['result'] = 'pass'
finally:
    report['inputs_unchanged'] = all(sha(Path(path)) == digest for path, digest in pins.items())
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    assert report['inputs_unchanged']
