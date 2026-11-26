"""Cold boot the written native disk and reopen record seven from the bundled demo."""
import argparse
import json
from pathlib import Path
import runpy


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('image', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    runner = runpy.run_path(str(Path(__file__).with_name('run.py')))
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = vision['glyphs'](Path('Kernel/FontStd.HC'))
    before = runner['sha'](args.image)
    guest = Guest(args.image.resolve(), args.out.resolve(), True)
    try:
        guest.wait('DONE native kernel startup\n')
        start = len(guest.collect())
        submit = runner['submit']
        wait = runner['wait_frame']
        submit(guest, f'ExeFile("C:/{runner["SOURCE"]}");')
        wait(guest, 'menu', 'ead acct, ', vision, font, start)
        guest.press('r')
        wait(guest, 'read-prompt', 'Acct #', vision, font, start)
        submit(guest, '7')
        wait(guest, 'reopened-record', 'Pine', vision, font, start)
        frame = guest.out / 'reopened-record.png'
        if not vision['matches'](frame, 'Ada', font, first_row=0):
            raise ValueError('Reopened name differs')
        guest.press('esc')
        guest.wait('COMMAND OK\n', start=start)
        guest.command('6*7;')
        result = dict(result='pass', input_disk_sha256=before,
                      frame_sha256=runner['sha'](frame), fresh_result=guest.result_pixels())
    finally:
        guest.close()
    result['disk_unchanged'] = runner['sha'](args.image) == before
    if not result['disk_unchanged']:
        raise ValueError('Read-only reopen changed the database disk')
    (args.out / 'result.json').write_text(json.dumps(result, indent=2)+'\n')


if __name__ == '__main__':
    main()
