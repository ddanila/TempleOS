#!/usr/bin/env python3
"""Compare native RandU16 outputs and states with observed original vectors."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
ROOT=Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--reference',type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    reference=json.loads(args.reference.read_text())
    vectors=reference.get('vectors',[])
    if reference.get('result')!='pass' or len(vectors)!=64:parser.error('Need a passing original 64-vector report')
    if [(v['seed'],v['index']) for v in vectors]!=[(seed,index) for seed in (0,1,0x123456789ABCDEF0,0xFFFFFFFFFFFFFFFF) for index in range(16)]:parser.error('Unexpected original vector order')
    if args.out.exists():parser.error('Use a fresh output directory')
    out=args.out.resolve();out.mkdir(parents=True)
    helper=ROOT/'tools/i386-kernel-input.py'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p.resolve()):sha(p) for p in (Path(__file__),args.disk,args.reference,helper)}
    report=dict(result='running',input_sha256=pins,scope='64 original seeded RandU16 outputs and full post-call states, timer-mode state differs, original seed/task flags restored; not distribution or entropy quality')
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    try:
        commands=[('I64 rv_flags=Fs->task_flags,rv_seed=Fs->rand_seed;',[]),('U0 RVPrepare(){Bts(&Fs->task_flags,TASKf_NONTIMER_RAND);}RVPrepare;',[]),('U0 RVSeed(I64 value){Fs->rand_seed=value;}',[]),('Bool RVCompare(I64 value,I64 state){I64 actual=RandU16;return actual==value&&Fs->rand_seed==state;}',[])]
        for row in vectors:
            if not row['index']:commands.append((f"RVSeed(0x{row['seed']:X});",[]))
            commands.append((f"RVCompare({row['value']},0x{row['state']:X});",['1']))
        expected=next(row['state'] for row in vectors if row['seed']==1 and row['index']==0)
        commands.append((f'U0 RVTimer(){{Btr(&Fs->task_flags,TASKf_NONTIMER_RAND);Fs->rand_seed=1;RandU16;}}RVTimer;',[]))
        commands.append((f'Fs->rand_seed!=0x{expected:X};',['1']))
        commands += [('U0 RVRestore(){Fs->task_flags=rv_flags;Fs->rand_seed=rv_seed;}RVRestore;',[]),('Fs->rand_seed==rv_seed&&Fs->task_flags==rv_flags;',['1']),('6*7;',['42'])]
        disk=out/'working.img';shutil.copyfile(args.disk,disk)
        report['behavior']=runpy.run_path(str(helper))['run_input'](disk,out/'behavior',cpu='486,-fpu',qmp_stdio=True,snapshot=False,startup_check={'status':'ok','answers':[],'commands':commands})
        report['result']='pass'
    except Exception as error:
        report.update(result='fail',error=str(error));raise
    finally:
        changed=[p for p,h in pins.items() if sha(Path(p))!=h]
        if changed:report.update(result='fail',changed_inputs=changed)
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise RuntimeError('Pinned random prerequisites changed')
if __name__=='__main__':main()
