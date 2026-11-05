#!/usr/bin/env python3
"""Check original completed function publication after execution failures."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path);parser.add_argument('--reference',type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True);args=parser.parse_args()
    source=args.disk.resolve();ref=args.reference.resolve();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    reference=json.loads((ref/'result.json').read_text())
    if reference.get('result')!='pass' or not reference.get('inputs_unchanged') or len(reference.get('records',[]))!=8:
        raise ValueError('Passing eight-case original publication reference required')
    commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),
        ('U0 PubRun(U8 *s,I64 f){try{ExePutS(s,0,f);}catch{Fs->catch_except=TRUE;}}',[])]
    #Start with a runtime throw so missing public Break cannot hide publication.
    for index in (1,0,2,3,5,4,6,7):
        name=f'NativePub{index:02}'
        ending=['41;Break;','41;throw(\'Delib\',TRUE);','41;Unknown after_break;',
            'Fs->task_flags|=1<<TASKf_PENDING_BREAK;'][index%4]
        text=f'I64 {name}(){{return 99;}}'+ending
        #Every completed function must survive; the wrapper catches runtime throws.
        commands.append((f'PubRun("{text}",{index//4});',
            ['Error: Undefined identifier at '] if index%4==2 else []))
        commands.append((name+';',['99']))
    commands.append(('6*7;',['42']))
    if any(len(c[0])>255 for c in commands):raise ValueError('Input exceeds native buffer')
    paths=[source,ref/'result.json',Path(__file__).resolve(),ROOT/'tools/i386-kernel-input.py']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins={str(p):sha(p) for p in paths}
    out.mkdir(parents=True);report=dict(result='fail',input_sha256=pins,commands=commands,
        scope='Original-derived completed function remains callable after ExePutS explicit break, runtime throw, parse failure or pending break, with flags 0/CCF_CMD_LINE. 8 MiB KVM 486 without FPU/live WinMgr and exact pixels. Pending-break timing/return differences remain separate; not whole API qualification.')
    try:
        run=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior']=run(source,out/'qemu',snapshot=True,ram_mib=8,cpu='486,-fpu',accel='kvm',
            qmp_stdio=True,welcome=True,keep_window_manager=True,
            startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False})
        report['result']='pass'
    except Exception as exc:
        report['error']=str(exc);raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Completed publication workflow failed')


if __name__=='__main__':main()
