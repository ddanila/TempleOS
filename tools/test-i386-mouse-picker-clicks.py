#!/usr/bin/env python3
"""Run the full-suite file-picker click sequence as an isolated exact-pixel test."""
import argparse
import ast
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path);parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--runner',type=Path,default=ROOT/'tools/i386-kernel-input.py')
    parser.add_argument('--accel',choices=('tcg','kvm'),default='tcg')
    args=parser.parse_args();source=args.disk.resolve();runner=args.runner.resolve();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    context={'mouse_picker_one':['TempleOS i386','File picker','C:/MouseBrowse','', '> One.HC','  Two.HC'],
        'mouse_picker_two':['TempleOS i386','File picker','C:/MouseBrowse','', '  One.HC','> Two.HC'],
        'mouse_block':bytes([0xDB]).decode('cp437')}
    commands=[('#include "/Kernel/I386/PublicUser.HH"',[])]
    calls=[]
    for node in ast.walk(ast.parse(runner.read_text())):
        if isinstance(node,ast.Call) and isinstance(node.func,ast.Name) and node.func.id=='submit' and len(node.args)>2:
            if isinstance(node.args[2],ast.Constant) and node.args[2].value in (
                'mouse-picker-directory','mouse-picker-one','mouse-picker-two','mouse-picker-select','mouse-picker-release'):
                calls.append(node)
    if len(calls)!=5:raise ValueError('Missing full-suite mouse-picker workflow')
    for node in sorted(calls,key=lambda n:n.lineno):
        spec=[ast.literal_eval(node.args[0]),ast.literal_eval(node.args[1])]
        for keyword in node.keywords:
            if keyword.arg=='interaction':
                spec.append(eval(compile(ast.Expression(keyword.value),str(runner),'eval'),{'__builtins__':{}},context))
        commands.append(spec)
    commands.append(('6*7;',['42']))
    paths=[source,runner,Path(__file__).resolve()];sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths};out.mkdir(parents=True)
    report=dict(result='fail',input_sha256=pins,commands=commands,
        scope='Unmodified full-suite mouse file selection/double-click/editor/return sequence, 8 MiB 486 without FPU/live WinMgr, exact checkpoint pixels')
    try:
        run=runpy.run_path(str(runner))['run_input']
        report['behavior']=run(source,out/'qemu',snapshot=True,ram_mib=8,cpu='486,-fpu',accel=args.accel,
            qmp_stdio=True,welcome=True,keep_window_manager=True,
            startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False})
        report['result']='pass'
    except Exception as exc:
        report['error']=str(exc);raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Mouse-picker workflow failed')


if __name__=='__main__':main()
