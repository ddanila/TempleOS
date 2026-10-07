#!/usr/bin/env python3
"""Check original JobResScan completion queues before porting popup services."""
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
    parser.add_argument('--worker', action='store_true', help='Actual cross-task TaskExe wake-master contract')
    parser.add_argument('--execution', action='store_true', help='Original actual TaskExe self-queue execution and result contract')
    parser.add_argument('--shared-core', action='store_true', help='Compile current shared body under a distinct name')
    args = parser.parse_args()
    if args.out.exists(): parser.error('Use a fresh output directory')
    out = args.out.resolve(); overlay = out/'overlay'; overlay.mkdir(parents=True)
    core = ROOT/'Kernel/Job.HC'
    fixture = ROOT/'tests/guest/i386-job-results'/('Worker.HC' if args.worker else 'Execution.HC' if args.execution else 'Contract.HC')
    shared = ROOT/'Kernel/JobResScanCore.HC'
    files = [Path(__file__).resolve(), core, shared, fixture, ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py', ROOT/'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C', ROOT/'build/rebuild-test/overlay/Compiler/Compiler.BIN']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in files}
    report = dict(result='running', input_sha256=pins, shared_core=args.shared_core, execution=args.execution, worker=args.worker, 
                  scope='Boot-bound original JobResScan: empty and pending results, master/self and separate control done rings, any-result scan, caller heap and locks; synthetic completion queues, not actual TaskExe worker execution')
    if args.execution:
        report['scope'] = 'Actual original TaskExe self-queue: metadata, copied source, pending scan, JobsHndlr completion, value42 and empty rings across ten cycles; no heap, cross-task servant, cancellation or popup coverage'
    if args.worker:
        report['scope'] = 'Original spawned job worker: ten wake-master TaskExe completions, dispatched/done flags, resumed master, result42 and empty rings; no exact heap, worker fault or popup UI coverage'
    if args.shared_core:
        report['scope'] = 'Current shared JobResScan body compiled as JRScanOracle in original TempleOS; synthetic queue contract and caller heap, not boot-bound behavior or actual TaskExe execution'
    try:
        source = fixture.read_text()
        if args.shared_core:
            source = shared.read_text().replace('Bool JobResScan(', 'Bool JRScanOracle(', 1) + source.replace('JobResScan(', 'JRScanOracle(')
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
