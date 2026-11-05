#!/usr/bin/env python3
"""Run an isolated build/test guest and collect debugcon reports, exports, and display."""
import argparse
import json
import hashlib
from pathlib import Path
import runpy
import socket
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('iso', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--timeout', type=float, default=180)
    parser.add_argument('--i386-disk', action='store_true', help='Run a protected-mode test disk with VGA and 8 MiB RAM')
    parser.add_argument('--ram-mib', type=int, choices=(8,16), default=8,
                        help='RAM for an i386 disk run; full diagnostics require 16 MiB')
    parser.add_argument('--target-disk', type=Path, help='Attach a separate IDE target disk')
    parser.add_argument('--qmp-stdio', action='store_true',
                        help='Control QEMU over stdio when Unix sockets are unavailable')
    parser.add_argument('--native-welcome', action='store_true',
                        help='After native startup DONE, require the complete welcome raster and prompt')
    args = parser.parse_args()
    if args.native_welcome and not args.i386_disk:
        parser.error('--native-welcome requires --i386-disk')
    if args.target_disk and args.target_disk.resolve()==args.iso.resolve():
        parser.error('--target-disk must be distinct from the boot image')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    log = out / 'debug.log'
    qmp_dir = None if args.qmp_stdio else Path(tempfile.mkdtemp(prefix='templeos-qmp-'))
    qmp_path = qmp_dir / 'qmp.sock' if qmp_dir else None
    qmp_arg = 'stdio' if args.qmp_stdio else f'unix:{qmp_path},server=on,wait=off'
    log.write_text('')
    cmd = ['qemu-system-x86_64', '-machine', 'pc', '-accel', 'tcg',
           '-cpu', 'max', '-m', '2048', '-smp', '2', '-nic', 'none',
           '-drive', f'file={args.iso.resolve()},format=raw,media=cdrom,if=ide,index=2',
           '-boot', 'd', '-display', 'none', '-no-reboot',
           '-debugcon', f'file:{log}', '-global', 'isa-debugcon.iobase=0xe9',
           '-qmp', qmp_arg]
    if args.i386_disk:
        cmd = ['qemu-system-i386', '-machine', 'pc', '-accel', 'tcg',
               '-cpu', '486', '-m', str(args.ram_mib), '-nic', 'none',
               '-drive', f'file={args.iso.resolve()},format=raw,if=ide',
               '-display', 'none', '-no-reboot', '-debugcon', f'file:{log}',
               '-qmp', qmp_arg]
        if args.target_disk:
            cmd += ['-drive',f'file={args.target_disk.resolve()},format=raw,if=ide,index=2']
    elif args.target_disk:
        cmd += ['-drive',f'file={args.target_disk.resolve()},format=raw,if=ide,index=0']
    (out / 'command.json').write_text(json.dumps(cmd, indent=2)+'\n')
    sock = None if args.qmp_stdio else socket.socket(socket.AF_UNIX)
    with (out / 'qemu.log').open('w') as stderr:
        proc = subprocess.Popen(cmd, stderr=stderr,
                                stdin=subprocess.PIPE if args.qmp_stdio else None,
                                stdout=subprocess.PIPE if args.qmp_stdio else None,
                                bufsize=0)
        try:
            deadline = time.monotonic()+args.timeout
            if args.qmp_stdio:
                class QMPStream:
                    def readline(self): return proc.stdout.readline()
                    def write(self, data): return proc.stdin.write(data)
                stream = QMPStream()
            else:
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
            ready_deadline=None
            if args.native_welcome:
                from PIL import Image
                helper=Path(__file__).resolve().with_name('i386-kernel-input.py')
                variants=runpy.run_path(str(helper))['startup_console_variants']()
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
                        if args.native_welcome:
                            if line!='DONE native kernel startup\n':
                                raise ValueError('Unexpected completion before native welcome')
                            ready_deadline=time.monotonic()+30
                        else:
                            command('screendump', filename=str(out / 'screen.ppm'))
                            return
                if ready_deadline is not None:
                    command('screendump', filename=str(out / 'screen.ppm'))
                    with Image.open(out/'screen.ppm') as screen:
                        pixels=screen.convert('RGB').tobytes()
                        variant=next((name for name,expected in variants.items()
                                      if screen.size==(640,480) and pixels==expected),None)
                    if variant is not None:
                        (out/'screen-oracle.json').write_text(json.dumps(dict(result='pass',
                            variant=variant,compared_pixels=640*480,
                            raster_sha256=hashlib.sha256(pixels).hexdigest(),
                            scope='Complete welcome frame and prompt after startup; only exact cursor on/off variants'),indent=2)+'\n')
                        return
                    if time.monotonic()>ready_deadline:
                        raise TimeoutError('Native startup did not present the complete welcome raster')
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
            if sock is not None: sock.close()
            if qmp_path is not None: qmp_path.unlink(missing_ok=True)
            if qmp_dir is not None: qmp_dir.rmdir()


if __name__ == '__main__':
    main()
