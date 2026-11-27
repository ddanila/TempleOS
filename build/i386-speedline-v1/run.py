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

parser = argparse.ArgumentParser()
parser.add_argument('--disk', type=Path)
parser.add_argument('--reference-image', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir(parents=True)
fixture = Path(__file__).with_name('Probe.HC').read_bytes()
demo = Path('Demo/Graphics/Speedline.HC')
native = bool(args.disk)
sha = lambda data: hashlib.sha256(data).hexdigest()
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
if native:
    pack = runpy.run_path('tools/package-i386-native-image.py')
    assert pack['snapshot'](args.disk.read_bytes())[1]['/'+demo.as_posix()][2] == demo.read_bytes()
    image = out/'working.img'
    pack['package'](args.disk, image, additions={'/Probe/Speedline.HC': fixture})
elif args.reference_image:
    image = args.reference_image.resolve()
else:
    overlay = out/'overlay'
    overlay.mkdir()
    pins = runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference'](overlay)
    assert pins[demo.as_posix()] == sha(demo.read_bytes())
    (overlay/'Once.HC').write_bytes(fixture)
    image = out/'original.iso'
    subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),
                    '--output',str(image)],check=True)

guest = Guest(image,out/'guest',native,reference_cpus=1)
report = dict(result='running', demo_sha256=sha(demo.read_bytes()),
              input_sha256=sha(image.read_bytes()), mode='native' if native else 'original',
              scope='Unmodified Speedline demo with two physical mouse speeds, color selection and key exit')

def pointer():
    found = re.findall(r'^COLOR PTR (\d+) (\d+)$',guest.collect(),re.M)
    if not found:
        raise ValueError('Missing pointer sample')
    return tuple(map(int,found[-1]))

def move_to(x,y):
    for _ in range(36):
        px,py = pointer()
        dx,dy = x-px,y-py
        if abs(dx)<=2 and abs(dy)<=2:
            return px,py
        events = [{'type':'rel','data':{'axis':axis,'value':max(-64,min(64,delta))}}
                  for axis,delta in [('x',dx),('y',dy)] if delta]
        guest.call('input-send-event',events=events)
        time.sleep(.11)
    raise ValueError(f'Unable to move to {(x,y)} from {pointer()}')

def button(name,down):
    guest.call('input-send-event',events=[{'type':'btn','data':{'button':name,'down':down}}])
    time.sleep(.15)

def drag(start,delay):
    first=move_to(*start)
    time.sleep(.35)
    button('left',True)
    try:
        for _ in range(10):
            guest.call('input-send-event',events=[{'type':'rel',
                'data':{'axis':'x','value':32}}])
            time.sleep(delay)
        last=pointer()
    finally:
        button('left',False)
    if not 140<=last[0]-first[0]<=176 or abs(last[1]-first[1])>2:
        raise ValueError(f'Unexpected physical stroke endpoints: {first}, {last}')
    return [first,last]

def picture(name):
    guest.screenshot(name)
    with Image.open(guest.out/(name+'.png')) as frame:
        return frame.convert('RGB')

def count_color(frame,box,color):
    return sum(pixel==color for pixel in frame.crop(box).get_flattened_data())

def color_menu():
    deadline = time.monotonic()+15
    while time.monotonic()<deadline:
        pixels = picture('picker').load()
        rows=[]
        for y in range(16,460):
            red=[x for x in range(640) if pixels[x,y]==(168,0,0)]
            if len(red)>60 and red[-1]-red[0]<130:
                rows.append((y,red))
        if rows:
            y,red=rows[len(rows)//2]
            return red[0]+30,y
        time.sleep(.15)
    raise ValueError('Color popup did not draw its red swatch')

try:
    if native:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/Speedline.HC"')
        guest.command('CTask *dw=Spawn(&PalWatch,NULL,"Speedline pointer",,Fs);')
    else:
        guest.wait('SPEEDLINE READY\n')
        time.sleep(2)
        guest.type('CTask *dw=Spawn(&PalWatch,NULL,"Speedline pointer",,Fs);')
        guest.press('ret')
    guest.wait('COLOR PTR ')
    offset=len(guest.collect())
    command=f'ExeFile("{("C" if native else "T")}:/{demo}");'
    if not native:command+='PalLog("SPEEDLINE DONE\\n");'
    guest.type(command)
    guest.press('ret')
    time.sleep(3)
    if 'INPUT REJECT ' in guest.collect()[offset:]:
        raise ValueError(guest.collect()[offset:])
    move_to(600,420)
    initial=picture('start')
    slow_box=(140,130,220,210)
    fast_box=(140,205,220,285)
    red_box=(360,280,440,365)
    assert count_color(initial,slow_box,(0,0,0))==0
    assert count_color(initial,fast_box,(0,0,0))==0
    assert count_color(initial,red_box,(168,0,0))==0
    report['slow_drag']=drag((100,170),.25)
    move_to(600,420)
    report['slow_pixels']=count_color(picture('slow'),slow_box,(0,0,0))
    report['fast_drag']=drag((100,245),.04)
    move_to(600,420)
    after_fast=picture('fast')
    report['fast_pixels']=count_color(after_fast,fast_box,(0,0,0))
    assert report['slow_pixels']>=60
    assert report['fast_pixels']>report['slow_pixels']+160
    button('right',True)
    button('right',False)
    move_to(*color_menu())
    button('left',True)
    button('left',False)
    time.sleep(.8)
    report['red_drag']=drag((320,320),.06)
    move_to(600,420)
    after_red=picture('red')
    report['red_pixels']=count_color(after_red,red_box,(168,0,0))
    assert report['red_pixels']>=100
    assert count_color(after_red,slow_box,(0,0,0))==report['slow_pixels']
    assert count_color(after_red,fast_box,(0,0,0))==report['fast_pixels']
    guest.press('esc')
    guest.wait('COMMAND OK\n' if native else 'SPEEDLINE DONE\n',25,offset)
    time.sleep(.5)
    cleared=picture('cleared')
    assert count_color(cleared,slow_box,(0,0,0))==0
    assert count_color(cleared,fast_box,(0,0,0))==0
    assert count_color(cleared,red_box,(168,0,0))==0
    if native:
        guest.command('Kill(dw);')
        guest.command('6*7;')
        report['fresh_arithmetic']=guest.result_pixels()
    report['result']='pass'
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
