#!/usr/bin/env python3
"""Compare bitmap conversion and document sprite ownership to the original system."""
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, nargs='?')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--shared', action='store_true')
    args = parser.parse_args()
    if args.disk and args.shared:
        parser.error('--shared applies to the original-system control')
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-bitmap-document/Contract.HC'
    inputs = [Path(__file__).resolve(), Path(reference.__file__), fixture]
    report = dict(result='running', mode='native' if args.disk else 'shared' if args.shared else 'pinned-original',
                  scope='Four bitmap widths/padding payloads, independent sprite records, document copy ownership and tagged/default/no-document insertion; not rendering or complete graphics Type')
    expected = {}
    for i,(w,h) in enumerate(zip((1,8,9,17),(1,2,3,2))):
        body = bytes((j*7+i)&255 for j in range(((w+7)&~7)*h))
        expected[f'bitmap{i}.DATA'] = struct.pack('<Biiii',23,0,0,w,h)+body+b'\0'
    if args.disk:
        inputs += [args.disk.resolve(), ROOT/'tools/i386-kernel-input.py',
                   ROOT/'tools/build-i386-kernel.py', ROOT/'tools/package-i386-native-image.py']
    else:
        overlay = out/'reference-overlay'
        overlay.mkdir()
        report.update(reference_revision=reference.REFERENCE, repair_revision=reference.REPAIRS,
                      reference_sha256=reference.restore_reference(overlay))
        inputs += [ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py']
        if args.shared:
            report['source_overrides'] = {}
            for name in ('Adam/Gr/SpriteNew.HC','Adam/Gr/DC2SpriteCore.HC',
                         'Adam/Gr/GrSpritePlot.HC','Adam/Gr/DocSpriteCore.HC',
                         'Adam/Gr/SpriteRecordsCore.HC','Adam/Gr/SpriteRenderCore.HC',
                         'Adam/Gr/GrDefaultContext.HH'):
                path=ROOT/name
                (overlay/name).write_bytes(path.read_bytes())
                inputs.append(path)
                report['source_overrides'][name]=reference.sha(path)
    report['input_sha256']={str(p):reference.sha(p) for p in inputs}
    try:
        if args.disk:
            disk=out/'working.img'
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
                args.disk.resolve(),disk,additions={'/BitmapDoc.HC':fixture.read_bytes()})
            commands=[('#include "C:/BitmapDoc.HC"',[]),('BitmapDocContract(67);',['63']),('6*7;',['42'])]
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
                disk,out/'guest',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='tcg',qmp_stdio=True,
                startup_check={'status':'ok','answers':[],'commands':commands,'command_timeout':120})
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](
                disk,{'/'+n for n in expected}|{'/BitmapDoc.HC'})
            if files['/BitmapDoc.HC'] != fixture.read_bytes():
                raise ValueError('Delivered fixture differs')
            observed={n:files['/'+n] for n in expected}
        else:
            source=fixture.read_text()+ '\nU0 Report(U8 *s){while(*s)OutU8(0xE9,*s++); }\n'
            source+='I64 mask=BitmapDocContract(66);U8 *line=MStrPrint("MASK %d\\n",mask);Report(line);Free(line);\n'
            for name in expected:
                source+='U8 *buf'+name[6]+';I64 len'+name[6]+';\n'
                source+=f'buf{name[6]}=FileRead("B:/{name}",&len{name[6]});line=MStrPrint("EXPORT {name} %X %X\\n",buf{name[6]},len{name[6]});Report(line);Free(line);\n'
            source+='Report("DONE bitmap document\\n");\n'
            (overlay/'Once.HC').write_text(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=reference.sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if 'MASK 63\n' not in (out/'guest/debug.log').read_text():
                raise ValueError('Original document ownership checks failed')
            observed={n:(out/'guest'/n).read_bytes() for n in expected}
        report['observed_hex']={n:v.hex() for n,v in observed.items()}
        if observed != expected:
            raise ValueError('Bitmap sprite bytes differ from independent record oracle')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        raise
    finally:
        report['inputs_unchanged']=all(reference.sha(Path(p))==d for p,d in report['input_sha256'].items())
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':
        raise ValueError(report['error'])


if __name__=='__main__':
    main()
