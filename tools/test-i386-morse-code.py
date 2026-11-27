#!/usr/bin/env python3
"""Compare physical Morse key timing, decoded text and speaker output."""
import argparse
import array
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys
import time
import wave

ROOT = Path(__file__).resolve().parents[1]
DEMO = 'Demo/Snd/MorseCode.HC'
FIXTURE = r'''
U0 MorseTestLog(U8 *text)
{
  while (*text) OutU8(0xE9,*text++);
}
U0 MorseTest()
{
  CDoc *previous=DocPut,*doc=DocNew;
  I64 size;
  U8 *data,*line;
  Bool raw=Raw(OFF);
  Fs->put_doc=doc;
  MorseTestLog("MORSE BEGIN\n");
  try {
    ExeFile("::/Demo/Snd/MorseCode.HC");
  } catch {
    Fs->catch_except=TRUE;
  }
  Fs->put_doc=previous;
  data=DocSave(doc,&size);
  line=MStrPrint("EXPORT morse.DD %X %X\n",data,size);
  MorseTestLog(line);
  MorseTestLog("MORSE DONE\n");
  Sleep(1000);
  Free(line); Free(data); DocDel(doc);
  Raw(raw);
}
MorseTest;
'''


def speaker_frequency(path):
    with wave.open(str(path), 'rb') as stream:
        rate = stream.getframerate()
        if (stream.getnchannels(), stream.getsampwidth(), rate) != (1, 2, 44100):
            raise ValueError('Expected 44.1 kHz signed mono speaker capture')
        samples = array.array('h', stream.readframes(stream.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()
    width = rate // 25
    voiced = []
    for start in range(0, len(samples)-width+1, width):
        block = samples[start:start+width]
        if max(block)-min(block) < 500:
            continue
        mean = sum(block)/width
        peaks = sum(a <= mean < b for a,b in zip(block, block[1:]))
        voiced.append(peaks * rate / width)
    if len(voiced) < 8:
        raise ValueError('Missing Morse tone')
    voiced.sort()
    frequency = voiced[len(voiced)//2]
    # Snd(74) is B5.
    if abs(frequency - 987.77) > 60:
        raise ValueError(f'Morse tone frequency differs: {frequency:.2f} Hz')
    return frequency


def run(image, out, native):
    guest_type = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
    audio = out/'speaker.wav'
    guest = guest_type(image, out, native, audio_wav=audio, reference_cpus=1)
    try:
        if native:
            guest.wait('DONE native kernel startup\n')
            guest.type('#include "C:/Probe/MorseTest.HC"')
            guest.press('ret')
        guest.wait('MORSE BEGIN\n')
        time.sleep(2)
        growth = []
        for symbols in ('.-', '.', '-'):
            for symbol in symbols:
                before = audio.stat().st_size
                guest.key('x', True)
                time.sleep(.075 if symbol == '.' else .225)
                guest.key('x', False)
                time.sleep(.09)
                growth.append(audio.stat().st_size-before)
            time.sleep(.40)
        guest.press('esc')
        guest.wait('MORSE DONE\n', timeout=30)
        time.sleep(1.5)
        settled = audio.stat().st_size
        if native:
            guest.command('6*7;')
            guest.result_pixels()
        else:
            time.sleep(1.5)
        if audio.stat().st_size != settled:
            raise ValueError('Speaker output continued after Escape')
    finally:
        guest.close()
    if min(growth) <= 0 or min(growth[1::2]) <= max(growth[::2]):
        raise ValueError(f'Dot and dash PCM durations differ from expected order: {growth}')
    return {'element_pcm_bytes': growth, 'frequency_hz': speaker_frequency(audio),
            'wav_sha256': hashlib.sha256(audio.read_bytes()).hexdigest()}


def normalize_document(data):
    """Preserve the whole transcript apart from the live timer readings."""
    pattern = rb'Down: +([0-9]+\.[0-9]{6}) Up: +([0-9]+\.[0-9]{6})'
    readings = re.findall(pattern, data)
    if len(readings) != 1:
        raise ValueError('Expected one live timing field')
    down, up = map(float, readings[0])
    if not (.140 <= down < .350 and .300 <= up < 1.0):
        raise ValueError(f'Final dash and Escape gap differ: {down:g}, {up:g}')
    return re.sub(pattern, b'Down: <dash> Up: <gap>', data)


def compare(out, ref_iso, image):
    result = {}
    for name, guest_image, native in [('original', ref_iso, False), ('native', image, True)]:
        result[name] = run(guest_image, out/name, native)
    documents = [normalize_document((out/name/'morse.DD').read_bytes())
                 for name in ('original', 'native')]
    if documents[0] != documents[1]:
        raise ValueError('Morse DolDoc differs from the original')
    decoded = re.sub(rb'\$[^$\n]*\$', b'', documents[0]).rstrip(b'\x05\n ')
    if not decoded.endswith(b'.-A .E -T'):
        raise ValueError(f'Missing decoded A, E and T: {decoded[-100:]!r}')
    result['normalized_document_sha256'] = hashlib.sha256(documents[0]).hexdigest()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    disk = args.disk.resolve()
    sha = lambda data: hashlib.sha256(data).hexdigest()
    input_sha = sha(disk.read_bytes())
    report = {'result': 'running', 'disk_sha256': input_sha}
    try:
        overlay = out/'original-source'
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
        original = (overlay/DEMO).read_bytes()
        pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        delivered = pack['snapshot'](disk.read_bytes())[1]['/'+DEMO][2]
        if delivered != (ROOT/DEMO).read_bytes():
            raise ValueError('Delivered Morse demo differs from the working source')
        report.update(reference_source_sha256=sha(original), native_source_sha256=sha(delivered))
        (overlay/'Once.HC').write_text(FIXTURE)
        ref_iso = out/'original.iso'
        subprocess.run(['python3', str(ROOT/'tools/build-iso.py'), '--overlay', str(overlay),
                        '--output', str(ref_iso)], cwd=ROOT, check=True)
        image = out/'native.img'
        pack['package'](disk, image, additions={'/Probe/MorseTest.HC': FIXTURE.encode()})
        report.update(compare(out, ref_iso, image), result='pass')
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = sha(disk.read_bytes()) == input_sha
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if not report['inputs_unchanged']:
        raise ValueError('Input disk changed')


if __name__ == '__main__':
    main()
