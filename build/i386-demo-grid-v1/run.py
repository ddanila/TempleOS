"""Compare physical mouse trails and click-to-exit cleanup in both guests."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

from PIL import Image


SOURCES = {'grid': '/Demo/Graphics/Grid.HC', 'mouse': '/Demo/Graphics/MouseDemo.HC'}
MOVES = ((27, 34), (31, -19), (-18, 37), (39, 13))
NEIGHBORS = tuple((dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy)


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


def capture(guest_type, disk, out, native, demo):
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
        guest.type(f'ExeFile("{drive}:{SOURCES[demo]}"); if(!MemCmp(&ms_grid,&gt_old,sizeof(CGridGlbls)) && gt_draw==gr.fp_draw_ms) GTLog("GRID SETTINGS RESTORED\\n");')
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
        points = sorted((x, y) for x, y in moved - initial
                         if (demo == 'mouse' or not (x % 5 or y % 5))
                         and not any((x + dx, y + dy) in moved
                                     for dx, dy in NEIGHBORS))
        if len(points) < 3:
            raise ValueError(f'Fewer than three isolated trail points on {out.name}')
        if cleared.intersection(points):
            raise ValueError(f'Trail remained after left click on {out.name}')
        key = 'snapped_points' if demo == 'grid' else 'trail_points'
        result = dict(settings_restored=True,
                      screenshots_sha256={stage: sha(path) for stage, path in frames.items()})
        result[key] = points
        guest.press('end')
        guest.screenshot('after-end')
        start = len(guest.collect())
        guest.type('if(6*7==42)GTLog("GRID ARITHMETIC PASS\\n");')
        guest.press('ret')
        try:
            guest.wait('GRID ARITHMETIC PASS\n', timeout=12, start=start)
            result['fresh_result'] = 'pass'
        except TimeoutError:
            result['fresh_result'] = 'missing'
        guest.screenshot('after-arithmetic')
        return result
    finally:
        guest.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original_iso', type=Path)
    parser.add_argument('native_image', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    parser.add_argument('--demo', choices=SOURCES, default='grid')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    original, native = (path.resolve() for path in (args.original_iso, args.native_image))
    inputs = {str(path): sha(path) for path in (original, native)}
    disk = out / 'working.img'
    shutil.copyfile(native, disk)
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    report = dict(input_sha256=inputs, source_sha256=sha(Path(SOURCES[args.demo][1:])), moves=MOVES, runs={})
    with ThreadPoolExecutor(max_workers=2) as pool:
        runs = {side: pool.submit(capture, guest_type, image, out / side, side == 'native', args.demo)
                for side, image in (('original', original), ('native', disk))}
        for side, future in runs.items():
            try:
                report['runs'][side] = {'result': 'pass', **future.result()}
            except (RuntimeError, TimeoutError, ValueError) as ex:
                report['runs'][side] = dict(result='fail', error=str(ex))
    report['inputs_unchanged'] = all(sha(Path(path)) == digest for path, digest in inputs.items())
    passed = report['inputs_unchanged'] and all(
        run['result'] == 'pass' and run['fresh_result'] == 'pass'
        for run in report['runs'].values())
    key = 'snapped_points' if args.demo == 'grid' else 'trail_points'
    if passed and report['runs']['original'][key] != report['runs']['native'][key]:
        report['error'] = 'The guests drew different trail points'
        passed = False
    report['result'] = 'pass' if passed else 'fail'
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if not passed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
