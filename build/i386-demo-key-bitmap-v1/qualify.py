"""Check that held-key sprite shapes match after aligning their origins."""
import argparse
import json
from pathlib import Path
import runpy


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    helpers = runpy.run_path(str(Path(__file__).with_name('run.py')))
    receipt_path = args.run / 'result.json'
    receipt = json.loads(receipt_path.read_bytes())
    if receipt['result'] != 'pass' or not receipt['inputs_unchanged']:
        raise ValueError('Both guests must complete the hold and release')
    shapes = {}
    for side, report in receipt['runs'].items():
        directory = args.run / side
        before = directory / 'before-hold.png'
        after = directory / 'after-release.png'
        if helpers['sha'](before) != report['idle_sha256'] or helpers['sha'](after) != report['after_release_sha256']:
            raise ValueError(f'{side} idle or release frame changed')
        baseline = helpers['ink'](before)
        if helpers['ink'](after) - baseline:
            raise ValueError(f'{side} sprite remained after release')
        shapes[side] = []
        for sample in report['samples'][:2]:
            frame = directory / sample['frame']
            if helpers['sha'](frame) != sample['sha256']:
                raise ValueError(f'{side} held frame changed')
            pixels = helpers['ink'](frame) - baseline
            left = min(x for x, _ in pixels)
            top = min(y for _, y in pixels)
            shapes[side].append({(x-left,y-top) for x,y in pixels})
    if shapes['original'] != shapes['native'] or not all(shapes['native']):
        raise ValueError('Aligned sprite masks differ')
    print(json.dumps(dict(result='pass', input_sha256=receipt['input_sha256'],
                          capture_sha256=helpers['sha'](receipt_path),
                          matched_pixels=[len(shape) for shape in shapes['native']],
                          fresh_result=receipt['runs']['native']['fresh_result']), indent=2))


if __name__ == '__main__':
    main()
