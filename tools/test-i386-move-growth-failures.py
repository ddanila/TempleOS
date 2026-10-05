#!/usr/bin/env python3
"""Run real write/flush failures spanning destination growth and file transfer."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', type=Path, required=True)
    parser.add_argument('--disk', type=Path, required=True)
    parser.add_argument('--exports', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    repository = args.repository.resolve()
    inputs = [Path(__file__).resolve(), args.disk.resolve()]
    inputs += sorted((repository/'tools').glob('*.py'))
    inputs += sorted(p for p in args.exports.resolve().rglob('*') if p.is_file())
    digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): digest(p) for p in inputs}
    report = {'result': 'fail', 'input_sha256': pins}
    try:
        build = runpy.run_path(str(repository/'tools/build-i386-kernel.py'))
        report.update(build['verify_file_io_failure_matrix'](
            args.disk.resolve(), args.exports.resolve(), args.out.resolve(), growth=True))
        if any(digest(Path(p)) != h for p, h in pins.items()):
            raise ValueError('Failure matrix qualification inputs changed')
        report['inputs_unchanged'] = True
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
