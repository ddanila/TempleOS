#!/usr/bin/env python3
"""Reject invalid Budget schedules through real forms without creating data or strings."""
import argparse,hashlib,json,runpy,struct,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
PHASES=('zero','negative','null','valid','entry-cancel','retained','invalidated')
NAMES=tuple(n+s for n in PHASES for s in ('.DD','.fields','.state'))+tuple(n+'-report.DD' for n in ('zero','negative','null','invalidated'))+('null-menu.DD','mask.bin','accounts.DD')
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def verify(out,native):
    recurrence=runpy.run_path(str(ROOT/'tools/test-i386-budget-recurrence.py'))
    if (out/'mask.bin').read_bytes()!=struct.pack('<q',1023):raise ValueError('Validation/restoration mask differs')
    if (out/'accounts.DD').read_bytes()!=recurrence['ACCOUNTS']:raise ValueError('Accounts changed')
    for n in ('zero','negative','null','invalidated'):
        if (out/(n+'-report.DD')).read_bytes()!=b'':raise ValueError('Rejected schedule changed report')
    recurrence['menu_check']((out/'null-menu.DD').read_bytes(),0)
    for n in PHASES:
        if n=='entry-cancel':
            fields=b'Date              :01/01/2001_\n      5.00_\nCredit (from) Acct:GHOST_\nDebit  (to)   Acct:VOID_\nDesc              :discard me_\n'
            state=struct.pack('<512sQ512s512s512s',b'*',0,b'',b'',b'');doc=b'\nAmount            $$\n\n\n\x05\n'
        else:
            typ=0 if n=='null' else 1;label='Null' if typ==0 else 'Interval'
            period=-1 if n=='negative' else 0 if n in ('zero','invalidated') else 1
            fields=f'[{label}]\nStart Date:01/01/2001_\nEnd Date  :01/03/2001_\nPeriod    :{period:8.2f}_\n'.encode()
            retained=n in ('retained','invalidated')
            bits=0x3FF0000000000000+(not native) if retained else 0
            state=struct.pack('<HH16s16sQ',typ,0,b'01/01/2001' if retained else b'[',b'01/03/2001' if retained else b']',bits)
            doc=f'$LS-DRT,"[{label}]",D="ST_BGT_TEMPLATE_TYPES"$\n\n\n'.encode()+(b'' if n=='retained' else b'\x05')+b'\n'
        for suffix,expected in [('.fields',fields),('.state',state),('.DD',doc)]:
            if (out/(n+suffix)).read_bytes()!=expected:raise ValueError('Validation form differs: '+n+suffix+': '+repr((out/(n+suffix)).read_bytes()))
def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--archive',type=Path);ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    if a.disk and not a.reference or not a.disk and not a.archive:ap.error('Native requires --reference; original requires --archive')
    fixture=ROOT/'tests/guest/i386-budget-validation/Contract.HC'
    paths=[Path(__file__).resolve(),fixture,ROOT/'docs/i386-compatibility-inventory.json',ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ('test-i386-budget-recurrence.py','i386-budget-source.py','build-iso.py','guest-run.py','test-i386-timeclock-reference.py','package-i386-native-image.py','build-i386-kernel.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py')]
    if a.disk:
        gold=a.reference.resolve();r=json.loads((gold/'result.json').read_text())
        if r.get('result')!='pass' or not r.get('inputs_unchanged') or r.get('fixture_sha256')!=sha(fixture):raise ValueError('Matching original control required')
        paths += [a.disk.resolve(),gold/'result.json']+[gold/n for n in NAMES]
    else:paths.append(a.archive.resolve())
    out.mkdir(parents=True);pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    report=dict(result='running',fixture_sha256=sha(fixture),input_sha256=pins,scope='Real keyboard zero/negative interval and Null-type rejection; valid schedule followed by typed transaction cancellation, retained accepted schedule then zero-period rejection. No seeded entries or direct handler calls. Exact visible/backing/raw forms, empty reports, absent data/strings, caller restoration, whole native filesystem unchanged after Install. Not full application or resources qualification.');guest=None
    try:
        if not a.disk:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Apps/Budget/Accts.DD.Z').write_bytes(a.archive.read_bytes())
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");\n#include "T:/Apps/Budget/Load.HC"\n#include "T:/Apps/Budget/Install.HC"\n'+fixture.read_bytes()+b'\nBudgetValidation;\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        else:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));before=pack['snapshot'](a.disk.read_bytes())[1]
            expected=runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['budget_source']
            for e in json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())['entries']:
                if e['path'].startswith('Apps/Budget/') and before['/'+e['path']][2]!=expected(e):raise ValueError('Budget source differs: '+e['path'])
            image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/BudgetValidation.HC':fixture.read_bytes()})
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];guest=Guest(image,out/'guest',bool(a.disk))
        if a.disk:
            guest.wait('DONE native kernel startup\n');commands=['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Apps/Budget/Load.HC"','#include "C:/Apps/Budget/Install.HC"','#include "C:/Probe/BudgetValidation.HC"'];report['commands']=commands
            for c in commands:guest.command(c)
            installed=pack['snapshot'](image.read_bytes())[1]
            guest.type('BudgetValidation;');guest.press('ret')
        guest.wait('BV ready\n');time.sleep(1)
        def escape(cancel=False):
            if cancel:guest.key('shift',True)
            guest.press('esc')
            if cancel:guest.key('shift',False)
        def fill(name,period,retained=False):
            guest.wait('BV '+name+' ready\n',30)
            for _ in range(3 if retained else 1):guest.press('tab')
            for value in ([f'{period:8.2f}'] if retained else ['01/01/2001','01/03/2001',f'{period:8.2f}']):guest.type(value);guest.press('tab')
            guest.wait('BV '+name+' draft\n',30);guest.screenshot(name)
        for name,period in [('zero',0),('negative',-1)]:
            guest.press('t');fill(name,period);escape();guest.wait('BV '+name+' returned\n',30)
        guest.press('t');guest.wait('BV null-menu ready\n',30);guest.press('spc');guest.wait('BV null-menu opened\n',30);guest.press('spc');fill('null',1);escape();guest.wait('BV null returned\n',30)
        guest.press('t');fill('valid',1);escape();guest.wait('BV entry-cancel ready\n',30)
        for value in ['01/01/2001','      5.00','GHOST','VOID','discard me']:guest.type(value);guest.press('tab')
        guest.wait('BV entry-cancel draft\n',30);guest.screenshot('entry-cancel');escape(True);guest.wait('BV retained ready\n',30);guest.screenshot('retained')
        fill('invalidated',0,True);escape();guest.wait('BV done actions\n',30);guest.screenshot('after-rejections');escape(True);guest.wait('BV done\n',30)
        if a.disk:
            guest.wait('COMMAND OK\n',start=guest.collect().index('INPUT LINE BudgetValidation;'));guest.command('6*7;');report['fresh_result']=guest.result_pixels()
        guest.close();guest=None
        for n in NAMES:(out/n).write_bytes((out/'guest'/n).read_bytes())
        verify(out,bool(a.disk))
        if a.disk:
            files=pack['snapshot'](image.read_bytes())[1]
            if files!=installed:raise ValueError('Rejected forms/abort changed filesystem bytes or metadata')
            report['files_unchanged_after_install']=True
            for n in NAMES:
                if n.endswith('.state'):continue
                if (out/n).read_bytes()!=(gold/n).read_bytes():raise ValueError('Original validation differs: '+n)
            changed={n for n in set(before)|set(files) if before.get(n)!=files.get(n)}
            if changed-{'/Probe/BudgetValidation.HC','/Budget/Accts.DD.Z'}:raise ValueError('Unrelated installed file changed: '+repr(changed))
            report['changed_files']=sorted(changed);report['preserved_files']=len(set(before)-changed)
        report.update(result='pass',mask=1023)
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        if a.disk and guest is not None and guest.p.poll() is None:
            try:
                guest.call('stop');guest.collect();(out/'failure-registers.txt').write_text(guest.call('human-monitor-command',**{'command-line':'info registers'}));guest.call('pmemsave',val=0,size=64*1024*1024,filename=str(out/'failure-memory.bin'));report['failure_capture']={n:sha(out/n) for n in ('failure-memory.bin','failure-registers.txt')}
            except Exception as err:report['capture_error']=str(err)
        raise
    finally:
        if guest is not None:guest.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
