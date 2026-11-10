#!/usr/bin/env python3
"""Compare public default-home resolution with the pinned original system."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = '1|?:/Home|?:/Home/HomeSys.HC|1|1|?:/Home\n'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('image', type=Path, nargs='?')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-home-path-reference/Once.HC'
    paths = [Path(__file__).resolve(), fixture, ROOT/'tools/package-i386-native-image.py',
             ROOT/'tools/test-i386-autocomplete-interaction.py', ROOT/'tools/build-iso.py',
             ROOT/'tools/guest-run.py', ROOT/'tools/test-i386-timeclock-reference.py']
    if args.image:
        args.image = args.image.resolve()
        paths.append(args.image)
    report = dict(result='running', system='native' if args.image else 'pinned-original',
                  scope='Public Cd default, DirCur, ~/HomeSys.HC and Cd(~); normalize only drive letter. Not full HomeSys/default Once qualification.',
                  input_sha256={str(p): sha(p) for p in paths}, expected=EXPECTED)
    guest = None
    try:
        if args.image:
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            image = out/'working.img'
            report['packaging'] = pack['package'](args.image, image,
                                                  additions={'/Probe/HomePath.HC': fixture.read_bytes()})
            Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
            guest = Guest(image, out/'guest', True)
            guest.wait('DONE native kernel startup\n')
            guest.command('#include "C:/Probe/HomePath.HC"', timeout=180)
            guest.wait('DONE original home path\n')
            guest.collect()
        else:
            reference = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_source_sha256'] = reference['restore_reference'](overlay)
            subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', str(overlay),
                            '--overlay', str(fixture.parent), '--output', str(out/'original.iso')],
                           cwd=ROOT, check=True)
            subprocess.run([sys.executable, 'tools/guest-run.py', str(out/'original.iso'),
                            '--out', str(out/'guest'), '--qmp-stdio', '--timeout', '120'],
                           cwd=ROOT, check=True)
        data = (out/'guest/home-path.bin').read_text()
        report.update(fixture_executed=True, raw=data)
        # Preserve all path bytes except the actual boot drive, which differs.
        normalized = data.replace('T:/', '?:/').replace('C:/', '?:/')
        report['normalized'] = normalized
        if normalized != EXPECTED:
            raise ValueError('Public home paths differ from original')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        if guest:
            guest.close()
        report['inputs_unchanged'] = all(sha(Path(p)) == h for p, h in report['input_sha256'].items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Input changed during run')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
