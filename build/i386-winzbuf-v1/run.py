import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys
import tempfile
import time


parser = argparse.ArgumentParser()
parser.add_argument('--disk', type=Path)
parser.add_argument('--reference-image', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir(parents=True)
fixture = Path(__file__).with_name('Probe.HC').read_bytes()
demo = Path('Demo/Graphics/WinZBuf.HC')
native = bool(args.disk)
sha = lambda data: hashlib.sha256(data).hexdigest()
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
if native:
    pack = runpy.run_path('tools/package-i386-native-image.py')
    assert pack['snapshot'](args.disk.read_bytes())[1]['/'+demo.as_posix()][2] == demo.read_bytes()
    image = out/'working.img'
    pack['package'](args.disk, image, additions={'/Probe/WinZBuf.HC': fixture})
elif args.reference_image:
    image = args.reference_image.resolve()
    receipt = json.loads((image.parent / 'result.json').read_text())
    assert receipt['input_sha256'] == sha(image.read_bytes())
    pinned = runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference']
    with tempfile.TemporaryDirectory(dir=out) as reference_tree:
        assert pinned(Path(reference_tree))[demo.as_posix()] == sha(demo.read_bytes())
else:
    overlay = out/'overlay'
    overlay.mkdir()
    pins = runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference'](overlay)
    assert pins[demo.as_posix()] == sha(demo.read_bytes())
    (overlay/'Once.HC').write_bytes(fixture)
    image = out/'original.iso'
    subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),
                    '--output',str(image)],check=True)

guest = Guest(image,out/'guest',native,reference_cpus=1)
report = dict(result='running', demo_sha256=sha(demo.read_bytes()),
              input_sha256=sha(image.read_bytes()), mode='native' if native else 'original',
              scope='Unmodified WinZBuf demo, two controlled window positions and dismissal')

try:
    if native:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/WinZBuf.HC"')
        guest.command('ZSetup;Spawn(&ZWatch,Fs,"Z map watcher",,Fs);')
    else:
        guest.wait('Z READY\n')
        time.sleep(2)
        guest.type('ZSetup;Spawn(&ZWatch,Fs,"Z map watcher",,Fs);')
        guest.press('ret')
        time.sleep(2)
    offset = len(guest.collect())
    drive = 'C' if native else 'T'
    command = f'ExeFile("{drive}:/{demo}");'
    if not native:
        command += r'ZLog("Z DONE\n");'
    guest.type(command)
    guest.press('ret')
    for phase in range(2):
        guest.wait(f'Z MAP {phase} ',timeout=30,start=offset)
        guest.wait('Z MAP END\n',timeout=15,start=offset)
        marker = re.search(rf'^Z MAP {phase} (\d+) (\d+)\n([0-9a-f]{{4800}})\nZ MAP END$',
                           guest.collect()[offset:],re.M)
        assert marker, guest.collect()[offset:][-600:]
        x,y = map(int,marker.groups()[:2])
        report[f'phase{phase}'] = dict(x=x,y=y,indices=marker[3])
        guest.screenshot(f'map{phase}')
        offset += marker.end()
    guest.press('spc')
    guest.wait('COMMAND OK\n' if native else 'Z DONE\n',25,offset)
    time.sleep(.5)
    guest.screenshot('cleared')
    if native:
        guest.command('6*7;')
        report['fresh_arithmetic'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
