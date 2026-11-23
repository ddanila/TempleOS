import argparse
import hashlib
import json
from pathlib import Path
import runpy
import re
import struct
import subprocess
import time

from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path, nargs='?')
parser.add_argument('--refocus', action='store_true')
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC').resolve()
guest_runner = Path('tools/test-i386-autocomplete-interaction.py')
reference = Path('tools/test-i386-timeclock-reference.py')
packer = Path('tools/package-i386-native-image.py')
loader = fixture.with_name('Load.HC')
application = Path('Apps/Vocabulary/VocabQuiz.HC')
font_path = Path('Kernel/FontStd.HC')
inputs = [Path(__file__), fixture, guest_runner, reference, packer, loader, application, font_path]
if args.disk:
    inputs.append(args.disk)

def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

pins = {str(path): sha(path) for path in inputs}
report = {'result': 'running', 'input_sha256': pins,
          'scope': 'Vocabulary quiz answer and definition popup using the original dictionary'}
guest = None

def patched_application():
    source = application.read_bytes()
    anchor = b'  do {\n    right_word=RandVocabWord;'
    assert source.count(anchor)==1
    return source.replace(anchor, b'  if (!acd.num_words)\n    Adam("ACInit;");\n' + anchor)

try:
    if args.disk:
        image = out/'working.img'
        pack = runpy.run_path(str(packer))
        package, snapshot = pack['package'], pack['snapshot']
        app = patched_application()
        replacements = {'Load.HC': loader.read_bytes(), 'VocabQuiz.HC': app}

        def patched_snapshot(disk):
            tree, files, directories = snapshot(disk)
            for name, body in replacements.items():
                path = '/Apps/Vocabulary/' + name
                attr, date, _ = files[path]
                tree['Apps'][2]['Vocabulary'][2][name] = files[path] = (attr, date, body)
            return tree, files, directories

        package.__globals__['snapshot'] = patched_snapshot
        try:
            report['packaging'] = package(
                args.disk, image, additions={'/VocabularyProbe.HC': fixture.read_bytes()})
        finally:
            package.__globals__['snapshot'] = snapshot
        source = snapshot(args.disk.read_bytes())[1]
        delivered = snapshot(image.read_bytes())[1]
        changed = {name for name in source if source[name] != delivered.get(name)}
        if changed != {'/Apps/Vocabulary/' + name for name in replacements}:
            raise ValueError(f'Unexpected application changes: {changed}')
        report['changed_files'] = sorted(changed)
    else:
        overlay = out/'overlay'
        report['reference_sha256'] = runpy.run_path(str(reference))['restore_reference'](overlay)
        (overlay/'Apps/Vocabulary/Load.HC').write_bytes(loader.read_bytes())
        (overlay/'Apps/Vocabulary/VocabQuiz.HC').write_bytes(patched_application())
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
            b'#include "T:/Apps/Vocabulary/Load.HC"\n'
            + fixture.read_bytes() + b'\nVQProbe;\n')
        image = out/'original.iso'
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                        '--output', str(image)], check=True)
    Guest = runpy.run_path(str(guest_runner))['Guest']
    guest = Guest(image, out/'guest', bool(args.disk))
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        for command in (
            '#include "C:/Apps/Vocabulary/Load.HC"',
            '#include "C:/VocabularyProbe.HC"',
        ):
            guest.command(command)
        guest.type('VQProbe;')
        guest.press('ret')
    font = b''.join(struct.pack('<Q', int(value, 16)) for value in
                    re.findall(rb'0x[0-9A-Fa-f]{16}', font_path.read_bytes()))

    def await_answer(name, unanswered=False):
        deadline = time.monotonic() + 30
        glyphs = font[ord('A')*8:ord('A')*8+8]
        while time.monotonic() < deadline:
            guest.screenshot(name)
            with Image.open(guest.out / (name + '.png')) as image:
                rgb = image.convert('RGB')
                pixels = rgb.load()
                for y in range(0, 480, 8):
                    for x in range(0, 585, 8):
                        first = bytes(sum((pixels[x+dx,y+dy]!=(255,255,255)) << dx
                                          for dx in range(8)) for dy in range(8))
                        if first != glyphs:
                            continue
                        for i,ch in enumerate('Answer:'):
                            cell = bytes(sum((pixels[x+8*i+dx,y+dy]!=(255,255,255)) << dx
                                             for dx in range(8)) for dy in range(8))
                            if cell != font[ord(ch)*8:ord(ch)*8+8]:
                                break
                        else:
                            if unanswered:
                                numeral = bytes(sum((pixels[x+56+dx,y+dy]!=(255,255,255)) << dx
                                                    for dx in range(8)) for dy in range(8))
                                if numeral == font[ord('1')*8:ord('1')*8+8]:
                                    continue
                            return
            time.sleep(.3)
        raise TimeoutError('Vocabulary answer prompt did not render')

    log = guest.wait('VOCAB opening\n', 90)
    match = re.search(r'VOCAB focus ([0-9A-F]+) ([0-9A-F]+)\n', log)
    owner, slot = (int(value, 16) for value in match.groups())
    width = 4 if args.disk else 8
    sample = out/'focus.bin'
    report['focus'] = {'owner': owner}

    def observe_focus(name):
        guest.call('pmemsave', val=slot, size=width, filename=str(sample))
        report['focus'][name] = int.from_bytes(sample.read_bytes(), 'little')

    await_answer('question')
    observe_focus('first_question')
    guest.press('1')
    guest.wait('VOCAB definition popup\n', 30)
    time.sleep(1.5)
    guest.screenshot('definition')
    observe_focus('definition')
    guest.press('esc')
    await_answer('next-question', unanswered=True)
    time.sleep(.8)
    observe_focus('second_question')
    if args.refocus:
        guest.call('input-send-event',events=[
            {'type':'rel','data':{'axis':'x','value':-72}},
            {'type':'rel','data':{'axis':'y','value':60}}])
        time.sleep(.25)
        for down in (True, False):
            guest.call('input-send-event',events=[
                {'type':'btn','data':{'down':down,'button':'left'}}])
            time.sleep(.2)
        observe_focus('after_click')
    guest.press('esc')
    guest.wait('VOCAB returned\n', 20)
    if args.disk:
        guest.command('6*7;')
        report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(name)) == digest for name, digest in pins.items())
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
