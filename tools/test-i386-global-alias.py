#!/usr/bin/env python3
"""Compare publication and retained use of completed extern globals."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]

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
    fixture = ROOT/'tests/guest/i386-global-alias/Contract.HC'
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
                  scope='Same-input extern/definition publication for aggregate, scalar and incomplete-array globals; original alias flags and shared addresses, initialized fields, retained reads and mutations after control release. Bytes after string terminators are unspecified and excluded.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/PublicGlobalAlias.HC': fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Probe').mkdir()
            (overlay/'Probe/PublicGlobalAlias.HC').write_bytes(fixture.read_bytes())
            commands=['ExeFile("::/Probe/PublicGlobalAlias.HC");',
                      'ExePutS('+json.dumps('AGExport("aggregate-retained.bin");')+');',
                      'ExePutS('+json.dumps('aggregate_records[1].size=9;aggregate_scalar=-9;aggregate_bytes[2]=7;')+');',
                      'ExePutS('+json.dumps('AGExport("aggregate-mutated.bin");')+');']
            (overlay/'Once.HC').write_text('\n'.join(commands)+'\n')
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/PublicGlobalAlias.HC"')
        g.wait('aggregate-initial.bin DONE\n')
        def check(name,mutated=False):
            data=(g.out/name).read_bytes();(out/name).write_bytes(data)
            if len(data)!=55 or struct.unpack_from('<3q',data)!= (1,1,1):raise ValueError('Global alias metadata differs')
            #HolyC string initializers leave bytes after the terminator unspecified.
            expected={24:1,25:2,26:ord('o'),27:ord('n'),28:ord('e'),29:0,
                      34:3,35:9 if mutated else 4,36:ord('t'),37:ord('w'),38:ord('o'),39:0}
            if any(data[i]!=v for i,v in expected.items()):raise ValueError('Aggregate fields differ')
            if struct.unpack_from('<q',data,44)[0]!=(-9 if mutated else 0x1122334455667788):raise ValueError('Scalar differs')
            if data[52:]!=bytes([1,2,7 if mutated else 3]):raise ValueError('Incomplete-array definition differs')
        check('aggregate-initial.bin')
        if args.disk:
            g.command('AGExport("aggregate-retained.bin");')
            check('aggregate-retained.bin')
            g.command('aggregate_records[1].size=9;aggregate_scalar=-9;aggregate_bytes[2]=7;')
            g.command('AGExport("aggregate-mutated.bin");')
            check('aggregate-mutated.bin',True)
        if not args.disk:
            g.wait('aggregate-mutated.bin DONE\n');check('aggregate-retained.bin');check('aggregate-mutated.bin',True)
        report['cases']=3
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
