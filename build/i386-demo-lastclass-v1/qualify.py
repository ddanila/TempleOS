"""Check the LastClass names, live CCPU report, and static CTask report in VGA."""
import argparse
import json
from pathlib import Path
import runpy


PANELS = {
    'inferred-classes': ('is a "CTask".', 'is a "Student".', 'is a "School".', 'is a "I64i".'),
    'live-report': ('Class:"CCPU"', 'idle_pt_hits', 'idle_factor', 'profiler_timer_irq'),
    'static-report': ('except_callers', 'answer_type', 'popup_task', 'user_data'),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    runner = runpy.run_path(str(Path(__file__).with_name('run.py')))
    font_path = Path('Kernel/FontStd.HC')
    font = vision['glyphs'](font_path)
    receipt = json.loads((args.run / 'result.json').read_bytes())
    if not receipt['inputs_unchanged']:
        raise ValueError('Input changed')
    observations = {}
    for side, run in receipt['runs'].items():
        if run['result'] != 'captured':
            raise ValueError(f'{side}: {run["error"]}')
        observations[side] = {}
        for label, phrases in PANELS.items():
            frame = args.run / side / f'{label}.png'
            if runner['sha'](frame) != run['screenshots_sha256'][label]:
                raise ValueError(f'{side}: {label} frame changed')
            hits = {phrase: vision['matches'](frame, phrase, font, first_row=0) for phrase in phrases}
            if not all(hits.values()):
                raise ValueError(f'{side} {label}: {hits}')
            observations[side][label] = hits
    print(json.dumps(dict(result='pass', font_sha256=runner['sha'](font_path),
                          runs=observations, fresh_result=receipt['runs']['native']['fresh_result']),
                     indent=2))


if __name__ == '__main__':
    main()
