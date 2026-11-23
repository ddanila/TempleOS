"""Run the unchanged source-debug-map contract using a packaged guest file."""
import hashlib
import json
from pathlib import Path
import runpy
import sys

disk, out = map(Path, sys.argv[1:])
out = out.resolve()
out.mkdir()
fixture = Path('tests/guest/i386-source-links/DebugMap.HC').read_bytes()
packer = runpy.run_path('tools/package-i386-native-image.py')['package']
image = out/'working.img'
report = {'package': packer(disk, image, additions={'/RectDebugMap.HC': fixture}),
          'fixture_sha256':hashlib.sha256(fixture).hexdigest()}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out/'guest', True, ram_mib=8)
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/RectDebugMap.HC"')
    guest.command('if(JRContract("C:/RectDebugMap.HC")!=63)throw(\'DbgMap\',TRUE);')
    guest.command('6*7;')
    report['fresh_arithmetic'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as error:
    report.update(result='fail', error=str(error))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
