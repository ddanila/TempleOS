import argparse
import hashlib
import json
from pathlib import Path
import runpy
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
trace = Path(__file__).with_name('Trace.HC')
def with_trace(body):
    if b'U0 KAFoulConditions(' in body:
        return body
    animate = b'U0 AnimateTask(CTask *parent_task)'
    start = b'if (o==human && t0>o->foul_t0+1.0 &&'
    call = b'if(o==human && j==1 && dt)KAFoulConditions(t0,o->foul_t0,dt,d,objs[j].team);\n\t\t      '
    if body.count(animate)!=1 or body.count(start)!=1:
        raise ValueError('Unexpected application source')
    return body.replace(animate,trace.read_bytes()+b'\n'+animate).replace(start,call+start)

inputs = [Path(__file__), fixture, guest_runner, reference, packer, trace]
if args.disk:
    inputs.append(args.disk)

def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

pins = {str(path): sha(path) for path in inputs}
report = {'result': 'running', 'input_sha256': pins,
          'scope': 'KeepAway foul rule with controlled player approach, opponent point and prompt recovery'}
guest = None
try:
    if args.disk:
        image = out/'working.img'
        package = runpy.run_path(str(packer))
        snapshot = package['snapshot']
        def traced_snapshot(disk):
            tree, files, directories = snapshot(disk)
            path = '/Apps/KeepAway/KeepAway.HC'
            attr,date,body = files[path]
            replacement=(attr,date,with_trace(body))
            files[path]=replacement
            tree['Apps'][2]['KeepAway'][2]['KeepAway.HC']=replacement
            return tree,files,directories
        package['package'].__globals__['snapshot'] = traced_snapshot
        report['packaging'] = package['package'](
            args.disk, image, additions={'/KeepAwayProbe.HC': fixture.read_bytes()})
    else:
        overlay = out/'overlay'
        report['reference_sha256'] = runpy.run_path(str(reference))['restore_reference'](overlay)
        app=overlay/'Apps/KeepAway/KeepAway.HC'
        app.write_bytes(with_trace(app.read_bytes()))
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
            b'#include "T:/Apps/KeepAway/Load.HC"\n'
            + fixture.read_bytes() + b'\nKAProbe;\n')
        image = out/'original.iso'
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                        '--output', str(image)], check=True)
    Guest = runpy.run_path(str(guest_runner))['Guest']
    guest = Guest(image, out/'guest', bool(args.disk))
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        for command in (
            '#include "C:/Apps/KeepAway/Load.HC"',
            '#include "C:/KeepAwayProbe.HC"',
        ):
            guest.command(command)
        guest.type('KAProbe;')
        guest.press('ret')
    guest.wait('KEEP popup\n', 90)
    guest.press('esc')
    guest.wait('KEEP foul 0-1\n', 15)
    guest.screenshot('foul')
    guest.press('esc')
    guest.wait('KEEP returned\n', 20)
    if args.disk:
        guest.command('6*7;')
        report['fresh_result'] = guest.result_pixels()
    report['score'] = [0, 1]
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(name)) == digest for name, digest in pins.items())
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
