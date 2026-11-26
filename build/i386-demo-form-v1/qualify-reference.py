"""Verify the original Form workflow and the native launch rejection."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy


PANELS = {
    'accept-form': ('Float 2:', '4.50000000e3', '0000000000001234',
                    'Teen', 'John', '1234 Pine St.', 'Check'),
    'accept-result': ('4.50000000e3', '4660', '-567', 'Teen', 'John',
                      'Address1=1234 Pine St.', 'Address2=', 'Check',
                      'ClassRep Example', 'Class:"FDStruct"'),
    'cancel-form': ('Float 2:', 'Teen', 'John', 'Check'),
    'cancel-result': ('Cancel', 'ClassRep Example', 'Class:"FDStruct"'),
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    receipt = json.loads((args.run / 'result.json').read_bytes())
    original = receipt['runs']['original']
    if not receipt['inputs_unchanged'] or original['result'] != 'captured':
        raise ValueError('Missing original capture or changed input')
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font_path = Path('Kernel/FontStd.HC')
    font = vision['glyphs'](font_path)
    for panel, labels in PANELS.items():
        frame = args.run / 'original' / f'{panel}.png'
        if sha(frame) != original['screenshots_sha256'][panel]:
            raise ValueError(f'Frame changed: {panel}')
        for label in labels:
            if not vision['matches'](frame, label, font, first_row=0):
                raise ValueError(f'Missing {label!r} in {panel}')
    source = Path('Demo/DolDoc/Form.HC')
    if sha(source) != receipt['input_sha256'][str(source.resolve())]:
        raise ValueError('Demo source changed')
    line = next(number for number, text in enumerate(source.read_text().splitlines(), 1)
                if text.strip() == 'ClassRep(&fds);')
    log = args.run / 'native' / 'launch.log'
    required = f'FRONTEND ERROR Undefined identifier at  file C:/{source} line {line}'
    if required not in log.read_text() or 'INPUT REJECT ' not in log.read_text():
        raise ValueError('Missing native ClassRep rejection')
    print(json.dumps(dict(result='fail', original='pass', font_sha256=sha(font_path),
                          verified_labels=PANELS, native_rejection=required,
                          native_log_sha256=sha(log)), indent=2))


if __name__ == '__main__':
    main()
