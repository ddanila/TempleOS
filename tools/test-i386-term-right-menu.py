#!/usr/bin/env python3
"""Exercise the complete terminal right-click menu in real popup tasks."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?')
    parser.add_argument('--refresh-only',action='store_true',help='Only covered popup ShiftEsc and refresh progress; full button gate remains separate')
    parser.add_argument('--shared',action='store_true')
    parser.add_argument('--reference',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if bool(args.disk)!=bool(args.reference) or args.disk and args.shared:parser.error('Native needs disk and --reference')
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-term-right-menu/Contract.HC'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[Path(__file__).resolve(),fixture]
    report=dict(result='running',mode='native' if args.disk else 'shared' if args.shared else 'pinned-original',
                scope='All ten original terminal menu actions, Cancel button, ShiftEsc and explicit covered popup in real popup tasks; three exact documents for text/null/empty headers, eleven buttons, refresh progress and caller role restoration; not terminal callback action execution')
    modes=[13] if args.refresh_only else list(range(13))
    captures=[] if args.refresh_only else [f'term-menu{i}.DD' for i in range(3)]
    report['refresh_only']=args.refresh_only
    if args.refresh_only:report['scope']='Covered real popup: advancing manager frames, ShiftEsc return, eleven buttons and restored caller roles; does not qualify button activation'
    if args.disk:
        baseline=json.loads((args.reference/'result.json').read_text())
        if baseline.get('result')!='pass' or baseline.get('mode')!='pinned-original' or baseline.get('refresh_only',False)!=args.refresh_only:raise ValueError('Need passing original control')
        for name in captures:
            if sha(args.reference/'guest'/name)!=baseline['capture_sha256'][name]:raise ValueError('Reference document changed')
        inputs += [args.reference/'result.json']+[args.reference/'guest'/name for name in captures]
        inputs += [args.disk.resolve()]+[ROOT/n for n in ('tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/i386-kernel-input.py','Kernel/FontStd.HC')]
    else:
        inputs += [ROOT/n for n in ('tools/test-i386-timeclock-reference.py','tools/build-iso.py','tools/guest-run.py')]
        reference=runpy.run_path(str(inputs[-3]))
        overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=reference['restore_reference'](overlay)
        if args.shared:
            manifest=ROOT/'build/rebuild-test/result.json'
            snapshot=json.loads(manifest.read_text())
            if snapshot.get('result')!='pass':raise ValueError('Need passing current rebuild')
            for name,digest in snapshot['source_sha256'].items():
                path=ROOT/name
                if sha(path)!=digest:raise ValueError('Changed rebuilt source: '+name)
                inputs.append(path)
                target=overlay/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(path.read_bytes())
            for name,relative in [('Compiler.BIN','Compiler/Compiler.BIN'),('Kernel.BIN','0000Boot/0000Kernel.BIN.C')]:
                path=ROOT/'build/rebuild-test/overlay'/relative
                if sha(path)!=snapshot['generations'][-1][name]:raise ValueError('Changed rebuilt binary')
                inputs.append(path);(overlay/relative).write_bytes(path.read_bytes())
            inputs.append(manifest)
            report['rebuilt_source_sha256']=snapshot['source_sha256']
    report['input_sha256']={str(p):sha(p) for p in inputs}
    try:
        if args.disk:
            disk=out/'working.img'
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={'/TermRightMenu.HC':fixture.read_bytes()})
            commands=[('#include "C:/TermRightMenu.HC"',[]),('TMDrive(67);',[])]+[(f'TMChoose({i});',['1']) for i in modes]+[('6*7;',['42'])]
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](disk,out/'guest',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='tcg',qmp_stdio=True,welcome=True,startup_check={'status':'ok','answers':[],'commands':commands,'command_timeout':30 if args.refresh_only else 120,'pause_window_manager':False})
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,{'/TermRightMenu.HC'}|{'/'+n for n in captures})
            if files['/TermRightMenu.HC']!=fixture.read_bytes():raise ValueError('Delivered fixture changed')
            observed={n:files['/'+n] for n in captures}
            if observed!={n:(args.reference/'guest'/n).read_bytes() for n in captures}:raise ValueError('Menu documents differ from original')
        else:
            source=fixture.read_bytes()+b'\nU0 TMReport(U8*s){while(*s)OutU8(0xE9,*s++); }\n'
            source+=b'tm_drive=66;I64 tm_mask=0;\n'
            for mode in modes:source+=f'if(TMChoose({mode}))tm_mask|=1<<{mode};\n'.encode()
            source+=b'U8 *tm_line=MStrPrint("MENU MASK %d\\n",tm_mask);TMReport(tm_line);Free(tm_line);\n'
            for i in range(len(captures)):
                source+=f'U8 *tm_buffer{i};I64 tm_size{i};tm_buffer{i}=FileRead("B:/term-menu{i}.DD",&tm_size{i});tm_line=MStrPrint("EXPORT term-menu{i}.DD %X %X\\n",tm_buffer{i},tm_size{i});TMReport(tm_line);Free(tm_line);\n'.encode()
            source+=b'TMReport("DONE terminal menu\\n");\n'
            (overlay/'Once.HC').write_bytes(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if f'MENU MASK {sum(1<<mode for mode in modes)}\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original terminal menu contract failed')
            observed={n:(out/'guest'/n).read_bytes() for n in captures}
        report['capture_sha256']={n:hashlib.sha256(data).hexdigest() for n,data in observed.items()}
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==d for p,d in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
