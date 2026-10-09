#!/usr/bin/env python3
"""Load build support in a child, retire it, and reuse the provider from other tasks."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUTPUTS = ('/Probe/ChildStartup1.t32m', '/Probe/ChildStartup2.t32m', '/Probe/ParentStartup.t32m')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    candidate = out/'candidate.img'
    if candidate == args.disk.resolve():
        parser.error('candidate must not overwrite source')
    original_sha = hashlib.sha256(args.disk.read_bytes()).hexdigest()
    shutil.copyfile(args.disk, candidate)
    report = dict(result='running', source_disk_sha256=original_sha,
                  scope='First-use in a child, natural task exit, child/parent reuse and public task-pool recovery at 16 MiB')
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    commands = [
        ('CTask *BuildChild;I64 BuildChildResult;', []),
        ('U0 BuildInChild(U8 *target){BuildChildResult=I386BuildModule("C:/Kernel/I386/Startup.HC",target,TRUE);}', []),
        ('Bool WaitBuildChild(){I64 end=cnts.jiffies+20000;while(TaskValidate(BuildChild)&&cnts.jiffies<end)Yield;return !TaskValidate(BuildChild)&&BuildChildResult>0;}', []),
        ('Bool StartBuildChild(U8 *target){BuildChildResult=-1;BuildChild=Spawn(&BuildInChild,target,"Build child",-1,Fs);return BuildChild&&WaitBuildChild;}', []),
        ('Bool RepeatBuildChild(U8 *target){I64 n=Fs->data_heap->bp->used_u8s,r=Fs->data_heap->bp->alloced_u8s;return StartBuildChild(target)&&Fs->data_heap->bp->used_u8s==n&&Fs->data_heap->bp->alloced_u8s==r;}', []),
        (f'StartBuildChild("C:{OUTPUTS[0]}");', ['1']),
        (f'RepeatBuildChild("C:{OUTPUTS[1]}");', ['1']),
        (f'I386BuildModule("C:/Kernel/I386/Startup.HC","C:{OUTPUTS[2]}",TRUE)>0;', ['1']),
        ('6*7;', ['42'])]
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Lifetime contract exceeds interactive line limit')
    try:
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        runner(candidate, out/'qemu', snapshot=False, ram_mib=16, accel='tcg',
               cpu='486,-fpu', qmp_stdio=True, startup_timeout=180,
               startup_check={'status':'ok', 'answers':[], 'commands':commands,
                              'command_timeout':600, 'rejected_answers':['0'],
                              'rejection_prefixes':('BUILD MODULE REJECT ',)})
        log = (out/'qemu/debug.log').read_text()
        first = log.find('INPUT LINE StartBuildChild("C:')
        if log.count('BUILD PROVIDER loaded\n') != 1 or log.find('BUILD PROVIDER loaded\n') < first or first < 0:
            raise ValueError('Provider must first load in the child and be reused')
        build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        persisted = build['mutated_file_contents'](candidate, set(OUTPUTS))
        audit = runpy.run_path(str(ROOT/'tools/test-i386-retained-build.py'))['exports_of']
        reference = build['mutated_file_contents'](args.disk, {'/Modules/I386/Startup.t32m'})
        _, expected = audit(reference['/Modules/I386/Startup.t32m'])
        for path in OUTPUTS:
            _, exports = audit(persisted.get(path))
            if set(exports) != set(expected):
                raise ValueError('Child/parent output export contract differs from installed Startup')
        if len({persisted[path] for path in OUTPUTS}) != 1:
            raise ValueError('Child and parent builds produce different module bytes')
        report.update(result='pass', successful_builds=3, build_provider_loads=1,
                      first_use_task='child', natural_child_exits=2,
                      second_child_public_pool_restored=True)
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        if hashlib.sha256(args.disk.read_bytes()).hexdigest() != original_sha:
            report.update(result='fail', error='Input disk changed during lifetime test')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
