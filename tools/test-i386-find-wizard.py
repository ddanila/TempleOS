#!/usr/bin/env python3
"""Compare real FindWiz acceptance, directory choice and interactive result task."""
import argparse
import hashlib
import json
from pathlib import Path
import re
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
    fixture=ROOT/'tests/guest/i386-find-wizard/Contract.HC'
    originals={}
    for name in ['Adam/Opt/Utils/Find.HC','Adam/ABlkDev/FileMgr.HC']:
        originals[name]=subprocess.check_output(['git','show','c26482bb6ad3f80106d28504ec5db3c6a360732c:'+name],cwd=ROOT)
        if (ROOT/name).read_bytes()!=originals[name]:raise ValueError('Original source changed: '+name)
    libraries=['Adam/AutoComplete/MakeAC.HC','Adam/AutoComplete/ACFill.HC','Adam/AutoComplete/ACTask.HC','Adam/AutoComplete/ACInit.HC','Adam/TaskSettings.HC','Adam/TaskSettingsCore.HC']
    paths=[Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/n for n in originals]+[ROOT/n for n in libraries]+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if args.disk:paths.append(args.disk.resolve())
    out.mkdir();pins={str(p):sha(p) for p in paths};g=None
    report=dict(result='running',input_sha256=pins,scope='Shift-Ctrl-F public dispatch: edited FindWiz form acceptance, real directory picker cancel/accept, DocPut rather than explicit argument, exact search fields/caller roles/lock/directory, recursive case-sensitive whole-label search with quoted needle, filemask exclusion, actual file/line links and interactive result task arithmetic/closure. Programmatic form fields, host picker input; no physical Shift-Ctrl-F, replacement, heap or visual equivalence claim.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        additions={'/Probe/FindWizard.HC':fixture.read_bytes(),'/Probe/WizardScope/A.TXT':b'n"eedle one\nN"EEDLE mixed\nn"eedlex\n','/Probe/WizardScope/Nested/B.TXT':b'n"eedle two\n','/Probe/WizardScope/Skip.BIN':b'n"eedle excluded\n'}
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';before=pack['snapshot'](args.disk.read_bytes())[1]
            for n,b in originals.items():
                if before['/'+n][2]!=b:raise ValueError('Delivered original differs: '+n)
            for n in libraries:
                if before['/'+n][2]!=(ROOT/n).read_bytes():raise ValueError('Delivered library differs: '+n)
            report['packaging']=pack['package'](args.disk.resolve(),image,additions=additions)
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            for n,b in additions.items():
                p=overlay/n.lstrip('/');p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\nFWCheck("T:/Probe/WizardScope");\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        runtime=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'));g=runtime['Guest'](image,out/'guest',bool(args.disk),reference_cpus=1)
        root=('C' if args.disk else 'T')+':/Probe/WizardScope'
        if args.disk:
            g.wait('DONE native kernel startup\n')
            report['library_commands']=[f'AdamFile("C:/{n}",FALSE);' for n in ['Adam/AutoComplete/MakeAC.HC','Adam/TaskSettings.HC','Adam/Opt/Utils/Find.HC']]
            report['library_commands'].append('#include "C:/Adam/ABlkDev/FileMgr.HC"')
            for c in report['library_commands']:
                start=len(g.collect());g.command(c)
                if 'INPUT REJECT ' in g.collect()[start:]:raise ValueError('Application load rejected: '+c)
            g.command('#include "C:/Probe/FindWizard.HC"');g.type('FWCheck("'+root+'");');g.press('ret')
        for i in range(2):
            g.wait(f'FIND WIZARD PICKER {i}\n',timeout=300);g.screenshot(f'picker-{i}')
            if not i:g.key('shift',True)
            g.press('esc')
            if not i:g.key('shift',False)
            g.wait(f'FIND WIZARD RETURN {i} MASK ',timeout=300)
        g.wait('FIND WIZARD RESULTS READY\n',timeout=300)
        raw=(g.out/'wizard-results.DD').read_bytes();(out/'wizard-results.DD').write_bytes(raw)
        links=re.findall(rb'A="PL:([^"\n]+)"',raw)
        wanted=[(root+'/A.TXT,1').encode(),(root+'/Nested/B.TXT,1').encode()]
        report['links']=[x.decode() for x in links]
        if sorted(links)!=sorted(wanted):raise ValueError('Search links differ: '+repr(links))
        if b' n"eedle one' not in raw or b' n"eedle two' not in raw or b' mixed' in raw or b' excluded' in raw:raise ValueError('Search text differs')
        g.screenshot('results-before-command')
        if runtime['has_result_pixels'](g.out/'results-before-command.png'):raise ValueError('42 was present before command')
        g.type('6*7;');g.press('ret');report['result_task_arithmetic']=g.result_pixels()
        g.key('shift',True);g.press('esc');g.key('shift',False)
        g.wait('FIND WIZARD RESULTS CLOSED\n');g.wait('FIND WIZARD DONE\n')
        masks=(g.out/'wizard-masks.bin').read_bytes();(out/'wizard-masks.bin').write_bytes(masks)
        report['masks']=list(struct.unpack('<2q',masks))
        if args.disk:
            g.wait('COMMAND OK\n',start=g.log.read_text().index('INPUT LINE FWCheck('));g.command('6*7;');report['caller_arithmetic']=g.result_pixels()
        g.close();g=None
        if args.disk:
            after=pack['snapshot'](image.read_bytes())[1]
            if set(before)&set(additions) or set(after)!=set(before)|set(additions) or any(after[n]!=v for n,v in before.items()) or any(after[n][2]!=b for n,b in additions.items()):raise ValueError('Unexpected filesystem changes')
            report['preserved_files']=len(before);report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        if report['masks']!=[63,63]:raise ValueError('Wizard caller state differs')
        report['result']='pass'
    except BaseException as exc:report.update(result='fail',error=type(exc).__name__+': '+str(exc));raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
