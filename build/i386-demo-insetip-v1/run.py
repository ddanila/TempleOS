"""Compare the bundled InSetIP mouse movement demo on both guests."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import re
import runpy
import shutil
import time


DEMO = Path('Demo/InFile/InSetIP.HC')
EXPORT = r'''U0 DemoMouseState(){U8 *s=MStrPrint("\nMOUSE STATE %d %d %d %d %d %d\n",ms.pos.x,ms.pos.y,ms.lb,ms.rb,Fs->pix_left+Fs->scroll_x,Fs->pix_top+Fs->scroll_y),*p=s;while(*p)OutU8(0xE9,*p++);Free(s);}DemoMouseState;'''
RECORD = re.compile(r'^MOUSE STATE ((?:-?\d+ ){5}-?\d+)\n', re.M)


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def type_line(guest, text):
    guest.type(text)
    guest.press('ret')


def state(guest, start):
    deadline = time.monotonic() + 90
    while guest.p.poll() is None and time.monotonic() < deadline:
        log = guest.collect()[start:]
        if 'INPUT REJECT ' in log:
            raise ValueError(log[-1200:])
        match = RECORD.search(log)
        if match is not None:
            return list(map(int, match.group(1).split()))
        time.sleep(.1)
    raise TimeoutError('Missing complete mouse state')


def capture(Guest, image, out, native):
    guest = Guest(image, out, native, reference_cpus=1)
    observed = {}
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        start = len(guest.collect())
        type_line(guest, EXPORT)
        observed['before'] = state(guest, start)
        start = len(guest.collect())
        type_line(guest, 'Bool demo_had_border=WinBorder(ON);DemoMouseState;WinBorder(demo_had_border);')
        observed['border_origin'] = state(guest, start)[4:]
        if native:
            guest.wait('COMMAND OK\n', start=start)
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        type_line(guest, f'ExeFile("{drive}:/{DEMO}");DemoMouseState;')
        observed['after'] = state(guest, start)
        origin_x, origin_y = observed['border_origin']
        if observed['after'][:4] != [origin_x + 20, origin_y + 20, 0, 0]:
            raise ValueError('The demo did not finish at the expected position with both buttons up')
        guest.screenshot('mouse-after')
        for name, command, expected in (
            ('explicit_position', 'InSetMs(0,77,65);', [77, 65, 0, 0]),
            ('out_of_range_x', 'InSetMs(0,-1,66);', [77, 66, 0, 0]),
            ('out_of_range_y', 'InSetMs(0,78,480);', [78, 66, 0, 0]),
            ('default_position', 'InSetMs(0);', [78, 66, 0, 0]),
        ):
            start = len(guest.collect())
            type_line(guest, command + 'DemoMouseState;')
            observed[name] = state(guest, start)
            if observed[name][:4] != expected:
                raise ValueError(f'Unexpected mouse state for {name}: {observed[name]}')
        if native:
            guest.wait('COMMAND OK\n', start=start)
            guest.command('6*7;')
            observed['fresh_arithmetic'] = guest.result_pixels()
        return dict(result='pass', **observed)
    except (RuntimeError, TimeoutError, ValueError) as exc:
        return dict(result='fail', error=str(exc), **observed)
    finally:
        guest.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path)
    parser.add_argument('native', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    original, native, out = (p.resolve() for p in (args.original, args.native, args.out))
    out.mkdir()
    pins = {str(p): sha(p) for p in (original, native, DEMO.resolve())}
    working = out / 'working.img'
    shutil.copyfile(native, working)
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    with ThreadPoolExecutor(max_workers=2) as pool:
        jobs = {name: pool.submit(capture, Guest, image, out / name, name == 'native')
                for name, image in [('original', original), ('native', working)]}
        runs = {name: job.result() for name, job in jobs.items()}
    unchanged = all(sha(Path(path)) == expected for path, expected in pins.items())
    passed = unchanged and all(run['result'] == 'pass' for run in runs.values())
    (out / 'result.json').write_text(json.dumps(dict(
        result='pass' if passed else 'fail', input_sha256=pins, inputs_unchanged=unchanged,
        working_disk_sha256=sha(working), runs=runs), indent=2) + '\n')
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
