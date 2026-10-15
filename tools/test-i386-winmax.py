#!/usr/bin/env python3
"""Require original WinMax geometry through the public window API."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
FIXTURE=ROOT/"tests/guest/i386-winmax-reference/WinMax.HC"
def chooser_commands():
    source=FIXTURE.read_text()
    commands=[('U0 WMPrerequisite(){WinMax;}',[]),
              (f'U8 *wm_source=CAlloc({len(source)+1});',[]),
              ('U0 WMTransfer(I64 o,U8*s,I64 n){MemCpy(wm_source+o,s,n);}',[])]
    for offset in range(0,len(source),60):
        chunk=source[offset:offset+60]
        encoded=json.dumps(chunk.replace('$','$$'))
        commands.append((f'WMTransfer({offset},{encoded},{len(chunk)});',[]))
    commands += [(f'FileWrite("C:/WinMax.HC",wm_source,{len(source)})>0;',['1']),
                 ('Free(wm_source);',[]),('#include "C:/WinMax.HC"',[]),
                 ('WMCase(TRUE);',['1']),('WMCase(FALSE);',['1']),('6*7;',['42'])]
    return commands

COMMANDS=chooser_commands()

if any(len(c[0])>255 for c in COMMANDS):
    raise ValueError("Put/display fixture exceeds native input limit")


def serializable(value):
    if isinstance(value,dict):
        return {str(key):serializable(item) for key,item in value.items()}
    if isinstance(value,(list,tuple)):
        return [serializable(item) for item in value]
    if isinstance(value,set):
        return [serializable(item) for item in sorted(value)]
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, FIXTURE, ROOT/'Kernel/FontStd.HC', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='WinMax prerequisite followed by identical original geometry fixture; border and borderless current-task bounds, restoration and continuation; not task selection, IRQ, exception or form behavior',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':False,
                           'rejection_prefixes':('INPUT REJECT ',),
                           'command_timeout':120})
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        saved=build['mutated_file_contents'](working,{'/WinMax.HC'}).get('/WinMax.HC')
        if saved!=FIXTURE.read_bytes():raise ValueError('Guest WinMax fixture differs from source')
        report['guest_fixture_sha256']=sha(FIXTURE)
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
