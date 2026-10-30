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
    ap.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    ap.add_argument('--suspended-clear',action='store_true',help='Also check document clearing and input with WinMgr suspended')
    args=ap.parse_args()
    out=args.out.resolve();source=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    paths=[source,Path(__file__).resolve(),ROOT/'tools/test-i386-timeclock-welcome.py',ROOT/'tools/i386-kernel-input.py',ROOT/'Kernel/FontStd.HC',ROOT/'Doc/Start.DD']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,ram_mib=args.ram_mib,suspended_clear=args.suspended_clear,scope='Exact initial native welcome pixels and optional suspended clear/input; not original desktop or startup timing qualification')
    try:
        text=(ROOT/'Doc/Start.DD').read_text()
        for fragment in ('TempleOS V5.03','Public Domain Operating System','Help & Index','Quick Start: Cmd line'):
            if fragment not in text:raise ValueError('Welcome source changed: '+fragment)
        image=out/'working.img';shutil.copyfile(source,image)
        commands=['U0 P(){if(sys_winmgr_task!=adam_task)Suspend(sys_winmgr_task,TRUE);}P;',
                  '6*7;','DocClear;','6*7;'] if args.suspended_clear else []
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](image,out/'guest',commands,args.ram_mib,args.suspended_clear)
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
        if args.suspended_clear:
            def check_frame(name,lines,colors):
                base=render(lines,colors)
                x=len(lines[-1])*8;y=(len(lines)-1)*8
                blink=render(lines,colors,pixel_colors={(x+dx,y+dy):0 for dy in range(8) for dx in range(8)})
                with Image.open(out/'guest'/name) as actual:
                    if actual.size!=(640,480) or actual.convert('RGB').tobytes() not in (base,blink):raise ValueError(name+' pixels differ')
            check_frame('done-2.ppm',['> '],{})
            check_frame('done-3.ppm',['> 6*7;','42','> '],{(0,col):2 for col in range(2,6)}|{(1,0):2,(1,1):2,(2,0):2})
            if 'SUSPENDED DOCUMENT PRESENT FAILED' in (out/'guest/debug.log').read_text():raise ValueError('Suspended document presenter failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
