#!/usr/bin/env python3
"""Original-oracle public Cd relative lookup, failure progress and mkdir mode."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CHECKS = ['DirMk("C:/Probe/CdChild")',
          'Cd("C:/Probe")', 'Cd("CdChild")',
          'FileWrite("Child.BIN","CHILD",5,0x1122334455667788)>0',
          'FileFind("C:/Probe/CdChild/Child.BIN")',
          'Cd("..")', 'Cd("")', 'Cd(".")',
          '!Cd("C:/Probe/CdMissing/Deeper")',
          'FileWrite("AfterFail.BIN","FAIL",4,0x1122334455667788)>0',
          'FileFind("C:/Probe/AfterFail.BIN")',
          'Cd("C:/Probe/CdMade/Deep",TRUE)',
          'FileWrite("Made.BIN","MADE",4,0x1122334455667788)>0',
          'FileFind("C:/Probe/CdMade/Deep/Made.BIN")', 'Cd("C:/")']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--task-fields', action='store_true', help='Require public Fs->cur_dir to reflect every directory change and partial failure')
    args = parser.parse_args()
    checks = list(CHECKS)
    if args.task_fields:
        expected_dirs = {'Cd("C:/Probe")':'/Probe','Cd("CdChild")':'/Probe/CdChild',
                         'Cd("..")':'/Probe','Cd("")':'/Probe','Cd(".")':'/Probe',
                         '!Cd("C:/Probe/CdMissing/Deeper")':'/Probe',
                         'Cd("C:/Probe/CdMade/Deep",TRUE)':'/Probe/CdMade/Deep',
                         'Cd("C:/")':'/'}
        checks = [part for source in checks for part in
                  ([source,f'!StrCmp(Fs->cur_dir,"{expected_dirs[source]}")']
                   if source in expected_dirs else [source])]
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    candidate = out/'candidate.img'
    if candidate == args.disk.resolve():parser.error('output overlaps source')
    original = args.disk.read_bytes()
    candidate.write_bytes(original)
    report = dict(result='fail', source_disk_sha256=hashlib.sha256(original).hexdigest(),
                  scope='Public Cd: relative/parent/empty/dot, partial progress on failure, nested make_dirs; not default home/drive/error parity')
    report['public_task_fields'] = args.task_fields
    try:
        overlay = out/'overlay'
        overlay.mkdir(exist_ok=True)
        lines = ['U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}', 'U0 OriginalCd(){']
        original_checks = ['DirMk("B:/Probe")']+[s.replace('C:/','B:/') for s in checks]
        for index, source in enumerate(original_checks):
            lines.append(f'if(!({source})){{Report("FAIL Cd case {index}\\n");return;}}')
        lines += ['Report("DONE original Cd\\n");}', 'OriginalCd;']
        (overlay/'Once.HC').write_text('\n'.join(lines)+'\n')
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'oracle.iso')],cwd=ROOT,check=True)
        subprocess.run(['python3','tools/guest-run.py',str(out/'oracle.iso'),'--out',str(out/'oracle'),'--timeout','180','--qmp-stdio'],cwd=ROOT,check=True)
        report['original_oracle'] = 'pass'
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(candidate,out/'behavior',snapshot=False,cpu='486,-fpu',qmp_stdio=True,
                                   startup_check={'status':'ok','answers':[],'commands':[(s+';',['1']) for s in checks]+[('6*7;',['42'])]})
        build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        report['filesystem'] = build['verify_mutated_volume'](candidate)
        expected = {'/Probe/CdChild/Child.BIN':b'CHILD','/Probe/AfterFail.BIN':b'FAIL','/Probe/CdMade/Deep/Made.BIN':b'MADE'}
        if build['mutated_file_contents'](candidate,set(expected)) != expected:
            raise ValueError('Cd writes did not reach the required directories')
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        report['source_disk_unchanged'] = args.disk.read_bytes() == original
        if not report['source_disk_unchanged']:report.update(result='fail',error='Source changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__ == '__main__':main()
