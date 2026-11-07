#!/usr/bin/env python3
"""Compare unflagged DocEd typing, exit, state and client rendering with the original."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import time
from PIL import Image, ImageChops

ROOT=Path(__file__).resolve().parents[1]
RECT=(8,16,632,472)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def client(path,stage):
    im=Image.open(path).convert('RGB').crop(RECT)
    #Only the known caret cell may blink. Serialized text/cursor is checked too.
    im.paste((255,255,255),(stage*8,0,stage*8+8,8))
    return im

def capture(g,name,stage):
    deadline=time.monotonic()+30;started=time.monotonic();previous=None;previous_im=None;stable=0;trace=[];saved=set()
    while time.monotonic()<deadline:
        g.screenshot(name);im=client(g.out/(name+'.png'),stage);raw=im.tobytes()
        digest=hashlib.sha256(raw).hexdigest()
        bbox=ImageChops.difference(im,previous_im).getbbox() if previous_im is not None else None
        trace.append({'sha256':digest,'difference_bbox':bbox})
        (g.out/(name+'-capture-trace.json')).write_text(json.dumps(trace,indent=2)+'\n')
        if digest not in saved and len(saved)<8:
            im.save(g.out/(name+f'-candidate-{len(saved)}.png'));saved.add(digest)
        stable=stable+1 if raw==previous else 0;previous=raw;previous_im=im.copy()
        if time.monotonic()-started>=1 and stable>=2:
            im.save(g.out/(name+'-client.png'));return raw
        time.sleep(.15)
    raise TimeoutError('Editor client did not settle: '+name)

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path)
    ap.add_argument('--dont-home',action='store_true',help='Control through the existing flagged editor path; fixture already starts at DocTop')
    ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    invocation='NECheck(DOF_DONT_HOME);' if args.dont_home else 'NECheck;'
    if out.exists():ap.error('Use a fresh output directory')
    if args.disk and not args.reference:ap.error('Native run requires an inspected original reference')
    fixture=ROOT/'tests/guest/i386-doced-normal/Contract.HC'
    paths=[Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ('test-i386-autocomplete-interaction.py','test-i386-timeclock-reference.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py')]
    libraries=['Adam/AutoComplete/MakeAC.HC','Adam/AutoComplete/ACFill.HC','Adam/AutoComplete/ACTask.HC','Adam/AutoComplete/ACInit.HC','Adam/TaskSettings.HC','Adam/TaskSettingsCore.HC'] if args.disk else []
    paths += [ROOT/name for name in libraries]
    names=[f'normal-{case}-{stage}' for case in range(2) for stage in range(2)]
    if args.disk:
        paths.append(args.disk.resolve());ref=args.reference.resolve()
        rr=json.loads((ref/'result.json').read_text());audit=json.loads((ref/'visual-audit.json').read_text())
        if rr['result']!='pass' or not rr['inputs_unchanged'] or audit['result']!='pass' or rr.get('dont_home',False)!=args.dont_home:raise ValueError('Unqualified original reference')
        paths += [ref/'result.json',ref/'visual-audit.json']
        for name in names:
            p=ref/'guest'/(name+'-client.png')
            if audit['client_sha256'][p.name]!=sha(p):raise ValueError('Original client image changed')
            paths.append(p)
    out.mkdir();pins={str(p):sha(p) for p in paths}
    report=dict(result='running',dont_home=args.dont_home,input_sha256=pins,scope=('DOF_DONT_HOME control. ' if args.dont_home else 'Unflagged editor. ')+'Two DocEd sessions: real Z typing, Escape/Shift-Escape, editor border/title/parent/roles/locks, serialized text/cursor and fixed-geometry focused client raster excluding one caret cell, with autocomplete disabled/restored through its public API, child windows kept behind and the mouse moved outside the client. No save/reboot, full shortcuts, heap or default-geometry qualification.',client_rect=list(RECT),compared_pixels=624*456-64)
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None
    try:
        additions={'/Probe/NormalEdit.HC':fixture.read_bytes()}
        if args.disk:
            image=out/'working.img';pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));before=pack['snapshot'](args.disk.read_bytes())[1]
            for name in libraries:
                if before['/'+name][2]!=(ROOT/name).read_bytes():raise ValueError('Delivered library differs: '+name)
            report['packaging']=pack['package'](args.disk.resolve(),image,additions=additions)
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\n'+invocation.encode()+b'\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n')
            report['library_commands']=['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);']
            for command in report['library_commands']:g.command(command)
            g.command('#include "C:/Probe/NormalEdit.HC"');g.type(invocation);g.press('ret')
        differences={}
        for case in range(2):
            for stage in range(2):
                g.wait(f'NORMAL EDIT READY {case} {stage}\n',timeout=180)
                g.call('input-send-event',events=[{'type':'rel','data':{'axis':'x','value':2000}},{'type':'rel','data':{'axis':'y','value':2000}}])
                name=f'normal-{case}-{stage}';pixels=capture(g,name,stage)
                if args.disk:
                    wanted=Image.open(ref/'guest'/(name+'-client.png')).convert('RGB').tobytes()
                    differences[name]=sum(pixels[i:i+3]!=wanted[i:i+3] for i in range(0,len(pixels),3))
                if not stage:g.type('Z')
            if case:g.key('shift',True)
            g.press('esc')
            if case:g.key('shift',False)
            g.wait(f'NORMAL EDIT RETURN {case}\n')
        g.wait('NORMAL EDIT DONE\n')
        exports={}
        for f in ('normal-active.bin','normal-return.bin','normal-edit-0.bin','normal-edit-1.bin'):
            data=(g.out/f).read_bytes();(out/f).write_bytes(data);exports[f]=data
        report['active']=list(struct.unpack('<4q',exports['normal-active.bin']))
        report['returned']=list(struct.unpack('<2q',exports['normal-return.bin']))
        report['text_hex']=[exports[f'normal-edit-{i}.bin'].hex() for i in range(2)]
        report['pixel_differences']=differences
        if args.disk:g.command('6*7;');report['arithmetic_pixels']=g.result_pixels()
        g.close();g=None
        if args.disk:
            after=pack['snapshot'](image.read_bytes())[1]
            if set(after)!=set(before)|set(additions) or any(after[n]!=v for n,v in before.items()) or any(after[n][2]!=v for n,v in additions.items()):raise ValueError('Unexpected filesystem mutation')
            report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        if report['active']!=[127]*4 or report['returned']!=[127]*2 or any(exports[f'normal-edit-{i}.bin']!=b'Z\x05First\nSecond\n' for i in range(2)) or any(differences.values()):
            raise ValueError('Normal editor differs: '+repr((report['active'],report['returned'],report['text_hex'],differences)))
        report['result']='pass'
    except BaseException as exc:report.update(result='fail',error=type(exc).__name__+': '+str(exc));raise
    finally:
        if g:
            try:g.close()
            except Exception as exc:report.update(result='fail',cleanup_error=str(exc))
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
