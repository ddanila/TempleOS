"""Check the rendered Form defaults, accepted values, cancellation, and class report."""
import argparse
import json
from pathlib import Path
import runpy


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    reference = runpy.run_path(str(root / 'qualify-reference.py'))
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font_path = Path('Kernel/FontStd.HC')
    font = vision['glyphs'](font_path)
    receipt = json.loads((args.run / 'result.json').read_bytes())
    if not receipt['inputs_unchanged']:
        raise ValueError('Input changed')
    runs = {}
    for side, run in receipt['runs'].items():
        if run['result'] != 'captured':
            raise ValueError(f'{side}: {run["error"]}')
        observations = {}
        for panel, labels in reference['PANELS'].items():
            frame = args.run / side / f'{panel}.png'
            if reference['sha'](frame) != run['screenshots_sha256'][panel]:
                raise ValueError(f'{side} changed frame: {panel}')
            observations[panel] = {}
            for label in labels:
                hits = vision['matches'](frame, label, font, first_row=0)
                if not hits:
                    raise ValueError(f'{side} {panel} missing {label!r}')
                observations[panel][label] = hits
        runs[side] = observations
    print(json.dumps(dict(result='pass', font_sha256=reference['sha'](font_path),
                          runs=runs, fresh_result=receipt['runs']['native']['fresh_result']),
                     indent=2))


if __name__ == '__main__':
    main()
