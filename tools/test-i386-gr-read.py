#!/usr/bin/env python3
"""Compare original GR file reading, default extensions and document bitmap insertion."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
import runpy
import sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('reference', ROOT/'tools/test-i386-timeclock-reference.py')
reference = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reference)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?')
    parser.add_argument('--reference',type=Path,help='Passing pinned-original output providing GR records')
    parser.add_argument('--shared',action='store_true')
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if bool(args.disk)!=bool(args.reference) or args.disk and args.shared:
        parser.error('Native requires both disk and --reference; --shared is an original control')
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-gr-read/Contract.HC'
    generator=ROOT/'tests/guest/i386-dc-load/Generate.HC'
    inputs=[Path(__file__).resolve(),Path(reference.__file__),fixture,generator]
    report=dict(result='running',mode='native' if args.disk else 'shared' if args.shared else 'pinned-original',
                scope='Eight ExtDft path/extension cases; GRRead raw/compressed files, task ownership, default extension and nested compression, missing-file NULL, explicit/default DocGR insertion; not complete Type or rendering qualification')
    if args.disk:
        baseline=json.loads((args.reference/'result.json').read_text())
        if baseline['result']!='pass' or baseline['mode']!='pinned-original':raise ValueError('Need passing original control')
        records={f'/load{i}.DATA':(args.reference/'guest'/f'load{i}.DATA').read_bytes() for i in range(4)}
        for name,data in records.items():
            if reference.sha(args.reference/'guest'/name[1:])!=baseline['record_sha256'][name[1:]]:raise ValueError('Changed reference record')
        inputs += [args.disk.resolve(),args.reference/'result.json']+[args.reference/'guest'/n[1:] for n in records]
        inputs += [ROOT/'tools/i386-kernel-input.py',ROOT/'tools/package-i386-native-image.py',ROOT/'tools/build-i386-kernel.py']
    else:
        overlay=out/'reference-overlay';overlay.mkdir()
        report.update(reference_revision=reference.REFERENCE,repair_revision=reference.REPAIRS,reference_sha256=reference.restore_reference(overlay))
        inputs += [ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
        if args.shared:
            manifest=ROOT/'build/rebuild-test/result.json'
            snapshot=json.loads(manifest.read_text())
            if snapshot.get('result')!='pass':raise ValueError('Need a passing current rebuild')
            for name,digest in snapshot['source_sha256'].items():
                path=ROOT/name
                if reference.sha(path)!=digest:raise ValueError('Changed rebuilt source: '+name)
                inputs.append(path)
                target=overlay/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(path.read_bytes())
            for name,relative in [('Compiler.BIN','Compiler/Compiler.BIN'),('Kernel.BIN','0000Boot/0000Kernel.BIN.C')]:
                path=ROOT/'build/rebuild-test/overlay'/relative
                if reference.sha(path)!=snapshot['generations'][-1][name]:raise ValueError('Changed rebuilt binary')
                inputs.append(path);(overlay/relative).write_bytes(path.read_bytes())
            inputs.append(manifest)
            report['rebuilt_source_sha256']=snapshot['source_sha256']
    report['input_sha256']={str(p):reference.sha(p) for p in inputs}
    try:
        if args.disk:
            disk=out/'working.img'
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={**records,'/GRRead.HC':fixture.read_bytes()})
            commands=[('#include "C:/GRRead.HC"',[]),('GRExtContract;',['255']),('GRReadContract(67);',['63']),('6*7;',['42'])]
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](disk,out/'guest',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='tcg',qmp_stdio=True,startup_check={'status':'ok','answers':[],'commands':commands,'command_timeout':120})
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,set(records)|{'/GRRead.HC'})
            if any(files[n]!=data for n,data in {**records,'/GRRead.HC':fixture.read_bytes()}.items()):raise ValueError('Delivered inputs changed')
        else:
            source=generator.read_text()+fixture.read_text()+'\nI64 gr_mask=GRExtContract;U8 *gr_line=MStrPrint("EXT MASK %d\\n",gr_mask);Report(gr_line);Free(gr_line);gr_mask=GRReadContract(66);gr_line=MStrPrint("GR MASK %d\\n",gr_mask);Report(gr_line);Free(gr_line);Report("DONE graphics file read\\n");\n'
            (overlay/'Once.HC').write_text(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=reference.sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            log=(out/'guest/debug.log').read_text()
            if 'GR MASK 63\n' not in log or 'EXT MASK 255\n' not in log:raise ValueError('Original graphics-file checks failed')
            report['record_sha256']={f'load{i}.DATA':reference.sha(out/'guest'/f'load{i}.DATA') for i in range(4)}
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(reference.sha(Path(p))==d for p,d in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])


if __name__=='__main__':main()
