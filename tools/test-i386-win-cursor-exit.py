#!/usr/bin/env python3
"""Check callback Exit during public WinCursorPosSet releases the parent-owned document lock."""
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
    out=args.out.resolve();fixture=ROOT/'tests/guest/i386-win-cursor-exit/Contract.HC'
    if out.exists():ap.error('Use a fresh output directory')
    paths=[args.disk.resolve(),fixture,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ['package-i386-native-image.py','build-i386-kernel.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py']]+[ROOT/'Kernel/FontStd.HC']
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='Public WinCursorPosSet in a worker, parent-owned shown document: tag callback Exit, no return, actual child reap, lock release, continued document use, caller roles and exact caller heap recovery. Not mouse event delivery or general cursor/error qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());guest=None
    try:
        pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
        report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/WinCursorExit.HC':fixture.read_bytes()})
        before=pack['snapshot'](image.read_bytes())[1]
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];guest=Guest(image,out/'guest',True)
        guest.wait('DONE native kernel startup\n');guest.command('#include "C:/Probe/WinCursorExit.HC"');guest.command('WinCursorExitContract;')
        raw=(out/'guest/cursor-mask.bin').read_bytes();(out/'cursor-mask.bin').write_bytes(raw)
        api=(out/'guest/cursor-api-mask.bin').read_bytes();(out/'cursor-api-mask.bin').write_bytes(api)
        if raw!=struct.pack('<q',255):raise ValueError('Cursor Exit mask differs: '+repr(struct.unpack('<q',raw)))
        if api!=struct.pack('<q',7):raise ValueError('Cursor inactive-target API mask differs: '+repr(struct.unpack('<q',api)))
        guest.command('6*7;');report['fresh_result']=guest.result_pixels();guest.close();guest=None
        if pack['snapshot'](image.read_bytes())[1]!=before:raise ValueError('Cursor Exit changed file bytes/metadata')
        report.update(result='pass',mask=255,api_mask=7,files_unchanged=True)
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
