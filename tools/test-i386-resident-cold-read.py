#!/usr/bin/env python3
"""Original-oracle resident disk read followed by cached owned reads."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, help='Bootable image with /Probe/ReadResident.BIN containing A,NUL,B,255 and resident metadata')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    candidate = out/'candidate.img'
    if candidate == args.disk.resolve():
        parser.error('output overlaps source')
    original = args.disk.read_bytes()
    candidate.write_bytes(original)
    report = dict(result='fail', source_disk_sha256=hashlib.sha256(original).hexdigest(),
                  scope='Resident disk population, first disk attributes then cached attributes, fresh owned reads')
    definitions = runpy.run_path(str(ROOT/'tools/test-i386-public-file-read.py'))['DEFINITIONS']
    selected = [definitions[0], definitions[2], definitions[4]]
    checks = ['ReadCheck("C:/Probe/ReadResident.BIN",0xA00)',
              'ReadCheck("C:/Probe/ReadResident.BIN",0)',
              'ReadOwned("C:/Probe/ReadResident.BIN")']
    try:
        overlay = out/'overlay'
        overlay.mkdir(exist_ok=True)
        lines = ['U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}']+selected
        lines += ['U0 ColdReads(){U8 *name;CHashGeneric *entry;',
                  'if(FileWrite("B:/ReadResident.BIN",ReadBytes,4,0x1122334455667788,0x200)<=0){Report("FAIL setup\\n");return;}',
                  'name=FileNameAbs("B:/ReadResident.BIN");entry=HashFind(name,adam_task->hash_table,HTT_FILE);Free(name);',
                  'if(!entry){Report("FAIL resident cache setup\\n");return;}HashRemDel(entry,adam_task->hash_table);']
        for index, check in enumerate(checks):
            lines.append('if(!('+check.replace('C:/Probe/','B:/')+')){Report("FAIL cold case '+str(index)+'\\n");return;}')
        lines += ['Report("DONE cold resident\\n");}', 'ColdReads;']
        (overlay/'Once.HC').write_text('\n'.join(lines)+'\n')
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'oracle.iso')], cwd=ROOT, check=True)
        subprocess.run(['python3','tools/guest-run.py',str(out/'oracle.iso'),'--out',str(out/'oracle'),'--timeout','180','--qmp-stdio'], cwd=ROOT, check=True)
        report['original_oracle'] = 'pass'
        commands = [(source,[]) for source in selected]+[(check+';',['1']) for check in checks]+[('6*7;',['42'])]
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(candidate,out/'behavior',snapshot=False,cpu='486,-fpu',qmp_stdio=True,
                                   startup_check={'status':'ok','answers':[],'commands':commands})
        if candidate.read_bytes() != original:
            raise ValueError('Read-only cold cache contract changed disk bytes')
        report['candidate_disk_unchanged'] = True
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        report['source_disk_unchanged'] = args.disk.read_bytes() == original
        if not report['source_disk_unchanged']:
            report.update(result='fail',error='Source changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__ == '__main__':
    main()
