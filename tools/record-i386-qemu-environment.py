#!/usr/bin/env python3
"""Record a QEMU boot profile and the firmware actually opened, with CPUs paused."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import re
import shutil
import subprocess


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def profile(argv):
    selected = []
    values = {'-machine', '-accel', '-cpu', '-m', '-nic', '-drive', '-bios', '-L', '-vga'}
    ignored = {'-display', '-debugcon', '-qmp', '-monitor'}
    switches = {'-snapshot', '-no-reboot', '-no-shutdown'}
    disks = []
    index = 1
    while index < len(argv):
        flag = argv[index]
        if flag in values or flag in ignored:
            if index + 1 >= len(argv):
                raise ValueError('Missing value for ' + flag)
            value = argv[index + 1]
            if flag in values:
                if flag == '-machine' and 'audiodev=' in value:
                    raise ValueError('Use the ordinary boot command without audio capture')
                if flag == '-drive':
                    options = dict(part.split('=', 1) for part in value.split(',') if '=' in part)
                    if options.get('format') != 'raw' or options.get('if') != 'ide' or not options.get('file'):
                        raise ValueError('Expected an explicit raw IDE disk')
                    if set(options) - {'file', 'format', 'if', 'index', 'readonly', 'snapshot'}:
                        raise ValueError('Unsupported disk profile options')
                    disks.append(Path(options['file']).resolve())
                    # Probe only immutable copies, with disposable snapshot writes.
                    options.pop('readonly', None)
                    options['snapshot'] = 'on'
                    value = ','.join(key + '=' + val for key, val in options.items())
                selected += [flag, value]
            index += 2
        elif flag in switches:
            index += 1  # Replace snapshot below; never execute guest CPUs.
        else:
            raise ValueError('Unsupported profile option: ' + flag)
    for flag in ('-machine', '-accel', '-cpu', '-m', '-nic'):
        if selected.count(flag) != 1:
            raise ValueError('Require one explicit ' + flag)
    if not disks:
        raise ValueError('Boot profile has no disk')
    return selected, disks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    raw = args.command.read_bytes()
    argv = json.loads(raw)
    if not isinstance(argv, list) or not argv or any(not isinstance(v, str) for v in argv):
        parser.error('Expected a recorded QEMU argument list')
    executable = shutil.which(argv[0])
    tracer = shutil.which('strace')
    if not executable or not tracer:
        parser.error('QEMU executable and strace are required')
    executable = Path(executable).resolve()
    selected, disks = profile(argv)
    pins = {str(path): sha(path) for path in [executable, *disks]}
    args.out.mkdir(parents=True)
    for index, flag in enumerate(selected):
        if flag == '-drive':
            options = dict(part.split('=', 1) for part in selected[index + 1].split(','))
            source = Path(options['file']).resolve()
            copy = args.out.resolve() / ('probe-disk-' + str(index) + '.img')
            shutil.copyfile(source, copy)
            if sha(copy) != pins[str(source)] or sha(source) != pins[str(source)]:
                raise ValueError('Disk changed while creating immutable probe copy')
            options['file'] = str(copy)
            selected[index + 1] = ','.join(key + '=' + val for key, val in options.items())
            pins[str(copy)] = sha(copy)
    probe = [str(executable), *selected, '-snapshot', '-S', '-display', 'none',
             '-monitor', 'none', '-qmp', 'stdio']
    requests = [('capabilities', 'qmp_capabilities', {}),
                ('machines', 'query-machines', {}),
                ('pci', 'query-pci', {}), ('version', 'query-version', {}),
                ('roms', 'human-monitor-command', {'command-line': 'info roms'}),
                ('quit', 'quit', {})]
    data = ''.join(json.dumps(dict(execute=execute, arguments=arguments, id=name)) + '\n'
                   for name, execute, arguments in requests)
    completed = subprocess.run([tracer, '-f', '-e', 'trace=openat', '-o',
                                str(args.out / 'opens.log'), *probe],
                               input=data, text=True, capture_output=True, timeout=30)
    (args.out / 'qmp.log').write_text(completed.stdout)
    (args.out / 'stderr.log').write_text(completed.stderr)
    if completed.returncode:
        raise ValueError('Paused QEMU probe failed: ' + completed.stderr)
    replies = {}
    for line in completed.stdout.splitlines():
        response = json.loads(line)
        if 'id' in response:
            if 'error' in response:
                raise ValueError('QMP probe failed: ' + json.dumps(response))
            replies[response['id']] = response['return']
    if set(replies) != {name for name, _, _ in requests}:
        raise ValueError('Incomplete QMP environment replies')
    alias = selected[selected.index('-machine') + 1].split(',')[0]
    matching = [m for m in replies['machines'] if m['name'] == alias or m.get('alias') == alias]
    if len(matching) != 1:
        raise ValueError('Could not resolve requested machine type')
    firmware = {}
    for line in (args.out / 'opens.log').read_text().splitlines():
        match = re.search(r'openat\([^,]+, "([^"\n]+)".*\)\s+=\s+(\d+)', line)
        if match:
            path = Path(match[1])
            if 'bios' in path.name and path.suffix == '.bin' and path.is_file():
                path = path.resolve()
                firmware[str(path)] = dict(bytes=path.stat().st_size, sha256=sha(path))
    if not any('vgabios' in Path(p).name for p in firmware) or not any(
            'vgabios' not in Path(p).name for p in firmware):
        raise ValueError('Actual system and VGA firmware opens were not captured')
    if any(sha(Path(p)) != identity for p, identity in pins.items()) or args.command.read_bytes() != raw:
        raise ValueError('Probe changed or raced its command, binary or disk inputs')
    version = subprocess.check_output([str(executable), '--version'], text=True).strip()
    report = dict(result='pass', command_sha256=hashlib.sha256(raw).hexdigest(),
                  original_command=argv, paused_probe_command=probe,
                  qemu_executable=str(executable), qemu_version=version,
                  input_sha256=pins, machine=matching[0], firmware=firmware,
                  rom_mappings=replies['roms'], pci=replies['pci'],
                  qmp_version=replies['version'], host=platform.uname()._asdict(),
                  source_disks_unchanged=True,
                  scope='Paused ordinary boot-profile environment on byte-identical disk copies; actual firmware opens, no guest execution, timing measurement or complete device qualification')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: report[k] for k in ('result', 'qemu_version', 'machine', 'firmware')}))


if __name__ == '__main__':
    main()
