#!/usr/bin/env python3
"""Compare Budget account documents, selected rows and delete callback."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]
NAMES=('bank.DD','rent.DD','deleted.DD','mask.bin')
POINTER=re.compile(rb',U=0x([0-9A-F]+)\$')


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def verify(records):
    bank,rent,deleted,mask=records
    if mask!=struct.pack('<q',31):raise ValueError('Account-view state mask differs: '+repr(mask))
    ids=[POINTER.findall(data) for data in (bank,rent,deleted)]
    if len(ids[0])!=3 or len(set(ids[0]))!=3 or ids[1]!=ids[0] or ids[2]!=[ids[0][0],ids[0][2]] or any(int(v,16)==0 for v in ids[0]):
        raise ValueError('Rows do not retain transaction identities')
    def row(date,credit,debit,balance,amount,desc):
        return f'$MU-UL,"{date} {credit:>8} {debit:>8}:{balance:8.2f} {amount:8.2f}:{desc}",U=<entry>$\n'.encode()
    expected=[
        b'$FG,0$'+row('09/04/98','WAGES','BANK',100,100,'salary')+b'$FG,1$'+row('09/05/98','BANK','FOOD',80,20,'groceries')+row('09/06/98','BANK','RENT',50,30,'rent')+b'\x05',
        b'$FG,0$'+row('09/04/98','WAGES','BANK',0,100,'salary')+b'$FG,1$\x05'+row('09/05/98','BANK','FOOD',0,20,'groceries')+row('09/06/98','BANK','RENT',30,30,'rent'),
        b'$FG,0$'+row('09/04/98','WAGES','BANK',100,100,'salary')+b'$FG,1$\x05'+row('09/06/98','BANK','RENT',70,30,'rent')]
    normalized=[POINTER.sub(b',U=<entry>$',v) for v in (bank,rent,deleted)]
    if normalized!=expected:raise ValueError('Account documents differ from independent expected rows')
    return normalized


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--archive',type=Path);ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();fixture=ROOT/'tests/guest/i386-budget-views/Contract.HC'
    if out.exists():ap.error('Use a fresh output directory')
    if args.disk and not args.reference:ap.error('Native requires --reference')
    if not args.disk and not args.archive:ap.error('Original requires --archive')
    paths=[Path(__file__).resolve(),fixture,ROOT/'docs/i386-compatibility-inventory.json',ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ('i386-budget-source.py','build-iso.py','guest-run.py','test-i386-timeclock-reference.py','package-i386-native-image.py','build-i386-kernel.py','test-i386-timeclock-welcome.py')]
    if args.disk:
        gold=args.reference.resolve();info=json.loads((gold/'result.json').read_text())
        if info.get('result')!='pass' or not info.get('inputs_unchanged') or info.get('fixture_sha256')!=sha(fixture):raise ValueError('Matching original reference required')
        paths += [args.disk.resolve(),gold/'result.json']+[gold/n for n in NAMES]
    else:paths.append(args.archive.resolve())
    out.mkdir(parents=True);pins={str(p):sha(p) for p in paths}
    report=dict(result='running',fixture_sha256=sha(fixture),input_sha256=pins,scope='Actual BgtRegen and BgtPutKey over unsorted constructed transactions: account colors/balances/rows, selection preservation, delete and unhandled-key callbacks. Not physical key/mouse input, rendered pixels, popup entry or whole application qualification.')
    try:
        if not args.disk:
            overlay=out/'overlay';overlay.mkdir()
            report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Apps/Budget/Accts.DD.Z').write_bytes(args.archive.read_bytes())
            once=b'Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");\n#include "T:/Apps/Budget/Load.HC"\n#include "T:/Apps/Budget/Install.HC"\n'+fixture.read_bytes()
            once+=b'\nU0 BVLog(U8 *s){while(*s)OutU8(0xE9,*s++);}\nBudgetViews;\n'
            for name,value,size in [('bank.DD','bv_bank','bv_bank_size'),('rent.DD','bv_rent','bv_rent_size'),('deleted.DD','bv_deleted','bv_deleted_size'),('mask.bin','&bv_mask','8')]:
                once+=f'BVLog(MStrPrint("EXPORT {name} %X %X\\n",{value},{size}));\n'.encode()
            once+=b'BVLog("DONE Budget views\\n");\n';(overlay/'Once.HC').write_bytes(once)
            iso=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            subprocess.run(['python3','tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','180'],cwd=ROOT,check=True)
            records=[(out/'guest'/n).read_bytes() for n in NAMES]
        else:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));before=pack['snapshot'](args.disk.read_bytes())[1]
            expected=runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['budget_source']
            for entry in json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())['entries']:
                if entry['path'].startswith('Apps/Budget/') and before['/'+entry['path']][2]!=expected(entry):raise ValueError('Budget source differs: '+entry['path'])
            source=fixture.read_bytes()+b'\nU0 BVSave(){FileWrite("C:/BVBank.DATA",bv_bank,bv_bank_size);FileWrite("C:/BVRent.DATA",bv_rent,bv_rent_size);FileWrite("C:/BVDeleted.DATA",bv_deleted,bv_deleted_size);FileWrite("C:/BVMask.DATA",&bv_mask,8);}\n'
            image=out/'working.img';report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/BudgetViews.HC':source})
            commands=['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Apps/Budget/Load.HC"','#include "C:/Apps/Budget/Install.HC"','#include "C:/Probe/BudgetViews.HC"','BudgetViews;BVSave;','6*7;']
            report['commands']=commands
            runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](image,out/'guest',commands,64,True,accel='kvm')
            files=pack['snapshot'](image.read_bytes())[1];outputs=('/BVBank.DATA','/BVRent.DATA','/BVDeleted.DATA','/BVMask.DATA');records=[files[n][2] for n in outputs]
            allowed=set(outputs)|{'/Probe/BudgetViews.HC','/Budget/Accts.DD.Z'}
            changed={n for n in set(before)|set(files) if before.get(n)!=files.get(n)}
            if changed-allowed:raise ValueError('Unrelated file changed: '+repr(changed-allowed))
            report['changed_files']=sorted(changed);report['preserved_files']=len(set(before)-allowed)
            report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        for name,value in zip(NAMES,records):(out/name).write_bytes(value)
        normalized=verify(records)
        if args.disk and normalized!=verify([(gold/n).read_bytes() for n in NAMES]):raise ValueError('Original account views differ')
        report.update(result='pass',mask=struct.unpack('<q',records[3])[0],normalized_documents=[v.decode('latin1') for v in normalized])
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
