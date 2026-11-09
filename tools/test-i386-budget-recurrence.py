#!/usr/bin/env python3
"""Drive calendar recurrence pickers, template editing and deletion through real forms."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]
NAMES=('before.DD','after.DD','mask.bin','data.bin','strings.DD','accounts.DD')
KINDS={'monthly':2,'bimonthly':3,'semiannual':4,'annual':5}
LABELS={1:'Interval',2:'Monthly',3:'Bimonthly',4:'Semiannual',5:'Annual',6:'CANCEL'}
STEPS={2:1,3:2,4:6,5:12}
CHOICES=('new-cancel','new-cancel-action','new-select','edit-cancel-select','edit-select','recreate-select')
DRAFTS=('created-schedule','created-entry','edit-cancel-schedule','edited-schedule','edited-entry','recreated-schedule','recreated-entry')
PHASES=CHOICES+DRAFTS
LIVE_NAMES=('created-live.bin','cancelled-live.bin','edited-live.bin','final-live.bin')
EXTRA_NAMES=tuple(n+s for n in PHASES for s in ('.DD','.fields','.state'))+tuple(n+s for n in CHOICES for s in ('.menu','.selected'))+('created.DD','cancelled.DD','edited.DD','deleted.DD')+tuple(n+s for n in LIVE_NAMES for s in ('','.schedule'))
REOPEN_NAMES=tuple('reopen-'+n for n in NAMES)+('reopen-live.bin','reopen-live.bin.schedule')
POINTER=re.compile(rb',U=0x([0-9A-F]+)\$')
ACCOUNTS=b'$FG,6$JOB\n$FG,1$BANK\n$FG,4$CREDIT\n$FG,2$CASH\n$FG,0$RENT\nCAR\nUTILITIES\nMISC\nCLOTHS\nHEALTH\nCHARITY\n'
from datetime import date
BASE_DATE=date(1998,9,4)
def dates(kind):
    answer=[]
    for i in range(3):
        y,m=divmod(1998*12+10+i*STEPS[kind],12);answer.append(date(y,m+1,4))
    return answer
def edit_kind(kind):return kind+1 if kind<5 else 2
def end(kind):return dates(kind)[-1].strftime('%m/%d/%Y')
def day(d):return 730000+(d-BASE_DATE).days
def schedule(kind,first,last):return struct.pack('<HH16s16sd',kind,0,first.encode(),last.encode(),0.)
def entry(initial,native):
    if initial:return struct.pack('<512sQ512s512s512s',b'*',0,b'',b'',b'')
    return struct.pack('<512sQ512s512s512s',b'11/04/98',0x4059000000000000+(not native),b'BANK',b'RENT',b'plan')
def report(kind,desc,cursor=3):
    data=b'$FG,1$'
    for i,d in enumerate(dates(kind)):
        if cursor==i:data+=b'\x05'
        data+=f'$MU-UL,"{d.strftime("%m/%d/%y")}     BANK     RENT: {-100.*(i+1):7.2f}   100.00:{desc}",U=<entry>$\n'.encode()
    return data+(b'\x05' if cursor==3 else b'')
def doc_check(doc,kind,desc,cursor=3):
    ids=POINTER.findall(doc)
    if len(ids)!=3 or len(set(ids))!=3 or not all(int(v,16) for v in ids):raise ValueError('Invalid recurrence row identities')
    if POINTER.sub(b',U=<entry>$',doc)!=report(kind,desc,cursor):raise ValueError('Recurrence report/cursor differs: '+repr(doc))
    return [int(v,16) for v in ids]
def menu_check(doc,selection):
    names=('Null','Interval','Monthly','Bimonthly','Semiannual','Annual','CANCEL')
    expected=b'$FG,9$'
    for i,name in enumerate(names):
        if i==6:expected+=b'\n'
        if selection==i:expected+=b'\x05'
        expected+=f'$MU,"{name}",LE={i if i<6 else -1}$\n'.encode()
    if doc!=expected:raise ValueError('Recurrence list actions/default/cursor differ: '+repr(doc))
def verify(records,native=False,kind=2):
    before,after,mask,data,strings,accounts=records
    if before!=b'' or mask!=struct.pack('<q',16777215):raise ValueError('Recurrence/restoration mask or initial report differs')
    doc_check(after,kind,'plan')
    pairs=[line.split(',',1) for line in strings.decode('ascii').splitlines()];indices={v:int(k) for k,v in pairs}
    names={'JOB','BANK','CREDIT','CASH','RENT','CAR','UTILITIES','MISC','CLOTHS','HEALTH','CHARITY','plan'}
    if len(pairs)!=12 or set(indices)!=names or [int(k) for k,v in pairs]!=list(range(12)):raise ValueError('Recurrence strings differ')
    row=struct.pack('<QHHIIIQ',day(dates(kind)[0])<<32,0,0,indices['BANK'],indices['RENT'],indices['plan'],0x4059000000000000+(not native))
    expected=struct.pack('<qq',0,1)+schedule(kind,'11/04/1998',end(kind))+row
    if data!=expected:raise ValueError('Recurrence saved template differs')
    if accounts!=ACCOUNTS:raise ValueError('Recurrence accounts differ')
    return [POINTER.sub(b',U=<entry>$',v) for v in [before,after]]+[strings,accounts]
def live(data,kind,ids=None,native=False):
    if len(data)!=256:raise ValueError('Recurrence live state length differs')
    header=struct.unpack_from('<5Q',data);t,*strings,n=header
    if not t or n!=3 or len(set(strings))!=3 or not all(strings):raise ValueError('Invalid recurrence owner/strings')
    entries=[]
    for i,d in enumerate(dates(kind)):
        address,when,typ,flags,amount,owner,credit,debit,desc=struct.unpack_from('<9Q',data,40+i*72)
        if not address or when!=(day(d)<<32)+4 or typ!=4 or flags or amount!=0x4059000000000000+(not native) or owner!=t or [credit,debit,desc]!=strings:raise ValueError('Generated recurrence values/ownership differ')
        entries.append(address)
    if len(set(entries))!=3 or ids is not None and entries!=ids:raise ValueError('Recurrence row identities differ')
    return header,entries

def verify_phases(out,native=False,kind=2):
    target=edit_kind(kind)
    for name in PHASES:
        initial=name.startswith(('new-','created-','recreate-','recreated-'))
        chosen=1 if name.startswith('new-cancel') else kind if initial else target
        old_first,old_end=('[',']') if initial else ('11/04/1998',end(kind))
        if name in CHOICES:
            picked=5 if name=='new-cancel' else 6 if name=='new-cancel-action' else chosen
            menu_check((out/(name+'.menu')).read_bytes(),0);menu_check((out/(name+'.selected')).read_bytes(),picked)
            fields=f'[{LABELS[chosen]}]\nStart Date:{old_first}_\nEnd Date  :{old_end}_\nPeriod    :    0.00_\n'.encode()
            state=schedule(chosen,old_first,old_end)
            doc=f'$LS-DRT,"[{LABELS[chosen]}]",D="ST_BGT_TEMPLATE_TYPES"$\n\n\n\n'.encode()
        elif 'entry' in name:
            desc='edited plan' if name=='edited-entry' else 'plan'
            state=entry(initial,native)
            fields=f'Date              :11/04/1998_\n    100.00_\nCredit (from) Acct:BANK_\nDebit  (to)   Acct:RENT_\nDesc              :{desc}_\n'.encode()
            doc=b'\nAmount            $$\n\n\n\x05\n'
        else:
            state=schedule(chosen,old_first,old_end)
            fields=f'[{LABELS[chosen]}]\nStart Date:11/04/1998_\nEnd Date  :{end(chosen)}_\nPeriod    :    0.00_\n'.encode()
            doc=f'$LS-DRT,"[{LABELS[chosen]}]",D="ST_BGT_TEMPLATE_TYPES"$\n\n\n\x05\n'.encode()
        for suffix,expected in [('.state',state),('.fields',fields),('.DD',doc)]:
            actual=(out/(name+suffix)).read_bytes()
            if actual!=expected:raise ValueError('Recurrence form differs: '+name+suffix+': '+repr(actual))
    created_ids=doc_check((out/'created.DD').read_bytes(),kind,'plan')
    if doc_check((out/'cancelled.DD').read_bytes(),kind,'plan',0)!=created_ids:raise ValueError('Cancelled edit changed row identities')
    h,old_ids=live((out/'created-live.bin').read_bytes(),kind,created_ids,native)
    if live((out/'cancelled-live.bin').read_bytes(),kind,created_ids,native)!=(h,old_ids):raise ValueError('Cancelled edit changed owner/strings')
    h2,new_ids=live((out/'edited-live.bin').read_bytes(),target,None,native)
    if h2[0]==h[0] or set(h2[1:4])&set(h[1:4]):raise ValueError('Accepted edit reused live old template/strings')
    # BgtRegen preserves position by finding the first old menu pointer reused by a new row.
    cursor=next((new_ids.index(v) for v in old_ids if v in new_ids),3)
    if doc_check((out/'edited.DD').read_bytes(),target,'edited plan',cursor)!=new_ids:raise ValueError('Edited report action identities differ')
    if (out/'deleted.DD').read_bytes()!=b'':raise ValueError('Template deletion left generated rows')
    final_ids=doc_check((out/'after.DD').read_bytes(),kind,'plan')
    live((out/'final-live.bin').read_bytes(),kind,final_ids,native)
    for name in LIVE_NAMES:
        k=target if name=='edited-live.bin' else kind
        if (out/(name+'.schedule')).read_bytes()!=schedule(k,'11/04/1998',end(k)):raise ValueError('Live recurrence schedule differs')
    return cursor


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()




def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--archive',type=Path);ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--kind',choices=KINDS,required=True);args=ap.parse_args();kind=KINDS[args.kind];target=edit_kind(kind);first_command=f'BudgetEntry({kind});';reopen_command=f'BudgetEntry({kind},TRUE);'
    out=args.out.resolve();fixture=ROOT/'tests/guest/i386-budget-recurrence/Contract.HC'
    if out.exists():ap.error('Use a fresh output directory')
    if args.disk and not args.reference:ap.error('Native requires --reference')
    if not args.disk and not args.archive:ap.error('Original requires --archive')
    paths=[Path(__file__).resolve(),fixture,ROOT/'docs/i386-compatibility-inventory.json',ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ('i386-budget-source.py','build-iso.py','guest-run.py','test-i386-timeclock-reference.py','package-i386-native-image.py','build-i386-kernel.py','test-i386-timeclock-welcome.py','test-i386-autocomplete-interaction.py')]
    if args.disk:
        gold=args.reference.resolve();info=json.loads((gold/'result.json').read_text())
        if info.get('result')!='pass' or not info.get('inputs_unchanged') or info.get('fixture_sha256')!=sha(fixture) or info.get('kind')!=args.kind:raise ValueError('Matching original reference required')
        paths += [args.disk.resolve(),gold/'result.json']+[gold/n for n in NAMES+REOPEN_NAMES+EXTRA_NAMES]
    else:paths.append(args.archive.resolve())
    out.mkdir(parents=True);pins={str(p):sha(p) for p in paths}
    report=dict(result='running',kind=args.kind,edited_kind=LABELS[target],fixture_sha256=sha(fixture),input_sha256=pins,scope='Real nested recurrence list cancellation by Shift-Escape and CANCEL action, calendar template creation, cancelled schedule edit, accepted type/base-entry edit, deletion of generated family, recreation and native cold persistence. No seeded transactions; exact menu/form/live/storage and caller checks. Not full application qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    guest=None
    try:
        if not args.disk:
            overlay=out/'overlay';overlay.mkdir()
            report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Apps/Budget/Accts.DD.Z').write_bytes(args.archive.read_bytes())
            once=b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");\n#include "T:/Apps/Budget/Load.HC"\n#include "T:/Apps/Budget/Install.HC"\n'+fixture.read_bytes()+b'\n'+first_command.encode()+b'\n'
            (overlay/'Once.HC').write_bytes(once)
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        else:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));before=pack['snapshot'](args.disk.read_bytes())[1]
            expected=runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['budget_source']
            for entry in json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())['entries']:
                if entry['path'].startswith('Apps/Budget/') and before['/'+entry['path']][2]!=expected(entry):raise ValueError('Budget source differs: '+entry['path'])
            image=out/'working.img';report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/BudgetEntry.HC':fixture.read_bytes()})
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        guest=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            guest.wait('DONE native kernel startup\n');time.sleep(3)
            commands=['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Apps/Budget/Load.HC"','#include "C:/Apps/Budget/Install.HC"','#include "C:/Probe/BudgetEntry.HC"']
            report['commands']=commands
            for command in commands:guest.command(command)
            guest.type(first_command);guest.press('ret')
        guest.wait('BP ready\n');time.sleep(2);guest.screenshot('before')
        def escape(cancel=False):
            if cancel:guest.key('shift',True)
            guest.press('esc')
            if cancel:guest.key('shift',False)
        def choose(name,value,cancel=False):
            guest.wait('BP '+name+' ready\n',30);time.sleep(1);guest.press('spc');guest.wait('BP '+name+' opened\n',30)
            guest.press('home')
            for i in range(value):guest.press('down')
            guest.wait('BP '+name+' selected\n',30);guest.screenshot(name+'-selected')
            if cancel:escape(True)
            else:guest.press('spc')
            guest.wait('BP '+name+' returned\n',30);time.sleep(1)
        def schedule_form(name,k):
            guest.wait('BP '+name+' ready\n',30);guest.press('tab')
            for value in ('11/04/1998',end(k)):guest.type(value);guest.press('tab')
            guest.wait('BP '+name+' draft\n',30);guest.screenshot(name+'-filled')
        def entry_form(name,desc):
            guest.wait('BP '+name+' ready\n',30);time.sleep(1)
            for value in ('11/04/1998','    100.00','BANK','RENT',desc):guest.type(value);guest.press('tab')
            guest.wait('BP '+name+' draft\n',30);guest.screenshot(name+'-filled')
        guest.press('t');choose('new-cancel',5,True);choose('new-cancel-action',6);choose('new-select',kind)
        schedule_form('created-schedule',kind);escape();entry_form('created-entry','plan');escape();guest.wait('BP created\n',30)
        guest.press('home');guest.wait('BP edit selected\n',30);guest.press('ret')
        choose('edit-cancel-select',target);schedule_form('edit-cancel-schedule',target);escape(True);guest.wait('BP cancelled\n',30)
        guest.press('ret');choose('edit-select',target);schedule_form('edited-schedule',target);escape()
        entry_form('edited-entry','edited plan');escape();guest.wait('BP edited\n',30);time.sleep(2);guest.screenshot('edited')
        guest.press('home');guest.wait('BP delete selected\n',30);guest.key('ctrl',True);guest.press('y');guest.key('ctrl',False)
        guest.wait('BP deleted\n',30);guest.press('t');choose('recreate-select',kind)
        schedule_form('recreated-schedule',kind);escape();entry_form('recreated-entry','plan');escape();guest.wait('BP recreated\n',30)
        time.sleep(2);guest.screenshot('recreated')
        guest.press('esc');guest.wait('BP done\n',30)
        records=[(out/'guest'/n).read_bytes() for n in NAMES]
        for name in EXTRA_NAMES:(out/name).write_bytes((out/'guest'/name).read_bytes())
        if args.disk:
            guest.wait('COMMAND OK\n',start=guest.collect().index('INPUT LINE '+first_command))
            guest.command('6*7;');guest.result_pixels()
        if args.disk:
            guest.close();guest=None
            persisted=pack['snapshot'](image.read_bytes())[1]
            guest=Guest(image,out/'guest-reopen',True)
            guest.wait('DONE native kernel startup\n');time.sleep(3)
            for command in commands:
                if '/Install.HC' not in command:guest.command(command)
        guest.type(reopen_command);guest.press('ret');guest.wait('BR ready\n',30)
        time.sleep(2);guest.screenshot('reopened')
        guest.key('shift',True);guest.press('esc');guest.key('shift',False)
        guest.wait('BR done\n',30)
        reopened=[(guest.out/n).read_bytes() for n in REOPEN_NAMES]
        if args.disk:
            guest.wait('COMMAND OK\n',start=guest.collect().index('INPUT LINE '+reopen_command))
            guest.command('6*7;');guest.result_pixels()
        guest.close();guest=None
        for name,value in zip(REOPEN_NAMES,reopened):(out/name).write_bytes(value)
        if reopened[2]!=struct.pack('<q',63) or reopened[3:6]!=records[3:]:
            raise ValueError('Reopened records/restoration differ')
        if reopened[0]!=reopened[1]:raise ValueError('Read-only reopened document changed')
        for doc in reopened[:2]:doc_check(doc,kind,'plan')
        live(reopened[6],kind,doc_check(reopened[0],kind,'plan'),bool(args.disk))
        if reopened[7]!=schedule(kind,'11/04/1998',end(kind)):raise ValueError('Reopened recurrence schedule differs')
        if args.disk:
            if pack['snapshot'](image.read_bytes())[1]!=persisted:
                raise ValueError('Cold reopen/abort changed file bytes/metadata')
            for name,actual in zip(REOPEN_NAMES[:6],reopened[:6]):
                if name=='reopen-data.bin':continue
                expected=(gold/name).read_bytes()
                if POINTER.sub(b',U=<entry>$',actual)!=POINTER.sub(b',U=<entry>$',expected):
                    raise ValueError('Original reopen comparison differs: '+name)
            report['cold_reopen_files_unchanged']=True
        report['reopen_mask']=63
        if args.disk:
            files=pack['snapshot'](image.read_bytes())[1]
            allowed={'/Probe/BudgetEntry.HC','/Budget/Accts.DD.Z','/Budget/Strs.DD.Z','/Budget/Bgt.DATA.Z'}
            changed={n for n in set(before)|set(files) if before.get(n)!=files.get(n)}
            if changed-allowed:raise ValueError('Unrelated file changed: '+repr(changed-allowed))
            report['changed_files']=sorted(changed);report['preserved_files']=len(set(before)-allowed)
            report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        for name,value in zip(NAMES,records):(out/name).write_bytes(value)
        normalized=verify(records,bool(args.disk),kind)
        report['edited_cursor']=verify_phases(out,bool(args.disk),kind)
        if args.disk:
            for name in (n for n in EXTRA_NAMES if not n.endswith(('live.bin','.state')) and n!='edited.DD'):
                actual=POINTER.sub(b',U=<entry>$',(out/name).read_bytes())
                expected=POINTER.sub(b',U=<entry>$',(gold/name).read_bytes())
                if actual!=expected:raise ValueError('Original template phase differs: '+name)
        if args.disk:
            original_data=(gold/'data.bin').read_bytes()
            differences=[i for i,(a,b) in enumerate(zip(original_data,records[3])) if a!=b]
            if differences!=[84]:raise ValueError('Unexpected original/native numerical differences')
            report['saved_numeric_differences']=differences
        if args.disk and normalized!=verify([(gold/n).read_bytes() for n in NAMES],False,kind):raise ValueError('Original template workflow differs')
        report.update(result='pass',mask=struct.unpack('<q',records[2])[0],normalized_documents=[v.decode('latin1') for v in normalized])
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        if args.disk and guest is not None and guest.p.poll() is None:
            try:
                guest.call('stop');guest.collect()
                registers=guest.call('human-monitor-command',**{'command-line':'info registers'})
                (out/'failure-registers.txt').write_text(registers)
                guest.call('pmemsave',val=0,size=64*1024*1024,filename=str(out/'failure-memory.bin'))
                report['failure_capture']={'memory_sha256':sha(out/'failure-memory.bin'),'registers_sha256':sha(out/'failure-registers.txt')}
            except Exception as capture_error:report['capture_error']=str(capture_error)
        raise
    finally:
        if guest is not None:guest.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
