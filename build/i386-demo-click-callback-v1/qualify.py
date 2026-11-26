"""Verify callback results rendered as VGA glyphs and the recorded speaker sweep."""
import argparse
import array
import json
from pathlib import Path
import runpy
import sys
import wave

from PIL import Image


def jiffies(frame, font, matches):
    digits = {tuple(font[ord(character)]): character for character in '0123456789'}
    label = 'Current Jiffies:'
    result = []
    with Image.open(frame) as image:
        pixels = image.convert('RGB').load()
        for col, row in sorted(matches(frame, label, font, first_row=0), key=lambda hit: hit[::-1]):
            value = ''
            for column in range(col+len(label), image.width//8):
                glyph = tuple(sum(1 << x for x in range(8)
                                  if pixels[column*8+x, row*8+y] != (255, 255, 255))
                              for y in range(8))
                if glyph not in digits:
                    break
                value += digits[glyph]
            if value:
                result.append(int(value))
    return result


def sweep(path):
    with wave.open(str(path), 'rb') as wav:
        if (wav.getnchannels(), wav.getsampwidth(), wav.getframerate()) != (1, 2, 44100):
            raise ValueError('Unexpected PCM format')
        samples = array.array('h', wav.readframes(wav.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()
    frame = 882
    ranges = []
    for start in range(0, len(samples)-frame+1, frame):
        window = samples[start:start+frame]
        if max(window)-min(window) < 200:
            continue
        mean = sum(window)/frame
        ranges.append(50*sum(a <= mean < b for a,b in zip(window, window[1:])))
    if len(ranges) < 7 or not 400 <= min(ranges[:3]) <= 650 or not 850 <= max(ranges[-3:]) <= 1100:
        raise ValueError(f'Missing low-to-high speaker sweep: {ranges}')
    return {'pcm_milliseconds': round(len(samples)/44.1), 'active_windows_hz': ranges}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = vision['glyphs'](Path('Kernel/FontStd.HC'))
    observer = runpy.run_path('build/i386-demo-menu-buttons-v1/run.py')
    receipt = json.loads((args.run / 'result.json').read_bytes())
    if not receipt['inputs_unchanged']:
        raise ValueError('Input changed during capture')
    report = {}
    mismatches = []
    for side, result in receipt['runs'].items():
        if len(result['clicks']) != 4:
            raise ValueError(f'{side} did not finish the four clicks: {result}')
        output = args.run / side
        frame = output / 'after-click.png'
        if observer['sha'](frame) != result['after_click_sha256']:
            raise ValueError(f'{side} callback frame changed')
        values = jiffies(frame, font, vision['matches'])
        if len(values) != 3 or not values[0] < values[1] < values[2]:
            raise ValueError(f'Expected three increasing {side} results: {values}')
        audio = output / 'speaker.wav'
        if observer['sha'](audio) != result['audio_sha256']:
            raise ValueError(f'{side} audio changed')
        try:
            report[side] = dict(jiffies=values, sweep=sweep(audio))
        except ValueError as error:
            report[side] = dict(jiffies=values, sweep=None)
            mismatches.append(f'{side}: {error}')
        if 'error' in result:
            mismatches.append(f'{side}: {result["error"]}')
    print(json.dumps(dict(result='fail' if mismatches else 'pass', runs=report,
                          fresh_result=receipt['runs']['native'].get('fresh_result'),
                          mismatches=mismatches), indent=2))
    if mismatches:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
