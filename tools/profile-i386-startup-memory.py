#!/usr/bin/env python3
"""Capture a stopped 8 MiB startup heap and resolve allocation-failure callers."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def analyze(disk, log, memory):
    read = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents']
    names = ('Kernel', 'CompilerRuntime', 'MemoryRuntime', 'FileRuntime', 'ConsoleRuntime')
    paths = {f'/Modules/I386/{name}.t32m' for name in names}
    modules = read(disk, paths)
    image = disk.read_bytes()
    if image[528:532] != b'E32B':
        raise ValueError('Expected extended boot metadata')
    base = struct.unpack_from('<I', image, 540)[0]+8
    symbols = runpy.run_path(str(ROOT/'tools/profile-i386-boot.py'))['symbols']
    ranges = []
    for prefix, name in [('KERNEL', 'Kernel'), ('RUNTIME', 'CompilerRuntime'),
                         ('MEMORY', 'MemoryRuntime'), ('FILES', 'FileRuntime'),
                         ('CONSOLE', 'ConsoleRuntime')]:
        module = modules[f'/Modules/I386/{name}.t32m']
        match = re.search(r'^'+prefix+r' ([0-9A-Fa-f]+) ', log, re.M)
        address = base if name == 'Kernel' else int(match[1], 16)+8 if match else None
        if address is not None:
            ranges.extend((lo, hi, name+':'+label) for lo, hi, label in symbols(module, address))
    module = modules['/Modules/I386/Kernel.t32m']
    size, count, records = struct.unpack_from('<III', module, 16)
    data_exports = {}
    for index in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records+16*index)
        if kind == 3:
            data_exports[module[name:name+length].decode()] = base+offset
    heap_address = data_exports['kernel_heap']
    arena, capacity, used, peak, allocations, signature = struct.unpack_from('<6I', memory, heap_address)
    if signature != 0x48323349 or arena+capacity > len(memory):
        raise ValueError('Invalid captured heap control')
    blocks, histogram = [], Counter()
    offset = live_bytes = live_count = 0
    while offset < capacity:
        span, requested, tag, reserved = struct.unpack_from('<4I', memory, arena+offset)
        if span < 24 or span & 7 or offset+span > capacity or tag not in (0x46523349, 0x55523349):
            raise ValueError('Invalid captured heap block')
        live = tag == 0x55523349
        if live:
            if requested > span-16:
                raise ValueError('Captured allocation exceeds span')
            live_bytes += span
            live_count += 1
            histogram[requested] += 1
        blocks.append(dict(address=arena+offset, span=span, requested=requested, live=live))
        offset += span
    if (live_bytes, live_count) != (used, allocations):
        raise ValueError('Captured allocation totals do not match heap control')
    callers = []
    for match in re.finditer(r'^HEAP FAILURE CALLERS([^\n]+)', log, re.M):
        callers.append([dict(return_address=int(word, 16),
                             symbols=[label for lo, hi, label in ranges if lo <= int(word, 16)-1 < hi])
                        for word in match[1].split()])
    return dict(heap_address=heap_address, arena=arena, capacity=capacity, used=used, peak=peak,
                allocations=allocations, largest_free=max((b['span']-16 for b in blocks if not b['live']), default=0),
                requested_bytes=sum(size*count for size, count in histogram.items()),
                allocation_sizes=[dict(bytes=size, count=count, requested_total=size*count)
                                  for size, count in sorted(histogram.items(), key=lambda pair: pair[0]*pair[1], reverse=True)],
                failure_callers=callers, blocks=blocks,
                module_sha256={name:hashlib.sha256(data).hexdigest() for name, data in modules.items()})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--timeout', type=float, default=180)
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    pins = {str(p):sha(p) for p in (disk, Path(__file__).resolve(), ROOT/'tools/profile-i386-boot.py', ROOT/'tools/build-i386-kernel.py')}
    log_path = out/'debug.log'
    cmd = ['qemu-system-i386', '-machine', 'pc', '-accel', 'tcg', '-cpu', '486,-fpu', '-m', '8',
           '-nic', 'none', '-snapshot', '-drive', f'file={disk},format=raw,if=ide',
           '-display', 'none', '-no-reboot', '-debugcon', f'file:{log_path}', '-qmp', 'stdio']
    (out/'command.json').write_text(json.dumps(cmd, indent=2)+'\n')
    report = dict(result='running', scope='Stopped startup heap snapshot; not interaction or timing qualification', input_sha256=pins)
    with (out/'qemu.log').open('w') as stderr:
        proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=stderr, bufsize=0)
        try:
            json.loads(proc.stdout.readline())
            def command(name, **arguments):
                proc.stdin.write((json.dumps(dict(execute=name, arguments=arguments))+'\n').encode())
                while True:
                    line = proc.stdout.readline()
                    if not line:
                        raise RuntimeError('QMP disconnected')
                    response = json.loads(line)
                    if 'error' in response:
                        raise RuntimeError(response['error'])
                    if 'return' in response:
                        return response['return']
            command('qmp_capabilities')
            deadline = time.monotonic()+args.timeout
            while time.monotonic() < deadline:
                log = log_path.read_text() if log_path.exists() else ''
                if 'FAIL native kernel' in log or 'DONE native kernel startup\n' in log:
                    break
                if proc.poll() is not None:
                    raise RuntimeError('Guest exited before observation')
                time.sleep(.1)
            else:
                raise TimeoutError('Startup observation timed out')
            command('stop')
            dump = out/'memory.bin'
            command('pmemsave', val=0, size=8*1024*1024, filename=str(dump))
            log = log_path.read_text()
            report.update(analyze(disk, log, dump.read_bytes()))
            report.update(result='captured', boot_failed='FAIL native kernel' in log, memory_sha256=sha(dump))
            command('quit')
            proc.wait(timeout=10)
        except Exception as exc:
            report.update(result='fail', error=str(exc))
            raise
        finally:
            if proc.poll() is None:
                proc.kill()
                proc.wait()
            report['inputs_unchanged'] = all(sha(Path(p)) == h for p, h in pins.items())
            (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if not report['inputs_unchanged']:
        raise ValueError('Observation inputs changed')
    print(json.dumps({k:report[k] for k in ('result', 'boot_failed', 'used', 'capacity', 'largest_free', 'failure_callers')}))


if __name__ == '__main__':
    main()
