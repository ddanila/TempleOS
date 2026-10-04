#!/usr/bin/env python3
"""Forward declaration and failed-compilation recovery with debugger G published."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [
        ('HashFind("G",Fs->hash_table,HTT_FUN)!=0;', ['1']),
        ('extern I64 ForwardValue(I64 x);I64 ForwardCaller(){return ForwardValue(40);}I64 ForwardValue(I64 x){return x+2;}', []),
        ('ForwardCaller;', ['42']),
        ('extern I64 Pending();I64 Broken(){return Pending();}', ['Compilation failed']),
        ('ForwardCaller;', ['42']),
        ('HashFind("G",Fs->hash_table,HTT_FUN)!=0;', ['1']),
    ]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, disk = sha(Path(__file__)), sha(args.disk)
    report = dict(checker_sha256=checker, disk_sha256=disk,
                  scope='Forward call resolution and recovery after unresolved extern; preserves public debugger G name')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands()})
        if sha(Path(__file__)) != checker:
            raise ValueError('Forward-call checker changed during execution')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['source_disk_unchanged'] = sha(args.disk) == disk
        if not report['source_disk_unchanged']:
            report.update(result='fail', error='Forward-call check modified source disk')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
