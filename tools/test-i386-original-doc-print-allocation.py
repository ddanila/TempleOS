#!/usr/bin/env python3
"""Check the selected DocPrint allocation-failure contract in original TempleOS."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--allocator', choices=('MAlloc', 'CAlloc'), default='MAlloc')
    parser.add_argument('--fail-after', type=int, default=2)
    args = parser.parse_args()
    if args.out.exists() or args.fail_after < 1:
        parser.error('Use a fresh directory and positive fault index')
    out = args.out.resolve(); overlay = out/'overlay'; overlay.mkdir(parents=True)
    driver = ROOT/'tools/test-i386-doc-print-allocation.py'
    files = [Path(__file__).resolve(), driver] + [ROOT/p for p in (
        'Adam/DolDoc/DocPutS.HC', 'Adam/DolDoc/DocPutSCore.HC',
        'Kernel/StrPrintCore.HC', 'tools/build-iso.py', 'tools/guest-run.py')]
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in files}
    report = dict(result='running', input_sha256=pins, allocator=args.allocator,
                  fail_after=args.fail_after, scope='Selected original DocPrint allocation failure: exception/count, allocator bytes, lock, signature and task heap; allocation order may differ from native')
    try:
        commands = runpy.run_path(str(driver))['commands'](args.fail_after, args.allocator)
        source = '\n'.join(c for c,a in commands[:-2]) + '\n'
        source += 'U0 DFReport(U8 *s){while(*s)OutU8(0xE9,*s++);}\n'
        source += 'I64 df_mask=DFRun;U8 *df_line=MStrPrint("OBS DocPrint fault mask %d delta %d calls %d\\n",df_mask,df_delta,df_calls);DFReport(df_line);Free(df_line);\n'
        source += 'U8 *df_trace=MStrPrint("TRACE allocation sizes %d %d %d\\n",df_sizes[0],df_sizes[1],df_sizes[2]);DFReport(df_trace);Free(df_trace);\n'
        source += 'DFReport("DONE DocPrint fault\\n");\n'
        (overlay/'Once.HC').write_text(source)
        iso = out/'original.iso'
        subprocess.run([sys.executable, str(ROOT/'tools/build-iso.py'), '--overlay', str(ROOT/'build/rebuild-test/overlay'), '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(iso), '--out', str(out/'behavior'), '--timeout', '90', '--qmp-stdio'], cwd=ROOT, check=True)
        log = (out/'behavior/debug.log').read_text()
        report['observations'] = [line for line in log.splitlines() if line.startswith('OBS DocPrint fault')]
        if f'OBS DocPrint fault mask 63 delta 0 calls {args.fail_after}\n' not in log or 'DONE DocPrint fault\n' not in log:
            raise ValueError('Original allocation-failure recovery contract did not pass')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error)); raise
    finally:
        changed = [p for p,h in pins.items() if sha(Path(p)) != h]
        if changed: report.update(result='fail', changed_inputs=changed)
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass': raise RuntimeError('Pinned fault inputs changed')

if __name__ == '__main__':
    main()
