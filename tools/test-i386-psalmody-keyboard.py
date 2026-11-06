#!/usr/bin/env python3
"""Drive original/native Psalmody recording, deletion and abort with QEMU keys."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]
NAMES=('notes.bin','deleted.bin','mask.bin')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(records):
    notes,deleted,mask=records
    expected=[3,1,63,8,0,1,65,8,0,1,67,8,0]
    if notes!=struct.pack('<13q',*expected):raise ValueError('Recorded notes differ: '+repr(struct.unpack('<13q',notes)))
    if deleted!=struct.pack('<9q',2,*expected[1:9]):raise ValueError('Backspace survivors differ')
    if mask!=struct.pack('<q',63):raise ValueError('Caller restoration differs: '+repr(mask))

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    if args.disk and not args.reference:ap.error('Native requires original reference')
    fixture=ROOT/'tests/guest/i386-psalmody-keyboard/Contract.HC'
    paths=[Path(__file__).resolve(),fixture,ROOT/'docs/i386-compatibility-inventory.json',ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if args.disk:
        gold=args.reference.resolve();info=json.loads((gold/'result.json').read_text())
        if info.get('result')!='pass' or not info.get('inputs_unchanged') or info.get('fixture_sha256')!=sha(fixture):raise ValueError('Matching original control required')
        paths += [args.disk.resolve(),gold/'result.json']+[gold/n for n in NAMES]
    out.mkdir();pins={str(p):sha(p) for p in paths};g=None
    report=dict(result='running',fixture_sha256=sha(fixture),input_sha256=pins,scope='Full Psalmody keyboard record C5/D5/E5 with 0.4-second holds, exact note vectors, backspace deletion and Shift-Escape caller restoration. Not audio, playback, persistence or whole application qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));before=pack['snapshot'](args.disk.read_bytes())[1]
            for entry in json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())['entries']:
                if entry['path'].startswith('Apps/Psalmody/') and hashlib.sha256(before['/'+entry['path']][2]).hexdigest()!=entry['reference_sha256']:
                    raise ValueError('Psalmody source differs: '+entry['path'])
            image=out/'working.img';report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/PsalmodyKeyboard.HC':fixture.read_bytes()})
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n#include "T:/Apps/Psalmody/Load.HC"\n'+fixture.read_bytes()+b'\nPsalmodyKeyboard;\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n')
            providers = [
                'AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);',
                'AdamFile("C:/Adam/TaskSettings.HC",FALSE);',
                '#include "C:/Adam/Opt/Utils/Find.HC"',
                '#include "C:/Adam/God/GodExt.HC"',
                '#include "C:/Adam/God/GodBible.HC"',
                '#include "C:/Adam/God/HolySpirit.HC"',
                '#include "C:/Adam/God/GodSong.HC"',
                '#include "C:/Apps/Psalmody/Load.HC"',
                '#include "C:/Probe/PsalmodyKeyboard.HC"',
            ]
            report['native_provider_commands'] = providers
            for command in providers:g.command(command)
            g.type('PsalmodyKeyboard;');g.press('ret')
        g.wait('PS ready\n');time.sleep(2);g.screenshot('ready');g.press('z');g.wait('PS recording\n',30)
        for i,key in enumerate(['h','j','k'],1):
            g.key(key,True);time.sleep(.4);g.key(key,False);g.wait(f'PS note {i}\n',30)
        g.screenshot('recorded');g.press('backspace');g.wait('PS deleted\n',30);g.screenshot('deleted')
        g.key('shift',True);g.press('esc');g.key('shift',False);g.wait('PS done\n',30)
        records=[(g.out/n).read_bytes() for n in NAMES]
        for n,v in zip(NAMES,records):(out/n).write_bytes(v)
        verify(records)
        if args.disk:
            if records!=[(gold/n).read_bytes() for n in NAMES]:raise ValueError('Original vectors differ')
            g.wait('COMMAND OK\n',start=g.collect().index('INPUT LINE PsalmodyKeyboard;'));g.command('6*7;');g.result_pixels()
        g.close();g=None
        if args.disk:
            after=pack['snapshot'](image.read_bytes())[1];changed={n for n in set(before)|set(after) if before.get(n)!=after.get(n)}
            if changed!={'/Probe/PsalmodyKeyboard.HC'}:raise ValueError('Unexpected file changes: '+repr(changed))
            report['preserved_files']=len(before);report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report.update(result='pass',mask=63,notes=list(struct.unpack('<13q',records[0])))
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
