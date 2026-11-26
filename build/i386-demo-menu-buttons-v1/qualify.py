"""Verify the menu captures and reproduce the recorded speaker measurements."""
import argparse
import json
from pathlib import Path
import runpy


PANELS = {
    'initial-menu': ('Set Freq', 'Done'),
    'frequency': ('200 Hz', '400 Hz', '800 Hz'),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    receipt = json.loads((args.run / 'result.json').read_bytes())
    if receipt['result'] != 'pass' or not receipt['inputs_unchanged']:
        raise ValueError('The menu or audio run failed')

    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font_path = Path('Kernel/FontStd.HC')
    font = vision['glyphs'](font_path)
    runner = runpy.run_path(str(Path(__file__).with_name('run.py')))
    results = {}
    for side, run in receipt['runs'].items():
        output = args.run / side
        for panel, digest in run['screenshots_sha256'].items():
            image = output / f'{panel}.png'
            if runner['sha'](image) != digest:
                raise ValueError(f'Panel changed on {side}: {panel}')
            for label in PANELS.get(panel, ()):
                if not vision['matches'](image, label, font, first_row=0):
                    raise ValueError(f'{side} {panel} is missing {label}')

        audio = output / 'speaker.wav'
        if runner['sha'](audio) != run['audio_sha256']:
            raise ValueError(f'{side} audio changed')
        tones = runner['frequencies'](audio)
        if {str(hz): count for hz, count in tones.items()} != run['tone_windows']:
            raise ValueError(f'{side} tone measurements changed')
        if run['silent_bytes'] != 0:
            raise ValueError(f'{side} emitted more audio after sound off')
        results[side] = dict(tone_windows=run['tone_windows'], silent_bytes=run['silent_bytes'],
                             audio_sha256=run['audio_sha256'])

    print(json.dumps(dict(result='pass', input_sha256=receipt['input_sha256'],
                          font_sha256=runner['sha'](font_path), runs=results,
                          fresh_result=receipt['runs']['native']['fresh_result']), indent=2))


if __name__ == '__main__':
    main()
