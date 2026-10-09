#!/usr/bin/env python3
"""Kill a public child after module compilation starts, then verify recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
CANCELLED = '/Probe/CancelledBuildRuntime.t32m'
RECOVERED = '/Probe/AfterCancelStartup.t32m'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    candidate = out/'candidate.img'
    original_sha = hashlib.sha256(args.disk.read_bytes()).hexdigest()
    shutil.copyfile(args.disk, candidate)
    report = dict(result='running',source_disk_sha256=original_sha,
                  scope='Public Kill after module control activation, retirement, absent output and subsequent build at 16 MiB')
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    commands = [
        ('CTask *CancelChild;Bool CancelReturned,CancelEntryClean;', []),
        ('U0 CancelMark(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
        ('Bool SendCancelKill(){CancelMark("CANCEL KILL requested\\n");Bool killed=Kill(CancelChild);CancelMark("CANCEL KILL returned\\n");return killed;}', []),
        (f'U0 CancelBuild(U8 *data){{if(Fs->last_cc!=&Fs->next_cc)return;CancelEntryClean=TRUE;I386BuildModule("C:/Kernel/I386/BuildRuntime.HC","C:{CANCELLED}",TRUE);CancelReturned=TRUE;}}', []),
        ('Bool CancelActive(){return TaskValidate(CancelChild)&&CancelEntryClean&&CancelChild->last_cc!=&CancelChild->next_cc;}', []),
        ('Bool StartCancelBuild(){I64 end=cnts.jiffies+20000;CancelReturned=CancelEntryClean=FALSE;CancelChild=Spawn(&CancelBuild,0,"Cancel build",-1,Fs);while(TaskValidate(CancelChild)&&!CancelActive&&cnts.jiffies<end)Yield;return CancelActive;}', []),
        ('Bool StopCancelBuild(){Bool active=CancelActive;if(!active)return FALSE;CancelMark("CANCEL CONTROL observed\\n");Bool killed=SendCancelKill;return active&&killed&&!TaskValidate(CancelChild)&&!CancelReturned;}', []),
        ('StartCancelBuild&&StopCancelBuild;', ['1']),
        (f'I386BuildModule("C:/Kernel/I386/Startup.HC","C:{RECOVERED}",TRUE)>0;', ['1']),
        ('6*7;', ['42'])]
    if any(len(source.encode())>255 for source,_ in commands):
        raise ValueError('Cancellation fixture exceeds interactive line limit')
    try:
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        runner(candidate,out/'qemu',snapshot=False,ram_mib=16,accel='tcg',
               cpu='486,-fpu',qmp_stdio=True,startup_timeout=180,
               startup_check={'status':'ok','answers':[],'commands':commands,
                              'command_timeout':600,'rejected_answers':['0'],
                              'rejection_prefixes':('BUILD MODULE REJECT ',)})
        build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        files = build['mutated_file_contents'](candidate,{CANCELLED,RECOVERED})
        if CANCELLED in files:
            raise ValueError('Cancelled build published an output')
        audit = runpy.run_path(str(ROOT/'tools/test-i386-retained-build.py'))['exports_of']
        _, exports = audit(files.get(RECOVERED))
        reference = build['mutated_file_contents'](args.disk,{'/Modules/I386/Startup.t32m'})
        _, expected = audit(reference['/Modules/I386/Startup.t32m'])
        if set(exports)!=set(expected):
            raise ValueError('Post-cancellation Startup export contract changed')
        report['filesystem'] = build['verify_mutated_volume'](candidate)
        log = (out/'qemu/debug.log').read_text()
        for marker in ('CANCEL CONTROL observed\n','CANCEL KILL requested\n','CANCEL KILL returned\n'):
            if log.count(marker)!=1:
                raise ValueError(f'Missing or repeated cancellation checkpoint: {marker.strip()}')
        if log.count('BUILD PROVIDER loaded\n')!=1:
            raise ValueError('Cancellation must preserve one cached provider')
        report.update(result='pass',active_module_control_observed=True,
                      child_retired=True,cancelled_output_absent=True,
                      subsequent_build_pass=True,build_provider_loads=1)
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
