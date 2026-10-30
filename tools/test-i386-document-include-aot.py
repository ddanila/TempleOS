#!/usr/bin/env python3
"""Build a native module from nested DolDoc source with embedded binary records."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    files = {
        '/DocAot/Main.HC': b'#include "/DocAot/Child.HC"\npublic I64 DocAotCheck(){return DocAotSize==4 && DocAotBytes[0]==0 && DocAotBytes[1]==65 && DocAotBytes[2]==0 && DocAotBytes[3]==255;}\n',
        '/DocAot/Child.HC': b'U8 *DocAotBytes=$IB,"payload",BI=1$;\nI64 DocAotSize=$IS,"payload",BI=1$;\n\0' + struct.pack('<IIII', 1, 0, 4, 2) + bytes([0, 65, 0, 255]),
    }
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    paths = [Path(__file__).resolve(), args.disk.resolve()] + [ROOT/n for n in (
        'tools/package-i386-native-image.py', 'tools/build-i386-kernel.py',
        'tools/i386-kernel-input.py', 'tools/test-i386-timeclock-welcome.py',
        'tools/test-i386-retained-build.py', 'Kernel/FontStd.HC')]
    report = dict(result='running', input_sha256={str(p): sha(p) for p in paths},
                  scope='Native AOT build of nested serialized document with binary and size entries, persisted module export and separate JIT behavior; not module installation or execution')
    try:
        disk = out/'working.img'
        report['packaging'] = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(), disk, additions=files)
        commands = ['if(!I386BuildModule("C:/DocAot/Main.HC","C:/DocAot/Out.t32m",TRUE))throw(\'DocAot\',TRUE);',
                    '#include "C:/DocAot/Main.HC"', "if(!DocAotCheck)throw('DocAot',TRUE);", '6*7;']
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](disk, out/'guest', commands, 64, True, command_timeout=600)
        delivered = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk, set(files) | {'/DocAot/Out.t32m'})
        if any(delivered.get(name) != data for name, data in files.items()):
            raise ValueError('Delivered include files changed')
        module = delivered['/DocAot/Out.t32m']
        count, exports = runpy.run_path(str(ROOT/'tools/test-i386-retained-build.py'))['exports_of'](module)
        if 'DocAotCheck' not in exports:
            raise ValueError('Compiled module lacks DocAotCheck export')
        (out/'Out.t32m').write_bytes(module)
        report.update(result='pass', module_sha256=hashlib.sha256(module).hexdigest(), module_bytes=len(module), record_count=count, exports=exports)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p, digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
