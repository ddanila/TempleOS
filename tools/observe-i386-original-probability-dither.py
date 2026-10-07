#!/usr/bin/env python3
"""Record original probability-dither raster vectors for independent native comparison."""
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
    files=[Path(__file__).resolve()]+[ROOT/p for p in ('Kernel/KMathB.HC','Kernel/RandU16Core.HC','Adam/Gr/GrRectCore.HC','Adam/Gr/GrInitB.HC','Adam/Gr/GrRasterTablesCore.HC','tools/build-iso.py','tools/guest-run.py','build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C','build/rebuild-test/overlay/Compiler/Compiler.BIN')]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in files}
    report=dict(result='running',input_sha256=pins,scope='Original probability dithering: three thresholds, complete 16x16 bitmap fingerprints, changed counts and post-call random states with timer mixing disabled')
    try:
        source='U0 RVReport(U8 *s){while(*s)OutU8(0xE9,*s++); }\n'
        source+='I64 rp_flags=Fs->task_flags,rp_seed=Fs->rand_seed,rp_i,rp_hash,rp_changed;CDC *rp_dc=DCNew(16,16);U8 *rp_line;Bts(&Fs->task_flags,TASKf_NONTIMER_RAND);\n'
        for threshold in (0,32768,65535):
            source+=f'Fs->rand_seed=1;DCFill(rp_dc,BLACK);rp_dc->color=RED|BLUE<<16|ROPF_PROBABILITY_DITHER;rp_dc->dither_probability_u16={threshold};\n'
            source+='rp_changed=GrRect(rp_dc,0,0,16,16);rp_hash=0xCBF29CE484222325;for(rp_i=0;rp_i<256;rp_i++)rp_hash=(rp_hash^rp_dc->body[rp_i])*0x100000001B3;\n'
            source+=f'rp_line=MStrPrint("OBS prob {threshold} %X %X %d\\n",rp_hash,Fs->rand_seed,rp_changed);RVReport(rp_line);Free(rp_line);\n'
        source+='DCDel(rp_dc);Fs->rand_seed=rp_seed;Fs->task_flags=rp_flags;RVReport("DONE prob vectors\\n");\n'
        (overlay/'Once.HC').write_text(source)
        iso=out/'original.iso'
        subprocess.run([sys.executable,str(ROOT/'tools/build-iso.py'),'--overlay',str(ROOT/'build/rebuild-test/overlay'),'--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
        subprocess.run([sys.executable,str(ROOT/'tools/guest-run.py'),str(iso),'--out',str(out/'behavior'),'--timeout','90','--qmp-stdio'],cwd=ROOT,check=True)
        log=(out/'behavior/debug.log').read_text()
        cases=[]
        for line in log.splitlines():
            if line.startswith('OBS prob '):
                _,_,threshold,fingerprint,state,changed=line.split()
                cases.append(dict(threshold=int(threshold),fingerprint=int(fingerprint,16),state=int(state,16),changed=int(changed)))
        if [row['threshold'] for row in cases]!=[0,32768,65535] or 'DONE prob vectors\n' not in log:raise ValueError('Incomplete probability reference')
        if any(row['changed']!=256 for row in cases):raise ValueError('Unexpected original rectangle count')
        report.update(result='pass',cases=cases)
    except Exception as error:
        report.update(result='fail',error=str(error));raise
    finally:
        changed=[p for p,h in pins.items() if sha(Path(p))!=h]
        if changed:report.update(result='fail',changed_inputs=changed)
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass': raise RuntimeError('Pinned original random inputs changed')
if __name__=='__main__':main()
