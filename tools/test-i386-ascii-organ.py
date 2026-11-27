#!/usr/bin/env python3
"""Check the bundled ASCII Organ's keyboard, speaker, and document output."""
import argparse
import array
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys
import time
import wave

ROOT = Path(__file__).resolve().parents[1]
DEMO = 'Demo/Snd/ASCIIOrgan.HC'


def tones(path):
    with wave.open(str(path), 'rb') as stream:
        rate = stream.getframerate()
        if (stream.getnchannels(), stream.getsampwidth(), rate) != (1, 2, 44100):
            raise ValueError('Expected 44.1 kHz signed mono PCM')
        samples = array.array('h', stream.readframes(stream.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()
    # The demo subtracts ESC (27) from ASCII 'a' and 'f', yielding G5 and C6.
    width = rate // 20
    counts = [0, 0]
    for start in range(0, len(samples) - width + 1, width):
        block = samples[start:start + width]
        if max(block) - min(block) < 500:
            continue
        mean = sum(block) / width
        rising = sum(a <= mean < b for a, b in zip(block, block[1:]))
        hz = rising * rate / width
        if abs(hz - 783.99) <= 25:
            if counts[1]:
                raise ValueError('G5 returned after the C6 key')
            counts[0] += 1
        elif abs(hz - 1046.50) <= 25:
            counts[1] += 1
    if min(counts) < 6:
        raise ValueError(f'Both organ tones must last at least six windows: {counts}')
    return dict(g5_windows=counts[0], c6_windows=counts[1],
                wav_sha256=hashlib.sha256(path.read_bytes()).hexdigest())


def run(image, out, native):
    guest_type = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
    audio = out/'speaker.wav'
    guest = guest_type(image, out, native, audio_wav=audio, reference_cpus=1)
    try:
        if native:
            guest.wait('DONE native kernel startup\n')
            guest.type('#include "C:/Probe/OrganTest.HC"')
            guest.press('ret')
        guest.wait('ORGAN BEGIN\n')
        time.sleep(2)
        guest.press('a')
        time.sleep(.55)
        guest.press('f')
        time.sleep(.55)
        guest.key('shift', True)
        guest.press('esc')
        guest.key('shift', False)
        guest.wait('ORGAN DONE\n', timeout=30)
        time.sleep(1.2)
        settled = audio.stat().st_size
        if native:
            guest.command('6*7;')
            guest.result_pixels()
        else:
            time.sleep(1.5)
        if audio.stat().st_size != settled:
            raise ValueError('Speaker did not settle after Shift-Escape')
    finally:
        guest.close()
    return tones(audio)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    out.mkdir()
    sha = lambda data: hashlib.sha256(data).hexdigest()
    pins = sha(disk.read_bytes())
    report = dict(result='running', disk_sha256=pins)
    try:
        batch = runpy.run_path(str(ROOT/'tools/test-i386-demo-batch.py'))
        script = batch['FIXTURE'] + r'''
DemoBatchLog("ORGAN BEGIN\n");
DemoBatchRun("::/Demo/Snd/ASCIIOrgan.HC","organ.DD");
DemoBatchLog("ORGAN DONE\n");
'''
        overlay = out/'original-source'
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
        original = (overlay/DEMO).read_bytes()
        pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        delivered = pack['snapshot'](disk.read_bytes())[1]['/'+DEMO][2]
        if delivered != original:
            raise ValueError('Native ASCII Organ differs from the pinned source')
        report['source_sha256'] = sha(original)
        (overlay/'Once.HC').write_text(script)
        reference = out/'original.iso'
        subprocess.run(['python3', str(ROOT/'tools/build-iso.py'), '--overlay', str(overlay),
                        '--output', str(reference)], cwd=ROOT, check=True)
        native = out/'native.img'
        pack['package'](disk, native, additions={'/Probe/OrganTest.HC': script.encode()})
        for name, image in (('original', reference), ('native', native)):
            report[name] = run(image, out/name, name == 'native')
        doc = (out/'original/organ.DD').read_bytes()
        if doc != (out/'native/organ.DD').read_bytes():
            raise ValueError('ASCII Organ DolDoc differs')
        if b'Click for better organ' not in doc or len(doc) < 5000:
            raise ValueError('Missing the completed ASCII table or embedded organ link')
        report.update(result='pass', document_sha256=sha(doc), document_bytes=len(doc))
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = sha(disk.read_bytes()) == pins
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if not report['inputs_unchanged']:
        raise ValueError('Input disk changed')


if __name__ == '__main__':
    main()
