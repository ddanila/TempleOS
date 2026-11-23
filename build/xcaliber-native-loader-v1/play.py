"""Exercise bundled X-Caliber on the native image with the shared gameplay observer."""
import argparse
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('disk', type=Path)
parser.add_argument('--out', required=True, type=Path)
parser.add_argument('--warm-geometry', action='store_true')
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
probe = Path('build/xcaliber-reference-v1/Probe.HC').read_bytes()
image = out / 'working.img'
packer = runpy.run_path('tools/package-i386-native-image.py')
report = {'result': 'fail', 'package': packer['package'](args.disk, image,
                                                        additions={'/XCProbe.HC': probe})}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out / 'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    if args.warm_geometry:
        guest.command('#include "C:/Kernel/I386/NativeTTFGeometry.HC"')
        guest.command('#include "C:/Kernel/SerialDev/KeyCharPollCore.HC"')
    guest.command('#include "C:/Apps/X-Caliber/Load.HC"')
    guest.type('#include "C:/XCProbe.HC"')
    guest.press('ret')
    report['play'] = {}
    exercise = runpy.run_path('build/xcaliber-reference-v1/workflow.py')['exercise']
    exercise(guest, report['play'], fire=True, turn=True)
    guest.command('6*7;')
    report['arithmetic_pixels'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as error:
    report['error'] = str(error)
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
