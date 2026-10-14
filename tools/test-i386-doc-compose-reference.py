#!/usr/bin/env python3
"""Capture original text-before-document composition and single dynamic evaluation."""
import argparse
import json
from pathlib import Path
import runpy
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
EXPECTED = [1,65,2,66,2,17]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--current-system',action='store_true',
                        help='Run the same oracle on the latest qualified x64 rebuild and current sources')
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    overlay = out/'reference-overlay'
    overlay.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-doc-compose-reference'
    sha = REFERENCE['sha']
    inputs = [Path(__file__).resolve(), ROOT/'tools/test-i386-timeclock-reference.py',
              fixture/'Once.HC', ROOT/'Kernel/FontStd.HC', ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py']
    source_hashes = {}
    extra = [overlay]
    if args.current_system:
        manifest = ROOT/'build/rebuild-test/result.json'
        snapshot = json.loads(manifest.read_text())
        if snapshot.get('result') != 'pass':
            raise ValueError('Current-system control requires a passing rebuild')
        for name,digest in snapshot['source_sha256'].items():
            path = ROOT/name
            if sha(path) != digest:
                raise ValueError('Current-system source differs from rebuild: '+name)
            inputs.append(path)
        extra = [ROOT/'build/rebuild-test/overlay']
        for name,relative in [('Compiler.BIN','Compiler/Compiler.BIN'),
                              ('Kernel.BIN','0000Boot/0000Kernel.BIN.C')]:
            path = extra[0]/relative
            if sha(path) != snapshot['generations'][-1][name]:
                raise ValueError('Current-system binary differs from rebuild: '+name)
            inputs.append(path)
        inputs.append(manifest)
        source_hashes = snapshot['source_sha256']
    else:
        source_hashes = REFERENCE['restore_reference'](overlay)
    report = dict(result='running',
                  system='current-x64-rebuild' if args.current_system else 'pinned-original',
                  baseline_reference_revision=REFERENCE['REFERENCE'],
                  baseline_repair_revision=REFERENCE['REPAIRS'],
                  system_source_sha256=source_hashes,
                  input_sha256={str(p):sha(p) for p in inputs},
                  scope='Two original text-then-document frames: previous text cells, current sprite rectangle, dynamic callback exactly once per frame; not full desktop, focus, arbitrary sprites or stdout')
    try:
        iso = out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(extra[0]),
                        '--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256'] = sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),
                        '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        data = (out/'guest/doc-compose.bin').read_bytes()
        report['observed'] = list(struct.unpack('<6q',data))
        report['expected'] = EXPECTED
        if data != struct.pack('<6q',*EXPECTED):
            raise ValueError('Original document renderer differs from explicit cell oracle')
        import re
        glyphs = [int(v,16) for v in re.findall(rb'0x[0-9A-Fa-f]{16}',(ROOT/'Kernel/FontStd.HC').read_bytes())]
        for name,ch in [('compose-first.bin','P'),('compose-second.bin','A')]:
            expected = bytearray([15]*192)
            font = glyphs[ord(ch)].to_bytes(8,'little')
            for y in range(8):
                for x in range(8):
                    if font[y]&(1<<x): expected[y*24+x]=0
            for y in range(2,7):
                for x in range(4,17): expected[y*24+x]=1
            actual = (out/'guest'/name).read_bytes()
            report.setdefault('frame_hex',{})[name]=actual.hex()
            if actual!=bytes(expected):
                raise ValueError('Original text/sprite frame differs from independent pixel oracle: '+name)
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p))==h for p,h in report['input_sha256'].items())
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Reference inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__ == '__main__':
    main()
