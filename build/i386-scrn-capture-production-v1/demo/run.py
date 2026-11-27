from pathlib import Path
import hashlib,json,runpy,time
from collections import Counter,defaultdict
from PIL import Image

out=Path(__file__).resolve().parent
source=out.parent/'cross/kernel.img'
host_demo=Path('Demo/Graphics/ScrnCapture.HC').read_bytes()
sha=lambda data:hashlib.sha256(data).hexdigest()
pack=runpy.run_path('tools/package-i386-native-image.py')
assert pack['snapshot'](source.read_bytes())[1]['/Demo/Graphics/ScrnCapture.HC'][2]==host_demo
image=out/'working.img'
pack['package'](source,image,additions={'/Probe/Capture.HC': (out/'Capture.HC').read_bytes()})
Guest=runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
vision=runpy.run_path('build/i386-demo-define-v1/qualify.py')
font=vision['glyphs'](Path('Kernel/FontStd.HC'))
guest=Guest(image,out/'guest',True)
def caption(name,text,offset):
    deadline=time.monotonic()+25
    while time.monotonic()<deadline:
        log=guest.collect()[offset:]
        if 'INPUT REJECT' in log:raise ValueError(log)
        guest.screenshot(name)
        if vision['matches'](guest.out/(name+'.png'),text,font):return
        time.sleep(.3)
    raise TimeoutError(text)
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/Probe/Capture.HC"')
    offset=len(guest.collect())
    guest.type('#include "C:/Demo/Graphics/ScrnCapture.HC"')
    guest.press('ret')
    caption('capture','Capture scrn...',offset)
    guest.press('spc')
    caption('view','View captured scrn...',offset)
    guest.press('spc')
    time.sleep(2)
    guest.screenshot('replay')
    guest.press('spc')
    guest.wait('COMMAND OK\n',25,offset)
    guest.command('CaptureVerify;')
    guest.command('6*7;')
    arithmetic=guest.result_pixels()
    saved=(guest.out/'saved-scrn.raw').read_bytes()
    assert len(saved)==307200 and 2<len(set(saved))<=16 and max(saved)<16
    def pixels(name):
        return Image.open(guest.out/(name+'.png')).convert('RGB').get_flattened_data()
    counts=defaultdict(Counter)
    for index,color in zip(saved,pixels('capture'),strict=True):counts[index][color]+=1
    palette={index:c.most_common(1)[0][0] for index,c in counts.items()}
    matches=sum(palette[index]==color for index,color in zip(saved,pixels('replay'),strict=True))
    assert matches>=306000,matches
    (out/'result.json').write_text(json.dumps(dict(result='pass',
        scope='Unmodified bundled demo using the installed native capture services',
        source_sha256=sha(host_demo),disk_sha256=sha(source.read_bytes()),
        overlay_sha256=sha((out/'Capture.HC').read_bytes()),matches=matches,
        size=len(saved),bitmap_sha256=sha(saved),fresh_arithmetic=arithmetic),indent=2)+'\n')
finally:
    guest.close()
