import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import time

from PIL import Image

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
inputs = [Path(__file__), fixture, guest_runner, reference, packer]
if args.disk:
    inputs.append(args.disk)

def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

pins = {str(path): sha(path) for path in inputs}
report = {'result': 'running', 'input_sha256': pins,
          'scope': 'KeepAway handoff and pass scoring, staged clock expiration, lower-score restart, registry persistence and prompt recovery'}
guest = None
try:
    if args.disk:
        image = out/'working.img'
        report['packaging'] = runpy.run_path(str(packer))['package'](
            args.disk, image, additions={'/KeepAwayProbe.HC': fixture.read_bytes()})
    else:
        overlay = out/'overlay'
        report['reference_sha256'] = runpy.run_path(str(reference))['restore_reference'](overlay)
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
            b'#include "T:/Apps/KeepAway/Load.HC"\n'
            + fixture.read_bytes() + b'\nKAProbe;\n')
        image = out/'original.iso'
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                        '--output', str(image)], check=True)
    Guest = runpy.run_path(str(guest_runner))['Guest']
    guest = Guest(image, out/'guest', bool(args.disk), audio_wav=out/'speaker.wav')
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
    guest.wait('KEEP playing\n', 30)
    guest.wait('KEEP finished 8-0\n', 30)
    font = runpy.run_path('tools/check-i386-autocomplete-numeric-pixels.py')['font_bytes']()
    glyphs = [font[ord(char)*8:(ord(char)+1)*8] for char in 'Game Over']
    colors = {(168, 0, 0), (255, 0, 0)}
    caption = [(8*i+dx, dy) for i, rows in enumerate(glyphs)
               for dy, row in enumerate(rows) for dx in range(8) if row & (1<<dx)]
    deadline = time.monotonic()+8
    while time.monotonic()<deadline:
        guest.screenshot('game-over')
        with Image.open(guest.out/'game-over.png') as frame:
            pixels = frame.convert('RGB').load()
        #The game centers the caption, which can start between text cells.
        for y in range(220,250):
            for x in range(265,305):
                red = sum(pixels[x+dx,y+dy] in colors for dx,dy in caption)
                if red*100 >= 95*len(caption):
                    report['game_over_origin'] = [x,y]
                    report['game_over_red_pixels'] = [red, len(caption)]
                    break
            if 'game_over_origin' in report:
                break
        if 'game_over_origin' in report:
            break
        time.sleep(.15)
    else:
        raise ValueError('Game Over caption did not render')
    guest.press('ret')
    guest.wait('KEEP preserved 8-0\n', 30)
    guest.press('esc')
    guest.wait('KEEP returned\n', 20)
    if args.disk:
        guest.command('6*7;')
        report['fresh_result'] = guest.result_pixels()
        guest.close()
        guest = Guest(image, out/'reopen', True)
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Apps/KeepAway/Load.HC"')
        guest.command("if(best_score0!=8 || best_score1)throw('Best',TRUE);")
        guest.command('6*7;')
        report['cold_reopen_result'] = guest.result_pixels()
    report['best_score'] = [8, 0]
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(name)) == digest for name, digest in pins.items())
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
