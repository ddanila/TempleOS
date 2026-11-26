"""Verify all four rendered answers against the observed original format."""
import argparse
import json
from pathlib import Path
import runpy


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    runner = runpy.run_path(str(Path(__file__).with_name('run.py')))
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font_path = Path('Kernel/FontStd.HC')
    font = vision['glyphs'](font_path)
    sha = runner['sha']
    capture = json.loads((args.run / 'result.json').read_bytes())
    if not capture['inputs_unchanged']:
        raise ValueError('A test input changed')
    observations = {}
    for side, result in capture['runs'].items():
        folder = args.run / side
        for stage, prompt, _ in runner['STEPS']:
            frame = folder / f'{stage}.png'
            if sha(frame) != result['frames'][stage]['sha256'] or not vision['matches'](frame, prompt, font):
                raise ValueError(f'{side} {stage} prompt evidence differs')
        frame = folder / 'completed.png'
        if sha(frame) != result['completed_sha256']:
            raise ValueError(f'{side} completion evidence differs')
        values = {label: vision['matches'](frame, label, font) for label in runner['EXPECTED']}
        if not all(values.values()):
            raise ValueError(f'{side} did not render all four answers: {values}')
        observations[side] = values
    report = dict(result='pass', input_sha256=capture['input_sha256'],
                  font_sha256=sha(font_path), capture_sha256=sha(args.run/'result.json'),
                  answers=capture['answers'], values=observations,
                  fresh_result=capture['runs']['native']['fresh_result'])
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
