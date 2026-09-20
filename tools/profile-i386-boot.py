#!/usr/bin/env python3
"""Sample native boot PCs through QMP; pauses make elapsed time unsuitable for benchmarks."""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import random
import re
import socket
import struct
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def symbols(module, base):
    data = module.read_bytes()
    size, count, records = struct.unpack_from('<III', data, 16)
    starts, boundaries = [], {size}
    for index in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', data, records + 16 * index)
        if kind == 1:
            starts.append((offset, data[name:name + length].decode('ascii')))
            boundaries.add(offset)
        elif kind == 4:
            boundaries.add(offset)
    ends = sorted(boundaries)
    return [(base + start, base + next(end for end in ends if end > start), name)
            for start, name in starts]


def phase(log):
    if 'STARTUP source begin\n' in log:
        return 'startup_source'
    if 'PUBLIC HEADERS ok\n' in log:
        return 'after_headers'
    if 'PUBLIC HEADERS begin\n' in log:
        return 'public_headers'
    return 'foundation'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, default=ROOT / 'build/i386-boot-profile')
    parser.add_argument('--interval', type=float, default=.1)
    parser.add_argument('--timeout', type=float, default=180)
    args = parser.parse_args()
    if args.interval <= 0 or args.timeout <= 0:
        parser.error('interval and timeout must be positive')
    build = ROOT / 'build/i386-kernel'
    result = json.loads((build / 'result.json').read_text())
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    disk = build / 'kernel.img'
    if sha(disk) != result['disk_sha256']:
        raise ValueError('Disk differs from build evidence')
    for name, digest in result['modules'].items():
        if sha(build / 'exports' / f'{name}.t32m') != digest:
            raise ValueError(f'Module differs from build evidence: {name}')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    log_path, qmp = out / 'debug.log', out / 'qmp.sock'
    qmp.unlink(missing_ok=True)
    log_path.write_text('')
    cmd = ['qemu-system-i386', '-machine', 'pc', '-accel', 'tcg', '-cpu', '486',
           '-m', '8', '-nic', 'none', '-snapshot',
           '-drive', f'file={disk},format=raw,if=ide', '-display', 'none', '-no-reboot',
           '-debugcon', f'file:{log_path}', '-qmp', f'unix:{qmp},server=on,wait=off']
    (out / 'command.json').write_text(json.dumps(cmd, indent=2) + '\n')
    ranges = {'Kernel': symbols(build / 'exports/Kernel.t32m', 0x11008)}
    samples = []
    rng = random.Random(386)
    start = time.monotonic()
    with (out / 'qemu.log').open('w') as stderr, socket.socket(socket.AF_UNIX) as sock:
        proc = subprocess.Popen(cmd, stderr=stderr)
        try:
            deadline = start + args.timeout
            while not qmp.exists():
                if proc.poll() is not None or time.monotonic() >= deadline:
                    raise RuntimeError('Guest failed to start')
                time.sleep(.05)
            sock.connect(str(qmp))
            sock.settimeout(10)
            stream = sock.makefile('rwb', buffering=0)
            json.loads(stream.readline())

            def command(name, **arguments):
                stream.write((json.dumps(dict(execute=name, arguments=arguments)) + '\n').encode())
                while True:
                    line = stream.readline()
                    if not line:
                        raise RuntimeError('QMP disconnected')
                    response = json.loads(line)
                    if 'error' in response:
                        raise RuntimeError(response['error'])
                    if 'return' in response:
                        return response['return']

            command('qmp_capabilities')
            while time.monotonic() < deadline:
                if proc.poll() is not None:
                    raise RuntimeError('Guest exited before prompt')
                command('stop')
                log = log_path.read_text()
                if 'DONE native kernel startup\n' in log:
                    break
                if 'FAIL native kernel' in log or 'PUBLIC HEADERS error' in log:
                    raise RuntimeError('Guest boot failed')
                for prefix, module in [('RUNTIME', 'CompilerRuntime'), ('FILES', 'FileRuntime'),
                                       ('MEMORY', 'MemoryRuntime'), ('CONSOLE', 'ConsoleRuntime')]:
                    if module not in ranges:
                        match = re.search(r'^' + prefix + r' ([0-9A-Fa-f]+) ', log, re.M)
                        if match:
                            ranges[module] = symbols(build / 'exports' / f'{module}.t32m',
                                                     int(match[1], 16) + 8)
                registers = command('human-monitor-command', **{'command-line': 'info registers'})
                match = re.search(r'\bEIP=([0-9A-Fa-f]+)', registers)
                if not match:
                    raise ValueError('Missing EIP in QEMU registers')
                pc = int(match[1], 16)
                def symbol_at(address):
                    for module, spans in ranges.items():
                        found = next((name for lo, hi, name in spans if lo <= address < hi), None)
                        if found:
                            return module + ':' + found
                    return 'unmapped'

                label = symbol_at(pc)
                callers = []
                match = re.search(r'\bEBP=([0-9A-Fa-f]+)', registers)
                frame = int(match[1], 16) if match else 0
                #Generated code uses EBP frames. Keep the raw PCs, bound reads to
                #installed RAM, and reject cycles; prologue/epilogue samples may
                #still have an incomplete chain, so callers are statistical hints.
                for depth in range(5):
                    if not 0x1000 <= frame <= 8 * 1024 * 1024 - 8 or frame & 3:
                        break
                    memory = command('human-monitor-command',
                                     **{'command-line': f'xp /2wx 0x{frame:x}'})
                    words = re.findall(r'0x([0-9A-Fa-f]{8})\b', memory)
                    if len(words) != 2:
                        break
                    parent, address = (int(word, 16) for word in words)
                    callers.append(dict(pc=address, symbol=symbol_at(address - 1)))
                    if parent <= frame:
                        break
                    frame = parent
                samples.append(dict(seconds=time.monotonic() - start, phase=phase(log),
                                    pc=pc, symbol=label, callers=callers))
                command('cont')
                time.sleep(args.interval * rng.uniform(.5, 1.5))
            else:
                raise TimeoutError('Guest did not reach its prompt')
            if 'STARTUP source ok\n' not in log:
                raise ValueError('Startup did not succeed')
            command('quit')
            proc.wait(timeout=10)
        finally:
            if proc.poll() is None:
                proc.kill()
                proc.wait()
    counts = defaultdict(Counter)
    stacks = defaultdict(Counter)
    for sample in samples:
        counts[sample['phase']][sample['symbol']] += 1
        stack = ' <- '.join([sample['symbol']] + [c['symbol'] for c in sample['callers']])
        stacks[sample['phase']][stack] += 1
    report = dict(scope='Statistical PC samples of normal QEMU/486 boot; not call counts or an elapsed-time benchmark',
                  disk_sha256=result['disk_sha256'], source_sha256=result['source_sha256'],
                  profiler_sha256=sha(Path(__file__)), interval_seconds=args.interval,
                  samples=len(samples), phases={name:dict(counter.most_common()) for name,counter in counts.items()},
                  stacks={name:dict(counter.most_common()) for name,counter in stacks.items()})
    (out / 'samples.json').write_text(json.dumps(samples, indent=2) + '\n')
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    for name, counter in counts.items():
        print(name, 'samples:', counter.total(), 'top:', counter.most_common(5))


if __name__ == '__main__':
    main()
