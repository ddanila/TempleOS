#!/usr/bin/env python3
"""Launch Psalmody from a cold native prompt with the PersonalMenu command."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import time

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
LAUNCH = '#include "::/Apps/Psalmody/Run"'


def sha256(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def wait_for_score(guest, start):
    deadline = time.monotonic() + 60
    while time.monotonic() < deadline and guest.p.poll() is None:
        if 'INPUT REJECT ' in guest.collect()[start:]:
            raise ValueError(guest.collect()[start:][-1200:])
        guest.screenshot('launched')
        with Image.open(guest.out / 'launched.png') as frame:
            pixels = frame.convert('RGB').load()
            for top in range(0, 64, 8):
                rows = [top + i * 8 for i in (0, 1, 2, 3, 4, 6, 7, 8, 9, 10)]
                if (all(pixels[x, y] == (0, 0, 0)
                        for y in rows for x in range(120, 350))
                        and pixels[200, top + 40] != (0, 0, 0)):
                    return rows
        time.sleep(.5)
    raise TimeoutError('Missing both Psalmody staves')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    out.mkdir(parents=True)
    report = {'result': 'running', 'command': LAUNCH, 'disk_sha256': sha256(disk)}
    helper = runpy.run_path(str(ROOT / 'tools/test-i386-autocomplete-interaction.py'))
    guest = helper['Guest'](disk, out / 'guest', True, native_options=('-snapshot',))
    try:
        started = time.monotonic()
        guest.wait('DONE native kernel startup\n')
        report['startup_seconds'] = round(time.monotonic() - started, 2)
        start = len(guest.collect())
        guest.type(LAUNCH)
        guest.press('ret')
        report['staff_rows'] = wait_for_score(guest, start)
        guest.key('shift', True)
        try:
            guest.press('esc')
        finally:
            guest.key('shift', False)
        guest.wait('COMMAND OK\n', start=start)
        guest.command('6*7;')
        guest.result_pixels()
        report.update(result='pass', caller_arithmetic=42)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        guest.close()
        report['input_unchanged'] = sha256(disk) == report['disk_sha256']
        if not report['input_unchanged']:
            report.update(result='fail', error='Input disk changed')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
