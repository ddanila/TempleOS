#!/usr/bin/env python3
"""Run the unchanged ClassMeta demo and observe output, metadata and retained behavior."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
INITIAL=b'age:44 default:38\ncolor: default:4\nrank:3 default:3 Admiral\nage:22 default:38 percentile: 54.20\nrank:2 default:5\nserial_num: 55555 default:123456\n\x05'
MUTATED=b'age:55 default:38\ncolor: default:4\nrank:2 default:3 Captain\nage:40 default:38 percentile: 54.20\nrank:1 default:5\nserial_num:  1234 default:123456\n\x05'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-class-meta/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    paths.append(ROOT/'Demo/ClassMeta.HC')
    if args.disk:
        paths.append(args.disk.resolve())
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Unchanged bundled Demo/ClassMeta.HC through normal ExeFile, exact captured document output, class/global/member metadata, evaluated defaults, string/F64/function metadata, calls after input release and allocator churn, then mutated data with unchanged defaults. Persistent demo declarations and capture buffers intentionally survive until shutdown; full C1-C5 qualification remains open.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            if before['/Demo/ClassMeta.HC'][2]!=(ROOT/'Demo/ClassMeta.HC').read_bytes():raise ValueError('Delivered demo differs')
            additions = {'/Probe/ClassMeta.HC': fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes())
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/ClassMeta.HC"')
        g.wait('CLASS META DONE\n')
        data=(g.out/'class-meta-mask.bin').read_bytes()
        (out/'class-meta-mask.bin').write_bytes(data)
        for name in ('class-meta-initial.DD','class-meta-retained.DD','class-meta-mutated.DD'):
            if (g.out/name).exists():
                (out/name).write_bytes((g.out/name).read_bytes())
        report['mask']=struct.unpack('<q',data)[0]
        if report['mask']!=511:raise ValueError('ClassMeta workflow differs: '+str(report['mask']))
        report['outputs']={}
        for name,expected in [('class-meta-initial.DD',INITIAL),('class-meta-retained.DD',INITIAL),('class-meta-mutated.DD',MUTATED)]:
            actual=(out/name).read_bytes()
            if actual!=expected:raise ValueError('Unexpected complete demo output: '+name)
            report['outputs'][name]={'bytes':len(actual),'sha256':hashlib.sha256(actual).hexdigest()}
        if args.disk:
            g.command('6*7;');report['arithmetic_pixels']=g.result_pixels()
        g.close()
        g = None
        if args.disk:
            after = pack['snapshot'](image.read_bytes())[1]
            if {n for n in set(before)|set(after) if before.get(n)!=after.get(n)} != set(additions):
                raise ValueError('Unexpected filesystem changes')
            report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report['result'] = 'pass'
    except BaseException as exc:
        report.update(result='fail',error=str(exc))
        if g:g.screenshot('failure')
        raise
    finally:
        if g:
            try:
                g.close()
            except Exception as exc:
                report.update(result='fail',cleanup_error=str(exc))
        report['inputs_unchanged'] = all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__ == '__main__':
    main()
