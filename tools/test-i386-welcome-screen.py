#!/usr/bin/env python3
"""Check the native welcome screen against the source text and original font."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--ram-mib',type=int,choices=(8,64),default=64);args=ap.parse_args()
    out=args.out.resolve();source=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    paths=[source,Path(__file__).resolve(),ROOT/'tools/test-i386-timeclock-welcome.py',ROOT/'tools/i386-kernel-input.py',ROOT/'Kernel/FontStd.HC',ROOT/'Doc/Start.DD']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,ram_mib=args.ram_mib,scope='Exact initial native welcome pixels; not original desktop, command input or startup timing qualification')
    try:
        text=(ROOT/'Doc/Start.DD').read_text()
        for fragment in ('TempleOS V5.03','Public Domain Operating System','Help & Index','Quick Start: Cmd line'):
            if fragment not in text:raise ValueError('Welcome source changed: '+fragment)
        image=out/'working.img';shutil.copyfile(source,image)
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](image,out/'guest',[],args.ram_mib)
        rows=['TempleOS i386','HolyC console','',' '*33+'TempleOS V5.03','',' '*25+'Public Domain Operating System','','Help & Index, Quick Start: Cmd line','','> ']
        colors={(3,col):5 for col in range(33,47)}
        cells={(7,col) for col in (*range(12),*range(14,35))}
        colors.update({cell:4 for cell in cells})
        render=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['console_pixels']
        expected=render(rows,colors,underline_cells=cells)
        cursor={(16+x,72+y):0 for y in range(8) for x in range(8)}
        with_cursor=render(rows,colors,underline_cells=cells,pixel_colors=cursor)
        with Image.open(out/'guest/initial.ppm') as actual:
            if actual.size!=(640,480) or actual.convert('RGB').tobytes() not in (expected,with_cursor):raise ValueError('Welcome screen pixels differ')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
