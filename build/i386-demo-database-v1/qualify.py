"""Verify the full fixed-record file and cold reopen."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('comparison', type=Path)
    parser.add_argument('reopen', type=Path)
    args = parser.parse_args()
    result = json.loads((args.comparison / 'result.json').read_bytes())
    reopened = json.loads((args.reopen / 'result.json').read_bytes())
    if not result['inputs_unchanged'] or reopened['result'] != 'pass' or not reopened['disk_unchanged']:
        raise ValueError('Missing cold boot or changed disk')
    if reopened['input_disk_sha256'] != result['written_disk_sha256']:
        raise ValueError('Cold boot did not use the disk written in the comparison')
    expected = bytearray(100 * 512)
    record = 7 * 512
    expected[record:record+3] = b'Ada'
    expected[record+32:record+36] = b'Pine'
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font_path = Path('Kernel/FontStd.HC')
    font = vision['glyphs'](font_path)
    frames = {}
    for side, run in result['runs'].items():
        if run['result'] != 'captured':
            raise ValueError(f'{side}: {run["error"]}')
        directory = args.comparison / side
        data = (directory / 'database.bin').read_bytes()
        if data != expected or sha(data) != run['database_sha256']:
            raise ValueError(f'{side}: expected exactly one populated record')
        frames[side] = directory / 'read-report.png'
    frames['cold'] = args.reopen / 'reopened-record.png'
    if sha(frames['cold'].read_bytes()) != reopened['frame_sha256']:
        raise ValueError('Cold reopen frame changed')
    frame_pins = {}
    for side, frame in frames.items():
        for label in ('Class:"Acct"', 'Ada', 'Pine'):
            if not vision['matches'](frame, label, font, first_row=0):
                raise ValueError(f'{side}: missing {label!r} in {frame}')
        frame_pins[side] = sha(frame.read_bytes())
    print(json.dumps(dict(result='pass', bytes=len(expected), account=7, name='Ada', address='Pine',
                          database_sha256=sha(expected), font_sha256=sha(font_path.read_bytes()),
                          frames_sha256=frame_pins, fresh_result=reopened['fresh_result'],
                          cold_disk_sha256=reopened['input_disk_sha256']), indent=2))


if __name__ == '__main__':
    main()
