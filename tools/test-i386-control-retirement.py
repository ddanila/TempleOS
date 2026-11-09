#!/usr/bin/env python3
"""Check nested task exit detaches controls after callback recovery and drains child ownership."""
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
    out=args.out.resolve();fixture=ROOT/'tests/guest/i386-control-retirement/Contract.HC'
    if out.exists():ap.error('Use a fresh output directory')
    paths=[args.disk.resolve(),fixture,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ['package-i386-native-image.py','build-i386-kernel.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py']]+[ROOT/'Kernel/FontStd.HC']
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='Nested managed parent/leaf own scroll controls; caller-owned borrowed generic control survives detached with target cleared and state intact. Leaf return, explicit Exit and Kill with recovering end callback preserve controls until committed exit. Parent child lists drain through actual reap; caller heap and file bytes/metadata unchanged. Not full control/mouse/resource qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());guest=None
    try:
        pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
        report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/ControlRetire.HC':fixture.read_bytes()})
        before=pack['snapshot'](image.read_bytes())[1]
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];guest=Guest(image,out/'guest',True)
        guest.wait('DONE native kernel startup\n');guest.command('#include "C:/Probe/ControlRetire.HC"');guest.command('CRContract;')
        raw=(out/'guest/modes.bin').read_bytes();(out/'modes.bin').write_bytes(raw)
        if raw!=struct.pack('<3q',255,255,255):raise ValueError('Control retirement modes differ: '+repr(struct.unpack('<3q',raw)))
        guest.command('6*7;');report['fresh_result']=guest.result_pixels();guest.close();guest=None
        if pack['snapshot'](image.read_bytes())[1]!=before:raise ValueError('Control retirement changed file bytes/metadata')
        report.update(result='pass',masks=[255,255,255],files_unchanged=True)
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
