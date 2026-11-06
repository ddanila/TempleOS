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
    if mask!=struct.pack('<q',127):raise ValueError('Entry/restoration mask differs: '+repr(mask))
    ids=POINTER.findall(after)
    if len(ids)!=1 or not int(ids[0],16):raise ValueError('Missing transaction identity')
    normalized=[POINTER.sub(b',U=<entry>$',v) for v in (before,after)]
    expected=[b'',b'$FG,1$$MU-UL,"09/04/98     BANK     RENT: -125.50   125.50:popup entry",U=<entry>$\n\x05']
    if normalized!=expected:raise ValueError('Entry documents differ: '+repr(normalized))
    pairs=[row.split(',',1) for row in strings.decode('ascii').splitlines()]
    indices={value:int(key) for key,value in pairs}
    names={'JOB','BANK','CREDIT','CASH','RENT','CAR','UTILITIES','MISC','CLOTHS','HEALTH','CHARITY','popup entry'}
    if set(indices)!=names or [int(k) for k,v in pairs]!=list(range(12)):
        raise ValueError('Saved strings differ after popup entry')
    expected_data=struct.pack('<qQHHIIIdq',1,730000<<32,0,0,indices['BANK'],indices['RENT'],indices['popup entry'],125.5,0)
    if data!=expected_data:raise ValueError('Saved transaction records differ')
    expected_accounts=b'$FG,6$JOB\n$FG,1$BANK\n$FG,4$CREDIT\n$FG,2$CASH\n$FG,0$RENT\nCAR\nUTILITIES\nMISC\nCLOTHS\nHEALTH\nCHARITY\n'
    if accounts!=expected_accounts:raise ValueError('Saved accounts differ')
    return normalized+[data,strings,accounts]


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--archive',type=Path);ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();fixture=ROOT/'tests/guest/i386-budget-entry/Contract.HC'
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
    report=dict(result='running',fixture_sha256=sha(fixture),input_sha256=pins,scope='Full Budget() new transaction through real popup form and emulated keyboard: fixed date, amount, accounts and description, Escape accept/save, exact records and caller restoration. First cancels a fully typed popup; native cold reboot then read-only Budget reopen/abort, original same-boot reopen. Not full application qualification.')
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
        guest.press('n');guest.wait('BP cancel form\n',30);time.sleep(2)
        for i,value in enumerate(['01/01/2001','999.99','GHOST','VOID','discard me']):
            guest.type(value)
            if i<4:guest.press('tab')
        guest.screenshot('cancel-filled')
        guest.key('shift',True);guest.press('esc');guest.key('shift',False)
        guest.wait('BP cancelled\n',30);guest.screenshot('cancelled')
        guest.press('n');guest.wait('BP form\n',30);time.sleep(2);guest.screenshot('form')
        for i,value in enumerate(['09/04/1998','125.50','BANK','RENT','popup entry']):
            guest.type(value)
            if i<4:guest.press('tab')
        guest.screenshot('form-filled');guest.press('esc')
        guest.wait('BP entered\n',30);time.sleep(1);guest.screenshot('entered')
        guest.press('esc');guest.wait('BP done\n',30)
        records=[(out/'guest'/n).read_bytes() for n in NAMES]
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
        if reopened[2]!=struct.pack('<q',63) or reopened[3:]!=records[3:]:
            raise ValueError('Reopened records/restoration differ')
        if reopened[0]!=reopened[1]:raise ValueError('Read-only reopened document changed')
        for doc in reopened[:2]:
            ids=POINTER.findall(doc)
            if len(ids)!=1 or not int(ids[0],16) or POINTER.sub(b',U=<entry>$',doc)!=POINTER.sub(b',U=<entry>$',records[1]):
                raise ValueError('Reopened account view differs')
        if args.disk:
            if pack['snapshot'](image.read_bytes())[1]!=persisted:
                raise ValueError('Cold reopen/abort changed file bytes/metadata')
            for name,actual in zip(REOPEN_NAMES,reopened):
                if POINTER.sub(b',U=<entry>$',actual)!=POINTER.sub(b',U=<entry>$',(gold/name).read_bytes()):
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
