#!/usr/bin/env python3
"""Exercise the bundled AsmAndC1 prompt and PC speaker on either guest."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
DEMO = 'Demo/Asm/AsmAndC1.HC'
FIXTURE = b'''
#include "::/Demo/Asm/AsmAndC1.HC"
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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--count', type=int, choices=range(1, 6), default=2)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    native = args.disk is not None
    report = dict(result='running', count=args.count, native=native,
                  fixture_sha256=hashlib.sha256(FIXTURE).hexdigest())
    try:
        if native:
            image = out/'working.img'
            package = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            _, files, _ = package['snapshot'](args.disk.read_bytes())
            source = files['/'+DEMO][2]
            if source != (ROOT/DEMO).read_bytes():
                raise ValueError('Delivered demo differs from workspace')
            report['package'] = package['package'](
                args.disk, image, additions={'/AsmAndC1Probe.HC': FIXTURE})
        else:
            image = out/'original.iso'
            overlay = out/'overlay'
            reference = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
            reference['restore_reference'](overlay)
            source = (overlay/DEMO).read_bytes()
            (overlay/'Once.HC').write_bytes(
                b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+FIXTURE)
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
            label = f'Beeps:{args.count}'.encode('ascii')
            report['result_pixels'] = wait_text(guest, probe, font, label, 'beep-count')
            report['speaker_disabled'] = True
            if native:
                guest.wait('COMMAND OK\n')
                guest.command('6*7;')
                report['fresh_arithmetic'] = guest.result_pixels()
        finally:
            guest.close()
        with wave.open(str(audio), 'rb') as recording:
            frames = recording.getnframes()
            if not frames or not any(recording.readframes(frames)):
                raise ValueError('No nonzero PC speaker samples')
            report['audio_frames'] = frames
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
