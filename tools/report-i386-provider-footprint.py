#!/usr/bin/env python3
"""Report four core provider load spans and observed pressure from qualified boot logs."""
import argparse
import hashlib
import json
from pathlib import Path

LABELS = ('RUNTIME', 'FILES', 'MEMORY', 'CONSOLE')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def inspect(directory):
    directory = directory.resolve()
    result_path, log_path = directory/'result.json', directory/'debug.log'
    pins = {str(p): sha(p) for p in (result_path, log_path)}
    result = json.loads(result_path.read_text())
    if (result.get('status') != 'pass' or result.get('ram_mib') != 8 or
            result.get('qualification') != 'interactive' or result.get('diagnostics') is not False or
            result.get('interactive_budget_pass') is not True or result.get('build_provider_loads') != 0):
        raise ValueError('Requires qualified normal 8 MiB startup: '+str(directory))
    behavior = result.get('behavior', {})
    if (behavior.get('result') != 'pass' or behavior.get('cpu') != '486,-fpu' or
            behavior.get('ram_mib') != 8 or behavior.get('boot_mode') != 'interactive' or
            behavior.get('commands') != 9 or behavior.get('setup_commands') != 0 or
            behavior.get('window_manager_pause_requested') is not False or
            not 0 <= behavior.get('startup_seconds', -1) <= 60):
        raise ValueError('Startup behavior does not establish the minimal-profile gate')
    for name, digest in result['input_sha256'].items():
        if sha(Path(name)) != digest:
            raise ValueError('Startup input changed: '+name)
    providers, failures, arena = {}, [], None
    lines = log_path.read_text().splitlines()
    if lines.count('COMMAND OK') != 9:
        raise ValueError('Expected nine successful commands in the actual boot log')
    for line in lines:
        fields = line.split()
        if not fields:
            continue
        if fields[0] in LABELS and len(fields) >= 4:
            if fields[0] in providers:
                raise ValueError('Duplicate provider load: '+fields[0])
            address, size, span = (int(value, 16) for value in fields[1:4])
            if not address or size <= 8 or span < size:
                raise ValueError('Invalid provider load record')
            providers[fields[0]] = dict(image_bytes=size, retained_span_bytes=span)
        elif fields[0] == 'ARENA' and len(fields) == 3:
            arena = dict(base=int(fields[1], 16), bytes=int(fields[2], 16))
        elif fields[:2] == ['HEAP', 'EXHAUSTED']:
            if len(fields) != 7:
                raise ValueError('Unsupported heap failure trace')
            request, used, capacity, largest, allocations = (int(v, 16) for v in fields[2:])
            failures.append(dict(request_bytes=request, raw_used_bytes=used,
                                 raw_capacity_bytes=capacity, largest_free_payload_bytes=largest,
                                 raw_unallocated_span_bytes=capacity-used, allocations=allocations))
        elif line.startswith(('INPUT REJECT ', 'WINMGR window exception ', 'KERNEL FATAL ')):
            raise ValueError('Rejected/error boot cannot qualify footprint report')
    if set(providers) != set(LABELS) or arena is None:
        raise ValueError('Missing core provider/arena records')
    if any(sha(Path(p)) != digest for p, digest in pins.items()):
        raise ValueError('Footprint evidence changed during inspection')
    return dict(directory=str(directory), input_sha256=pins,
                startup_input_sha256=result['input_sha256'], arena=arena, providers=providers,
                four_provider_retained_span_bytes=sum(p['retained_span_bytes'] for p in providers.values()),
                startup_seconds=result['behavior']['startup_seconds'],
                commands=result['behavior']['commands'], allocation_failure_observations=failures,
                allocation_failure_observation_count=len(failures))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('current', type=Path)
    parser.add_argument('--baseline', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--max-console-span', type=lambda value: int(value, 0),
                        help='Optional byte budget for the logged Console provider load span')
    parser.add_argument('--require-no-allocation-failures', action='store_true',
                        help='Fail if the normal boot log contains any raw-heap exhaustion observations')
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output path')
    report = dict(result='pass', scope='Four logged core provider load spans; not total OS memory, minimum RAM, peak usage or all allocation outcomes',
                  tool_sha256=sha(Path(__file__)), current=inspect(args.current))
    if args.baseline:
        report['baseline'] = inspect(args.baseline)
        report['provider_span_delta_bytes'] = {
            name: report['current']['providers'][name]['retained_span_bytes']-
                  report['baseline']['providers'][name]['retained_span_bytes'] for name in LABELS}
    if args.max_console_span is not None:
        if args.max_console_span <= 0:
            parser.error('Console span budget must be positive')
        actual = report['current']['providers']['CONSOLE']['retained_span_bytes']
        report['console_budget'] = dict(limit_bytes=args.max_console_span, actual_bytes=actual,
                                       pass_budget=actual <= args.max_console_span)
        if actual > args.max_console_span:
            report['result'] = 'fail'
    if args.require_no_allocation_failures:
        count = report['current']['allocation_failure_observation_count']
        report['allocation_pressure_gate'] = dict(required_count=0, observed_count=count,
                                                 pass_gate=count == 0)
        if count:
            report['result'] = 'fail'
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(dict(result=report['result'], current=report['current']['providers'],
                         pressure_observations=report['current']['allocation_failure_observation_count'],
                         delta=report.get('provider_span_delta_bytes'),
                         console_budget=report.get('console_budget'),
                         allocation_pressure_gate=report.get('allocation_pressure_gate')), indent=2))
    if report['result'] != 'pass':
        raise SystemExit(1)

if __name__ == '__main__':
    main()
