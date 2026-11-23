import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
overlay = out / 'overlay'
fixture = Path(__file__).with_name('Probe.HC')
reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
source_hashes = reference['restore_reference'](overlay)
(overlay / 'Once.HC').write_bytes(
    b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
    b'#include "T:/Apps/Span/Load.HC"\n' + fixture.read_bytes() + b'\nSpanProbe;\n')
image = out / 'original.iso'
subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                '--output', str(image)], check=True)
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
report = {'result': 'running', 'image_sha256': sha(image), 'fixture_sha256': sha(fixture),
          'source_sha256': {name: digest for name, digest in source_hashes.items()
                            if name.startswith('Apps/Span/')}}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out / 'guest', False)
try:
    log = guest.wait('SPAN returned\n', 100)
    match = re.search(r'^SPAN persisted (\d+) bytes header (\d+) mass (\d+) spring (\d+)$',
                      log, re.M)
    size, header, mass, spring = map(int, match.groups())
    export = out / 'guest/steel-bridge.data'
    data = export.read_bytes()
    version, masses, springs = struct.unpack_from('<dii', data)
    if (version, masses, springs) != (1.0, 2, 1) or header != 16 or \
            size != len(data) or size != header + masses * mass + springs * spring:
        raise ValueError('Original Span file header disagrees with the record layout')
    report.update(result='pass', size=size, record_bytes={'header':header, 'mass':mass,
                  'spring':spring}, export_sha256=sha(export), version=version,
                  masses=masses, springs=springs)
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
