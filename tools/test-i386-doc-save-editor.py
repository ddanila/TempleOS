#!/usr/bin/env python3
"""Exercise physical save/autosave shortcuts through the original-body editor route."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-doc-save-editor/Contract.HC'
    paths=[Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/'tools'/n for n in ('test-i386-autocomplete-interaction.py','test-i386-timeclock-reference.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py')]
    if args.disk:paths.append(args.disk.resolve())
    out.mkdir();pins={str(p):sha(p) for p in paths};g=None
    report=dict(result='running',input_sha256=pins,scope='Physical Z, Ctrl-S, two Shift-Ctrl-S and Escape through DocEd(DOF_DONT_HOME); exact saved text/cursor, autosave toggles, caller roles/lock and native reboot. No default-editor migration, timed autosave, heap or visual qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
            before=pack['snapshot'](args.disk.read_bytes())[1]
            if '/SaveEditor.TXT' in before:raise ValueError('Save destination already exists')
            additions={'/Probe/SaveEditor.HC':fixture.read_bytes()}
            report['packaging']=pack['package'](args.disk.resolve(),image,additions=additions)
        else:
            overlay=out/'overlay';overlay.mkdir()
            report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\nSECheck("B:/SaveEditor.TXT");\nSEReopen("B:/SaveEditor.TXT");\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n');g.command('#include "C:/Probe/SaveEditor.HC"')
            g.type('SECheck("C:/SaveEditor.TXT");');g.press('ret')
        for stage in range(5):
            g.wait(f'SAVE EDITOR READY {stage}\n');g.screenshot(f'stage-{stage}')
            if stage==0:g.type('Z')
            elif stage==4:g.press('esc')
            else:
                g.key('ctrl',True)
                if stage>1:g.key('shift',True)
                g.press('s')
                if stage>1:g.key('shift',False)
                g.key('ctrl',False)
        g.wait('SAVE EDITOR DONE\n')
        for name in ('save-editor-text.bin','save-editor-mask.bin'):(out/name).write_bytes((g.out/name).read_bytes())
        report['mask']=struct.unpack('<q',(out/'save-editor-mask.bin').read_bytes())[0]
        report['text_hex']=(out/'save-editor-text.bin').read_bytes().hex()
        if args.disk:
            g.wait('COMMAND OK\n',start=g.log.read_text().index('INPUT LINE SECheck'))
            g.command('6*7;');report['arithmetic_pixels']=g.result_pixels()
        else:
            g.wait('SAVE EDITOR REOPEN DONE\n')
            data=(g.out/'save-editor-reopen.bin').read_bytes();(out/'save-editor-reopen.bin').write_bytes(data)
            if data!=b'Z\x05Keep\n':raise ValueError('Original saved bytes differ')
        g.close();g=None
        if report['mask']!=63 or (out/'save-editor-text.bin').read_bytes()!=b'Z\x05Keep\n':raise ValueError('Editor save state differs')
        if args.disk:
            after=pack['snapshot'](image.read_bytes())[1]
            expected=dict(additions);expected['/SaveEditor.TXT']=b'Z\x05Keep\n'
            if set(after)!=set(before)|set(expected) or any(after[n]!=v for n,v in before.items()) or any(after[n][2]!=v for n,v in expected.items()):raise ValueError('Saved filesystem differs')
            report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
            g=Guest(image,out/'reboot',True);g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/SaveEditor.HC"');g.command('SEReopen("C:/SaveEditor.TXT");')
            data=(g.out/'save-editor-reopen.bin').read_bytes();(out/'save-editor-reopen.bin').write_bytes(data)
            if data!=b'Z\x05Keep\n':raise ValueError('Reboot saved bytes differ')
            g.command('6*7;');report['reboot_arithmetic_pixels']=g.result_pixels();g.close();g=None
            if pack['snapshot'](image.read_bytes())[1]!=after:raise ValueError('Reboot changed files')
            report['reboot_filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report['result']='pass'
    except BaseException as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if g:
            try:g.close()
            except Exception as exc:report.update(result='fail',cleanup_error=str(exc))
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
