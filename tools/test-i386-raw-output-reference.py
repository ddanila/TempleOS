#!/usr/bin/env python3
"""Record original raw output contracts."""
import argparse
import json
from pathlib import Path
import runpy
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
EXPECTED_COLUMNS = [1,9,2,81,1,1,6,4801,4721,81,2,1,1]


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
    fixture = ROOT/'tests/guest/i386-raw-output-reference'
    sha = REFERENCE['sha']
    inputs = [Path(__file__).resolve(), ROOT/'tools/test-i386-timeclock-reference.py',
              fixture/'Once.HC', fixture/'Contract.HC', fixture/'oracle.json', ROOT/'Kernel/FontStd.HC', ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py']
    oracle=json.loads((fixture/'oracle.json').read_text())
    if sha(fixture/'Contract.HC')!=oracle['fixture_sha256']:raise ValueError('Fixture differs from frozen original oracle')
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
                  scope='Original raw cache and four hardware planes, character controls, dollar state, wrapping, scrolling, roles and heap cleanup')
    try:
        iso = out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(extra[0]),
                        '--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256'] = sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),
                        '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        report['captures']=[]
        for mode,column in enumerate(EXPECTED_COLUMNS):
            data=(out/f'guest/raw-output-{mode}.bin').read_bytes()
            if len(data)!=192048:raise ValueError('Raw capture length')
            meta=list(struct.unpack_from('<6q',data))
            expected=[column,4 if mode==6 else 8 if mode==8 else 0,80,60,int(mode!=12),31]
            if meta!=expected:raise ValueError(f'Raw state {mode}: {meta} != {expected}')
            cache=data[48:38448]
            for plane in range(4):
                if data[38448+plane*38400:38448+(plane+1)*38400]!=cache:
                    raise ValueError(f'Raw hardware differs from cache: {mode}, plane {plane}')
            import hashlib
            report['captures'].append(dict(mode=mode,meta=meta,sha256=hashlib.sha256(data).hexdigest(),cache_sha256=hashlib.sha256(cache).hexdigest()))
        if report['captures']!=oracle['captures']:raise ValueError('Captures differ from frozen original oracle')
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
