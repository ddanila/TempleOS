"""Verify the observed order of inner and outer exception handlers."""
import json
from pathlib import Path
import runpy


def main():
    root = Path(__file__).resolve().parent
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font_path = Path('Kernel/FontStd.HC')
    font = vision['glyphs'](font_path)
    sha = runpy.run_path(str(root / 'run.py'))['sha']
    older_run = root / 'comparison'
    point2_repeat = root / 'original-point2-repeat'
    newer_run = root / 'comparison-point4'
    older = json.loads((older_run / 'result.json').read_bytes())
    newer = json.loads((newer_run / 'result.json').read_bytes())
    repeat = json.loads((point2_repeat / 'result.json').read_bytes())
    if not older['inputs_unchanged'] or not newer['inputs_unchanged']:
        raise ValueError('Inputs changed during capture')
    if older['input_sha256'] != newer['input_sha256'] or repeat['image_sha256'] not in newer['input_sha256'].values():
        raise ValueError('Capture images differ')
    if repeat['source_sha256'] != sha(Path('Demo/Exceptions.HC')):
        raise ValueError('The original Point2 run used different source')
    cases = {
        'catch': {side: (newer_run / f'{side}-catch', newer['runs'][f'{side}-catch'])
                  for side in ('original', 'native')},
        'point2': {'original': (point2_repeat, repeat),
                   'native': (older_run / 'native-rethrow', older['runs']['native-rethrow'])},
        'point4': {side: (newer_run / f'{side}-rethrow', newer['runs'][f'{side}-rethrow'])
                   for side in ('original', 'native')},
    }
    observations = {}
    for case, runs in cases.items():
        observations[case] = {}
        for side, (directory, receipt) in runs.items():
            frame = directory / 'completed.png'
            if receipt['result'] != 'pass' or sha(frame) != receipt['completed_sha256']:
                raise ValueError(f'{side} {case} capture failed or changed')
            if side == 'native' and not receipt['fresh_result']:
                raise ValueError('The native prompt did not recover')
            def rows(label):
                return [row for _, row in vision['matches'](frame, label, font)]
            if case == 'catch':
                ordered = (rows('D2 hndlr'), rows('Ch:Point1:'), rows('Caught in D2'),
                           rows('Demo hndlr'), rows('Ch:Point3:'))
            else:
                tag = 'Ch:Point' + case[-1] + ':'
                points = rows(tag)
                ordered = (rows('D2 hndlr'), points[:1], rows('Demo hndlr'), points[1:])
            if any(len(group) != 1 for group in ordered):
                raise ValueError(f'Missing handler output on {side} {case}')
            order = [group[0] for group in ordered]
            if any(a >= b for a, b in zip(order, order[1:])):
                raise ValueError(f'Handler output is out of order on {side} {case}')
            observations[case][side] = dict(ordered_rows=order, completed_sha256=sha(frame))
    print(json.dumps(dict(result='pass', input_sha256=newer['input_sha256'],
                          font_sha256=sha(font_path), cases=observations), indent=2))


if __name__ == '__main__':
    main()
