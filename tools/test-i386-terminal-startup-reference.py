#!/usr/bin/env python3
"""Check original terminal welcome insertion and settings retained by DocClear."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('reference', ROOT/'tools/test-i386-timeclock-reference.py')
reference = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reference)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--shared', action='store_true',
                        help='Use the verified current original rebuild and sources')
    parser.add_argument('--reference', type=Path,
                        help='Compare saved documents with a pinned-original run')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    overlay = out/'reference-overlay'
    overlay.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-terminal-startup-reference'
    inputs = [Path(__file__).resolve(), Path(reference.__file__), fixture/'Once.HC',
              ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py']
    reference_sha256 = reference.restore_reference(overlay)
    if args.shared:
        manifest = ROOT/'build/rebuild-test/result.json'
        snapshot = json.loads(manifest.read_text())
        if snapshot.get('result') != 'pass':
            raise ValueError('Need a passing current original rebuild')
        inputs.append(manifest)
        for name, digest in snapshot['source_sha256'].items():
            source = ROOT/name
            if reference.sha(source) != digest:
                raise ValueError('Changed rebuilt source: '+name)
            inputs.append(source)
            target = overlay/name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(source.read_bytes())
        for name, relative in [('Compiler.BIN', 'Compiler/Compiler.BIN'),
                               ('Kernel.BIN', '0000Boot/0000Kernel.BIN.C')]:
            source = ROOT/'build/rebuild-test/overlay'/relative
            if reference.sha(source) != snapshot['generations'][-1][name]:
                raise ValueError('Changed rebuilt binary: '+name)
            inputs.append(source)
            (overlay/relative).write_bytes(source.read_bytes())
    names = ('terminal-empty.DD', 'terminal-welcome.DD', 'terminal-cleared.DD')
    expected = None
    if args.reference:
        baseline_path = args.reference.resolve()/'result.json'
        baseline = json.loads(baseline_path.read_text())
        if baseline.get('result') != 'pass' or baseline.get('mode', 'pinned-original') != 'pinned-original':
            raise ValueError('Need a passing pinned-original reference')
        if (baseline.get('reference_revision') != reference.REFERENCE or
                baseline.get('repair_revision') != reference.REPAIRS or
                baseline.get('reference_sha256') != reference_sha256):
            raise ValueError('Reference provenance does not match')
        inputs.append(baseline_path)
        expected = {}
        for name in names:
            path = args.reference.resolve()/'guest'/name
            data = path.read_bytes()
            if data.hex() != baseline['observed_hex'][name]:
                raise ValueError('Changed reference document: '+name)
            inputs.append(path)
            expected[name] = data
    report = dict(result='running', reference_revision=reference.REFERENCE,
                  repair_revision=reference.REPAIRS,
                  mode='shared' if args.shared else 'pinned-original',
                  reference_sha256=reference_sha256,
                  input_sha256={str(p):reference.sha(p) for p in inputs},
                  scope='Original DocTermNew, full welcome Type and DocClear; native startup and desktop task orchestration remain unqualified')
    try:
        iso = out/'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',str(overlay),
                        '--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256'] = reference.sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),
                        '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        observed = {name:(out/'guest'/name).read_bytes() for name in names}
        report['observed_hex'] = {name:data.hex() for name,data in observed.items()}
        if expected is not None and observed != expected:
            raise ValueError('Terminal documents differ from pinned original')
        if observed['terminal-empty.DD'] != b'':
            raise ValueError('Fresh original terminal serialization differs')
        if observed['terminal-cleared.DD'] != b'$WW+H,1$\x05':
            raise ValueError('Original welcome held word-wrap does not survive DocClear')
        welcome = observed['terminal-welcome.DD']
        if welcome != (overlay/'Doc/Start.DD').read_bytes()+b'\n\x05':
            raise ValueError('Full welcome document was not inserted')
        if 'DONE original terminal startup documents\n' not in (out/'guest/debug.log').read_text():
            raise ValueError('Original terminal initialization checks did not complete')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        if any(reference.sha(Path(p)) != digest for p,digest in report['input_sha256'].items()):
            report.update(result='fail', error='Reference fixture or tools changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
