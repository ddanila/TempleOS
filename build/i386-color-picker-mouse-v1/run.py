import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys
import time

from PIL import Image

parser=argparse.ArgumentParser()
parser.add_argument('--disk',type=Path)
parser.add_argument('--original-image',type=Path)
parser.add_argument('--out',type=Path,required=True)
args=parser.parse_args()
out=args.out.resolve()
out.mkdir(parents=True)
fixture=Path(__file__).with_name('Probe.HC').read_bytes()
native=bool(args.disk)
Guest=runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
vision=runpy.run_path('build/i386-demo-define-v1/qualify.py')
font=vision['glyphs'](Path('Kernel/FontStd.HC'))
if native:
    image=out/'working.img'
    pack=runpy.run_path('tools/package-i386-native-image.py')
    pack['package'](args.disk,image,additions={'/Probe/Color.HC':fixture})
elif args.original_image:
    image=args.original_image.resolve()
else:
    overlay=out/'overlay'
    overlay.mkdir()
    runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference'](overlay)
    (overlay/'Once.HC').write_bytes(fixture)
    image=out/'original.iso'
    subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),
                    '--output',str(image)],check=True)
guest=Guest(image,out/'guest',native,reference_cpus=1)
report=dict(result='running',scope='Color picker choices through physical mouse and keyboard',
            input_sha256=hashlib.sha256(image.read_bytes()).hexdigest())

def find_label(phase):
    # The RED swatch is a single 8-pixel row. The special options are
    # immediately before BLACK and after WHITE when enabled.
    offsets={'BASIC':0,'TRANSPARENT':-40,'DEFAULT':96,'CANCEL':0}
    headers={'BASIC':'Choose a basic color','TRANSPARENT':'Choose transparency',
             'DEFAULT':'Choose default','CANCEL':'Cancel the picker'}
    deadline=time.monotonic()+10
    while time.monotonic()<deadline:
        guest.screenshot(phase.lower())
        screenshot=guest.out/(phase.lower()+'.png')
        if not vision['matches'](screenshot,headers[phase],font):
            time.sleep(.1)
            continue
        with Image.open(screenshot) as frame:
            pixels=frame.convert('RGB').load()
            rows=[]
            for y in range(16,464):
                red=[x for x in range(640) if pixels[x,y]==(168,0,0)]
                if len(red)>60 and red[-1]-red[0]<130:
                    rows.append((y,red))
            if rows:
                y,red=rows[len(rows)//2]
                return red[0]+30,y+offsets[phase]
        time.sleep(.1)
    raise ValueError('Missing the red menu swatch')

def pointer():
    found=re.findall(r'^COLOR PTR (\d+) (\d+)$',guest.collect(),re.M)
    if not found:
        raise ValueError('Missing pointer observation')
    return tuple(map(int,found[-1]))

def move_to(x,y):
    for _ in range(28):
        mx,my=pointer()
        dx,dy=x-mx,y-my
        if abs(dx)<=2 and abs(dy)<=2:
            return
        events=[{'type':'rel','data':{'axis':axis,'value':max(-50,min(50,delta))}}
                for axis,delta in [('x',dx),('y',dy)] if delta]
        guest.call('input-send-event',events=events)
        time.sleep(.18)
    raise ValueError(f'Pointer did not reach {(x,y)}: {pointer()}')

def click():
    for down in (True,False):
        guest.call('input-send-event',events=[{'type':'btn','data':{'button':'left','down':down}}])
        time.sleep(.12)
try:
    if native:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/Color.HC"')
    else:
        guest.wait('COLOR READY\n')
        time.sleep(2)
    start=len(guest.collect())
    guest.type('PalProbe;')
    guest.press('ret')
    phases=('BASIC','TRANSPARENT','DEFAULT','CANCEL')
    report['selections']={}
    report['positions']={}
    for phase in phases:
        guest.wait('COLOR '+phase+' BEGIN\n',20,start)
        x,y=find_label(phase)
        report['positions'][phase]=[x,y]
        move_to(x,y)
        if phase=='CANCEL':
            guest.key('shift',True)
            guest.press('esc')
            guest.key('shift',False)
        else:
            click()
        deadline=time.monotonic()+15
        while time.monotonic()<deadline:
            log=guest.collect()[start:]
            match=re.search(r'^COLOR '+phase+r' (-?\d+)$',log,re.M)
            if match:
                report['selections'][phase]=int(match[1])
                break
            time.sleep(.12)
        else:
            raise ValueError(log[-800:])
    guest.wait('COLOR DONE\n',20,start)
    if native:
        guest.wait('COMMAND OK\n',20,start)
        guest.command('6*7;')
        report['fresh_arithmetic']=guest.result_pixels()
    assert report['selections']=={'BASIC':4,'TRANSPARENT':255,'DEFAULT':-2147483648,'CANCEL':-1}
    report['result']='pass'
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
