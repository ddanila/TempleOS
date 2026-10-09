#!/usr/bin/env python3
"""Reduce provider initializer macro-renaming to small persisted source units."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
CASES = {
    'Direct': 'I64 BuildOriginalMain(){return 42;}\nI64 Main(){return BuildOriginalMain;}\n',
    'MacroSingle': '#define Entry BuildOriginalMain\nI64 Entry(){return 42;}\nI64 Main(){return BuildOriginalMain;}\n',
    'MacroInclude': '#define Entry BuildOriginalMain\n#include "C:/Probe/MacroNameBody.HC"\nI64 Main(){return BuildOriginalMain;}\n',
}
BODY = 'I64 Entry(){return 42;}\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    disk = out/'candidate.img'
    original_sha = hashlib.sha256(args.disk.read_bytes()).hexdigest()
    shutil.copyfile(args.disk, disk)
    report = dict(result='running',source_disk_sha256=original_sha,
                  scope='Direct, same-file macro and included-file macro function naming; native build and persisted exports')
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    commands = [(f'FileWrite("C:/Probe/MacroNameBody.HC",{json.dumps(BODY)},{len(BODY)})>0;', ['1'])]
    for name, source in CASES.items():
        commands += [(f'FileWrite("C:/Probe/{name}.HC",{json.dumps(source)},{len(source)})>0;', ['1']),
                     (f'I386BuildModule("C:/Probe/{name}.HC","C:/Probe/{name}.t32m",TRUE)>0;', ['1'])]
    if any(len(source.encode())>255 for source,_ in commands):
        raise ValueError('Macro naming fixture exceeds interactive line limit')
    try:
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        runner(disk,out/'qemu',snapshot=False,ram_mib=16,accel='tcg',cpu='486,-fpu',
               qmp_stdio=True,startup_timeout=180,
               startup_check={'status':'ok','answers':[],'commands':commands,
                              'command_timeout':600,'rejected_answers':['0'],
                              'rejection_prefixes':('BUILD MODULE REJECT ',)})
        build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        files = build['mutated_file_contents'](disk,{f'/Probe/{name}.t32m' for name in CASES})
        audit = runpy.run_path(str(ROOT/'tools/test-i386-retained-build.py'))['exports_of']
        for name in CASES:
            _, exports = audit(files.get(f'/Probe/{name}.t32m'))
            if set(exports)!={'Main','BuildOriginalMain'}:
                raise ValueError(f'{name} function export contract changed')
        if len(set(files.values()))!=1:
            raise ValueError('Macro naming changed native module bytes')
        report.update(result='pass',cases=list(CASES),identical_module_bytes=True)
    except Exception as error:
        report.update(result='fail',error=str(error))
        raise
    finally:
        if hashlib.sha256(args.disk.read_bytes()).hexdigest()!=original_sha:
            report.update(result='fail',error='Input disk changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':
        raise ValueError(report['error'])
    print(json.dumps(report,indent=2))


if __name__=='__main__':
    main()
