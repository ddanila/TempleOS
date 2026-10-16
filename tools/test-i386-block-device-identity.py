#!/usr/bin/env python3
"""Check native public backing-device metadata against the actual QEMU disk."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
FIXTURE=ROOT/"Kernel/BlkDev/BlockDevRecord.HH"
COMMANDS = [
    ('Fs->cur_dv->bd!=NULL;',['1']),
    ('CBlkDev *bi=Fs->cur_dv->bd;',[]),
    ("bi->bd_signature==BD_SIGNATURE_VAL&&bi->type==BDT_ATA&&bi->first_drv_let=='C';",['1']),
    ('bi->base0==0x1F0&&bi->base1==0x3F4&&bi->unit==0&&bi->blk_size==512;',['1']),
    ('bi->flags&BDF_INITIALIZED&&!(bi->flags&(BDF_READ_CACHE|BDF_REMOVABLE|BDF_READ_ONLY|BDF_INIT_IN_PROGRESS));',['1']),
    ('bi->max_reads==1&&bi->max_writes==1&&bi->drv_offset==0;',['1']),
    ('bi->dev_id_record==NULL;',['1']),
    ('bi->RAM_dsk==NULL&&bi->file_dsk_name==NULL&&bi->file_dsk==NULL;',['1']),
    ('U32 bi_flags;U0 BIFlag(Bool set){if(set){bi_flags=bi->flags;bi->flags|=BDF_INIT_IN_PROGRESS;}else bi->flags=bi_flags;}',[]),
    ('BIFlag(TRUE);',[]),
    ('Cd("C:/");',['1']),
    ('Fs->cur_dv->bd==bi&&bi->flags&BDF_INIT_IN_PROGRESS;',['1']),
    ('BIFlag(FALSE);',[]),
    ('6*7;',['42']),
]


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
    sectors=source.stat().st_size//512
    commands.insert(8,(f'bi->max_blk=={sectors-1};',['1']))
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, FIXTURE, ROOT/'Kernel/FontStd.HC', ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    packaging = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
        source, working, additions={'/BlockDevRecord.HH':FIXTURE.read_bytes()})
    report = dict(result='running', scope='Primary-master ATA identity, ports, accessible capacity, optional-record state and stable metadata across Cd; not complete drive services, removable media or concurrent locking',
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
