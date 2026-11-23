"""Open Titanium from its packaged Run.HC and exercise the physical controls."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import time

from PIL import Image


def pixels(path):
    with Image.open(path) as image:
        return image.convert('RGB').tobytes()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk',type=Path)
    parser.add_argument('--current-app',action='store_true',
                        help='Test the current Titanium sources with the pinned x86-64 system')
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if args.disk and args.current_app:
        parser.error('--current-app applies to the x86-64 control')
    out=args.out.resolve()
    out.mkdir()
    native=bool(args.disk)
    report={'result':'running','native':native}
    if native:
        disk=out/'working.img'
        shutil.copyfile(args.disk,disk)
        report['source_sha256']=hashlib.sha256(args.disk.read_bytes()).hexdigest()
    else:
        disk=out/'original.iso'
        overlay=out/'overlay'
        sources=runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference'](overlay)
        if args.current_app:
            for path in ('Apps/Titanium/Load.HC','Apps/Titanium/Titanium.HC'):
                data=Path(path).read_bytes()
                (overlay/path).write_bytes(data)
                sources[path]=hashlib.sha256(data).hexdigest()
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
            b'U0 TiReturn(){U8 *p;for(p="TITANIUM returned\\n";*p;p++)OutU8(0xE9,*p);}\n'
            b'#include "T:/Apps/Titanium/Run.HC"\n'
            b'TiReturn;\n')
        report['application_sha256']={p:h for p,h in sources.items() if p.startswith('Apps/Titanium/')}
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),
                        '--output',str(disk)],check=True)
    Guest=runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest=Guest(disk,out/'guest',native)
    try:
        if native:
            guest.wait('DONE native kernel startup\n')
            start=len(guest.collect())
            guest.type('#include "C:/Apps/Titanium/Run.HC"')
            guest.press('ret')
        else:
            start=0
        observe=runpy.run_path('build/grmodels-menu-workflows-v1/run.py')['wait_text']
        check=runpy.run_path('tools/check-i386-autocomplete-numeric-pixels.py')
        font=check['font_bytes']()
        observe(guest,check,font,b'Scoring:','instructions')
        time.sleep(1)
        guest.press('ret')
        time.sleep(5)
        guest.screenshot('play')
        play=pixels(guest.out/'play.png')
        if play==pixels(guest.out/'instructions.png'):
            raise ValueError('Titanium still shows the instruction frame')
        guest.key('right',True)
        guest.key('spc',True)
        time.sleep(2)
        guest.screenshot('fire')
        guest.key('spc',False)
        guest.key('right',False)
        if play==pixels(guest.out/'fire.png'):
            raise ValueError('Titanium did not produce a second play frame')
        for stage in ('play','fire'):
            frame=pixels(guest.out/(stage+'.png'))
            colors=Counter(zip(frame[::3],frame[1::3],frame[2::3]))
            terrain=colors[(168,87,0)]+colors[(255,255,87)]
            if terrain < 100000:
                raise ValueError(f'Titanium terrain missing from {stage} frame')
            report[stage+'_terrain_pixels']=terrain
        guest.press('esc')
        time.sleep(2)
        guest.screenshot('after-escape')
        if native:
            guest.wait('COMMAND OK\n',45,start)
            guest.command('6*7;')
            report['fresh_arithmetic']=guest.result_pixels()
        else:
            guest.wait('TITANIUM returned\n',45)
        report['result']='pass'
    except Exception as error:
        report.update(result='fail',error=str(error))
        raise
    finally:
        guest.close()
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':
    main()
