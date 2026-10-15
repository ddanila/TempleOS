#!/usr/bin/env python3
"""Compile the exact mouse-present body and canonical complete records in isolation."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]

def extract(path,start,ending):
    text=path.read_text()
    a=text.index(start)
    b=text.index(ending,a)+len(ending)
    return text[a:b]+'\n'

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--task-validator-body',action='store_true',help='Use the complete canonical TaskValidate body rather than an import')
    args=parser.parse_args()
    source,out=args.disk.resolve(),args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    files=[ROOT/'Kernel/I386/Terminals.HC',ROOT/'Kernel/I386/RenderScope.HC',ROOT/'Kernel/I386/GraphicsScope.HC',ROOT/'Kernel/I386/MousePresent.HC']
    parts=['#include "/Kernel/Types.HH"\n#define NULL 0\n#define TRUE 1\n#define FALSE 0\n#include "/Kernel/I386/Task.HH"\n#include "/Kernel/I386/TextVga.HH"\npublic _intern 0x15 CTask *Fs();\nextern class CDC;\n']
    parts += [extract(files[0],'class CNativeTextInput {','};'),extract(files[0],'class CNativeTerminal {','};'),extract(files[1],'class CNativeRenderScope {','};'),extract(files[2],'class CNativeGraphicsScope:', '};')]
    parts += ['''CTask *graphics_owner,*sys_focus_task;
CNativeTerminal *native_terminal_root;
I64 native_display_epoch;
import U0 SysTry(U8*catch_start,U8*untry_start);
import U0 SysUntry();
import U0 NativeMousePresentRows(U8**planes,I64 old_y,I64 x,I64 y,I64 operation);
import CNativeTerminal *NativeTerminalFind(CTask*task);
import Bool NativeMouseBackingMatches(U8**planes,CNativeTerminal*terminal);
import Bool NativeDisplayViewMatches(U8**planes);
import Bool NativeGraphicsTextLock(CNativeGraphicsScope*scope);
import U0 NativeGraphicsTextUnlock(CNativeGraphicsScope*scope);
import Bool TaskValidate(CTask*task);
''',extract(files[3],'U0 NativeMousePresentSplit(', '\n}\n'), 'I64 Main(){return 42;}\n']
    if args.task_validator_body:
        task=ROOT/'Kernel/TaskValidate.HC'
        files.append(task)
        parts=[part.replace('import Bool TaskValidate(CTask*task);',task.read_text()) for part in parts]
    payload=''.join(parts).encode()
    (out/'Probe.HC').write_bytes(payload)
    working=out/'working.img'
    packaging=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](source,working,additions={'/MouseCompile.HC':payload})
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in [source,*files,Path(__file__).resolve(),ROOT/'tools/i386-kernel-input.py',ROOT/'tools/package-i386-native-image.py',ROOT/'tools/build-i386-kernel.py']}
    report=dict(result='running',input_sha256=pins,packaging=packaging,source_sha256=hashlib.sha256(payload).hexdigest(),scope='AOT compilation of exact mouse-present body with complete canonical private records and real helper prototypes; not link/runtime mouse qualification')
    try:
        report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](working,out/'qemu',snapshot=False,ram_mib=16,cpu='486,-fpu',accel='kvm',qmp_stdio=True,startup_check={'status':'ok','answers':[],'commands':[('I386BuildModule("C:/MouseCompile.HC","C:/Probe/MouseCompile.t32m",TRUE)>0;',['1']),('6*7;',['42'])],'command_timeout':180,'rejected_answers':['0'],'rejection_prefixes':('BUILD MODULE REJECT ',)})
        module=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](working,{'/Probe/MouseCompile.t32m'}).get('/Probe/MouseCompile.t32m')
        if not module:raise ValueError('Compiled module missing')
        (out/'MouseCompile.t32m').write_bytes(module)
        report.update(result='pass',module_sha256=hashlib.sha256(module).hexdigest())
    except Exception as exc:
        report.update(result='fail',error=str(exc)[-2000:])
        raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Probe inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
