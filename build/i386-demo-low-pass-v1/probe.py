"""Check the public LowPass1 default and explicit time steps after an 8 MiB boot."""
import argparse
import json
from pathlib import Path
import runpy
import shutil


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('image', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    image = args.image.resolve()
    out = args.out.resolve()
    out.mkdir()
    sha = runpy.run_path(str(Path(__file__).with_name('run.py')))['sha']
    digest = sha(image)
    disk = out / 'working.img'
    shutil.copyfile(image, disk)
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = guest_type(disk, out / 'guest', True, ram_mib=8)
    commands = (
        ('LowPass1(.01,37,400,0)==37', 'ZERO STEP'),
        ('LowPass1(.01,0,400)>3.98006 && LowPass1(.01,0,400)<3.98008', 'DEFAULT STEP'),
        ('LowPass1(.1,400,0,10)>147.1517 && LowPass1(.1,400,0,10)<147.1519', 'DECAY'),
    )
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('U0 LPLog(U8*s){while(*s)OutU8(0xE9,*s++);}')
        for condition, label in commands:
            start = len(guest.collect())
            guest.command(f'if({condition})LPLog("LOW PASS {label} PASS\\n");')
            guest.wait(f'LOW PASS {label} PASS\n', timeout=10, start=start)
        guest.command('6*7;')
        fresh = guest.result_pixels()
    finally:
        guest.close()
    if sha(image) != digest:
        raise ValueError('Input image changed')
    report = dict(result='pass', image_sha256=digest, ram_mib=8, inputs_unchanged=True,
                  cases=[label for _, label in commands], fresh_result=fresh)
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
