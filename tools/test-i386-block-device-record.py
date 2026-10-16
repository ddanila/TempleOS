#!/usr/bin/env python3
"""Check every canonical block-device field in the native public ABI."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
FIXTURE=ROOT/"Kernel/BlkDev/BlockDevRecord.HH"
# Packed i386 ABI: pointers are four bytes; I64/F64 remain eight bytes.
FIELDS = [('lock_fwding',0,4),('locked_flags',4,8),('bd_signature',12,4),
          ('type',16,4),('flags',20,4),('first_drv_let',24,1),('unit',25,1),
          ('pad',26,2),('base0',28,4),('base1',32,4),('blk_size',36,4),
          ('drv_offset',40,8),('init_root_dir_blks',48,8),('max_blk',56,8),
          ('dev_id_record',64,4),('RAM_dsk',68,4),('file_dsk_name',72,4),
          ('file_dsk',76,4),('owning_task',80,4),('last_time',84,8),
          ('max_reads',92,4),('max_writes',96,4)]
COMMANDS = [('sizeof(CBlkDev)==100;',['1'])]
for start in range(0,len(FIELDS),3):
    clauses=[f'offset(CBlkDev.{name})=={offset}&&sizeof(CBlkDev.{name})=={size}'
             for name,offset,size in FIELDS[start:start+3]]
    COMMANDS.append(('&&'.join(clauses)+';',['1']))
COMMANDS += [('BDF_INITIALIZED==2&&BDF_INIT_IN_PROGRESS==128&&BD_SIGNATURE_VAL==0x56534442;',['1']),('6*7;',['42'])]
if any(len(command)>255 for command,_ in COMMANDS):
    raise ValueError('Record layout commands exceed the native input limit')


def serializable(value):
    if isinstance(value,dict):
        return {str(key):serializable(item) for key,item in value.items()}
    if isinstance(value,(list,tuple)):
        return [serializable(item) for item in value]
    if isinstance(value,set):
        return [serializable(item) for item in sorted(value)]
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, FIXTURE, ROOT/'Kernel/FontStd.HC', ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    packaging = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
        source, working, additions={'/BlockDevRecord.HH':FIXTURE.read_bytes()})
    report = dict(result='running', scope='Complete 100-byte i386 CBlkDev layout: offsets and sizes of all 22 fields plus key flags/signature; not backing-device instances or drive behavior',
                  packaging=packaging, input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':False,
                           'rejected_answers':['0'],
                           'rejection_prefixes':('INPUT REJECT ','WINMGR window exception '),
                           'command_timeout':120})
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        saved=build['mutated_file_contents'](working,{'/BlockDevRecord.HH'}).get('/BlockDevRecord.HH')
        if saved!=FIXTURE.read_bytes():raise ValueError('Delivered block-device header differs from source')
        report['guest_fixture_sha256']=sha(FIXTURE)
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Native fixture inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':
        raise ValueError(report['error'])


if __name__=='__main__':
    main()
