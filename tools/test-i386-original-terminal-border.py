#!/usr/bin/env python3
"""Check original terminal border bindings and editor callbacks."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--shared-core', action='store_true', help='Compile current shared border and callback bodies')
    args = parser.parse_args()
    if args.out.exists(): parser.error('Use a fresh output directory')
    out = args.out.resolve(); overlay = out/'overlay'; overlay.mkdir(parents=True)
    core = ROOT/'Adam/DolDoc/DocTerm.HC'
    fixture = ROOT/'tests/guest/i386-terminal-border/Contract.HC'
    shared = ROOT/'Adam/DolDoc/DocBorderCallbacksCore.HC'
    border = ROOT/'Adam/DolDoc/DocBorderNewCore.HC'
    files = [Path(__file__).resolve(), core, shared, border, ROOT/'Adam/DolDoc/DocEd.HC', fixture, ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py', ROOT/'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C', ROOT/'build/rebuild-test/overlay/Compiler/Compiler.BIN']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in files}
    report = dict(result='running', input_sha256=pins, shared_core=args.shared_core,  
                  scope='Original DocBorderNew: five document-bound callbacks, task-title binding, border flag, actual overstrike/dollar/EOF callback text; no exact heap, live rendering or input action coverage')
    if args.shared_core:
        report['scope'] = 'Current shared border/callback bodies in original TempleOS: document bindings, title binding, border flag and overstrike/dollar/EOF outputs; no exact heap, live rendering or input action coverage'
    try:
        source = fixture.read_bytes()
        if args.shared_core:
            source = shared.read_bytes() + border.read_bytes() + source
            for name in (b'DocBorderNew', b'EdOverStrikeCB', b'EdAutoSaveCB', b'EdFilterCB', b'EdDollarCB', b'EdMoreCB', b'EdDollarTypeCB'):
                source = source.replace(name, b'TBShared'+name)
        source += b'\nU0 JRReport(U8 *s){while(*s)OutU8(0xE9,*s++); }\n'
        source += b'I64 jr_mask=JRContract;U8 *jr_line=MStrPrint("OBS job results mask %d\\n",jr_mask);JRReport(jr_line);Free(jr_line);\n'
        source += b'JRReport("DONE job results\\n");\n'
        (overlay/'Once.HC').write_bytes(source)
        iso = out/'original.iso'
        subprocess.run([sys.executable, str(ROOT/'tools/build-iso.py'), '--overlay', str(ROOT/'build/rebuild-test/overlay'), '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(iso), '--out', str(out/'behavior'), '--timeout', '90', '--qmp-stdio'], cwd=ROOT, check=True)
        log = (out/'behavior/debug.log').read_text()
        report['observations'] = [line for line in log.splitlines() if line.startswith('OBS job results')]
        if 'OBS job results mask 63\n' not in log or 'DONE job results\n' not in log:
            raise ValueError('Original job result contract did not pass')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error)); raise
    finally:
        changed = [p for p,h in pins.items() if sha(Path(p)) != h]
        if changed: report.update(result='fail', changed_inputs=changed)
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass': raise RuntimeError('Job result oracle inputs changed')

if __name__ == '__main__': main()
