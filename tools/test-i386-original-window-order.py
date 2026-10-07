#!/usr/bin/env python3
"""Check original window ordering and focus policy with actual tasks."""
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
    parser.add_argument('--shared-core', action='store_true', help='Compile current shared window ordering body')
    args = parser.parse_args()
    if args.out.exists(): parser.error('Use a fresh output directory')
    out = args.out.resolve(); overlay = out/'overlay'; overlay.mkdir(parents=True)
    core = ROOT/'Adam/Win.HC'
    fixture = ROOT/'tests/guest/i386-window-order/Contract.HC'
    shared = ROOT/'Adam/WinOrderCore.HC'
    files = [Path(__file__).resolve(), core, shared, fixture, ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py', ROOT/'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C', ROOT/'build/rebuild-test/overlay/Compiler/Compiler.BIN']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in files}
    report = dict(result='running', input_sha256=pins, shared_core=args.shared_core,  
                  scope='Actual original tasks: move-to-top and idempotence, self-focus inhibition, always-on-top ordering, child-raise suppression and recursive child focus; no popup, z-buffer or exact heap coverage')
    if args.shared_core:
        report['scope'] = 'Current shared window ordering body with original task-ring providers; move/idempotence, focus inhibition, always-on-top, child suppression and recursive focus; no popup/z-buffer/heap coverage'
    try:
        source = fixture.read_text()
        if args.shared_core:
            source = shared.read_text().replace('WinOnTopWindows', 'WOSharedOnTop').replace('WinToTop', 'WOSharedToTop') + source.replace('WinToTop(', 'WOSharedToTop(')
        source += '\nU0 JRReport(U8 *s){while(*s)OutU8(0xE9,*s++); }\n'
        source += 'I64 jr_mask=JRContract;U8 *jr_line=MStrPrint("OBS job results mask %d\\n",jr_mask);JRReport(jr_line);Free(jr_line);\n'
        source += 'JRReport("DONE job results\\n");\n'
        (overlay/'Once.HC').write_text(source)
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
