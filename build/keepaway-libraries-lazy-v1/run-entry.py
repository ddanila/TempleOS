import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

from PIL import Image


parser = argparse.ArgumentParser()
parser.add_argument('image', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
disk = out / 'working.img'
shutil.copyfile(args.image, disk)
helper = Path('tools/test-i386-autocomplete-interaction.py')
sample = Path(__file__).with_name('native64') / 'guest/instructions.png'

def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

pins = {str(path): digest(path) for path in (args.image, sample, helper, Path(__file__))}
report = {'result': 'running', 'runs': [], 'input_sha256': pins}
with Image.open(sample) as image:
    instructions_text = image.convert('RGB').crop((16, 104, 240, 112)).tobytes()

def instructions_visible(image):
    return any(image.crop((16, y, 240, y + 8)).tobytes() == instructions_text
               for y in range(0, 264, 8))

def arena_visible(image):
    pixels = Counter(image.get_flattened_data())
    if pixels[(255, 255, 87)] >= 200_000 and pixels[(168, 0, 0)] >= 1_000:
        return {'arena_yellow_pixels': pixels[(255, 255, 87)],
                'border_red_pixels': pixels[(168, 0, 0)]}
    return None

def wait_frame(name, condition):
    timeout = time.monotonic() + 45
    while time.monotonic() < timeout:
        guest.screenshot(name)
        with Image.open(guest.out / (name + '.png')) as image:
            found = condition(image.convert('RGB'))
        if found:
            return found
        if 'INPUT REJECT ' in guest.collect():
            raise ValueError('Guest rejected KeepAway Run.HC')
        time.sleep(.2)
    raise TimeoutError(f'Missing {name} frame')

lookup = 'HashFind("%s",adam_task->hash_table,HTT_FUN)'
autocomplete, settings = (lookup % name for name in ('AutoComplete', 'SettingsPush'))
Guest = runpy.run_path(str(helper))['Guest']
guest = Guest(disk, out / 'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    guest.command(f"if({autocomplete} || {settings})throw('KAearly',TRUE);")
    for index in (1, 2):
        start = len(guest.collect())
        command = '#include "C:/Apps/KeepAway/Run.HC"'
        guest.type(command)
        guest.press('ret')
        guest.wait('INPUT LINE ' + command + '\n', start=start)
        wait_frame(f'instructions-{index}', instructions_visible)
        guest.press('esc')
        observed = wait_frame(f'arena-{index}', arena_visible)
        guest.press('esc')
        guest.wait('COMMAND OK\n', start=start)
        report['runs'].append(observed)
        if index == 1:
            guest.command(f'CHash *ka_ac={autocomplete},*ka_settings={settings};')
            guest.command("if(!ka_ac || !ka_settings)throw('KAlib',TRUE);")
    guest.command(f"if(ka_ac!={autocomplete} || ka_settings!={settings})throw('KAdupe',TRUE);")
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    if 'WINMGR window exception ' in guest.collect():
        raise ValueError('Window Manager exception during KeepAway')
    report.update(result='pass', library_symbols_reused=True)
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    guest.close()
    report['inputs_unchanged'] = all(digest(Path(name)) == value for name, value in pins.items())
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
