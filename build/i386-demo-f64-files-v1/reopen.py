"""Cold-boot the written native disk and reopen its four sorted-demo files."""
import argparse
import json
from pathlib import Path
import runpy
import shutil


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('comparison', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    comparison = args.comparison.resolve()
    out = args.out.resolve()
    out.mkdir()
    runner = runpy.run_path(str(Path(__file__).with_name('run.py')))
    sha = runner['sha']
    disk = comparison / 'working.img'
    digest = sha(disk)
    working = out / 'working.img'
    shutil.copyfile(disk, working)
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = guest_type(working, out / 'guest', True, ram_mib=8)
    files = {}
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('U0 SGLog(U8*s){while(*s)OutU8(0xE9,*s++);}')
        start = len(guest.collect())
        guest.command('if(Sign(-4.0)==-1.0 && Sign(4.0)==1.0 && Sign(0x8000000000000000(F64))(U64)==0 && Sign(0x7FF8000000000000(F64))(U64)==0)SGLog("SIGN VECTORS PASS\\n");')
        guest.wait('SIGN VECTORS PASS\n', timeout=10, start=start)
        guest.command(runner['DUMP_FILE'])
        for stage in ('Unsorted', 'Sorted'):
            for extension in ('DATA', 'DD'):
                data = runner['export'](guest, True, stage, extension)
                path = f'{stage.lower()}-{extension.lower()}.bin'
                if data != (comparison / 'native' / path).read_bytes():
                    raise ValueError(f'File changed after cold boot: {path}')
                files[path] = sha(guest.out / path)
        guest.command('6*7;')
        fresh = guest.result_pixels()
    finally:
        guest.close()
    if sha(disk) != digest:
        raise ValueError('Source disk changed during reboot')
    report = dict(result='pass', ram_mib=8, input_disk_sha256=digest,
                  inputs_unchanged=True, sign_vectors=True, files=files, fresh_result=fresh)
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
