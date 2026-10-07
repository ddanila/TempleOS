#!/usr/bin/env python3
"""Compare native probability-dither pixels and random state with original observations."""
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
    cases=reference.get('cases',[])
    if reference.get('result')!='pass' or [row['threshold'] for row in cases]!=[0,32768,65535] or any(row['changed']!=256 for row in cases):parser.error('Need passing original probability-dither reference')
    if args.out.exists():parser.error('Use a fresh output directory')
    out=args.out.resolve();out.mkdir(parents=True)
    helper=ROOT/'tools/i386-kernel-input.py'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p.resolve()):sha(p) for p in (Path(__file__),args.disk,args.reference,helper)}
    report=dict(result='running',input_sha256=pins,scope='Original probability dither at three thresholds: complete 16x16 bitmap fingerprints, changed counts, post-call seeds, exact caller heap and restored task seed/flags; not screen coverage, entropy quality or other rasters')
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    try:
        commands=[
            ('class CRRState{I64 flags,seed,base;CDC *dc;};',[]),
            ('I64 RRHash(CDC *dc){I64 i,hash=0xCBF29CE484222325;for(i=0;i<256;i++)hash=(hash^dc->body[i])*0x100000001B3;return hash;}',[]),
            ('CDC *RRNew(I64 p){CDC *dc=DCNew(16,16);DCFill(dc,BLACK);dc->color=RED|BLUE<<16|ROPF_PROBABILITY_DITHER;dc->dither_probability_u16=p;return dc;}',[]),
            ('U0 RRBegin(CRRState *s,I64 p){s->base=Fs->data_heap->used_u8s;s->flags=Fs->task_flags;s->seed=Fs->rand_seed;Bts(&Fs->task_flags,TASKf_NONTIMER_RAND);Fs->rand_seed=1;s->dc=RRNew(p);}',[]),
            ('I64 RRCheck(CDC *dc,I64 hash,I64 seed){I64 m=0;if(GrRect(dc,0,0,16,16)==256)m|=1;if(RRHash(dc)==hash)m|=2;if(Fs->rand_seed==seed)m|=4;return m;}',[]),
            ('U0 RREnd(CRRState *s){DCDel(s->dc);Fs->task_flags=s->flags;Fs->rand_seed=s->seed;}',[]),
            ('I64 RRCase(I64 p,I64 h,I64 seed){CRRState s;I64 m;RRBegin(&s,p);m=RRCheck(s.dc,h,seed);RREnd(&s);if(Fs->data_heap->used_u8s==s.base&&Fs->task_flags==s.flags&&Fs->rand_seed==s.seed)m|=8;return m;}',[]),
        ]
        for row in cases:commands.append((f"RRCase({row['threshold']},0x{row['fingerprint']:X},0x{row['state']:X});",['15']))
        commands.append(('6*7;',['42']))
        if any(len(source)>255 for source,answers in commands):raise ValueError('Probability command exceeds console capacity')
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
