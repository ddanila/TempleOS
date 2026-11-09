#!/usr/bin/env python3
"""Check additional native raw MouseGet API alongside original logical half gain."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT=Path(__file__).resolve().parents[1]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();fixture=ROOT/'tests/guest/i386-mouse-raw-state/Contract.HC'
    if out.exists():ap.error('Use a fresh output directory')
    paths=[args.disk.resolve(),fixture,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ['package-i386-native-image.py','build-i386-kernel.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py']]+[ROOT/'Kernel/FontStd.HC']
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='Additional native raw MouseGet preserves unit movement, packet ordering, both-button transitions, NULL output guards and IRQ state while public logical position follows original0.5 gain. Dedicated document probe/restoration and exact heap, files/fresh42. Does not qualify typing commands while a mouse button is held.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());guest=None
    try:
        pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
        report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/MouseRawState.HC':fixture.read_bytes()})
        before=pack['snapshot'](image.read_bytes())[1]
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];guest=Guest(image,out/'guest',True)
        guest.wait('DONE native kernel startup\n');guest.command('#include "C:/Probe/MouseRawState.HC"')
        guest.type('MouseRawStateContract;');guest.press('ret')
        for phase,event in enumerate([{'type':'rel','data':{'axis':'x','value':24}},'left','right','left','right'],1):
            guest.wait(f'MR READY {phase}\n')
            if phase==1:events=[event,{'type':'rel','data':{'axis':'y','value':16}}]
            else:events=[{'type':'btn','data':{'button':event,'down':phase in [2,3]}}]
            guest.call('input-send-event',events=events)
        guest.wait('MR DONE\n')
        raw=(out/'guest/mouse-raw-state.bin').read_bytes();(out/'mouse-raw-state.bin').write_bytes(raw)
        mask=(out/'guest/mouse-raw-mask.bin').read_bytes();(out/'mouse-raw-mask.bin').write_bytes(mask)
        rows=list(struct.iter_unpack('<8q',raw))
        if len(rows)!=6 or rows[0]!=(320,240,0,0,320,240,0,0):raise ValueError('Raw initial state differs')
        for i,b in enumerate([0,1,3,2,0],1):
            if rows[i][:3]!=(344,256,b) or rows[i][3]<=rows[i-1][3] or rows[i][4:]!=(332,248,b&1,(b>>1)&1):raise ValueError('Raw/logical mouse state differs')
        if mask!=struct.pack('<q',15):raise ValueError('Raw mouse caller/heap/IRQ/NULL mask differs')
        guest.command('6*7;');report['fresh_result']=guest.result_pixels();guest.close();guest=None
        if pack['snapshot'](image.read_bytes())[1]!=before:raise ValueError('Raw mouse changed file bytes/metadata')
        report.update(result='pass',mask=15,rows=rows,files_unchanged=True)
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
