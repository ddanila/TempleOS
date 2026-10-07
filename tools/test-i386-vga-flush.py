#!/usr/bin/env python3
"""Require each actual VGAFlush call to present the complete visible surface."""
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
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    helper=ROOT/'tools/i386-kernel-input.py'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p.resolve()):sha(p) for p in (Path(__file__),args.disk,helper)}
    report=dict(result='running',input_sha256=pins,scope='Three real VGAFlush calls on a visible terminal each cause exactly one full 60-row upload; VGA checkpoints and final console result; not invisible-terminal retention, raw pixel appearance or physical hardware')
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    try:
        disk=out/'working.img';shutil.copyfile(args.disk,disk)
        commands=[('HashFind("VGAFlush",Fs->hash_table,~0)!=NULL;',['1']),('U0 RF(){U8 *s="RAW FLUSH MARK\\n";while(*s)OutU8(0xE9,*s++);VGAFlush;}',[])]
        commands += [('RF;',[]) for _ in range(3)]
        commands += [('6*7;',['42'])]
        report['behavior']=runpy.run_path(str(helper))['run_input'](disk,out/'behavior',cpu='486,-fpu',qmp_stdio=True,snapshot=False,startup_check={'status':'ok','answers':[],'commands':commands})
        parts=(out/'behavior/debug.log').read_text().split('RAW FLUSH MARK\n')
        if len(parts)!=4:raise ValueError('Missing flush call markers')
        uploads=[[int(line.split()[2]) for line in part.splitlines() if line.startswith('VGA ROWS ')] for part in parts[1:]]
        report['uploads_after_calls']=uploads
        if any(rows.count(60)!=1 for rows in uploads):raise ValueError('Each flush must cause exactly one complete upload')
        report['result']='pass'
    except Exception as error:
        report.update(result='fail',error=str(error));raise
    finally:
        changed=[p for p,h in pins.items() if sha(Path(p))!=h]
        if changed:report.update(result='fail',changed_inputs=changed)
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise RuntimeError('Flush qualification inputs changed')
if __name__=='__main__':main()
