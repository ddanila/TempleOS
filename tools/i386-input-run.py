#!/usr/bin/env python3
"""Drive the native input fixture through QEMU's emulated keyboard device."""
import argparse
import json
from pathlib import Path
import socket
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    log, qmp = out/'runner.log', out/'input-qmp.sock'
    log.write_text('')
    qmp.unlink(missing_ok=True)
    sequence = [('a', True), ('a', False), ('ret', True), ('ret', False),
                ('up', True), ('up', False), ('print', True), ('print', False),
                ('pause', True)]
    cmd = ['qemu-system-i386', '-machine', 'pc', '-accel', 'tcg', '-cpu', '486',
           '-m', '8', '-nic', 'none', '-drive', f'file={args.disk.resolve()},format=raw,if=ide',
           '-display', 'none', '-debugcon', f'file:{log}',
           '-device', 'isa-debug-exit,iobase=0xf4,iosize=4', '-no-reboot',
           '-qmp', f'unix:{qmp},server=on,wait=off']
    (out/'input-command.json').write_text(json.dumps(cmd, indent=2)+'\n')
    sock = socket.socket(socket.AF_UNIX)
    with (out/'input-qemu.log').open('w') as stderr:
        proc = subprocess.Popen(cmd, stderr=stderr)
        try:
            deadline = time.monotonic()+30
            while not qmp.exists():
                if proc.poll() is not None or time.monotonic()>deadline:
                    raise RuntimeError('Input guest failed to open QMP')
                time.sleep(.05)
            sock.connect(str(qmp))
            sock.settimeout(5)
            stream = sock.makefile('rwb', buffering=0)
            json.loads(stream.readline())

            def command(name, **arguments):
                stream.write((json.dumps({'execute': name, 'arguments': arguments})+'\n').encode())
                while True:
                    response = json.loads(stream.readline())
                    if 'error' in response:
                        raise RuntimeError(response)
                    if 'return' in response:
                        return

            command('qmp_capabilities')
            consumed = sent = 0
            while proc.poll() is None and time.monotonic()<deadline:
                for line in log.read_text().splitlines(keepends=True)[consumed:]:
                    if not line.endswith('\n'):
                        break
                    consumed += 1
                    if line.startswith('KEY '):
                        if sent>=len(sequence) or line!=f'KEY {sent}\n':
                            raise RuntimeError(f'Unexpected key request: {line}')
                        key, down = sequence[sent]
                        command('input-send-event', events=[{'type':'key', 'data':{
                            'down':down, 'key':{'type':'qcode', 'data':key}}}])
                        sent += 1
                time.sleep(.02)
            expected = ''.join(f'KEY {i}\n' for i in range(len(sequence)))+'PASS i386 functions\n'
            if proc.poll()!=33 or sent!=len(sequence) or log.read_text()!=expected:
                raise RuntimeError(f'Input guest failed or timed out: {log.read_text()}')
            (out/'input-events.json').write_text(json.dumps(sequence, indent=2)+'\n')
        finally:
            if proc.poll() is None:
                proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
            sock.close()
            qmp.unlink(missing_ok=True)


if __name__ == '__main__':
    main()
