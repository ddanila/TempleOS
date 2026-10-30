#!/usr/bin/env python3
"""Compare original task settings record layout and field behavior."""
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
    parser.add_argument('--shared',action='store_true')
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64,help='Native guest RAM; original controls use their normal runner')
    parser.add_argument('--reference',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if bool(args.disk)!=bool(args.reference) or args.disk and args.shared:parser.error('Native needs disk and --reference')
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-task-settings-record/Contract.HC'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[Path(__file__).resolve(),fixture]
    report=dict(result='running',mode='native' if args.disk else 'shared' if args.shared else 'pinned-original',
                scope='Task settings record layout and field storage; not settings lifecycle qualification')
    if args.disk:report['ram_mib']=args.ram_mib
    modes=[0]
    captures=['settings-layout.TXT']
    if args.disk:
        baseline=json.loads((args.reference/'result.json').read_text())
        if baseline.get('result')!='pass' or baseline.get('mode')!='pinned-original':raise ValueError('Need passing original control')
        for name in captures:
            if sha(args.reference/'guest'/name)!=baseline['capture_sha256'][name]:raise ValueError('Reference document changed')
        inputs += [args.reference/'result.json']+[args.reference/'guest'/name for name in captures]
        inputs += [args.disk.resolve()]+[ROOT/n for n in ('tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/i386-kernel-input.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC')]
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
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={'/SettingsRecord.HC':fixture.read_bytes()})
            commands=['#include "C:/SettingsRecord.HC"','settings_record_drive=67;']+["if(SettingsRecordContract!=7)throw('Settings',TRUE);"]+['6*7;']
            runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](disk,out/'guest',commands,args.ram_mib,True)
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,{'/SettingsRecord.HC'}|{'/'+n for n in captures})
            if files['/SettingsRecord.HC']!=fixture.read_bytes():raise ValueError('Delivered fixture changed')
            observed={n:files['/'+n] for n in captures}
            if observed['settings-layout.TXT']!=b'368 4 8 40 48 56 80 208 216 360\n':raise ValueError('Unexpected i386 settings record layout')
        else:
            source=fixture.read_bytes()+b'\nU0 PaletteReport(U8*s){while(*s)OutU8(0xE9,*s++); }\n'
            source+=b'settings_record_drive=66;I64 palette_mask=0;\n'
            source+=b'palette_mask=SettingsRecordContract;\n'
            source+=b'U8 *palette_line=MStrPrint("SETTINGS RECORD MASK %d\\n",palette_mask);PaletteReport(palette_line);Free(palette_line);\n'
            for i,name in enumerate(captures):
                source+=f'U8 *palette_buffer{i};I64 palette_size{i};palette_buffer{i}=FileRead("B:/{name}",&palette_size{i});palette_line=MStrPrint("EXPORT {name} %X %X\\n",palette_buffer{i},palette_size{i});PaletteReport(palette_line);Free(palette_line);\n'.encode()
            source+=b'PaletteReport("DONE settings record\\n");\n'
            (overlay/'Once.HC').write_bytes(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if f'SETTINGS RECORD MASK {7}\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original settings record contract failed')
            observed={n:(out/'guest'/n).read_bytes() for n in captures}
            if observed['settings-layout.TXT']!=b'392 8 16 48 64 80 104 232 240 384\n':raise ValueError('Unexpected original settings record layout')
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
