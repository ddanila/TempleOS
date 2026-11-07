#!/usr/bin/env python3
"""Compare original DirFile upward search, defaults and allocation ownership."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import re
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
EXPECTED=struct.pack('<44Q',*([1]*44))
ORIGINAL_WORDS=[1]*44
for case in (3,4,5,6,14,15,16,17,19,20):ORIGINAL_WORDS[case*2+1]=0
ORIGINAL_EXPECTED=struct.pack('<44Q',*ORIGINAL_WORDS)
TREE={name:b'marker' for name in ('DirFileProbe/A/B/C/anchor.HC','DirFileProbe/A/B/C/near.HC','DirFileProbe/A/B/C/plain','DirFileProbe/A/B/up.HC','DirFileProbe/A/top.HC','DirFileProbe/A/A.PRJ.Z','DirFileProbe/root.HC')}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    expected_bytes=EXPECTED if args.disk else ORIGINAL_EXPECTED
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-dir-file/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    if args.disk:
        paths.append(args.disk.resolve())
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Public DirFile: nearest existing directory, current/relative/absolute inputs, upward file and directory-name search, extension spelling, default paths, root behavior, input/cwd preservation, 512 repeated searches and exact native heap recovery. Original miss leaks recorded separately.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/DirFile.HC': fixture.read_bytes(),**{'/'+name:data for name,data in TREE.items()}}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes())
            for name,data in TREE.items():
                target=overlay/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/DirFile.HC"',timeout=900)
        g.wait('DIR FILE DONE\n',timeout=900)
        data=(g.out/'dir-file.bin').read_bytes()
        (out/'dir-file.bin').write_bytes(data)
        for name in ('dir-file-paths.txt','dir-file-heap-deltas.bin'):(out/name).write_bytes((g.out/name).read_bytes())
        report['heap_deltas']=list(struct.unpack('<21q',(out/'dir-file-heap-deltas.bin').read_bytes()))
        normalized=re.sub(rb'(?m)^([0-9]{2}:)[A-Z]:',rb'\1@:',(out/'dir-file-paths.txt').read_bytes())
        (out/'normalized-paths.txt').write_bytes(normalized)
        report['normalized_paths_sha256']=hashlib.sha256(normalized).hexdigest()
        words=struct.unpack('<44Q',data)
        if any(delta<0 or bool(words[i*2+1])!=(delta==0) for i,delta in enumerate(report['heap_deltas'])):raise ValueError('Inconsistent heap observations')
        if data!=expected_bytes:
            actual=struct.unpack('<'+'Q'*(len(data)//8),data)
            expected=struct.unpack('<'+'Q'*(len(expected_bytes)//8),expected_bytes)
            report['mismatches']=[{'word':i,'actual':a,'expected':e} for i,(a,e) in enumerate(zip(actual,expected)) if a!=e]
            raise ValueError('DirFile differs; see raw records')
        report['state']=list(struct.unpack('<44Q',data))
        report['outputs']={'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
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
