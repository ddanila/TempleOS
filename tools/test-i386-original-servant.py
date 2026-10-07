#!/usr/bin/env python3
"""Check original SrvCmdLine startup and servant dispatch before porting it."""
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
    parser.add_argument('--shared-core', action='store_true', help='Compile current shared servant loop with original startup hook')
    parser.add_argument('--startup-hook', action='store_true', help='Interpose startup hook while calling its original body')
    args = parser.parse_args()
    if args.out.exists(): parser.error('Use a fresh output directory')
    out = args.out.resolve(); overlay = out/'overlay'; overlay.mkdir(parents=True)
    core = ROOT/'Kernel/KTask.HC'
    fixture = ROOT/'tests/guest/i386-servant'/('StartupHook.HC' if args.startup_hook else 'Contract.HC')
    shared = ROOT/'Kernel/SrvTaskContCore.HC'
    files = [Path(__file__).resolve(), core, shared, fixture, ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py', ROOT/'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C', ROOT/'build/rebuild-test/overlay/Compiler/Compiler.BIN']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in files}
    report = dict(result='running', input_sha256=pins, shared_core=args.shared_core, startup_hook=args.startup_hook, 
                  scope='Actual original SrvCmdLine child: startup document/window inhibit, idle/awaiting flags, ten TaskExe wake-master results42, completed metadata, restored title and empty rings; no exact heaps, intercepted startup hook or popup UI coverage')
    if args.shared_core:
        report['scope'] = 'Current shared servant loop compiled in original TempleOS: original startup hook, actual child, idle flags, ten wake-master results, title restoration and empty rings; no exact heap or popup coverage'
    if args.startup_hook:
        report['scope'] += '; startup hook interposed and original body retained, exactly once after inhibit initialization, hook restored'
    try:
        source = fixture.read_text()
        if args.shared_core:
            source = shared.read_text().replace('U0 SrvTaskCont()', 'U0 JRSharedSrvTaskCont()', 1) + '\nU0 JRSharedSrvCmdLine(I64 dummy=0){no_warn dummy;Fs->win_inhibit=WIG_USER_TASK_DFT;CallExtStr("SrvStartUp");JRSharedSrvTaskCont;}\n' + source.replace('&SrvCmdLine', '&JRSharedSrvCmdLine')
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
