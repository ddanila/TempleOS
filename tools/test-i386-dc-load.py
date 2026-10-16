#!/usr/bin/env python3
"""Compare original device-context loading across raw, compressed and palette records."""
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
    fixture=ROOT/'tests/guest/i386-dc-load/Contract.HC'
    generator=ROOT/'tests/guest/i386-dc-load/Generate.HC'
    inputs=[Path(__file__).resolve(),Path(reference.__file__),fixture,generator]
    report=dict(result='running',mode='native' if args.disk else 'shared' if args.shared else 'pinned-original',
                scope='DCLoad raw and 7/8-bit compressed bodies, default/custom palettes, metadata, matrix reset, explicit/default task ownership and independent storage; raw expansion termination, invalid types and oversized declarations; not malformed compressed dictionaries or complete GR/Type qualification')
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
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={**records,'/DCLoad.HC':fixture.read_bytes()})
            commands=[('#include "C:/DCLoad.HC"',[]),('DCLoadContract(67);',['63']),('ExpandRawContract;',['31']),('6*7;',['42'])]
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](disk,out/'guest',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='tcg',qmp_stdio=True,startup_check={'status':'ok','answers':[],'commands':commands,'command_timeout':120})
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,set(records)|{'/DCLoad.HC'})
            if any(files[n]!=data for n,data in {**records,'/DCLoad.HC':fixture.read_bytes()}.items()):raise ValueError('Delivered inputs changed')
        else:
            source=generator.read_text()+fixture.read_text()+'\nI64 dc_mask=DCLoadContract(66);U8 *dc_line=MStrPrint("MASK %d\\n",dc_mask);Report(dc_line);Free(dc_line);dc_mask=ExpandRawContract;dc_line=MStrPrint("RAW MASK %d\\n",dc_mask);Report(dc_line);Free(dc_line);Report("DONE device context load\\n");\n'
            (overlay/'Once.HC').write_text(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=reference.sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            log=(out/'guest/debug.log').read_text()
            if 'MASK 63\n' not in log or 'RAW MASK 31\n' not in log:raise ValueError('Original load/expansion checks failed')
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
