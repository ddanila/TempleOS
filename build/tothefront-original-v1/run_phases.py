import argparse
import hashlib
import json
from pathlib import Path
import runpy
import re
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--disk', type=Path)
parser.add_argument('--map-raster', action='store_true')
parser.add_argument('--move', action='store_true')
occupation = parser.add_mutually_exclusive_group()
occupation.add_argument('--overrun', action='store_true')
occupation.add_argument('--close-assault', action='store_true')
parser.add_argument('--fire', action='store_true')
parser.add_argument('--trace-fire', action='store_true')
parser.add_argument('--trace-shot', action='store_true')
parser.add_argument('--userspace-irqchip', action='store_true')
indirect = parser.add_mutually_exclusive_group()
indirect.add_argument('--indirect', action='store_true')
indirect.add_argument('--indirect-damage', action='store_true')
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
if (args.overrun or args.close_assault) and (args.move or args.fire or args.indirect or args.indirect_damage):
    parser.error('--overrun and --close-assault each require a separate run')
if args.indirect_damage and args.fire:
    parser.error('--indirect-damage and --fire require separate runs')
if args.trace_fire and (not args.fire or not args.disk):
    parser.error('--trace-fire needs --fire and a native --disk')
if args.trace_shot and not args.trace_fire:
    parser.error('--trace-shot requires --trace-fire')
if args.userspace_irqchip and not args.disk:
    parser.error('--userspace-irqchip requires --disk')
out = args.out.resolve()
out.mkdir()
root = Path(__file__).resolve().parent
fixture = (root/'Phases.HC').read_bytes()
if args.map_raster:
    declaration = b'U0 TTFPhaseWatch('
    fixture = fixture.replace(declaration, (root/'MapRaster.HC').read_bytes() + b'\n' + declaration)
    fixture = fixture.replace(b'      old_turn=turn;', b'      if (old_turn<0) TTFExportMap;\n      old_turn=turn;')
if args.move:
    declaration = b'U0 TTFPhaseWatch('
    fixture = fixture.replace(declaration, (root/'Movement.HC').read_bytes() + b'\n' + declaration)
    fixture = fixture.replace(b'    Sleep(1);', b'    TTFTrackMove(owner);\n    Sleep(1);')
if args.overrun or args.close_assault:
    declaration = b'U0 TTFPhaseWatch('
    close_assault = b'1' if args.close_assault else b'0'
    probe = b'#define TTF_CLOSE_ASSAULT ' + close_assault + b'\n'
    probe += (root/'Overrun.HC').read_bytes()
    fixture = fixture.replace(declaration, probe + b'\n' + declaration)
    fixture = fixture.replace(b'    Sleep(1);', b'    TTFTrackAssault(owner);\n    Sleep(1);')
if args.fire:
    declaration = b'U0 TTFPhaseWatch('
    fixture = fixture.replace(declaration, (root/'DirectFire.HC').read_bytes() + b'\n' + declaration)
    fixture = fixture.replace(b'    Sleep(1);', b'    TTFTrackFire(owner);\n    Sleep(1);')
if args.indirect or args.indirect_damage:
    declaration = b'U0 TTFPhaseWatch('
    damage = b'1' if args.indirect_damage else b'0'
    probe = b'#define TTF_ARTILLERY_DAMAGE ' + damage + b'\n'
    probe += (root/'IndirectFire.HC').read_bytes()
    fixture = fixture.replace(declaration, probe + b'\n' + declaration)
    fixture = fixture.replace(b'    Sleep(1);', b'    TTFTrackIndirect(owner);\n    Sleep(1);')
if args.disk:
    image = out/'working.img'
    packer = runpy.run_path('tools/package-i386-native-image.py')
    if args.trace_fire:
        trace = runpy.run_path(str(root/'fire_trace.py'))
        trace['package'](args.disk, image, fixture, packer['snapshot'], packer['package'], args.trace_shot)
    else:
        packer['package'](args.disk, image, additions={'/TTFPhases.HC': fixture})
else:
    overlay = out/'overlay'
    reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
    reference['restore_reference'](overlay)
    (overlay/'Once.HC').write_bytes(
        b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
        b'#include "T:/Apps/ToTheFront/Load.HC"\n'
        b'U0 TTFReady(){U8 *p="TTF original loaded\\n";while(*p)OutU8(0xE9,*p++);}\n'
        b'TTFReady;\n' + fixture)
    image = out/'original.iso'
    subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                    '--output', str(image)], check=True)
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
exercise = runpy.run_path(str(root/'phase_workflow.py'))['exercise']
report = {'fixture_sha256': hashlib.sha256(fixture).hexdigest(),
          'input_sha256': hashlib.sha256((args.disk or image).read_bytes()).hexdigest()}
machine = 'pc,kernel-irqchip=off' if args.userspace_irqchip else 'pc'
report['machine'] = machine
guest = Guest(image, out/'guest', bool(args.disk), native_machine=machine)
try:
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Apps/ToTheFront/Load.HC"')
        start = len(guest.collect())
        guest.type('#include "C:/TTFPhases.HC"')
        guest.press('ret')
        guest.wait('COMPILER BREAK ready', start=start)
        time.sleep(12)
    else:
        guest.wait('TTF original loaded\n', 90)
        time.sleep(6)
    report.update(exercise(guest, args.move, args.fire,
                           args.indirect or args.indirect_damage, args.indirect_damage,
                           'close_assault' if args.close_assault else 'overrun' if args.overrun else None))
    if args.disk:
        guest.command('6*7;')
        report['after_match'] = guest.result_pixels()
    if args.map_raster:
        log = guest.wait('TTF map exported\n', 10)
        dimensions = re.search(r'^TTF map size ((?:\d+ ){4}\d+)$', log, re.M)
        if dimensions is None:
            raise ValueError('Missing map dimensions')
        width, height, stride, rows, columns = map(int, dimensions[1].split())
        sizes = {'map-pixels': stride * height, 'terrain': rows * columns,
                 'roads': rows * columns, 'rivers': rows * columns}
        report['map'] = {'width': width, 'height': height, 'stride': stride,
                         'rows': rows, 'columns': columns}
        for name, size in sizes.items():
            data = (guest.out / f'{name}.bin').read_bytes()
            if len(data) != size:
                raise ValueError(f'Unexpected {name} byte count')
            report['map'][name] = hashlib.sha256(data).hexdigest()
    report['result'] = 'pass'
except Exception as error:
    report.update(result='fail', error=str(error)[:3000])
    raise
finally:
    if args.trace_fire:
        report['fire_trace'] = [line for line in guest.collect().splitlines()
                                if line.startswith('TTF ')]
    guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
