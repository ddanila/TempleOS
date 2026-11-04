#!/usr/bin/env python3
"""Check retained exact-width input wrapping after scrolling the welcome console."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = 'Fs->next_task->last_task==Fs&&Fs->last_task->next_task==Fs&&Fs->next_task!=Fs;'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--accel', choices=('tcg', 'kvm'), default='tcg')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    disk = args.disk.resolve()
    helper = ROOT/'tools/test-i386-timeclock-welcome.py'
    renderer = ROOT/'tools/i386-kernel-input.py'
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in (disk, Path(__file__).resolve(), helper,
                                   renderer, ROOT/'Kernel/FontStd.HC')}
    report = dict(result='running', input_sha256=pins, accel=args.accel,
                  scope='Three identical exact-width commands after console scrolling; not full terminal qualification')
    try:
        working = out/'working.img'
        shutil.copyfile(disk, working)
        commands = ['I64 wrap_i;for(wrap_i=0;wrap_i<70;wrap_i++)"\\n";']+[SOURCE]*3
        runpy.run_path(str(helper))['guest'](working, out/'guest', commands, 64, True, accel=args.accel)
        rows = [('> '+SOURCE)[:79], ';', '1', '> ']
        colors = {(r, c): 2 for r, line in enumerate(rows) for c in range(len(line))}
        render = runpy.run_path(str(renderer))['console_pixels']
        expected = Image.frombytes('RGB', (640, 480), render(rows, colors)).crop((0, 0, 640, 32)).tobytes()
        cursor = {(16+x, 24+y): 0 for x in range(8) for y in range(8)}
        blinking = Image.frombytes('RGB', (640, 480), render(rows, colors, pixel_colors=cursor)).crop((0, 0, 640, 32)).tobytes()
        for index in range(1, 4):
            with Image.open(out/'guest'/f'done-{index}.ppm') as frame:
                actual = frame.convert('RGB').crop((0, 448, 640, 480)).tobytes()
            if actual not in (expected, blinking):
                raise ValueError(f'Repetition {index}: exact-width terminal tail differs')
        report.update(result='pass', repetitions=3, expected_tail=rows)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == value for p, value in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
