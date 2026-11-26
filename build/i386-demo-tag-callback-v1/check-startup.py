"""Run the welcome and startup-command oracle on a 486 guest with KVM."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('image', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    args.out.mkdir()
    working = args.out / 'working.img'
    shutil.copyfile(args.image, working)
    commands = runpy.run_path('tools/test-i386-startup-memory.py')['COMMANDS']
    run_input = runpy.run_path('tools/i386-kernel-input.py')['run_input']
    digest = hashlib.sha256(args.image.read_bytes()).hexdigest()
    report = dict(input_sha256=digest, cpu='486,-fpu', accel='kvm', ram_mib=8)
    try:
        report['behavior'] = run_input(
            working, args.out / 'qemu', ram_mib=8, snapshot=False,
            cpu='486,-fpu', accel='kvm', qmp_stdio=True, welcome=True,
            managed_pointer=True, startup_timeout=300,
            startup_check=dict(status='ok', answers=[], commands=commands,
                               pause_window_manager=False,
                               rejection_prefixes=('INPUT REJECT ',)))
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['inputs_unchanged'] = hashlib.sha256(args.image.read_bytes()).hexdigest() == digest
        (args.out / 'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
