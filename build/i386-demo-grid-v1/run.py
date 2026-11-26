"""Exercise Grid's physical mouse drawing and settings restoration in both guests."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

from PIL import Image


SOURCE = '/Demo/Graphics/Grid.HC'
MOVES = ((27, 34), (31, -19), (-18, 37), (39, 13))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def ink(frame):
    with Image.open(frame) as image:
        pixels = image.convert('RGB').load()
        return {(x, y) for y in range(64, 400) for x in range(24, 300)
                if pixels[x, y] == (0, 0, 0)}


def motion(guest, dx, dy):
    guest.call('input-send-event', events=[dict(type='rel', data=dict(axis=axis, value=value))
                                           for axis, value in (('x', dx), ('y', dy))])


def capture(guest_type, disk, out, native):
    guest = guest_type(disk, out, native, reference_cpus=1)
    restored = 'GRID SETTINGS RESTORED\n'
    drive = 'C' if native else 'T'
    setup = (
        'U0 GTLog(U8*s){while(*s)OutU8(0xE9,*s++);}',
        'CGridGlbls gt_old; U8 *gt_draw;',
        'MsSet(96,248); MemCpy(&gt_old,&ms_grid,sizeof(CGridGlbls)); gt_draw=gr.fp_draw_ms;',
    )
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        for command in setup:
            if native:
                guest.command(command)
            else:
                guest.type(command)
                guest.press('ret')
                time.sleep(1)
        start = len(guest.collect())
        guest.type(f'ExeFile("{drive}:{SOURCE}"); if(!MemCmp(&ms_grid,&gt_old,sizeof(CGridGlbls)) && gt_draw==gr.fp_draw_ms) GTLog("GRID SETTINGS RESTORED\\n");')
        guest.press('ret')
        time.sleep(5)
        guest.screenshot('initial')
        for dx, dy in MOVES:
            motion(guest, dx, dy)
            time.sleep(.5)
        guest.screenshot('moved')
        try:
            guest.call('input-send-event', events=[dict(type='btn', data=dict(button='left', down=True))])
            guest.wait(restored, timeout=12, start=start)
        finally:
            guest.call('input-send-event', events=[dict(type='btn', data=dict(button='left', down=False))])
        if native:
            guest.wait('COMMAND OK\n', start=start)
        time.sleep(2)
        guest.screenshot('after-click')
        frames = {stage: out / f'{stage}.png' for stage in ('initial', 'moved', 'after-click')}
        initial, moved, cleared = (ink(path) for path in frames.values())
        snapped = sorted((x, y) for x, y in moved - initial if not (x % 5 or y % 5)
                         and not any((x + dx, y + dy) in moved
                                     for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1))))
        if len(snapped) < 3:
            raise ValueError(f'Fewer than three isolated five-pixel trail points on {out.name}')
        if cleared.intersection(snapped):
            raise ValueError(f'Trail remained after left click on {out.name}')
        result = dict(snapped_points=snapped, settings_restored=True,
                      screenshots_sha256={stage: sha(path) for stage, path in frames.items()})
        if native:
            guest.press('end')
            guest.command('6*7;')
            result['fresh_result'] = guest.result_pixels()
        return result
    finally:
        guest.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original_iso', type=Path)
    parser.add_argument('native_image', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    original, native = (path.resolve() for path in (args.original_iso, args.native_image))
    inputs = {str(path): sha(path) for path in (original, native)}
    disk = out / 'working.img'
    shutil.copyfile(native, disk)
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    report = dict(input_sha256=inputs, source_sha256=sha(Path(SOURCE[1:])), moves=MOVES, runs={})
    with ThreadPoolExecutor(max_workers=2) as pool:
        runs = {side: pool.submit(capture, guest_type, image, out / side, side == 'native')
                for side, image in (('original', original), ('native', disk))}
        for side, future in runs.items():
            try:
                report['runs'][side] = {'result': 'pass', **future.result()}
            except (RuntimeError, TimeoutError, ValueError) as ex:
                report['runs'][side] = dict(result='fail', error=str(ex))
    report['inputs_unchanged'] = all(sha(Path(path)) == digest for path, digest in inputs.items())
    passed = report['inputs_unchanged'] and all(run['result'] == 'pass' for run in report['runs'].values())
    if passed and report['runs']['original']['snapped_points'] != report['runs']['native']['snapped_points']:
        report['error'] = 'The guests drew different snapped trail points'
        passed = False
    report['result'] = 'pass' if passed else 'fail'
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if not passed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
