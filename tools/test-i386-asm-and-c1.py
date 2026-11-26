#!/usr/bin/env python3
"""Exercise the bundled AsmAndC sound demos on either guest."""
import argparse
import array
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys
import wave
from statistics import median

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = b'''
U0 AsmAndC1ProbeDone()
{
  U8 *s;
  if (InU8(0x61)&3)
    s="FAIL AsmAndC1 left the speaker enabled\n";
  else
    s="ASM AND C1 DONE\n";
  while (*s) OutU8(0xE9,*s++);
}
AsmAndC1ProbeDone;
'''


def speaker_tones(audio, count, demo=1):
    with wave.open(str(audio), 'rb') as recording:
        rate = recording.getframerate()
        if (recording.getnchannels(), recording.getsampwidth(), rate) != (1, 2, 44100):
            raise ValueError('Expected 44.1 kHz mono 16-bit speaker audio')
        samples = array.array('h', recording.readframes(recording.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()

    # AsmAndC2 derives its beep and base from 400 Hz and 100 Hz.
    beep, base = (62, 40) if demo == 1 else (58, 34)
    expected = [beep, *(10 * index + base for index in range(count, 0, -1))]
    notes = {note: 440 * 2 ** ((note - 60) / 12) for note in expected}
    width = rate // 50
    runs = []
    for start in range(0, len(samples) - width + 1, width):
        window = samples[start:start + width]
        mean = sum(window) / width
        edges = [i for i, (a, b) in enumerate(zip(window, window[1:])) if a <= mean < b]
        if len(edges) < 3 or max(window) - min(window) < 200:
            continue
        frequency = rate / median(b - a for a, b in zip(edges, edges[1:]))
        nearest = min(notes, key=lambda note: abs(frequency - notes[note]))
        if abs(frequency - notes[nearest]) > notes[nearest] * 0.05:
            continue
        if runs and runs[-1]['note'] == nearest:
            runs[-1]['classified_ms'] += 20
        else:
            runs.append(dict(note=nearest, classified_ms=20))
    stable = [run for run in runs if run['classified_ms'] >= 60]
    return dict(frames=len(samples), sequence=stable, expected=expected)


def read_jiffies(guest, probe, font, wait_text):
    column, row = wait_text(guest, probe, font, b'Jiffies:', 'jiffies')
    with Image.open(guest.out/'jiffies.png') as frame:
        pixels = frame.convert('RGB').load()
        digits = []
        for offset in range(16):
            for digit in b'0123456789ABCDEF':
                if probe['text_at'](pixels, font, bytes([digit]), column + 8 + offset, row):
                    digits.append(digit)
                    break
            else:
                raise ValueError('Missing hexadecimal jiffies digit')
    value = int(bytes(digits), 16)
    if value <= 0:
        raise ValueError('Expected positive elapsed jiffies')
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--count', type=int, choices=range(1, 6), default=2)
    parser.add_argument('--demo', type=int, choices=(1, 2), default=1)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    native = args.disk is not None
    demo = f'Demo/Asm/AsmAndC{args.demo}.HC'
    fixture = f'#include "::/{demo}"\n'.encode() + FIXTURE
    report = dict(result='running', count=args.count, native=native,
                  fixture_sha256=hashlib.sha256(fixture).hexdigest(), demo=demo)
    try:
        if native:
            image = out/'working.img'
            package = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            _, files, _ = package['snapshot'](args.disk.read_bytes())
            source = files['/'+demo][2]
            if source != (ROOT/demo).read_bytes():
                raise ValueError('Delivered demo differs from workspace')
            report['package'] = package['package'](
                args.disk, image, additions={'/AsmAndC1Probe.HC': fixture})
        else:
            image = out/'original.iso'
            overlay = out/'overlay'
            reference = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
            reference['restore_reference'](overlay)
            source = (overlay/demo).read_bytes()
            (overlay/'Once.HC').write_bytes(
                b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture)
            subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                            '--output', str(image)], cwd=ROOT, check=True)
        report['demo_sha256'] = hashlib.sha256(source).hexdigest()
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        wait_text = runpy.run_path(str(ROOT/'build/grmodels-menu-workflows-v1/run.py'))['wait_text']
        probe = runpy.run_path(str(ROOT/'tools/check-i386-autocomplete-numeric-pixels.py'))
        font = probe['font_bytes']()
        audio = out/'speaker.wav'
        guest = Guest(image, out/'guest', native, reference_cpus=1, audio_wav=audio)
        try:
            if native:
                guest.wait('DONE native kernel startup\n')
                guest.type('#include "C:/AsmAndC1Probe.HC"')
                guest.press('ret')
            report['prompt'] = wait_text(guest, probe, font, b'Num of beeps 1-5 (3):', 'prompt')
            guest.press(str(args.count))
            guest.press('ret')
            guest.wait('ASM AND C1 DONE\n')
            if args.demo == 1:
                label = f'Beeps:{args.count}'.encode('ascii')
                report['result_pixels'] = wait_text(guest, probe, font, label, 'beep-count')
            else:
                report['elapsed_jiffies'] = read_jiffies(guest, probe, font, wait_text)
            report['speaker_disabled'] = True
            if native:
                guest.wait('COMMAND OK\n')
                guest.command('6*7;')
                report['fresh_arithmetic'] = guest.result_pixels()
        finally:
            guest.close()
        report['audio'] = speaker_tones(audio, args.count, args.demo)
        if [run['note'] for run in report['audio']['sequence']] != report['audio']['expected']:
            raise ValueError('PC speaker tones differ from the expected note sequence')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
