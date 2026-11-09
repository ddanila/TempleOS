#!/usr/bin/env python3
"""Drive Budget interval templates and periodic copies through their real popup forms."""
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
PHASES=('cancel-schedule','template-schedule','template-entry','periodic-cancel-schedule','periodic-cancel-entry','periodic-return-schedule','periodic-schedule','periodic-entry')
EXTRA_NAMES=tuple(n+s for n in PHASES for s in ('.DD','.fields','.state'))+('cancelled.DD','template.DD','template-live.bin','periodic-cancelled.DD','periodic-cancelled-live.bin','final-live.bin')
REOPEN_NAMES=tuple('reopen-'+n for n in NAMES)+('reopen-live.bin',)
POINTER=re.compile(rb',U=0x([0-9A-F]+)\$')
ACCOUNTS=b'$FG,6$JOB\n$FG,1$BANK\n$FG,4$CREDIT\n$FG,2$CASH\n$FG,0$RENT\nCAR\nUTILITIES\nMISC\nCLOTHS\nHEALTH\nCHARITY\n'
DATE=730000
TEMPLATE_ROWS=[(0,'rent plan'),(2,'rent plan'),(4,'rent plan')]
FINAL_ROWS=[(0,'rent plan'),(1,'cash batch'),(2,'cash batch'),(2,'rent plan'),(4,'rent plan')]
REOPEN_ROWS=[(0,'rent plan'),(1,'cash batch'),(2,'rent plan'),(2,'cash batch'),(4,'rent plan')]
def report(rows,cursor_first=False):
    data=b'$FG,1$'+(b'\x05' if cursor_first else b'')
    for i,(day,desc) in enumerate(rows,1):
        data+=f'$MU-UL,"09/{4+day:02d}/98     BANK     RENT: {-100.*i:7.2f}   100.00:{desc}",U=<entry>$\n'.encode()
    return data+(b'' if cursor_first else b'\x05')
def doc_check(doc,rows,cursor_first=False):
    ids=POINTER.findall(doc)
    if len(ids)!=len(rows) or len(set(ids))!=len(rows) or not all(int(v,16) for v in ids):raise ValueError('Invalid row identities')
    if POINTER.sub(b',U=<entry>$',doc)!=report(rows,cursor_first):raise ValueError('Template report differs: '+repr(doc))
    return [int(v,16) for v in ids]
def schedule(first,last,period,adjust=0):return struct.pack('<HH16s16sQ',1,0,first.encode(),last.encode(),struct.unpack('<Q',struct.pack('<d',period))[0]+adjust)
def entry(date,amount,credit,debit,desc,adjust=0):return struct.pack('<512sQ512s512s512s',date.encode(),struct.unpack('<Q',struct.pack('<d',amount))[0]+adjust,credit.encode(),debit.encode(),desc.encode())
def verify(records,native=False):
    before,after,mask,data,strings,accounts=records
    if before!=b'' or mask!=struct.pack('<q',262143):raise ValueError('Template/restoration mask or initial report differs')
    doc_check(after,FINAL_ROWS,True)
    pairs=[line.split(',',1) for line in strings.decode('ascii').splitlines()];indices={v:int(k) for k,v in pairs}
    names={'JOB','BANK','CREDIT','CASH','RENT','CAR','UTILITIES','MISC','CLOTHS','HEALTH','CHARITY','rent plan','cash batch'}
    if len(pairs)!=13 or set(indices)!=names or [int(k) for k,v in pairs]!=list(range(13)):raise ValueError('Template string table differs')
    def row(day,desc):return struct.pack('<QHHIIIQ',((DATE+day)<<32)+(0 if desc=='rent plan' else 4),0,0,indices['BANK'],indices['RENT'],indices[desc],0x4059000000000000+(not native))
    expected=struct.pack('<q',2)+row(1,'cash batch')+row(2,'cash batch')+struct.pack('<q',1)+schedule('09/04/1998','09/08/1998',2.,not native)+row(0,'rent plan')
    if data!=expected:raise ValueError('Template/periodic saved records differ')
    if accounts!=ACCOUNTS:raise ValueError('Template accounts differ')
    return [POINTER.sub(b',U=<entry>$',before),POINTER.sub(b',U=<entry>$',after),strings,accounts]
def live(data,rows,ids=None,native=False):
    if len(data)!=40+72*len(rows):raise ValueError('Live template state length differs')
    header=struct.unpack_from('<5Q',data);t,*base,n=header
    if not t or n!=len(rows) or len(set(base))!=3 or not all(base):raise ValueError('Invalid template owner/string identities')
    entries=[];owned=[]
    for i,(day,desc) in enumerate(rows):
        address,date,kind,flags,amount,owner,credit,debit,name=struct.unpack_from('<9Q',data,40+i*72)
        if not address or date!=((DATE+day)<<32)+4 or flags or amount!=0x4059000000000000+(not native):raise ValueError('Live date/flags/amount differs')
        if desc=='rent plan':
            if kind!=4 or owner!=t or [credit,debit,name]!=base:raise ValueError('Generated row ownership differs')
        else:
            if kind or owner or not all([credit,debit,name]) or set([credit,debit,name])&set(base):raise ValueError('Periodic row ownership differs')
            owned.extend([credit,debit,name])
        entries.append(address)
    if len(set(entries))!=len(rows) or len(set(owned))!=len(owned):raise ValueError('Aliased live rows/owned strings')
    if ids is not None and entries!=ids:raise ValueError('Report and live identities differ')
    return header,entries

def verify_phases(out,native=False):
    for name in PHASES:
        state=(out/(name+'.state')).read_bytes();fields=(out/(name+'.fields')).read_bytes()
        if 'entry' in name:
            desc='rent plan' if name=='template-entry' else 'cash batch'
            expected=entry('*',0.,'','','') if name=='template-entry' else entry('09/04/98',100.,'BANK','RENT','rent plan',not native)
            expected_fields=f'Date              :09/04/1998_\n    100.00_\nCredit (from) Acct:BANK_\nDebit  (to)   Acct:RENT_\nDesc              :{desc}_\n'.encode()
            expected_doc=b'\nAmount            $$\n\n\n\x05\n'
        else:
            if name=='cancel-schedule':first,last,period='01/01/2001','01/15/2001',7.
            elif name=='template-schedule':first,last,period='09/04/1998','09/08/1998',2.
            else:first,last,period='09/04/1998','09/06/1998',1.
            expected=schedule(first,last,period,not native) if name=='periodic-return-schedule' else schedule('09/04/98' if name.startswith('periodic') else '[',']',0.)
            expected_fields=f'[Interval]\nStart Date:{first}_\nEnd Date  :{last}_\nPeriod    :{period:8.2f}_\n'.encode()
            expected_doc=b'$LS-DRT,"[Interval]",D="ST_BGT_TEMPLATE_TYPES"$\n\n\n'+(b'' if name=='periodic-return-schedule' else b'\x05')+b'\n'
        if state!=expected:raise ValueError('Form backing state differs: '+name+': '+repr(state))
        if fields!=expected_fields:raise ValueError('Form fields differ: '+name+': '+repr(fields))
        if (out/(name+'.DD')).read_bytes()!=expected_doc:raise ValueError('Form structure differs: '+name+': '+repr((out/(name+'.DD')).read_bytes()))
    if (out/'cancelled.DD').read_bytes()!=b'':raise ValueError('Cancelled new template changed report')
    first=(out/'template.DD').read_bytes();cancelled=(out/'periodic-cancelled.DD').read_bytes()
    ids=doc_check(first,TEMPLATE_ROWS);cancel_ids=doc_check(cancelled,TEMPLATE_ROWS,True)
    if ids!=cancel_ids:raise ValueError('Periodic cancellation replaced template entries')
    h,e=live((out/'template-live.bin').read_bytes(),TEMPLATE_ROWS,ids,native)
    if live((out/'periodic-cancelled-live.bin').read_bytes(),TEMPLATE_ROWS,ids,native)!=(h,e):raise ValueError('Periodic cancellation changed template ownership')
    final_ids=doc_check((out/'after.DD').read_bytes(),FINAL_ROWS,True)
    h2,e2=live((out/'final-live.bin').read_bytes(),FINAL_ROWS,final_ids,native)
    if h2[:4]!=h[:4] or [e2[i] for i in [0,3,4]]!=e:raise ValueError('Periodic copy replaced original template rows')


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()




def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--archive',type=Path);ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();fixture=ROOT/'tests/guest/i386-budget-templates/Contract.HC'
    if out.exists():ap.error('Use a fresh output directory')
    if args.disk and not args.reference:ap.error('Native requires --reference')
    if not args.disk and not args.archive:ap.error('Original requires --archive')
    paths=[Path(__file__).resolve(),fixture,ROOT/'docs/i386-compatibility-inventory.json',ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ('i386-budget-source.py','build-iso.py','guest-run.py','test-i386-timeclock-reference.py','package-i386-native-image.py','build-i386-kernel.py','test-i386-timeclock-welcome.py','test-i386-autocomplete-interaction.py')]
    if args.disk:
        gold=args.reference.resolve();info=json.loads((gold/'result.json').read_text())
        if info.get('result')!='pass' or not info.get('inputs_unchanged') or info.get('fixture_sha256')!=sha(fixture):raise ValueError('Matching original reference required')
        paths += [args.disk.resolve(),gold/'result.json']+[gold/n for n in NAMES+REOPEN_NAMES+EXTRA_NAMES]
    else:paths.append(args.archive.resolve())
    out.mkdir(parents=True);pins={str(p):sha(p) for p in paths}
    report=dict(result='running',fixture_sha256=sha(fixture),input_sha256=pins,scope='Real Budget t interval template creation/cancellation and p periodic copy with nested entry cancellation, retained schedule and final acceptance. No seeded transactions. Exact forms/backing fields, generated versus owned rows, saved templates/normal records and caller restoration; native cold restart/read-only abort, original same-boot reopen. Not full application qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    guest=None
    try:
        if not args.disk:
            overlay=out/'overlay';overlay.mkdir()
            report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Apps/Budget/Accts.DD.Z').write_bytes(args.archive.read_bytes())
            once=b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");\n#include "T:/Apps/Budget/Load.HC"\n#include "T:/Apps/Budget/Install.HC"\n'+fixture.read_bytes()+b'\nBudgetEntry;\n'
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
            guest.type('BudgetEntry;');guest.press('ret')
        guest.wait('BP ready\n');time.sleep(2);guest.screenshot('before')
        def escape(cancel=False):
            if cancel:guest.key('shift',True)
            guest.press('esc')
            if cancel:guest.key('shift',False)
        def schedule_form(name,first,last,period,retained=False):
            guest.wait('BP '+name+' ready\n',30);time.sleep(1);guest.screenshot(name+'-initial')
            if not retained:
                guest.press('tab')
                for value in (first,last,f'{float(period):8.2f}'):guest.type(value);guest.press('tab')
            guest.wait('BP '+name+' draft\n',30);guest.screenshot(name+'-filled')
        def entry_form(name,desc):
            guest.wait('BP '+name+' ready\n',30);time.sleep(1);guest.screenshot(name+'-initial')
            for value in ('09/04/1998','    100.00','BANK','RENT',desc):guest.type(value);guest.press('tab')
            guest.wait('BP '+name+' draft\n',30);guest.screenshot(name+'-filled')
        guest.press('t');schedule_form('cancel-schedule','01/01/2001','01/15/2001','7');escape(True)
        guest.wait('BP cancelled\n',30)
        guest.press('t');schedule_form('template-schedule','09/04/1998','09/08/1998','2');escape()
        entry_form('template-entry','rent plan');escape();guest.wait('BP template entered\n',30)
        guest.press('home');guest.wait('BP periodic selected\n',30);guest.press('p')
        schedule_form('periodic-cancel-schedule','09/04/1998','09/06/1998','1');escape()
        entry_form('periodic-cancel-entry','cash batch');escape(True)
        schedule_form('periodic-return-schedule','','','',True);escape(True);guest.wait('BP periodic cancelled\n',30)
        guest.press('p');schedule_form('periodic-schedule','09/04/1998','09/06/1998','1');escape()
        entry_form('periodic-entry','cash batch');escape();guest.wait('BP periodic entered\n',30)
        guest.screenshot('periodic-entered')
        guest.press('esc');guest.wait('BP done\n',30)
        records=[(out/'guest'/n).read_bytes() for n in NAMES]
        for name in EXTRA_NAMES:(out/name).write_bytes((out/'guest'/name).read_bytes())
        if args.disk:
            guest.wait('COMMAND OK\n',start=guest.collect().index('INPUT LINE BudgetEntry;'))
            guest.command('6*7;');guest.result_pixels()
        if args.disk:
            guest.close();guest=None
            persisted=pack['snapshot'](image.read_bytes())[1]
            guest=Guest(image,out/'guest-reopen',True)
            guest.wait('DONE native kernel startup\n');time.sleep(3)
            for command in commands:
                if '/Install.HC' not in command:guest.command(command)
        guest.type('BudgetEntry(TRUE);');guest.press('ret');guest.wait('BR ready\n',30)
        time.sleep(2);guest.screenshot('reopened')
        guest.key('shift',True);guest.press('esc');guest.key('shift',False)
        guest.wait('BR done\n',30)
        reopened=[(guest.out/n).read_bytes() for n in REOPEN_NAMES]
        if args.disk:
            guest.wait('COMMAND OK\n',start=guest.collect().index('INPUT LINE BudgetEntry(TRUE);'))
            guest.command('6*7;');guest.result_pixels()
        guest.close();guest=None
        for name,value in zip(REOPEN_NAMES,reopened):(out/name).write_bytes(value)
        if reopened[2]!=struct.pack('<q',63) or reopened[3:6]!=records[3:]:
            raise ValueError('Reopened records/restoration differ')
        if reopened[0]!=reopened[1]:raise ValueError('Read-only reopened document changed')
        for doc in reopened[:2]:doc_check(doc,REOPEN_ROWS)
        live(reopened[6],REOPEN_ROWS,doc_check(reopened[0],REOPEN_ROWS),bool(args.disk))
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
        normalized=verify(records,bool(args.disk))
        verify_phases(out,bool(args.disk))
        if args.disk:
            for name in (n for n in EXTRA_NAMES if not n.endswith(('live.bin','.state'))):
                actual=POINTER.sub(b',U=<entry>$',(out/name).read_bytes())
                expected=POINTER.sub(b',U=<entry>$',(gold/name).read_bytes())
                if actual!=expected:raise ValueError('Original template phase differs: '+name)
        if args.disk:
            original_data=(gold/'data.bin').read_bytes()
            differences=[i for i,(a,b) in enumerate(zip(original_data,records[3])) if a!=b]
            if differences!=[32,64,116,148]:raise ValueError('Unexpected original/native numerical differences')
            report['saved_numeric_differences']=differences
        if args.disk and normalized!=verify([(gold/n).read_bytes() for n in NAMES]):raise ValueError('Original template workflow differs')
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
