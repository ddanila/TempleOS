#!/usr/bin/env python3
"""Compare actual ATAPI DVD image reads and non-optical write rejection with original TempleOS."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import struct
import time

ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def expected_bytes(count=12):
    return struct.pack(f"<{count}q",*([1]*count))

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-dvd-image/Contract.HC'
    includes=[]
    probe_bytes=bytes((i*13+5)%256 for i in range(133120))
    paths=includes+[Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if args.disk:paths.append(args.disk.resolve())
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='Eight checks: actual QEMU ATAPI reads on a manually configured secondary-slave DVD, exact 133120 bytes across three copy batches, lock/flag state and non-optical writer rejection. Discovery, successful burning and public heap cleanup remain unqualified.');g=None
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
            report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/DVDImage.HC':fixture.read_bytes(),**{'/'+p.name:p.read_bytes() for p in includes}})
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'DVDImage.HC').write_bytes(fixture.read_bytes())
            for p in includes:(overlay/p.name).write_bytes(p.read_bytes())
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n#include "::/DVDImage.HC"\nDVDCheck(66);\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        probe=out/'probe.iso';probe.write_bytes(probe_bytes)
        helper=ROOT/'tools/test-i386-autocomplete-interaction.py';source=helper.read_text()
        anchor="        (out/'command.json').write_text"
        if source.count(anchor)!=1:raise ValueError('Review Guest command instrumentation')
        source=source.replace(anchor,"        cmd += ['-drive', 'file='+str(_dvd_probe)+',format=raw,media=cdrom,if=ide,index=3']\n"+anchor)
        ns={'__name__':'dvd_image_guest','__file__':str(helper),'_dvd_probe':probe}
        exec(compile(source,str(helper),'exec'),ns)
        g=ns['Guest'](image,out/'guest',bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/DVDImage.HC"');g.command('DVDCheck(67);')
        deadline=time.monotonic()+180
        while True:
            remaining=deadline-time.monotonic()
            if remaining<=0:raise TimeoutError('Missing guest marker: DVD IMAGE DONE')
            try:
                g.wait('DVD IMAGE DONE\n',timeout=min(30,remaining));break
            except TimeoutError:
                g.call('screendump',filename=str(out/'waiting.ppm'))
        expected={'dvd-checks.bin':expected_bytes(8),'dvd-read.bin':probe_bytes,'dvd-after-reject.bin':probe_bytes}
        for name,want in expected.items():
            actual=(g.out/name).read_bytes();(out/name).write_bytes(actual)
            if actual!=want:raise ValueError(name+' differs from independent byte oracle')
        if args.disk:g.command('6*7;');g.result_pixels()
        report.update(result='pass',cases_checked=1,
                      table_sha256={n:hashlib.sha256(v).hexdigest() for n,v in expected.items()})
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        if g:g.call('screendump',filename=str(out/'failure.ppm'))
        raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
