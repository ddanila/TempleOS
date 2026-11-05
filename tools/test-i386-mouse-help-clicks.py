#!/usr/bin/env python3
"""Run the full-suite Help-link click/open/return sequence with exact pixels."""
import argparse
import ast
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]


def json_metadata(value):
    if isinstance(value,dict):
        return {str(key):json_metadata(item) for key,item in value.items()}
    if isinstance(value,(tuple,list)):
        return [json_metadata(item) for item in value]
    return value


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('disk',type=Path)
    p.add_argument('--out',type=Path,required=True);p.add_argument('--runner',type=Path,default=ROOT/'tools/i386-kernel-input.py')
    p.add_argument('--accel',choices=('tcg','kvm'),default='tcg');args=p.parse_args()
    disk=args.disk.resolve();runner=args.runner.resolve();out=args.out.resolve()
    if out.exists():p.error('Use a fresh output directory')
    tree=ast.parse(runner.read_text());context={}
    for node in ast.walk(tree):
        if isinstance(node,ast.Assign) and len(node.targets)==1 and isinstance(node.targets[0],ast.Name) and node.targets[0].id in ('help_rows','asm_rows'):
            name=node.targets[0].id
            if name in context:raise ValueError('Ambiguous full-suite Help rows')
            context[name]=ast.literal_eval(node.value)
    if set(context)!=set(('help_rows','asm_rows')):raise ValueError('Missing full-suite Help rows')
    context['help_selected_colors']={(5,n):15 for n in range(len('::/Doc/Asm.DD'))}
    context['help_selected_backgrounds']={(5,n):1 for n in range(len('::/Doc/Asm.DD'))}
    calls=[node for node in ast.walk(tree) if isinstance(node,ast.Call) and isinstance(node.func,ast.Name) and node.func.id=='submit' and len(node.args)>2 and isinstance(node.args[2],ast.Constant) and node.args[2].value=='mouse-help-link']
    if len(calls)!=1:raise ValueError('Missing unique full-suite Help mouse workflow')
    call=calls[0];spec=[ast.literal_eval(call.args[0]),ast.literal_eval(call.args[1])]
    interactions=[k.value for k in call.keywords if k.arg=='interaction']
    if len(interactions)!=1:raise ValueError('Missing Help interaction')
    spec.append(eval(compile(ast.Expression(interactions[0]),str(runner),'eval'),{'__builtins__':{}},context))
    commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),spec,('6*7;',['42'])]
    paths=[disk,runner,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']
    sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();pins={str(f):sha(f) for f in paths}
    out.mkdir(parents=True);report=dict(result='fail',input_sha256=pins,commands=json_metadata(commands),
        scope='Unmodified full-suite Help mouse select/double-click/open/return gestures and exact pixels, with consumed-state acknowledgements; 8 MiB 486 without FPU/live WinMgr. Not complete suite or original desktop qualification.')
    try:
        report['behavior']=runpy.run_path(str(runner))['run_input'](disk,out/'qemu',snapshot=True,
            ram_mib=8,cpu='486,-fpu',accel=args.accel,qmp_stdio=True,welcome=True,
            keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False})
        report['result']='pass'
    except Exception as exc:report['error']=str(exc);raise
    finally:
        report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Help click workflow failed')


if __name__=='__main__':main()
