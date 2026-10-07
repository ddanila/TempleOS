#!/usr/bin/env python3
"""Record original deterministic RandU16 vectors for independent native comparison."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if args.out.exists(): parser.error('Use a fresh output directory')
    out=args.out.resolve();overlay=out/'overlay';overlay.mkdir(parents=True)
    files=[Path(__file__).resolve()]+[ROOT/p for p in ('Kernel/KMathB.HC','Kernel/RandU16Core.HC','tools/build-iso.py','tools/guest-run.py','build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C','build/rebuild-test/overlay/Compiler/Compiler.BIN')]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in files}
    report=dict(result='running',input_sha256=pins,scope='Original seeded RandU16 recurrence, output and post-call seed with timer mixing disabled; not entropy or timer mode')
    try:
        source='U0 RVReport(U8 *s){while(*s)OutU8(0xE9,*s++); }\n'
        source+='I64 rv_flags=Fs->task_flags,rv_seed=Fs->rand_seed,rv_i,rv_out;U8 *rv_line;Bts(&Fs->task_flags,TASKf_NONTIMER_RAND);\n'
        for seed in (0,1,0x123456789ABCDEF0,0xFFFFFFFFFFFFFFFF):
            source+=f'Fs->rand_seed=0x{seed:X};\n'
            source+=f'for(rv_i=0;rv_i<16;rv_i++){{rv_out=RandU16;rv_line=MStrPrint("OBS rand {seed:X} %d %X %X\\n",rv_i,rv_out,Fs->rand_seed);RVReport(rv_line);Free(rv_line);}}\n'
        source+='Fs->rand_seed=rv_seed;Fs->task_flags=rv_flags;RVReport("DONE rand vectors\\n");\n'
        (overlay/'Once.HC').write_text(source)
        iso=out/'original.iso'
        subprocess.run([sys.executable,str(ROOT/'tools/build-iso.py'),'--overlay',str(ROOT/'build/rebuild-test/overlay'),'--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
        subprocess.run([sys.executable,str(ROOT/'tools/guest-run.py'),str(iso),'--out',str(out/'behavior'),'--timeout','90','--qmp-stdio'],cwd=ROOT,check=True)
        log=(out/'behavior/debug.log').read_text()
        vectors=[]
        for line in log.splitlines():
            if line.startswith('OBS rand '):
                _,_,seed,index,value,state=line.split()
                vectors.append(dict(seed=int(seed,16),index=int(index),value=int(value,16),state=int(state,16)))
        if len(vectors)!=64 or 'DONE rand vectors\n' not in log: raise ValueError('Incomplete original random vectors')
        if [(v['seed'],v['index']) for v in vectors]!=[(seed,index) for seed in (0,1,0x123456789ABCDEF0,0xFFFFFFFFFFFFFFFF) for index in range(16)]: raise ValueError('Unexpected vector order')
        report.update(result='pass',vectors=vectors)
    except Exception as error:
        report.update(result='fail',error=str(error));raise
    finally:
        changed=[p for p,h in pins.items() if sha(Path(p))!=h]
        if changed:report.update(result='fail',changed_inputs=changed)
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass': raise RuntimeError('Pinned original random inputs changed')
if __name__=='__main__':main()
