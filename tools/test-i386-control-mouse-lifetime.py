#!/usr/bin/env python3
"""Check control callback throw/Exit and owner retirement recover the managed worker."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import re
import time

ROOT=Path(__file__).resolve().parents[1]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();fixture=ROOT/'tests/guest/i386-control-mouse-lifetime/Contract.HC'
    if out.exists():ap.error('Use a fresh output directory')
    paths=[args.disk.resolve(),fixture,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ['package-i386-native-image.py','build-i386-kernel.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py']]+[ROOT/'Kernel/FontStd.HC']
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='Physical captured-control click: throw, recovering Exit, committed Exit with end callback explicitly cleared, and owner retirement during yielding callbacks with recovering/committed cancellation. Worker recovery/frame progress, child reap, borrowed control detach/canary and exact controller heap recovery. Not arbitrary explicit Free during callbacks or all input lifetime qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());guest=None
    try:
        pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
        report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/ControlMouseLife.HC':fixture.read_bytes()})
        before=pack['snapshot'](image.read_bytes())[1]
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];guest=Guest(image,out/'guest',True)
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/ControlMouseLife.HC"')
        guest.type('ControlMouseLifetimeRun;');guest.press('ret')
        for mode in range(5):
            guest.wait(f'CL READY {mode}\n')
            name=f'control-life-target-{mode}.bin';raw=(out/'guest'/name).read_bytes();(out/name).write_bytes(raw)
            window=(out/'guest'/f'control-life-window-{mode}.bin').read_bytes();(out/f'control-life-window-{mode}.bin').write_bytes(window)
            flags,inhibit,focus,inside=struct.unpack('<4q',window)
            if flags&3!=3 or inhibit&0x40005 or (focus,inside)!=(1,1):raise ValueError('Control lifetime fixture is not an admitted focused managed window')
            target=struct.unpack('<2q',raw);deadline=time.monotonic()+15
            while time.monotonic()<deadline:
                address=int(re.findall(r'CL STATE ([0-9A-F]+)\n',guest.collect())[-1],16)
                p=out/'guest/mouse-state.bin';guest.call('pmemsave',val=address,size=24,filename=str(p));x,y,b=struct.unpack('<3q',p.read_bytes())
                if (x,y)==target:break
                guest.call('input-send-event',events=[{'type':'rel','data':{'axis':'x','value':target[0]-x}},{'type':'rel','data':{'axis':'y','value':target[1]-y}}])
                # Wait for the scheduled observer before another correction.
                # The target is logical; physical gain is not assumed to be one.
                time.sleep(.75)
            else:raise TimeoutError('Pointer did not reach control')
            guest.call('input-send-event',events=[{'type':'btn','data':{'button':'left','down':True}}])
            guest.wait(f'CL ENTER {mode}\n',30)
            guest.call('input-send-event',events=[{'type':'btn','data':{'button':'left','down':False}}])
        guest.wait('CL DONE\n',60)
        raw=(out/'guest/control-life-masks.bin').read_bytes();(out/'control-life-masks.bin').write_bytes(raw)
        if raw!=struct.pack('<5q',255,255,255,255,255):raise ValueError('Control lifetime masks differ: '+repr(struct.unpack('<5q',raw)))
        guest.command('6*7;');report['fresh_result']=guest.result_pixels();guest.close();guest=None
        if pack['snapshot'](image.read_bytes())[1]!=before:raise ValueError('Control lifetime changed file bytes/metadata')
        report.update(result='pass',masks=[255]*5,files_unchanged=True)
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        if guest is not None and guest.p.poll() is None:
            try:
                guest.call('stop');guest.collect();registers=guest.call('human-monitor-command',**{'command-line':'info registers'});(out/'failure-registers.txt').write_text(registers)
                guest.call('pmemsave',val=0,size=64*1024*1024,filename=str(out/'failure-memory.bin'))
                report['failure_capture']={'memory_sha256':sha(out/'failure-memory.bin'),'registers_sha256':sha(out/'failure-registers.txt')}
            except Exception as err:report['capture_error']=str(err)
        raise
    finally:
        if guest is not None:guest.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
