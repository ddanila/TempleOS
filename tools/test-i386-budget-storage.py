#!/usr/bin/env python3
"""Compare original Budget storage and native cold-boot reopening."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ACCOUNTS = {'JOB','BANK','CREDIT','CASH','RENT','CAR','UTILITIES','MISC','CLOTHS','HEALTH','CHARITY'}


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def verify(data, strings, mask):
    if mask != struct.pack('<q', 15):
        raise ValueError('Budget reopened state differs: '+repr(mask))
    rows = strings.decode('ascii').splitlines()
    pairs = [row.split(',', 1) for row in rows]
    if len(pairs) != 12 or [int(k) for k, _ in pairs] != list(range(12)):
        raise ValueError('String table numbering differs')
    indices = {s:int(k) for k,s in pairs}
    if set(indices) != ACCOUNTS | {'rent payment'}:
        raise ValueError('String table content differs')
    expected = struct.pack('<qQHHIIIdq', 1, (730000<<32)+0x10000000, 0, 0,
                           indices['BANK'], indices['RENT'], indices['rent payment'], 125.0, 0)
    if data != expected:
        raise ValueError('Budget typed record differs')


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path,nargs='?')
    ap.add_argument('--archive',type=Path)
    ap.add_argument('--reference',type=Path)
    ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    if args.disk and not args.reference:ap.error('Native requires --reference')
    if not args.disk and not args.archive:ap.error('Original requires --archive')
    fixture=ROOT/'tests/guest/i386-budget-storage/Contract.HC'
    paths=[Path(__file__).resolve(),fixture,ROOT/'docs/i386-compatibility-inventory.json']
    paths += [ROOT/('tools/'+n) for n in ('build-iso.py','guest-run.py','test-i386-timeclock-reference.py',
        'package-i386-native-image.py','build-i386-kernel.py','test-i386-timeclock-welcome.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    paths.append(ROOT/'tools/i386-budget-source.py')
    pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
    if args.disk:
        gold=args.reference.resolve();info=json.loads((gold/'result.json').read_text())
        if info.get('result')!='pass' or not info.get('inputs_unchanged') or info.get('fixture_sha256')!=sha(fixture):
            raise ValueError('Matching passing original reference required')
        paths += [args.disk.resolve(), gold/'result.json']+[gold/n for n in ('data.bin','strings.DD','mask.bin')]
    else:paths.append(args.archive.resolve())
    out.mkdir(parents=True)
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',fixture_sha256=sha(fixture),input_sha256=pins,
        scope='Budget with reviewed I64 sort-slot port: installation, constructed transaction, exact typed/string records, same-session reopen and native cold reboot. Not UI transaction entry, account views, templates or whole application qualification.')
    try:
        if not args.disk:
            overlay=out/'overlay';overlay.mkdir()
            report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Apps/Budget/Accts.DD.Z').write_bytes(args.archive.read_bytes())
            once=b'Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");\n#include "T:/Apps/Budget/Load.HC"\n#include "T:/Apps/Budget/Install.HC"\n'
            once+=fixture.read_bytes()+b'\nU0 BSLog(U8 *s){while(*s)OutU8(0xE9,*s++);}\nBSPaths;BSWrite;\n'
            once+=b'BSLog(MStrPrint("EXPORT data.bin %X %X\\n",bs_data,bs_data_size));BSLog(MStrPrint("EXPORT strings.DD %X %X\\n",bs_strings,bs_strings_size));BSLog(MStrPrint("EXPORT mask.bin %X %X\\n",&bs_mask,8));BSLog("DONE Budget storage\\n");\n'
            (overlay/'Once.HC').write_bytes(once)
            iso=out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            subprocess.run(['python3','tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','180'],cwd=ROOT,check=True)
            for n in ('data.bin','strings.DD','mask.bin'):(out/n).write_bytes((out/'guest'/n).read_bytes())
            verify(*[(out/n).read_bytes() for n in ('data.bin','strings.DD','mask.bin')])
        else:
            image=out/'working.img'
            before=pack['snapshot'](args.disk.read_bytes())[1]
            inv=json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())
            budget_source=runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['budget_source']
            report['source_ports']=['Apps/Budget/BgtStrs.HC: explicit I64 sort slots']
            for e in inv['entries']:
                if e['path'].startswith('Apps/Budget/') and before['/'+e['path']][2]!=budget_source(e):
                    raise ValueError('Bundled Budget differs: '+e['path'])
            source=fixture.read_bytes()+b'\nU0 BSSave(){FileWrite("C:/BSData.DATA",bs_data,bs_data_size);FileWrite("C:/BSStrings.DATA",bs_strings,bs_strings_size);FileWrite("C:/BSMask.DATA",&bs_mask,8);}\n'
            report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/BudgetStorage.HC':source})
            load=['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);',
                  '#include "C:/Apps/Budget/Load.HC"','#include "C:/Probe/BudgetStorage.HC"']
            guest=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest']
            phases=[load+['#include "C:/Apps/Budget/Install.HC"','BSPaths;BSWrite;BSSave;','6*7;'],
                    load+['BSPaths;BSRead;BSSave;','6*7;']]
            persisted=None;report['phases']=[]
            for i,commands in enumerate(phases):
                guest(image,out/('guest-'+str(i)),commands,64,True,accel='kvm')
                files=pack['snapshot'](image.read_bytes())[1]
                data,strings,mask=[files[n][2] for n in ('/BSData.DATA','/BSStrings.DATA','/BSMask.DATA')]
                verify(data,strings,mask)
                for n,value in zip(('data.bin','strings.DD','mask.bin'),(data,strings,mask)):
                    (out/(str(i)+'-'+n)).write_bytes(value)
                    if value!=(gold/n).read_bytes():raise ValueError('Original comparison differs: '+n)
                saved={n:v for n,v in files.items() if n.startswith('/Budget/')}
                if persisted is not None and saved!=persisted:raise ValueError('Reboot changed Budget bytes/metadata')
                persisted=saved
                report['phases'].append(dict(phase=i,result='pass',commands=commands))
            allowed={'/Probe/BudgetStorage.HC','/Budget/Accts.DD.Z','/Budget/Strs.DD.Z','/Budget/Bgt.DATA.Z','/BSData.DATA','/BSStrings.DATA','/BSMask.DATA'}
            changed={n for n in set(before)|set(files) if before.get(n)!=files.get(n)}
            if changed-allowed:raise ValueError('Unrelated file changed: '+repr(changed-allowed))
            report['changed_files']=sorted(changed);report['preserved_files']=len(set(before)-allowed)
            report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
