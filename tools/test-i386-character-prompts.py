#!/usr/bin/env python3
"""Compare public character and confirmation input with original TempleOS."""
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
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--hardware',action='store_true',help='Also inject F1 then a through QEMU while GetChar waits');ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-character-prompts/Contract.HC'
    includes=[]
    paths=includes+[Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if args.disk:paths.append(args.disk.resolve())
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='Twelve original GetChar/YorN/AreYouSure/PressAKey checks using public queued key messages, returned scan code, echoed document text and exact heap recovery; hardware delivery and blocked/raw-cursor input remain separate.');g=None
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
            report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/CharacterPrompts.HC':fixture.read_bytes(),**{'/'+p.name:p.read_bytes() for p in includes}})
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'CharacterPrompts.HC').write_bytes(fixture.read_bytes())
            for p in includes:(overlay/p.name).write_bytes(p.read_bytes())
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n#include "::/CharacterPrompts.HC"\nCPCheck();\n'+(b'CPHardware();\n' if args.hardware else b''))
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/CharacterPrompts.HC"');g.command('CPCheck();')
        deadline=time.monotonic()+180
        while True:
            remaining=deadline-time.monotonic()
            if remaining<=0:raise TimeoutError('Missing guest marker: CHARACTER PROMPTS DONE')
            try:
                g.wait('CHARACTER PROMPTS DONE\n',timeout=min(30,remaining));break
            except TimeoutError:
                g.call('screendump',filename=str(out/'waiting.ppm'))
        expected={'character-prompts.bin':expected_bytes(12)}
        if args.hardware:
            if args.disk:g.type('CPHardware();');g.press('ret')
            g.wait('CHARACTER HARDWARE ready\n')
            g.press('f1');time.sleep(.3)
            if 'CHARACTER HARDWARE DONE\n' in g.collect():
                raise ValueError('GetChar returned for a zero-character key')
            g.press('a');g.wait('CHARACTER HARDWARE DONE\n')
            expected['hardware-character.bin']=struct.pack('<3q',97,30,1)
            report['hardware_scope']='QEMU F1 is skipped, a returns ASCII97/scan30, and waiting clears TASKf_IDLE; raw/debug cursor remains unqualified'

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
