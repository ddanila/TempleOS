#!/usr/bin/env python3
"""Run an isolated x86-64 build/test guest and collect debugcon reports/exports."""
import argparse
import json
from pathlib import Path
import socket
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('iso', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--timeout', type=float, default=180)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    log = out / 'debug.log'
    qmp_path = out / 'qmp.sock'
    qmp_path.unlink(missing_ok=True)
    log.write_text('')
    cmd = ['qemu-system-x86_64', '-machine', 'pc', '-accel', 'tcg',
           '-cpu', 'max', '-m', '2048', '-smp', '2', '-nic', 'none',
           '-drive', f'file={args.iso.resolve()},format=raw,media=cdrom,if=ide,index=2',
           '-boot', 'd', '-display', 'none', '-no-reboot',
           '-debugcon', f'file:{log}', '-global', 'isa-debugcon.iobase=0xe9',
           '-qmp', f'unix:{qmp_path},server=on,wait=off']
    (out / 'command.json').write_text(json.dumps(cmd, indent=2)+'\n')
    sock = socket.socket(socket.AF_UNIX)
    with (out / 'qemu.log').open('w') as stderr:
        proc = subprocess.Popen(cmd, stderr=stderr)
        try:
            deadline = time.monotonic()+args.timeout
            while not qmp_path.exists():
                if proc.poll() is not None or time.monotonic()>deadline:
                    raise RuntimeError('QEMU failed to open QMP')
                time.sleep(.1)
            sock.connect(str(qmp_path))
            sock.settimeout(15)
            stream = sock.makefile('rwb', buffering=0)
            json.loads(stream.readline())

            def command(name, **arguments):
                stream.write((json.dumps({'execute': name, 'arguments': arguments})+'\n').encode())
                while True:
                    response = json.loads(stream.readline())
                    if 'error' in response:
                        raise RuntimeError(response)
                    if 'return' in response:
                        return response['return']

            command('qmp_capabilities')
            consumed = 0
            while time.monotonic()<deadline and proc.poll() is None:
                lines = log.read_text(errors='replace').splitlines(keepends=True)
                for line in lines[consumed:]:
                    if not line.endswith('\n'):
                        break
                    consumed += 1
                    print(line.rstrip(), flush=True)
                    if line.startswith('EXPORT '):
                        _, name, address, size = line.split()
                        if Path(name).name != name:
                            raise ValueError('Invalid export name')
                        command('pmemsave', val=int(address,16), size=int(size,16),
                                filename=str(out / name))
                    if line.startswith('FAIL '):
                        command('screendump', filename=str(out / 'screen.ppm'))
                        raise RuntimeError(line.rstrip())
                    if line.startswith('DONE '):
                        command('screendump', filename=str(out / 'screen.ppm'))
                        return
                time.sleep(.2)
            command('screendump', filename=str(out / 'screen.ppm'))
            raise TimeoutError(f'Guest did not finish; inspect {out}')
        finally:
            proc.terminate()
            try:
                proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
            sock.close()
            qmp_path.unlink(missing_ok=True)


if __name__ == '__main__':
    main()
