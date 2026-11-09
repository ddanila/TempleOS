#!/usr/bin/env python3
"""Drive full Budget open/save/close with emulated keyboard events."""
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
REOPEN_NAMES=tuple('reopen-'+n for n in NAMES)
EXTRA_NAMES=('selected.DD','cancelled.DD','picker1.DD','picker2.DD','order1.txt','order2.txt','picker-info.bin','seed-data.bin','seed-strings.DD','seed-accounts.DD')
# Captured from the pinned original picker in budget-account-picker-original-v1.
PICKER_ORDER=('JOB','CASH','FOOD','MISC','CHARITY','RENT','WAGES','HEALTH','CREDIT','CLOTHS','CAR','UTILITIES','BANK')
MENU_POINTER=re.compile(rb'LE=([0-9]+)')
POINTER=re.compile(rb',U=0x([0-9A-F]+)\$')


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def row(date,credit,debit,balance,amount,desc):
    return f'$MU-UL,"{date} {credit:>8} {debit:>8}:{balance:8.2f} {amount:8.2f}:{desc}",U=<entry>$\n'.encode()


def bank(selected=False):
    return (b'$FG,0$'+row('09/04/98','WAGES','BANK',100,100,'salary')+b'$FG,1$'+
            (b'\x05' if selected else b'')+row('09/05/98','BANK','FOOD',80,20,'groceries')+
            row('09/06/98','BANK','RENT',50,30,'rent')+(b'' if selected else b'\x05'))


def rent():
    return b'$FG,0$'+row('09/04/98','WAGES','BANK',0,100,'salary')+b'$FG,1$\x05'+row('09/05/98','BANK','FOOD',0,20,'groceries')+row('09/06/98','BANK','RENT',30,30,'rent')


def verify_order(data):
    names=data.decode('ascii').splitlines()
    if names!=list(PICKER_ORDER):raise ValueError('Picker accounts/order differ: '+repr(names))
    return names


def verify(records):
    before,after,mask,data,strings,accounts=records
    if mask!=struct.pack('<q',2047):raise ValueError('Picker/restoration mask differs: '+repr(mask))
    ids=[POINTER.findall(d) for d in (before,after)]
    if len(ids[0])!=3 or len(set(ids[0]))!=3 or ids[0]!=ids[1] or not all(int(v,16) for v in ids[0]):raise ValueError('View switch changed entry identities')
    normalized=[POINTER.sub(b',U=<entry>$',v) for v in (before,after)]
    if normalized!=[bank(),rent()]:raise ValueError('Account reports differ: '+repr(normalized))
    pairs=[line.split(',',1) for line in strings.decode('ascii').splitlines()];indices={v:int(k) for k,v in pairs}
    expected={'JOB','BANK','CREDIT','CASH','RENT','CAR','UTILITIES','MISC','CLOTHS','HEALTH','CHARITY','WAGES','FOOD','salary','groceries','rent'}
    if len(pairs)!=16 or set(indices)!=expected or [int(k) for k,v in pairs]!=list(range(16)):raise ValueError('Seed strings differ')
    expected_data=struct.pack('<q',3)
    for day,credit,debit,amount,desc in [(730000,'WAGES','BANK',100.,'salary'),(730001,'BANK','FOOD',20.,'groceries'),(730002,'BANK','RENT',30.,'rent')]:
        expected_data+=struct.pack('<QHHIIId',day<<32,0,0,indices[credit],indices[debit],indices[desc],amount)
    expected_data+=struct.pack('<q',0)
    if data!=expected_data:raise ValueError('View/picker altered saved transactions')
    expected_accounts=b'$FG,6$JOB\n$FG,1$BANK\n$FG,4$CREDIT\n$FG,2$CASH\n$FG,0$RENT\nCAR\nUTILITIES\nMISC\nCLOTHS\nHEALTH\nCHARITY\nWAGES\nFOOD\n'
    if accounts!=expected_accounts:raise ValueError('Seed accounts differ')
    return normalized+[data,strings,accounts]


def verify_reopen(records,saved):
    before,after,mask,data,strings,accounts=records
    if mask!=struct.pack('<q',63) or before!=after or records[3:]!=saved[3:]:raise ValueError('Read-only reopen changed state or data')
    ids=POINTER.findall(before)
    if len(ids)!=3 or len(set(ids))!=3 or not all(int(v,16) for v in ids):raise ValueError('Reopened entry identities differ')
    normalized=[POINTER.sub(b',U=<entry>$',v) for v in (before,after)]
    if normalized!=[bank(),bank()]:raise ValueError('Reopen did not reset BANK account view')
    return normalized+[data,strings,accounts]


def verify_menus(first,second):
    links=[MENU_POINTER.findall(data) for data in (first,second)]
    if len(links[0])!=13 or len(set(links[0]))!=13 or not all(int(v) for v in links[0]) or links[0]!=links[1]:
        raise ValueError('Account literal-link identities differ')
    colors={'JOB':6,'CASH':2,'CREDIT':4,'BANK':1}
    normalized=[]
    for data,selected in [(first,'BANK'),(second,'RENT')]:
        expected=b'View Acct\n\n'
        for name in PICKER_ORDER:
            expected+=f'$FG,{colors.get(name,0)}$'.encode()
            if name==selected:expected+=b'\x05'
            expected+=f'$MU-UL,"{name}",LE=<account>$\n'.encode()
        actual=MENU_POINTER.sub(b'LE=<account>',data)
        if actual!=expected:raise ValueError('Picker document/default differs: '+repr(actual))
        normalized.append(actual)
    return normalized


def normalize_phase(name,data):
    if name in ('picker1.DD','picker2.DD'):return MENU_POINTER.sub(b'LE=<account>',data)
    if name in ('selected.DD','cancelled.DD'):return POINTER.sub(b',U=<entry>$',data)
    return data


def pointer_boundary(args):
    out=args.out.resolve();fixture=ROOT/'tests/guest/i386-budget-account-picker/PointerBoundary.HC'
    if out.exists():raise ValueError('Use a fresh output directory')
    paths=[Path(__file__).resolve(),fixture]+[ROOT/('tools/'+n) for n in ('build-iso.py','guest-run.py','test-i386-timeclock-reference.py','package-i386-native-image.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py')]
    if args.disk:
        if not args.reference:raise ValueError('Native boundary requires original reference')
        gold=args.reference.resolve();reference=json.loads((gold/'result.json').read_text())
        if reference.get('result')!='pass' or reference.get('mode')!='pointer-boundary' or not reference.get('inputs_unchanged') or reference.get('fixture_sha256')!=sha(fixture):raise ValueError('Matching original pointer boundary required')
        paths += [args.disk.resolve(),gold/'result.json',gold/'pointer-cancel.bin']
    out.mkdir(parents=True);pins={str(p):sha(p) for p in paths}
    report=dict(result='running',mode='pointer-boundary',native=bool(args.disk),fixture_sha256=sha(fixture),input_sha256=pins,scope='Public command execution: pointer-return narrowing, legacy negative-sentinel tests and explicit pointer-width comparison. No sentinel dereference, application UI or heap qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());guest=None
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/PointerCancel.HC':fixture.read_bytes()})
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes())
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];guest=Guest(image,out/'guest',bool(args.disk))
        if args.disk:guest.wait('DONE native kernel startup\n');guest.command('#include "C:/Probe/PointerCancel.HC"')
        guest.wait('POINTER CANCEL DONE\n');data=(guest.out/'pointer-cancel.bin').read_bytes();rows=list(struct.unpack('<12q',data));(out/'pointer-cancel.bin').write_bytes(data)
        expected=[4,4294967295,1,0,1,1,1,1,1,4660,4294967295,4660] if args.disk else [8,-1,0,1,1,1,1,1,1,4660,-1,4294971956]
        if rows!=expected:raise ValueError('Pointer boundary differs: '+repr(rows))
        if args.disk:
            if list(struct.unpack('<12q',(gold/'pointer-cancel.bin').read_bytes()))!=[8,-1,0,1,1,1,1,1,1,4660,-1,4294971956]:raise ValueError('Original pointer boundary changed')
        report.update(result='pass',records=rows)
    except Exception as error:report.update(result='fail',error=str(error));raise
    finally:
        if guest:guest.close()
        report['inputs_unchanged']=all(sha(Path(n))==h for n,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--archive',type=Path);ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--pointer-boundary',action='store_true');ap.add_argument('--shared-budget',action='store_true',help='Original runtime with the reviewed current Budget width ports');args=ap.parse_args()
    if args.pointer_boundary:
        if args.shared_budget:ap.error('Boundary mode does not load Budget')
        return pointer_boundary(args)
    if args.disk and args.shared_budget:ap.error('Shared Budget mode is original-only')
    out=args.out.resolve();fixture=ROOT/'tests/guest/i386-budget-account-picker/Contract.HC'
    if out.exists():ap.error('Use a fresh output directory')
    if args.disk and not args.reference:ap.error('Native requires --reference')
    if not args.disk and not args.archive:ap.error('Original requires --archive')
    paths=[Path(__file__).resolve(),fixture,ROOT/'docs/i386-compatibility-inventory.json',ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ('i386-budget-source.py','build-iso.py','guest-run.py','test-i386-timeclock-reference.py','package-i386-native-image.py','build-i386-kernel.py','test-i386-timeclock-welcome.py','test-i386-autocomplete-interaction.py')]
    if args.disk:
        gold=args.reference.resolve();info=json.loads((gold/'result.json').read_text())
        if info.get('result')!='pass' or not info.get('inputs_unchanged') or info.get('fixture_sha256')!=sha(fixture):raise ValueError('Matching original reference required')
        paths += [args.disk.resolve(),gold/'result.json']+[gold/n for n in NAMES+REOPEN_NAMES+EXTRA_NAMES]
    else:
        paths.append(args.archive.resolve())
        if args.shared_budget:
            paths += [ROOT/e['path'] for e in json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())['entries'] if e['path'].startswith('Apps/Budget/')]
    out.mkdir(parents=True);pins={str(p):sha(p) for p in paths}
    report=dict(result='running',shared_budget=args.shared_budget,fixture_sha256=sha(fixture),input_sha256=pins,scope='Full Budget v account picker with three explicitly seeded transactions: BANK/RENT defaults, keyboard Home/Down/Space acceptance, changed BANK selection then Shift-Escape cancellation, stable entry/literal-link identities, exact reports/files and native cold reopen reset to BANK. Read-only observer; not transaction-entry UI, mouse, resources or whole application qualification.')
    for source,name in [(fixture,'fixture.HC'),(Path(__file__).resolve(),'runner-source.py')]:
        (out/name).write_bytes(source.read_bytes())
    guest=None
    try:
        if not args.disk:
            overlay=out/'overlay';overlay.mkdir()
            report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            if args.shared_budget:
                reviewed=runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['budget_source'];report['shared_budget_source_sha256']={}
                for entry in json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())['entries']:
                    if entry['path'].startswith('Apps/Budget/'):
                        data=(ROOT/entry['path']).read_bytes()
                        if data!=reviewed(entry):raise ValueError('Unreviewed Budget source: '+entry['path'])
                        (overlay/entry['path']).write_bytes(data);report['shared_budget_source_sha256'][entry['path']]=sha(ROOT/entry['path'])
            (overlay/'Apps/Budget/Accts.DD.Z').write_bytes(args.archive.read_bytes())
            once=b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");\n#include "T:/Apps/Budget/Load.HC"\n#include "T:/Apps/Budget/Install.HC"\n'+fixture.read_bytes()+b'\nBudgetPicker;\n'
            (overlay/'Once.HC').write_bytes(once)
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        else:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));before=pack['snapshot'](args.disk.read_bytes())[1]
            expected=runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['budget_source']
            for entry in json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())['entries']:
                if entry['path'].startswith('Apps/Budget/') and before['/'+entry['path']][2]!=expected(entry):raise ValueError('Budget source differs: '+entry['path'])
            image=out/'working.img';report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/BudgetPicker.HC':fixture.read_bytes()})
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        guest=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            guest.wait('DONE native kernel startup\n');time.sleep(3)
            commands=['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Apps/Budget/Load.HC"','#include "C:/Apps/Budget/Install.HC"','#include "C:/Probe/BudgetPicker.HC"']
            report['commands']=commands
            for command in commands:guest.command(command)
            guest.type('BudgetPicker;');guest.press('ret')
        guest.wait('BP ready\n');time.sleep(2);guest.screenshot('before')
        guest.press('home');guest.press('down');guest.wait('BP selected\n',30);guest.screenshot('selected')
        guest.press('v');guest.wait('BP picker1 ready\n',30);time.sleep(2);guest.screenshot('picker-bank-default')
        order=verify_order((out/'guest/order1.txt').read_bytes())
        if args.disk and (out/'guest/order1.txt').read_bytes()!=(gold/'order1.txt').read_bytes():raise ValueError('Original picker order differs')
        guest.press('home')
        for i in range(order.index('RENT')):guest.press('down')
        guest.wait('BP RENT selected\n',30);guest.screenshot('rent-selected');guest.press('spc')
        guest.wait('BP RENT view\n',30);time.sleep(2);guest.screenshot('rent-view')
        guest.press('v');guest.wait('BP picker2 ready\n',30);time.sleep(2);guest.screenshot('picker-rent-default')
        if (out/'guest/order2.txt').read_bytes()!=(out/'guest/order1.txt').read_bytes():raise ValueError('Picker order changed between openings')
        guest.press('home')
        for i in range(order.index('BANK')):guest.press('down')
        guest.wait('BP BANK selected\n',30);guest.screenshot('bank-selected')
        guest.key('shift',True);guest.press('esc');guest.key('shift',False)
        guest.wait('BP picker cancelled\n',30);time.sleep(1);guest.screenshot('cancelled')
        guest.key('shift',True);guest.press('esc');guest.key('shift',False);guest.wait('BP done\n',30)
        records=[(out/'guest'/n).read_bytes() for n in NAMES]
        for name in EXTRA_NAMES:(out/name).write_bytes((out/'guest'/name).read_bytes())
        if (out/'cancelled.DD').read_bytes()!=records[1]:raise ValueError('Cancelled picker changed RENT report or identity')
        selected=(out/'selected.DD').read_bytes()
        if POINTER.findall(selected)!=POINTER.findall(records[0]) or POINTER.sub(b',U=<entry>$',selected)!=bank(True):raise ValueError('Initial middle-row selection differs')
        if [(out/n).read_bytes() for n in ('seed-data.bin','seed-strings.DD','seed-accounts.DD')]!=records[3:]:raise ValueError('Account views changed seeded files')
        info=list(struct.unpack('<8q',(out/'picker-info.bin').read_bytes()));bank_index=order.index('BANK');rent_index=order.index('RENT')
        if info!=[13,bank_index,bank_index,rent_index,13,rent_index,bank_index,rent_index]:raise ValueError('Picker defaults/indices differ: '+repr(info))
        verify_menus((out/'picker1.DD').read_bytes(),(out/'picker2.DD').read_bytes())
        report['picker_order']=order;report['picker_info']=info
        if args.disk:
            for name in EXTRA_NAMES:
                actual=(out/name).read_bytes();reference=(gold/name).read_bytes()
                if normalize_phase(name,actual)!=normalize_phase(name,reference):raise ValueError('Original picker phase differs: '+name)
        if args.disk:
            guest.wait('COMMAND OK\n',start=guest.collect().index('INPUT LINE BudgetPicker;'))
            guest.command('6*7;');guest.result_pixels()
        if args.disk:
            guest.close();guest=None
            persisted=pack['snapshot'](image.read_bytes())[1]
            guest=Guest(image,out/'guest-reopen',True)
            guest.wait('DONE native kernel startup\n');time.sleep(3)
            # No installation or writes: reopen the actual image saved in phase one.
            for command in commands:
                if '/Install.HC' not in command:guest.command(command)
        guest.type('BudgetPicker(TRUE);');guest.press('ret')
        guest.wait('BR ready\n');time.sleep(2);guest.screenshot('reopen-before')
        guest.key('shift',True);guest.press('esc');guest.key('shift',False)
        guest.wait('BR done\n',30)
        reopened=[(guest.out/n).read_bytes() for n in REOPEN_NAMES]
        if args.disk:
            guest.wait('COMMAND OK\n',start=guest.collect().index('INPUT LINE BudgetPicker(TRUE);'))
            guest.command('6*7;');guest.result_pixels()
        guest.close();guest=None
        for name,value in zip(REOPEN_NAMES,reopened):(out/name).write_bytes(value)
        reopened_normalized=verify_reopen(reopened,records)
        if args.disk:
            if reopened_normalized!=verify_reopen([(gold/n).read_bytes() for n in REOPEN_NAMES],[(gold/n).read_bytes() for n in NAMES]):
                raise ValueError('Original reopen comparison differs')
            after_abort=pack['snapshot'](image.read_bytes())[1]
            if after_abort!=persisted:raise ValueError('Cold reopen/abort changed file bytes or metadata')
            report['cold_reopen_abort_files_unchanged']=True
        report['reopen_mask']=struct.unpack('<q',reopened[2])[0]
        report['reopen_normalized_documents']=[v.decode('latin1') for v in reopened_normalized]
        if args.disk:
            files=pack['snapshot'](image.read_bytes())[1]
            allowed={'/Probe/BudgetPicker.HC','/Budget/Accts.DD.Z','/Budget/Strs.DD.Z','/Budget/Bgt.DATA.Z'}
            changed={n for n in set(before)|set(files) if before.get(n)!=files.get(n)}
            if changed-allowed:raise ValueError('Unrelated file changed: '+repr(changed-allowed))
            report['changed_files']=sorted(changed);report['preserved_files']=len(set(before)-allowed)
            report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        for name,value in zip(NAMES,records):(out/name).write_bytes(value)
        normalized=verify(records)
        if args.disk and normalized!=verify([(gold/n).read_bytes() for n in NAMES]):raise ValueError('Original account views differ')
        report.update(result='pass',mask=struct.unpack('<q',records[2])[0],normalized_documents=[v.decode('latin1') for v in normalized])
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if guest is not None:guest.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
