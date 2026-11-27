import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import time

from PIL import Image

out = Path(__file__).resolve().parent
native = sys.argv[1] == 'native'
mode = 'native' if native else 'original'
demo = Path('Demo/Games/Stadium/Stadium.HC')
bitmap = demo.with_name('StadiumBG.GR')
sha = lambda data: hashlib.sha256(data).hexdigest()
disk = Path('build/i386-stadium-capture-v2/cross/kernel.img')
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
font = runpy.run_path('build/i386-demo-define-v1/qualify.py')['glyphs'](Path('Kernel/FontStd.HC'))
if native:
    files = runpy.run_path('tools/package-i386-native-image.py')['snapshot'](disk.read_bytes())[1]
    for path in (demo, bitmap):
        assert files['/'+path.as_posix()][2] == path.read_bytes()
    image = out / 'working.img'
    shutil.copyfile(disk,image)
else:
    overlay = out / 'original-source'
    overlay.mkdir()
    hashes = runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference'](overlay)
    for path in (demo, bitmap):
        assert hashes[path.as_posix()] == sha(path.read_bytes())
    (overlay/'Once.HC').write_text(
        'U0 StadiumLog(U8 *s){while(*s)OutU8(0xE9,*s++);}\n'
        'StadiumLog("STADIUM GAME READY\\n");\n'
    )
    image = out/'original.iso'
    subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),
                    '--output',str(image)],check=True)
guest = Guest(image,out/mode,native,reference_cpus=1)
report = dict(result='running',source_sha256=sha(demo.read_bytes()),
              background_sha256=sha(bitmap.read_bytes()),input_sha256=sha(image.read_bytes()),
              scope='Unmodified Stadium game with physical mouse, restart, and Escape input')
red = (168,0,0)
label = b'Peg the Fans'
ink = [(i*8+x,y) for i,c in enumerate(label)
       for y,mask in enumerate(font[c]) for x in range(8) if mask & (1 << x)]
def wait_title(start):
    deadline = time.monotonic()+40
    while time.monotonic() < deadline:
        log=guest.collect()[start:]
        if 'INPUT REJECT ' in log:
            raise ValueError(log)
        guest.screenshot('title')
        with Image.open(guest.out/'title.png') as frame:
            pixels=frame.convert('RGB').load()
            for y in range(0,65):
                for x in range(0,160):
                    if all(pixels[x+dx,y+dy]==red for dx,dy in ink):
                        return x,y
        time.sleep(.25)
    raise TimeoutError('Stadium title not drawn')
def capture(name):
    guest.screenshot(name)
    with Image.open(guest.out/(name+'.png')) as frame:
        return frame.convert('RGB')
def changed(a,b,box):
    return sum(x!=y for x,y in zip(a.crop(box).get_flattened_data(),
                                  b.crop(box).get_flattened_data(),strict=True))
try:
    guest.wait('DONE native kernel startup\n' if native else 'STADIUM GAME READY\n')
    time.sleep(2)
    start=len(guest.collect())
    command=f'ExeFile("{("C" if native else "T")}:/{demo}");'
    if not native:command+='StadiumLog("STADIUM GAME DONE\\n");'
    guest.type(command)
    guest.press('ret')
    title_x,title_y=wait_title(start)
    report['title']=[title_x,title_y]
    first=capture('fans-before')
    time.sleep(.6)
    second=capture('fans-after')
    report['fan_region_pixels_changed']=changed(first,second,(0,title_y+20,640,title_y+110))
    assert report['fan_region_pixels_changed']>5
    guest.call('input-send-event',events=[{'type':'rel','data':{'axis':'x','value':10}},
                                         {'type':'rel','data':{'axis':'y','value':-35}}])
    time.sleep(.6)
    baseline=capture('pitch-before')
    guest.call('input-send-event',events=[{'type':'btn','data':{'button':'left','down':True}}])
    hits=[]
    try:
        for i in range(7):
            frame=capture(f'pitch-{i}')
            hits.append(changed(baseline,frame,(80,180,600,455)))
    finally:
        guest.call('input-send-event',events=[{'type':'btn','data':{'button':'left','down':False}}])
    report['pitch_region_pixels_changed']=hits
    assert max(hits)>8
    guest.press('ret')
    time.sleep(.4)
    restarted=capture('restart')
    report['restart_fan_region_pixels_changed']=changed(second,restarted,(0,title_y+20,640,title_y+110))
    assert report['restart_fan_region_pixels_changed']>5
    guest.press('esc')
    guest.wait('COMMAND OK\n' if native else 'STADIUM GAME DONE\n',25,start)
    if native:
        guest.command('6*7;')
        report['fresh_arithmetic']=guest.result_pixels()
    report['result']='pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    guest.close()
    (out/(mode+'-result.json')).write_text(json.dumps(report,indent=2)+'\n')
