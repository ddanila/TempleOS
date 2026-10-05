#!/usr/bin/env python3
"""Require public Caller to identify live compiled functions and reject bad depth."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--invalid-frames', action='store_true', help='Exercise temporary self, misaligned and out-of-stack frame links')
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    inputs = [args.disk.resolve(), Path(__file__).resolve(), ROOT/'tools/i386-kernel-input.py']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in inputs}
    report = {'result': 'fail', 'input_sha256': pins,
              'scope': 'Public live-stack Caller depths 0/1 and invalid-depth rejection; not fabricated or freed frames'}
    checks = [
        ('Caller(-1)==0;', ['1']),
        ('Caller(0x7FFFFFFF)==0;', ['1']),
        ('U8 *CallerBodyBase=0,*CallerOuterBase=0;I64 CallerBodySize=0,CallerOuterSize=0;', []),
        ('Bool CallerBody(){U8 *p=Caller(0),*q=Caller(1);return p>=CallerBodyBase&&p<CallerBodyBase+CallerBodySize&&q>=CallerOuterBase&&q<CallerOuterBase+CallerOuterSize;}', []),
        ('Bool CallerOuter(){return CallerBody;}', []),
        ('U0 CallerBind(){CallerBodyBase=(&CallerBody+0)(U64);CallerOuterBase=(&CallerOuter+0)(U64);CallerBodySize=MSize(CallerBodyBase);CallerOuterSize=MSize(CallerOuterBase);}', []),
        ('CallerBind;CallerBodySize>0&&CallerOuterSize>0;', ['1']),
        ('CallerOuter;', ['1'])]
    if args.invalid_frames:
        checks += [
            ('_intern 0x71 U8 *CallerFrame();', []),
            ('Bool CallerBad(U32 mode){U32 *p=CallerFrame();U32 save=p[0];Bool ok;if(mode==0)p[0]=(p+0)(U64);else if(mode==1)p[0]=(p+0)(U64)+1;else p[0]=1;ok=Caller(2)==0;p[0]=save;return ok;}', []),
            ('CallerBad(0);', ['1']),
            ('CallerBad(1);', ['1']),
            ('CallerBad(2);', ['1']),
            ('CallerOuter;', ['1'])]
        report['scope'] = 'Public Caller depths0/1, bad-depth rejection, temporary cyclic/misaligned/out-of-stack links, then valid-stack reuse; not freed/debugger/other-task frames'
    try:
        report['behavior'] = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
            args.disk, args.out/'behavior', cpu='486,-fpu', accel='kvm',
            startup_check={'status': 'ok', 'answers': [], 'commands': checks})
        if any(sha(Path(p)) != digest for p, digest in pins.items()):
            raise ValueError('Caller qualification input changed')
        report.update(result='pass', inputs_unchanged=True)
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
