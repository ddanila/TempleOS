"""Exercise the public GrPlot binding on a cold 8 MiB boot."""
import argparse
import hashlib
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
    digest = hashlib.sha256(image.read_bytes()).hexdigest()
    disk = out / 'working.img'
    shutil.copyfile(image, disk)
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = guest_type(disk, out / 'guest', True, ram_mib=8)
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('U0 PTLog(U8*s){while(*s)OutU8(0xE9,*s++);}')
        guest.command('CDC *pt=DCNew(8,8); pt->color=RED;')
        guest.command('GrPlot(pt,7,7); GrPlot(pt,-1,1); GrPlot(pt,8,0);')
        start = len(guest.collect())
        guest.command('if(GrPeek0(pt,7,7)==RED && GrPeek0(pt,0,1)==BLACK && GrPeek0(pt,7,0)==BLACK)PTLog("PLOT CLIP PASS\\n"); DCDel(pt);')
        guest.wait('PLOT CLIP PASS\n', start=start)
        guest.command('6*7;')
        result = guest.result_pixels()
    finally:
        guest.close()
    if hashlib.sha256(image.read_bytes()).hexdigest() != digest:
        raise ValueError('Input image changed')
    report = dict(result='pass', ram_mib=8, image_sha256=digest,
                  fresh_result=result, inputs_unchanged=True)
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
