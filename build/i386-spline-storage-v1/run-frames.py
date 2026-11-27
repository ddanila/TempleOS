from hashlib import sha256
from pathlib import Path
from runpy import run_path
import json
import sys

image, out, fixture = (Path(arg).resolve() for arg in sys.argv[1:])
out.mkdir()
working = out / 'working.img'
packager = run_path('tools/package-i386-native-image.py')
digest = sha256(image.read_bytes()).hexdigest()
packager['package'](image, working, {'/SplineControl.HC': fixture.read_bytes()})
driver = run_path('tools/test-i386-autocomplete-interaction.py')
guest = driver['Guest'](working, out / 'guest', True, ram_mib=64)
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/SplineControl.HC"')
    guest.command('U0 SplineReport(U8 *s){while(*s)OutU8(0xE9,*s++);}')
    guest.command('U8 *spline_report=MStrPrint("SPLINE MASK %d\\n",SplineFrames);SplineReport(spline_report);Free(spline_report);')
    assert 'SPLINE MASK 15\n' in guest.collect()
    guest.command('6*7;')
    guest.result_pixels()
finally:
    guest.close()
_, files, _ = packager['snapshot'](working.read_bytes())
report = {'image_sha256': digest, 'fixture_sha256': sha256(fixture.read_bytes()).hexdigest(),
          'inputs_unchanged': digest == sha256(image.read_bytes()).hexdigest(),
          'frames': {}, 'mask': 15, 'arithmetic': 42}
for order in (2, 3):
    for closed in (0, 1):
        name = f'Spline{order}{closed}.BIN'
        pixels = files['/' + name][2]
        ink = pixels.count(4)
        assert len(pixels) == 96 * 80 and ink > 20
        report['frames'][name] = {'sha256': sha256(pixels).hexdigest(), 'ink': ink}
        (out / name).write_bytes(pixels)
(out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
