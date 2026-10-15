#!/usr/bin/env python3
"""Check parent frame allocations remain live during descendant cleanup."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [('#include "/Kernel/I386/PublicUser.HH"', []),
 ('CTask *pf_parent,*pf_child;I64 pf_used;Bool pf_ready,pf_observed,pf_returned;', []),
 ('U0 PFEnd(){pf_observed=TaskValidate(pf_parent)&&pf_parent->data_heap->used_u8s==pf_used;}', []),
 ('U0 PFChild(U8 *data){Fs->task_end_cb=&PFEnd;pf_ready=TRUE;while(TRUE)Yield;}', []),
 ('U0 PFDraw(CDC *dc){pf_child=Spawn(&PFChild,NULL,"Frame '
  'child",-1,Fs);LBtr(&pf_child->display_flags,DISPLAYf_SHOW);while(!pf_ready)Yield;pf_used=Fs->data_heap->used_u8s;pf_ready=FALSE;while(TRUE)Yield;}',
  []),
 ('U0 PFParent(U8 *data){NativeGraphicsPresent(&PFDraw);pf_returned=TRUE;}', []),
 ('U0 PFStart(){pf_parent=Spawn(&PFParent,NULL,"Frame '
  'parent",-1,Fs);LBtr(&pf_parent->display_flags,DISPLAYf_SHOW);while(!pf_used)Yield;Kill(pf_parent,FALSE,FALSE);}',
  []),
 ('I64 PFCheck(){I64 '
  'i,m=0;PFStart;for(i=0;i<200&&TaskValidate(pf_parent);i++)Sleep(5);if(pf_observed)m|=1;if(!TaskValidate(pf_parent)&&!TaskValidate(pf_child))m|=2;if(!pf_returned)m|=4;return '
  'm;}',
  []),
 ('PFCheck;', ['7']),
 ('NativeGraphicsPresent;', ['1']),
 ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Parent frame heap remains intact through child end callback; both tasks retire, no normal frame return, presentation reusable',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['61'],
                           'command_timeout':120})
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
