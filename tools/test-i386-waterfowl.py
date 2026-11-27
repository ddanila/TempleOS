#!/usr/bin/env python3
"""Check WaterFowl's animated display, melody and task cleanup on both guests."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import time

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEMO = 'Demo/Snd/WaterFowl.HC'
FIXTURE = r'''
U0 WaterTestLog(U8 *text)
{
  while (*text) OutU8(0xE9,*text++);
}
U0 WaterTest()
{
  CTaskSettings *settings=Fs->next_settings;
  CTask *song=Fs->song_task;
  U8 *draw=Fs->draw_it;
  WaterTestLog("WATER BEGIN\n");
  ExeFile("::/Demo/Snd/WaterFowl.HC");
  if (Fs->next_settings!=settings || Fs->song_task!=song || Fs->draw_it!=draw)
    WaterTestLog("FAIL WaterFowl settings\n");
  WaterTestLog("WATER DONE\n");
}
WaterTest;
'''


def run(image, out, native, notes, melody):
    guest_type = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
    audio = out/'speaker.wav'
    guest = guest_type(image, out, native, audio_wav=audio, reference_cpus=1)
    try:
        if native:
            guest.wait('DONE native kernel startup\n')
            guest.type('#include "C:/Probe/WaterTest.HC"')
        else:
            guest.wait('WATER READY\n')
            time.sleep(2)
            guest.type('ExeFile("T:/Probe/WaterTest.HC");')
        guest.press('ret')
        guest.wait('WATER BEGIN\n')
        deadline = time.monotonic() + 35
        while not audio.exists() or audio.stat().st_size < 32768:
            log = guest.collect()
            if 'INPUT REJECT ' in log or 'WATER DONE\n' in log:
                raise ValueError(f'WaterFowl stopped before playing: {log[-1500:]}')
            if time.monotonic() >= deadline or guest.p.poll() is not None:
                raise ValueError('Missing WaterFowl speaker output')
            time.sleep(.1)
        deadline = time.monotonic() + 20
        while True:
            guest.screenshot('scene-first')
            if scenery(out/'scene-first.png'):
                break
            if time.monotonic() >= deadline:
                raise ValueError('WaterFowl scenery did not appear')
            time.sleep(.2)
        time.sleep(3)
        guest.screenshot('scene-second')
        if not scenery(out/'scene-second.png'):
            raise ValueError('WaterFowl scenery disappeared before exit')
        time.sleep(8)
        guest.press('x')
        guest.wait('WATER DONE\n', timeout=35)
        if 'FAIL WaterFowl settings\n' in guest.collect():
            raise ValueError('WaterFowl did not restore the task settings')
        time.sleep(1.0)
        settled = audio.stat().st_size
        if native:
            guest.command('6*7;')
            guest.result_pixels()
        else:
            time.sleep(1.5)
        if settled != audio.stat().st_size:
            raise ValueError('WaterFowl speaker continued after exit')
    finally:
        guest.close()
    with Image.open(out/'scene-first.png') as first, Image.open(out/'scene-second.png') as second:
        crop = (8, 24, 632, 456)
        a, b = (frame.convert('RGB').crop(crop) for frame in (first, second))
        changed = changed_pixels(a, b)
    if changed < 100:
        raise ValueError(f'Only {changed} interior pixels changed during WaterFowl')
    return dict(changed_pixels=changed, **melody(audio, notes))


def rgb_pixels(image):
    data = image.tobytes()
    return zip(data[::3], data[1::3], data[2::3])


def changed_pixels(first, second):
    return sum(a != b for a, b in zip(rgb_pixels(first), rgb_pixels(second)))


def scenery(path):
    with Image.open(path) as source:
        frame = source.convert('RGB')
        sky = frame.crop((200, 50, 440, 160))
        water = frame.crop((200, 270, 440, 360))
        return (sum(rgb == (168, 0, 0) for rgb in rgb_pixels(sky)) > 24000
                and sum(rgb == (0, 0, 168) for rgb in rgb_pixels(water)) > 8000)


def compare_scenery(out):
    # The title bar and the moving poem sit outside this region. The small
    # moving bird and mouse pointer can occupy a few pixels inside it.
    crop = (0, 8, 640, 400)
    counts = []
    for name in ('scene-first.png', 'scene-second.png'):
        with Image.open(out/'original'/name) as original, Image.open(out/'native'/name) as native:
            count = changed_pixels(original.convert('RGB').crop(crop), native.convert('RGB').crop(crop))
        if count > 250:
            raise ValueError(f'{name}: {count} pixels differ in the scenery region')
        counts.append(count)
    return counts


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    disk = args.disk.resolve()
    sha = lambda data: hashlib.sha256(data).hexdigest()
    disk_hash = sha(disk.read_bytes())
    report = dict(result='running', disk_sha256=disk_hash)
    try:
        overlay = out/'original-source'
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
        reference = (overlay/DEMO).read_bytes()
        pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        delivered = pack['snapshot'](disk.read_bytes())[1]['/'+DEMO][2]
        if delivered != (ROOT/DEMO).read_bytes():
            raise ValueError('Bundled WaterFowl differs from the working source')
        report.update(original_source_sha256=sha(reference), native_source_sha256=sha(delivered))
        music = runpy.run_path(str(ROOT/'tools/test-i386-oh-great.py'))
        notes = music['score_frequencies'](reference)
        if len(notes) != 36:
            raise ValueError('Unexpected WaterFowl melody')
        (overlay/'Once.HC').write_text(
            'U0 WaterReady(){U8 *s="WATER READY\\n";while(*s)OutU8(0xE9,*s++);}\n'
            'WaterReady;\n')
        (overlay/'Probe').mkdir(exist_ok=True)
        (overlay/'Probe/WaterTest.HC').write_text(FIXTURE)
        iso = out/'original.iso'
        subprocess.run(['python3', str(ROOT/'tools/build-iso.py'), '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        native_image = out/'native.img'
        pack['package'](disk, native_image, additions={'/Probe/WaterTest.HC': FIXTURE.encode()})
        for name, image in (('original', iso), ('native', native_image)):
            report[name] = run(image, out/name, name == 'native', notes, music['pitches'])
        report['scenery_different_pixels'] = compare_scenery(out)
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = sha(disk.read_bytes()) == disk_hash
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if not report['inputs_unchanged']:
        raise ValueError('Input disk changed')


if __name__ == '__main__':
    main()
