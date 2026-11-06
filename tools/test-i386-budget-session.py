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
POINTER=re.compile(rb',U=0x([0-9A-F]+)\$')


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def verify(records):
    before,after,mask,data,strings,accounts=records
    if mask!=struct.pack('<q',63):raise ValueError('Keyboard state mask differs: '+repr(mask))
    ids=[POINTER.findall(data) for data in (before,after)]
    if len(ids[0])!=3 or len(set(ids[0]))!=3 or ids[1]!=[ids[0][0],ids[0][2]] or any(int(v,16)==0 for v in ids[0]):
        raise ValueError('Keyboard deletion changed transaction identities')
    def row(date,credit,debit,balance,amount,desc):
        return f'$MU-UL,"{date} {credit:>8} {debit:>8}:{balance:8.2f} {amount:8.2f}:{desc}",U=<entry>$\n'.encode()
    expected=[b'$FG,0$'+row('09/04/98','WAGES','BANK',100,100,'salary')+b'$FG,1$'+row('09/05/98','BANK','FOOD',80,20,'groceries')+row('09/06/98','BANK','RENT',50,30,'rent')+b'\x05',
              b'$FG,0$'+row('09/04/98','WAGES','BANK',100,100,'salary')+b'$FG,1$\x05'+row('09/06/98','BANK','RENT',70,30,'rent')]
    normalized=[POINTER.sub(b',U=<entry>$',v) for v in (before,after)]
    if normalized!=expected:raise ValueError('Keyboard account documents differ')
    pairs=[row.split(',',1) for row in strings.decode('ascii').splitlines()]
    indices={value:int(key) for key,value in pairs}
    names={'JOB','BANK','CREDIT','CASH','RENT','CAR','UTILITIES','MISC','CLOTHS','HEALTH','CHARITY','WAGES','FOOD','salary','rent'}
    if set(indices)!=names or [int(k) for k,v in pairs]!=list(range(15)):
        raise ValueError('Saved strings differ after interactive deletion')
    expected_data=struct.pack('<q',2)
    for day,credit,debit,amount,desc in [(730000,'WAGES','BANK',100.,'salary'),(730002,'BANK','RENT',30.,'rent')]:
        expected_data+=struct.pack('<QHHIIId',day<<32,0,0,indices[credit],indices[debit],indices[desc],amount)
    expected_data+=struct.pack('<q',0)
    if data!=expected_data:raise ValueError('Saved transaction records differ')
    expected_accounts=b'$FG,6$JOB\n$FG,1$BANK\n$FG,4$CREDIT\n$FG,2$CASH\n$FG,0$RENT\nCAR\nUTILITIES\nMISC\nCLOTHS\nHEALTH\nCHARITY\nWAGES\nFOOD\n'
    if accounts!=expected_accounts:raise ValueError('Saved accounts differ')
    return normalized+[data,strings,accounts]


def verify_reopen(records, saved):
    before,after,mask,data,strings,accounts=records
    if mask!=struct.pack('<q',63):raise ValueError('Reopen/restoration mask differs')
    ids=[POINTER.findall(doc) for doc in (before,after)]
    if len(ids[0])!=2 or len(set(ids[0]))!=2 or ids[1]!=[ids[0][1]] or any(int(v,16)==0 for v in ids[0]):
        raise ValueError('Reopened deletion identities differ')
    # A fresh View starts at the end, rather than the saved session's selected row.
    expected_before=POINTER.sub(b',U=<entry>$',saved[1]).replace(b'\x05',b'')+b'\x05'
    expected_after=b'$FG,1$\x05$MU-UL,"09/06/98     BANK     RENT:  -30.00    30.00:rent",U=<entry>$\n'
    normalized=[POINTER.sub(b',U=<entry>$',v) for v in (before,after)]
    if normalized!=[expected_before,expected_after]:raise ValueError('Reopened documents differ: '+repr(normalized))
    if records[3:]!=saved[3:]:raise ValueError('Abort changed saved records')
    return normalized+[data,strings,accounts]


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--archive',type=Path);ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();fixture=ROOT/'tests/guest/i386-budget-session/Contract.HC'
    if out.exists():ap.error('Use a fresh output directory')
    if args.disk and not args.reference:ap.error('Native requires --reference')
    if not args.disk and not args.archive:ap.error('Original requires --archive')
    paths=[Path(__file__).resolve(),fixture,ROOT/'docs/i386-compatibility-inventory.json',ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ('i386-budget-source.py','build-iso.py','guest-run.py','test-i386-timeclock-reference.py','package-i386-native-image.py','build-i386-kernel.py','test-i386-timeclock-welcome.py','test-i386-autocomplete-interaction.py')]
    if args.disk:
        gold=args.reference.resolve();info=json.loads((gold/'result.json').read_text())
        if info.get('result')!='pass' or not info.get('inputs_unchanged') or info.get('fixture_sha256')!=sha(fixture):raise ValueError('Matching original reference required')
        paths += [args.disk.resolve(),gold/'result.json']+[gold/n for n in NAMES+REOPEN_NAMES]
    else:paths.append(args.archive.resolve())
    out.mkdir(parents=True);pins={str(p):sha(p) for p in paths}
    report=dict(result='running',fixture_sha256=sha(fixture),input_sha256=pins,scope='Full Budget() lifecycle with preseeded transactions: Home/Down selection, Ctrl-Y deletion, Escape save, same-session readback, document/menu/settings/window/autocomplete restoration. Cold native reboot then Home/Ctrl-Y/Shift-Escape abort and unchanged saved files. Original control reopens in the same boot. Not popup entry or full application qualification.')
    for source,name in [(fixture,'fixture.HC'),(Path(__file__).resolve(),'runner-source.py')]:
        (out/name).write_bytes(source.read_bytes())
    guest=None
    try:
        if not args.disk:
            overlay=out/'overlay';overlay.mkdir()
            report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Apps/Budget/Accts.DD.Z').write_bytes(args.archive.read_bytes())
            once=b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");\n#include "T:/Apps/Budget/Load.HC"\n#include "T:/Apps/Budget/Install.HC"\n'+fixture.read_bytes()+b'\nBudgetSession;\n'
            (overlay/'Once.HC').write_bytes(once)
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        else:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));before=pack['snapshot'](args.disk.read_bytes())[1]
            expected=runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['budget_source']
            for entry in json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())['entries']:
                if entry['path'].startswith('Apps/Budget/') and before['/'+entry['path']][2]!=expected(entry):raise ValueError('Budget source differs: '+entry['path'])
            image=out/'working.img';report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/BudgetSession.HC':fixture.read_bytes()})
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        guest=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            guest.wait('DONE native kernel startup\n');time.sleep(3)
            commands=['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Apps/Budget/Load.HC"','#include "C:/Apps/Budget/Install.HC"','#include "C:/Probe/BudgetSession.HC"']
            report['commands']=commands
            for command in commands:guest.command(command)
            guest.type('BudgetSession;');guest.press('ret')
        guest.wait('BP ready\n');time.sleep(2);guest.screenshot('before')
        guest.press('home');guest.press('down');guest.wait('BP selected\n',30)
        guest.screenshot('selected')
        guest.key('ctrl',True);guest.press('y');guest.key('ctrl',False)
        guest.wait('BP deleted\n',30);time.sleep(1);guest.screenshot('deleted')
        guest.press('esc');guest.wait('BP done\n',30)
        records=[(out/'guest'/n).read_bytes() for n in NAMES]
        if args.disk:
            guest.wait('COMMAND OK\n',start=guest.collect().index('INPUT LINE BudgetSession;'))
            guest.command('6*7;');guest.result_pixels()
        if args.disk:
            guest.close();guest=None
            persisted=pack['snapshot'](image.read_bytes())[1]
            guest=Guest(image,out/'guest-reopen',True)
            guest.wait('DONE native kernel startup\n');time.sleep(3)
            # No installation or writes: reopen the actual image saved in phase one.
            for command in commands:
                if '/Install.HC' not in command:guest.command(command)
        guest.type('BudgetSession(TRUE);');guest.press('ret')
        guest.wait('BR ready\n');time.sleep(2);guest.screenshot('reopen-before')
        guest.press('home');guest.wait('BR selected\n',30)
        guest.key('ctrl',True);guest.press('y');guest.key('ctrl',False)
        guest.wait('BR deleted\n',30);time.sleep(1);guest.screenshot('reopen-deleted')
        guest.key('shift',True);guest.press('esc');guest.key('shift',False)
        guest.wait('BR done\n',30)
        reopened=[(guest.out/n).read_bytes() for n in REOPEN_NAMES]
        if args.disk:
            guest.wait('COMMAND OK\n',start=guest.collect().index('INPUT LINE BudgetSession(TRUE);'))
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
            allowed={'/Probe/BudgetSession.HC','/Budget/Accts.DD.Z','/Budget/Strs.DD.Z','/Budget/Bgt.DATA.Z'}
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
