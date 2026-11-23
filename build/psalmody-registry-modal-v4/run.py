import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import time

parser = argparse.ArgumentParser()
parser.add_argument('image', type=Path)
parser.add_argument('--out', required=True, type=Path)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Modal.HC')
pack = runpy.run_path('tools/package-i386-native-image.py')
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
pins = {str(p): sha(p) for p in (args.image, fixture, Path(__file__),
        Path('tools/package-i386-native-image.py'),
        Path('tools/test-i386-autocomplete-interaction.py'))}
working = out/'working.img'
name = '/Probe/Modal.HC'
outcome = {'result': 'running', 'input_sha256': pins}
guest = None

def changed(before, after):
    return {key for key in before.keys() | after.keys()
            if before.get(key) != after.get(key)}

def wait_export(name, start=0):
    guest.wait(f'EXPORT {name} ', 30, start=start)
    p = guest.out/name
    end = time.monotonic() + 15
    while not p.exists() and time.monotonic() < end:
        guest.collect()
        time.sleep(.1)
    return p.read_bytes()

def click(target, address):
    assert 0 <= target[0] < 640 and 0 <= target[1] < 480, target
    state = guest.out/'pointer.bin'
    deadline = time.monotonic() + 15
    while True:
        guest.call('pmemsave', val=address, size=16, filename=str(state))
        x, y = struct.unpack('<2q', state.read_bytes())
        if (x, y) == target:
            break
        if time.monotonic() >= deadline:
            raise TimeoutError('Guest pointer did not reach checkbox or button')
        guest.call('input-send-event', events=[
            {'type':'rel', 'data':{'axis':'x', 'value':target[0]-x}},
            {'type':'rel', 'data':{'axis':'y', 'value':target[1]-y}}])
        time.sleep(.2)
    for down in (True, False):
        guest.call('input-send-event', events=[
            {'type':'btn', 'data':{'down':down, 'button':'left'}}])
        time.sleep(.08)

def launch(command, directory):
    guest = Guest(working, directory, True)
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/Probe/Modal.HC"')
    offset = len(guest.collect())
    guest.type(command)
    guest.press('ret')
    return guest, offset

try:
    before = pack['snapshot'](args.image.read_bytes())[1]
    outcome['packaging'] = pack['package'](args.image, working, additions={name:fixture.read_bytes()})
    guest, start = launch('RegistryModal;', out/'guest')
    log = guest.wait('RP mouse ', 30, start=start)
    if not re.search(r'RP mouse ([0-9A-F]+)\n', log):
        log = guest.wait('EXPORT modal-1.bin ', 30, start=start)
    address = int(re.search(r'RP mouse ([0-9A-F]+)\n', log)[1],16)
    for phase in range(1,4):
        points = struct.unpack('<4q', wait_export(f'modal-{phase}.bin', start))
        time.sleep(.3)
        guest.screenshot(f'modal-{phase}')
        if phase == 1:
            guest.key('shift', True)
            guest.press('esc')
            guest.key('shift', False)
        else:
            if phase == 3:
                click(points[:2], address)
                guest.wait('RP checked\n', 30, start=start)
            click(points[2:], address)
    guest.wait('RP done\n', 30, start=start)
    if 'EXPORT modal-4.bin ' in guest.collect()[start:]:
        raise ValueError('A fourth popup opened after acceptance')
    flags = struct.unpack('<4q', wait_export('flags.bin', start))
    if flags != (0, 0, 0, 8):
        raise ValueError(f'Unexpected flag transitions {flags}')
    guest.wait('COMMAND OK\n', start=start)
    guest.close()
    guest = None
    persisted = pack['snapshot'](working.read_bytes())[1]
    files = changed(before, persisted)
    if files != {name, '/Home/Registry.HC.Z'}:
        raise ValueError(f'Unexpected file changes {files}')
    guest, start = launch('RegistryModal(TRUE);', out/'reopen')
    guest.wait('RP done\n', 30, start=start)
    cold = struct.unpack('<q', wait_export('flags.bin', start))[0]
    if cold != 8:
        raise ValueError(f'Cold flag mismatch {cold}')
    guest.wait('COMMAND OK\n', start=start)
    guest.command('6*7;')
    outcome['fresh_result'] = guest.result_pixels()
    guest.close()
    guest = None
    if pack['snapshot'](working.read_bytes())[1] != persisted:
        raise ValueError('Suppressed popup changed persisted files')
    outcome.update(result='pass', flags=flags, cold_flags=cold, changed_files=sorted(files))
except Exception as exc:
    outcome.update(result='fail', error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    outcome['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
    (out/'result.json').write_text(json.dumps(outcome,indent=2)+'\n')
