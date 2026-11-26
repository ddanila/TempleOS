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
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC').resolve()
guest_runner = Path('tools/test-i386-autocomplete-interaction.py')
reference = Path('tools/test-i386-timeclock-reference.py')
packer = Path('tools/package-i386-native-image.py')
font_path = Path('Kernel/FontStd.HC')
inputs = [Path(__file__), fixture, guest_runner, reference, packer, font_path]
if args.disk:
    inputs.append(args.disk)

def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

pins = {str(path): sha(path) for path in inputs}
report = {'result': 'running', 'input_sha256': pins,
          'scope': 'Vocabulary quiz answer and definition popup using the original dictionary'}
guest = None
try:
    if args.disk:
        image = out/'working.img'
        report['packaging'] = runpy.run_path(str(packer))['package'](
            args.disk, image, additions={'/VocabularyProbe.HC': fixture.read_bytes()})
    else:
        overlay = out/'overlay'
        report['reference_sha256'] = runpy.run_path(str(reference))['restore_reference'](overlay)
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
            + fixture.read_bytes()
            + b'\n#include "T:/Apps/Vocabulary/Run.HC"\n'
            + b'VQExport;VQOut("VOCAB returned\\n");\n')
        image = out/'original.iso'
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                        '--output', str(image)], check=True)
    Guest = runpy.run_path(str(guest_runner))['Guest']
    guest = Guest(image, out/'guest', bool(args.disk))
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        guest.wait('STARTUP source ok\n')
        guest.command('#include "C:/VocabularyProbe.HC"')
        start = len(guest.collect())
        guest.type('#include "C:/Apps/Vocabulary/Run.HC"')
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

    guest.wait('VOCAB opening\n', 90)
    report['bundled_dictionary_loaded'] = True
    await_answer('question')
    for index in range(2):
        start_popup = len(guest.collect())
        guest.press('1')
        guest.wait('VOCAB definition popup\n', 30, start_popup)
        time.sleep(1.5)
        guest.screenshot(f'definition-{index+1}')
        guest.press('esc')
        guest.wait('VOCAB definition closed\n', 30, start_popup)
        await_answer(f'question-{index+2}', unanswered=True)
        time.sleep(.8)
    guest.press('esc')
    if args.disk:
        guest.wait('COMMAND OK\n', 20, start)
        guest.command("if(acd.num_words<10000)throw('Words',TRUE);")
        #Wait for the export while the guest still owns the source buffer.
        guest.command('VQExport;')
        guest.command('6*7;')
        report['fresh_result'] = guest.result_pixels()
    else:
        guest.wait('VOCAB returned\n', 20)
    output = (guest.out/'vocabulary.DD').read_bytes()
    correct = output.find(b'$FG,10$Correct')
    incorrect = output.find(b'$FG,12$Incorrect')
    if not 0 <= correct < incorrect:
        raise ValueError('Expected correct first answer and incorrect second answer')
    questions = re.findall(rb'\$BK,1\$([A-Za-z]+)\$BK,0\$:', output)
    if questions != [b'Vowelize', b'Spilikin', b'Ornithorhynchus']:
        raise ValueError(f'Unexpected seeded quiz words: {questions}')
    report['questions'] = [word.decode('ascii') for word in questions]
    report['feedback'] = ['Correct', 'Incorrect']
    quiz = output[output.index(b'$WW,1$$CM-LE', output.index(b'Vowelize')-60):]
    end = quiz.index(b'$FG,9$Answer:$FG$$LM,0$')+len(b'$FG,9$Answer:$FG$$LM,0$')
    report['quiz_sha256'] = hashlib.sha256(quiz[:end]).hexdigest()
    report['quiz_bytes'] = end
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(name)) == digest for name, digest in pins.items())
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
