import argparse
import hashlib
import json
from pathlib import Path
import runpy
import re
import struct
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path, nargs='?')
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC').resolve()
guest_runner = Path('tools/test-i386-autocomplete-interaction.py')
reference = Path('tools/test-i386-timeclock-reference.py')
packer = Path('tools/package-i386-native-image.py')
ode_types = Path('Kernel/KernelA.HH')
ode = Path('build/strut-ode-power-v1/SerialODE.HC')
d3 = Path('build/strut-ode-power-v1/D3.HC')
inputs = [Path(__file__), fixture, guest_runner, reference, packer, ode_types, ode, d3]
if args.disk:
    inputs.append(args.disk)

def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

pins = {str(path): sha(path) for path in inputs}
report = {'result': 'running', 'input_sha256': pins,
          'scope': 'Unchanged Strut instructions, physical mass and spring creation, play simulation and exit'}
guest = None
try:
    if args.disk:
        image = out/'working.img'
        types = ode_types.read_bytes()
        types = types[types.index(b'#help_index "Math/ODE"'):types.index(b'#help_index "Processor"')]
        report['packaging'] = runpy.run_path(str(packer))['package'](
            args.disk, image, additions={
                '/StrutProbe.HC': fixture.read_bytes(), '/Probe/ODETypes.HH': types,
                '/Probe/SerialODE.HC': ode.read_bytes(), '/Probe/D3.HC': d3.read_bytes()})
    else:
        overlay = out/'overlay'
        report['reference_sha256'] = runpy.run_path(str(reference))['restore_reference'](overlay)
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
            b'#include "T:/Apps/Strut/Load.HC"\n'
            + fixture.read_bytes() + b'\nSTProbe;\n')
        image = out/'original.iso'
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                        '--output', str(image)], check=True)
    Guest = runpy.run_path(str(guest_runner))['Guest']
    guest = Guest(image, out/'guest', bool(args.disk))
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        for command in (
            '#include "C:/Probe/ODETypes.HH"',
            '#include "C:/Probe/D3.HC"',
            '#include "C:/Probe/SerialODE.HC"',
            'AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);',
            'AdamFile("C:/Adam/TaskSettings.HC",FALSE);',
            '#include "C:/Adam/Ctrls/CtrlsBttn.HC"',
            '#include "C:/Apps/Strut/Load.HC"',
            '#include "C:/StrutProbe.HC"',
        ):
            guest.command(command)
        guest.type('STProbe;')
        guest.press('ret')
    guest.wait('STRUT instructions\n', 90)
    time.sleep(1)
    guest.screenshot('instructions')
    guest.press('a')
    log = guest.wait('STRUT editor ', 90)
    address = int(re.search(r'STRUT editor ([0-9A-F]+)\n',log)[1],16)
    pointer = out/'pointer.bin'

    def move(target):
        until = time.monotonic() + 18
        while time.monotonic() < until:
            guest.call('pmemsave', val=address,size=24,filename=str(pointer))
            x,y,left=struct.unpack('<3q',pointer.read_bytes())
            if (x,y)==target:
                return
            guest.call('input-send-event', events=[
                {'type':'rel','data':{'axis':'x','value':target[0]-x}},
                {'type':'rel','data':{'axis':'y','value':target[1]-y}}])
            time.sleep(.2)
        raise TimeoutError(f'Pointer did not reach {target}')

    def button(down):
        guest.call('input-send-event', events=[
            {'type':'btn','data':{'down':down,'button':'left'}}])
        time.sleep(.3)

    first,second=(140,160),(245,180)
    for index,position in enumerate((first,second)):
        move(position)
        button(True)
        button(False)
        guest.wait(('STRUT first mass\n','STRUT second mass\n')[index],20)
    guest.press('s')
    time.sleep(.5)
    move(first)
    button(True)
    move(second)
    button(False)
    guest.wait('STRUT spring\n',20)
    guest.screenshot('ship')
    guest.press('spc')
    guest.wait('STRUT play\n',20)
    guest.wait('STRUT simulation advanced\n',20)
    guest.press('esc')
    guest.wait('STRUT returned\n',20)
    if args.disk:
        guest.command('6*7;')
        report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    if guest:
        report['observations']=[line for line in guest.collect().splitlines() if line.startswith('STRUT ')]
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(name)) == digest for name, digest in pins.items())
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
