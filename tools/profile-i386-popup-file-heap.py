#!/usr/bin/env python3
"""Capture the 8 MiB heap when PopUpFile task allocation fails."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-popup-file/Contract.HC'
    source = ROOT/'tests/guest/i386-popup-file/PFCase.HC'
    helper = ROOT/'tools/test-i386-timeclock-welcome.py'
    profiler = ROOT/'tools/profile-i386-startup-memory.py'
    inputs = [disk, fixture, source, helper, profiler, Path(__file__).resolve(),
              ROOT/'tools/profile-i386-boot.py', ROOT/'tools/build-i386-kernel.py',
              ROOT/'tools/package-i386-native-image.py']
    pins = {str(p): sha(p) for p in inputs}
    out.mkdir(parents=True)
    report = {'result': 'running', 'input_sha256': pins,
              'scope': 'QMP-stopped 8 MiB heap after PopUpFile allocation failure; diagnostic, not startup timing or desktop qualification'}
    proc = None
    try:
        image = out/'working.img'
        report['packaging'] = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
            disk, image, additions={'/Probe/PopUpFileContract.HC': fixture.read_bytes(),
                                    '/Probe/PFCase.HC': source.read_bytes()})
        keys = runpy.run_path(str(helper)); plain, shifted = keys['PLAIN'], keys['SHIFTED']
        log = out/'debug.log'
        command = ['qemu-system-i386', '-machine', 'pc', '-accel', 'tcg', '-cpu', '486,-fpu',
                   '-m', '8', '-nic', 'none', '-drive', f'file={image},format=raw,if=ide',
                   '-display', 'none', '-no-reboot', '-debugcon', f'file:{log}', '-qmp', 'stdio']
        (out/'command.json').write_text(json.dumps(command, indent=2)+'\n')
        with (out/'qemu.log').open('w') as stderr:
            proc = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                    stderr=stderr, text=True, bufsize=1)
            if not json.loads(proc.stdout.readline()):
                raise RuntimeError('Missing QMP greeting')
            def qmp(name, **arguments):
                proc.stdin.write(json.dumps({'execute': name, 'arguments': arguments})+'\n')
                proc.stdin.flush()
                while True:
                    line = proc.stdout.readline()
                    if not line:
                        raise RuntimeError('QMP disconnected')
                    reply = json.loads(line)
                    if 'error' in reply:
                        raise RuntimeError(str(reply['error']))
                    if 'return' in reply:
                        return reply['return']
            def wait_for(predicate, timeout=240):
                deadline = time.monotonic()+timeout
                while time.monotonic()<deadline and proc.poll() is None:
                    text = log.read_text(errors='replace') if log.exists() else ''
                    if predicate(text):
                        return text
                    time.sleep(.02)
                raise TimeoutError('Guest log wait failed')
            def key(name, down):
                qmp('input-send-event', events=[{'type': 'key', 'data': {
                    'down': down, 'key': {'type': 'qcode', 'data': name}}}])
            def press(name):
                key(name, True); key(name, False)
            def send(text):
                for ch in text:
                    shift = ch.isupper() or ch in shifted
                    if shift:
                        key('shift', True)
                    press(plain.get(ch, ch.lower()))
                    if shift:
                        key('shift', False)
                    time.sleep(.3)
                press('ret')
            qmp('qmp_capabilities')
            wait_for(lambda s: 'DONE native kernel startup\n' in s)
            time.sleep(5)
            for text in ['U0 TestPauseWM(){if(sys_winmgr_task!=adam_task)Suspend(sys_winmgr_task,TRUE);}TestPauseWM;',
                         '#include "C:/Probe/PopUpFileContract.HC"']:
                before = len(log.read_text())
                send(text)
                result = wait_for(lambda s: 'COMMAND OK\n' in s[before:] or 'INPUT REJECT ' in s[before:])
                if 'INPUT REJECT ' in result[before:] or 'INPUT LINE '+text+'\n' not in result[before:]:
                    raise ValueError('Setup command rejected or changed')
                time.sleep(5)
            before = len(log.read_text())
            send('PopUpFileContract;')
            result = wait_for(lambda s: 'HEAP EXHAUSTED ' in s[before:] or 'COMMAND OK\n' in s[before:])
            if 'HEAP EXHAUSTED ' not in result[before:]:
                raise ValueError('Expected allocation failure was not observed')
            qmp('stop')
            registers = qmp('human-monitor-command', **{'command-line': 'info registers'})
            dump = out/'memory.bin'
            qmp('pmemsave', val=0, size=8*1024*1024, filename=str(dump))
            log_text = log.read_text(errors='replace')
            analysis = runpy.run_path(str(profiler))['analyze'](image, log_text, dump.read_bytes(), registers)
            report.update(result='captured', registers=registers, memory_sha256=sha(dump), **analysis)
            qmp('quit'); proc.wait(timeout=15)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        if proc and proc.poll() is None:
            proc.kill(); proc.wait()
        report['inputs_unchanged'] = all(sha(Path(path)) == digest for path, digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'captured':
        raise ValueError(report.get('error'))


if __name__ == '__main__':
    main()
