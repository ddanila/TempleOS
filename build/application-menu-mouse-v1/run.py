import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import sys
import time

parser=argparse.ArgumentParser()
parser.add_argument('image',type=Path,nargs='?')
parser.add_argument('--out',type=Path,required=True)
args=parser.parse_args()
root=Path(__file__).resolve().parent
out=args.out.resolve()
out.mkdir()
fixture=root/'MenuProbe.HC'
runner=Path('tools/test-i386-autocomplete-interaction.py')
packer=Path('tools/package-i386-native-image.py')
reference=Path('tools/test-i386-timeclock-reference.py')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
pins={str(p):sha(p) for p in (fixture,runner,packer,reference,Path(__file__))}
report=dict(result='running',input_sha256=pins,scope='Physical PS/2 drag into the original focus task menu and exact MSG_CMD arguments. No direct task message injection.')
guest=None
try:
    if args.image:
        pins[str(args.image)]=sha(args.image)
        image=out/'working.img'
        runpy.run_path(str(packer))['package'](args.image,image,additions={'/Probe/MenuProbe.HC':fixture.read_bytes()})
    else:
        overlay=out/'overlay'
        runpy.run_path(str(reference))['restore_reference'](overlay)
        (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\nMenuProbe;\n')
        image=out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],check=True)
    Guest=runpy.run_path(str(runner))['Guest']
    guest=Guest(image,out/'guest',bool(args.image))
    if args.image:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/MenuProbe.HC"')
        guest.type('MenuProbe;')
        guest.press('ret')
    guest.wait('MENU ready ',30)
    state=out/'mouse.bin'
    address=int(re.search(r'MENU ready ([0-9A-F]+)\n',guest.collect())[1],16)
    def move(target):
        until=time.monotonic()+12
        while time.monotonic()<until:
            guest.call('pmemsave',val=address,size=24,filename=str(state))
            x,y,_=struct.unpack('<3q',state.read_bytes())
            if (x,y)==target:return
            guest.call('input-send-event',events=[
                {'type':'rel','data':{'axis':'x','value':target[0]-x}},
                {'type':'rel','data':{'axis':'y','value':target[1]-y}}])
            time.sleep(.2)
        raise TimeoutError(f'Target {target} not reached')
    def left(down):
        guest.call('input-send-event',events=[{'type':'btn','data':{'down':down,'button':'left'}}])
    move((20,4))
    guest.screenshot('menu-heading')
    left(True)
    time.sleep(.4)
    move((20,12))
    guest.screenshot('menu-highlight')
    left(False)
    guest.wait('MENU done\n',20)
    response=struct.unpack('<3q',(guest.out/'menu.bin').read_bytes())
    report['response']=response
    assert response==(1,0xA74,0x53),response
    report['result']='pass'
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    if guest:guest.close()
    report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in pins.items())
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
