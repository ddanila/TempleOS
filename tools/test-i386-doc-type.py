#!/usr/bin/env python3
"""Compare complete original Type/DocType documents, raw output and Busy timing services."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
import runpy
import struct
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
    fixture=ROOT/'tests/guest/i386-doc-type/Contract.HC'
    busy_core=ROOT/'Kernel/BusyCore.HC'
    generator=ROOT/'tests/guest/i386-dc-load/Generate.HC'
    inputs=[Path(__file__).resolve(),Path(reference.__file__),fixture,generator,busy_core]
    report=dict(result='running',mode='native' if args.disk else 'shared' if args.shared else 'pinned-original',
                scope='Complete DocType text and graphics branches, six exact documents, raw DocDump/DocType cache and four VGA planes, invalid/no-document/unsupported-type returns, original Busy fallback and actual HPET delay, native compilation of the shared Busy body; not full terminal startup or whole-file qualification')
    captures=[f'type{i}.DD' for i in range(6)]+[f'raw-type{i}.BIN' for i in range(2)]
    fixture_bytes=fixture.read_bytes()+b'\n#define Busy BusySourceCheck\n'+busy_core.read_bytes()
    if args.disk:
        baseline=json.loads((args.reference/'result.json').read_text())
        if baseline['result']!='pass' or baseline['mode']!='pinned-original':raise ValueError('Need passing original control')
        records={f'/load{i}.DATA':(args.reference/'guest'/f'load{i}.DATA').read_bytes() for i in range(4)}
        for name,data in records.items():
            if reference.sha(args.reference/'guest'/name[1:])!=baseline['record_sha256'][name[1:]]:raise ValueError('Changed reference record')
        for name in captures:
            if reference.sha(args.reference/'guest'/name)!=baseline['capture_sha256'][name]:raise ValueError('Changed original document/raw capture')
        inputs += [args.reference/'guest'/name for name in captures]
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
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={**records,'/DocType.HC':fixture_bytes})
            commands=[('#include "C:/DocType.HC"',[]),('BusySourceCheck(0);',[]),('DTBusy(0xFED00000);',['7']),('DTSeed(67);',['7']),('DTDocuments(67);',['1023']),('DTWarm;',[]),('DTRaw(67,0);',['1']),('DTRaw(67,1);',['1']),('6*7;',['42'])]
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](disk,out/'guest',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='tcg',qmp_stdio=True,startup_check={'status':'ok','answers':[],'commands':commands,'command_timeout':120,'pause_window_manager':False})
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,set(records)|{'/DocType.HC'}|{'/'+n for n in captures})
            if any(files[n]!=data for n,data in {**records,'/DocType.HC':fixture_bytes}.items()):raise ValueError('Delivered inputs changed')
            observed={n:files['/'+n] for n in captures}
            expected={n:(args.reference/'guest'/n).read_bytes() for n in captures}
            if observed!=expected:raise ValueError('Native documents or raw VGA capture differ from original')
        else:
            source=generator.read_bytes()+fixture_bytes+b'\n'
            source+=b'I64 dt_mask=DTBusy(dev.uncached_alias+0xFED00000);U8 *dt_line=MStrPrint("BUSY MASK %d\\n",dt_mask);Report(dt_line);Free(dt_line);\n'
            source+=b'BusySourceCheck(0);dt_mask=DTSeed(66);dt_line=MStrPrint("SEED MASK %d\\n",dt_mask);Report(dt_line);Free(dt_line);\n'
            source+=b'dt_mask=DTDocuments(66);dt_line=MStrPrint("DOC MASK %d\\n",dt_mask);Report(dt_line);Free(dt_line);DTWarm;\n'
            source+=b'if(DTRaw(66,0)&&DTRaw(66,1))Report("RAW PASS\\n");\n'
            for i,name in enumerate(captures):
                source+=f'U8 *dt_buf{i};I64 dt_size{i};dt_buf{i}=FileRead("B:/{name}",&dt_size{i});dt_line=MStrPrint("EXPORT {name} %X %X\\n",dt_buf{i},dt_size{i});Report(dt_line);Free(dt_line);\n'.encode()
            source+=b'Report("DONE document type\\n");\n'
            (overlay/'Once.HC').write_bytes(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=reference.sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            log=(out/'guest/debug.log').read_text()
            if not all(marker in log for marker in ('BUSY MASK 7\n','SEED MASK 7\n','DOC MASK 1023\n','RAW PASS\n')):raise ValueError('Original Type/timing checks failed')
            observed={n:(out/'guest'/n).read_bytes() for n in captures}
            report['record_sha256']={f'load{i}.DATA':reference.sha(out/'guest'/f'load{i}.DATA') for i in range(4)}
        for mode,col in enumerate((84,160)):
            data=observed[f'raw-type{mode}.BIN']
            if len(data)!=192048 or list(struct.unpack_from('<6q',data))!=[col,0,80,60,1,1]:raise ValueError('Raw output state differs')
            if any(data[48+38400*(plane+1):48+38400*(plane+2)]!=data[48:38448] for plane in range(4)):raise ValueError('Raw VGA planes differ from cache')
        report['capture_sha256']={n:__import__('hashlib').sha256(data).hexdigest() for n,data in observed.items()}
        report['result']='pass' 
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(reference.sha(Path(p))==d for p,d in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])


if __name__=='__main__':main()
