#!/usr/bin/env python3
"""Drive full Budget open/save/close with emulated keyboard events."""
from fractions import Fraction
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
EDIT_NAMES=('entered.DD','edited.DD')
POINTER=re.compile(rb',U=0x([0-9A-F]+)\$')


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def verify(records,native=False,cancel_existing=False):
    before,after,mask,data,strings,accounts=records
    if mask!=struct.pack('<q',2047 if cancel_existing else 511):raise ValueError('Entry/restoration mask differs: '+repr(mask))
    ids=POINTER.findall(after)
    if len(ids)!=2 or len(set(ids))!=2 or not all(int(v,16) for v in ids):raise ValueError('Missing transaction identity')
    normalized=[POINTER.sub(b',U=<entry>$',v) for v in (before,after)]
    expected=[b'',b'$FG,1$$MU-UL,"09/04/98     BANK     RENT: -125.50   125.50:popup entry!",U=<entry>$\n\x05$MU-UL,"09/04/98     BANK     RENT: -251.00   125.50:popup entry!",U=<entry>$\n']
    if normalized!=expected:raise ValueError('Entry documents differ: '+repr(normalized))
    pairs=[row.split(',',1) for row in strings.decode('ascii').splitlines()]
    indices={value:int(key) for key,value in pairs}
    names={'JOB','BANK','CREDIT','CASH','RENT','CAR','UTILITIES','MISC','CLOTHS','HEALTH','CHARITY','popup entry!'}
    if set(indices)!=names or [int(k) for k,v in pairs]!=list(range(12)):
        raise ValueError('Saved strings differ after popup entry')
    amount_bits=0x405F600000000002
    if native:
        # Existing native policy: exact rational power rounded to binary64, then binary64 multiply.
        value=float(Fraction(12550))*float(Fraction(1,100))
        amount_bits=struct.unpack('<Q',struct.pack('<d',value))[0]
        if amount_bits!=0x405F600000000000:raise ValueError('Unsupported host binary64 oracle')
    entry=struct.pack('<QHHIIIQ',766525<<32,0,0,indices['BANK'],indices['RENT'],indices['popup entry!'],amount_bits)
    expected_data=struct.pack('<q',2)+entry*2+struct.pack('<q',0)
    if data!=expected_data:raise ValueError('Saved transaction records differ')
    expected_accounts=b'$FG,6$JOB\n$FG,1$BANK\n$FG,4$CREDIT\n$FG,2$CASH\n$FG,0$RENT\nCAR\nUTILITIES\nMISC\nCLOTHS\nHEALTH\nCHARITY\n'
    if accounts!=expected_accounts:raise ValueError('Saved accounts differ')
    return normalized+[data,strings,accounts]


def compare_target_data(actual,reference):
    offsets=[i for i,(a,b) in enumerate(zip(actual,reference)) if a!=b]
    if len(actual)!=80 or len(reference)!=80 or offsets!=[32,64]:
        raise ValueError('Unexpected serialized target difference')
    return offsets


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--archive',type=Path);ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--cancel-existing',action='store_true',help='Cancel modified existing-entry and copy forms before accepting them');args=ap.parse_args()
    out=args.out.resolve();fixture=ROOT/'tests/guest/i386-budget-edit-copy'/('Cancellation.HC' if args.cancel_existing else 'Contract.HC')
    edit_names=EDIT_NAMES+('edit-cancelled.DD','copy-cancelled.DD') if args.cancel_existing else EDIT_NAMES
    if out.exists():ap.error('Use a fresh output directory')
    if args.disk and not args.reference:ap.error('Native requires --reference')
    if not args.disk and not args.archive:ap.error('Original requires --archive')
    paths=[Path(__file__).resolve(),fixture,ROOT/'docs/i386-compatibility-inventory.json',ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ('i386-budget-source.py','build-iso.py','guest-run.py','test-i386-timeclock-reference.py','package-i386-native-image.py','build-i386-kernel.py','test-i386-timeclock-welcome.py','test-i386-autocomplete-interaction.py')]
    if args.disk:
        gold=args.reference.resolve();info=json.loads((gold/'result.json').read_text())
        if info.get('result')!='pass' or not info.get('inputs_unchanged') or info.get('fixture_sha256')!=sha(fixture):raise ValueError('Matching original reference required')
        paths += [args.disk.resolve(),gold/'result.json']+[gold/n for n in NAMES+REOPEN_NAMES+edit_names]
    else:paths.append(args.archive.resolve())
    out.mkdir(parents=True);pins={str(p):sha(p) for p in paths}
    report=dict(result='running',cancel_existing=args.cancel_existing,cancellation_scope='Modified form tags are observed before Shift-Escape; original transaction/document/string identities, exact values and absent unsaved files must survive' if args.cancel_existing else None,fixture_sha256=sha(fixture),input_sha256=pins,scope='Full Budget() edit/copy existing transaction after new-entry cancellation: read-only observer, real keyboard description edit and independent copy allocation, save/cold native reopen; new transaction through real popup form and emulated keyboard: fixed date, amount, accounts and description, Escape accept/save, exact records and caller restoration. First cancels a fully typed popup; native cold reboot then read-only Budget reopen/abort, original same-boot reopen. Not full application qualification.')
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
        guest.press('home');guest.wait('BP edit selected\n',30);guest.press('ret')
        if args.cancel_existing:
            guest.wait('BP edit cancel form\n',30);time.sleep(2)
            for i in range(4):guest.press('tab')
            guest.key('ctrl',True);guest.press('right');guest.key('ctrl',False);guest.type('?')
            guest.wait('BP edit draft changed\n',30);guest.screenshot('edit-cancel-filled');guest.key('shift',True);guest.press('esc');guest.key('shift',False)
            guest.wait('BP edit cancelled\n',30);guest.screenshot('edit-cancelled');guest.press('home');guest.press('ret')
        guest.wait('BP edit form\n',30);time.sleep(2);guest.screenshot('edit-form')
        for i in range(4):guest.press('tab')
        guest.key('ctrl',True);guest.press('right');guest.key('ctrl',False);guest.type('!')
        guest.screenshot('edit-filled');guest.press('esc');guest.wait('BP edited\n',30)
        guest.screenshot('edited');guest.press('home');guest.press('c')
        if args.cancel_existing:
            guest.wait('BP copy cancel form\n',30);time.sleep(2)
            for i in range(4):guest.press('tab')
            guest.key('ctrl',True);guest.press('right');guest.key('ctrl',False);guest.type('?')
            guest.wait('BP copy draft changed\n',30);guest.screenshot('copy-cancel-filled');guest.key('shift',True);guest.press('esc');guest.key('shift',False)
            guest.wait('BP copy cancelled\n',30);guest.screenshot('copy-cancelled');guest.press('home');guest.press('c')
        guest.wait('BP copy form\n',30)
        time.sleep(2);guest.screenshot('copy-form');guest.press('esc');guest.wait('BP copied\n',30)
        guest.screenshot('copied');guest.press('esc');guest.wait('BP done\n',30)
        records=[(out/'guest'/n).read_bytes() for n in NAMES]
        snapshots=[(out/'guest'/n).read_bytes() for n in EDIT_NAMES]
        expected_entered=b'$FG,1$$MU-UL,"09/04/98     BANK     RENT: -125.50   125.50:popup entry",U=<entry>$\n\x05'
        expected_edited=expected_entered.replace(b'popup entry"',b'popup entry!"')
        for name,value,expected_doc in zip(EDIT_NAMES,snapshots,(expected_entered,expected_edited)):
            ids=POINTER.findall(value)
            if len(ids)!=1 or not int(ids[0],16) or POINTER.sub(b',U=<entry>$',value)!=expected_doc:
                raise ValueError('Intermediate edit document differs: '+name+': '+repr(value))
            (out/name).write_bytes(value)
            if args.disk and POINTER.sub(b',U=<entry>$',value)!=POINTER.sub(b',U=<entry>$',(gold/name).read_bytes()):
                raise ValueError('Original intermediate document differs: '+name)
        if args.cancel_existing:
            for name,base_name in [('edit-cancelled.DD','entered.DD'),('copy-cancelled.DD','edited.DD')]:
                value=(out/'guest'/name).read_bytes();base=(out/base_name).read_bytes()
                expected_doc=base[:-1].replace(b'$FG,1$$MU',b'$FG,1$\x05$MU')
                if value!=expected_doc:raise ValueError('Cancelled form changed entry document/identity: '+name+': '+repr(value))
                (out/name).write_bytes(value)
                if args.disk and POINTER.sub(b',U=<entry>$',value)!=POINTER.sub(b',U=<entry>$',(gold/name).read_bytes()):
                    raise ValueError('Original cancellation document differs: '+name)
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
        expected_reopened=POINTER.sub(b',U=<entry>$',records[1]).replace(b'\n\x05$MU',b'\n$MU')+b'\x05'
        for doc in reopened[:2]:
            ids=POINTER.findall(doc)
            if len(ids)!=2 or len(set(ids))!=2 or not all(int(v,16) for v in ids) or POINTER.sub(b',U=<entry>$',doc)!=expected_reopened:
                raise ValueError('Reopened account view differs')
        if args.disk:
            if pack['snapshot'](image.read_bytes())[1]!=persisted:
                raise ValueError('Cold reopen/abort changed file bytes/metadata')
            for name,actual in zip(REOPEN_NAMES,reopened):
                if name=='reopen-data.bin':
                    compare_target_data(actual,(gold/name).read_bytes())
                elif POINTER.sub(b',U=<entry>$',actual)!=POINTER.sub(b',U=<entry>$',(gold/name).read_bytes()):
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
        normalized=verify(records,native=bool(args.disk),cancel_existing=args.cancel_existing)
        if args.disk:
            reference=verify([(gold/n).read_bytes() for n in NAMES],cancel_existing=args.cancel_existing)
            if normalized[:2]+normalized[3:]!=reference[:2]+reference[3:]:raise ValueError('Original account views differ')
            offsets=compare_target_data(normalized[2],reference[2])
            report['numeric_architecture_difference']=dict(original_amount_bits='405F600000000002',native_amount_bits='405F600000000000',differing_data_offsets=offsets,policy='docs/i386-lex-number.md; docs/i386-f64-backend.md')
        report.update(result='pass',mask=struct.unpack('<q',records[2])[0],normalized_documents=[v.decode('latin1') for v in normalized])
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if guest is not None:guest.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
