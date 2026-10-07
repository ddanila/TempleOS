#!/usr/bin/env python3
"""Qualify two native generations using an already qualified six-module build."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_identity(repo):
    # Include untracked candidate sources, while excluding generated build trees.
    paths = []
    for directory in ('Kernel', 'Compiler', 'Adam', 'tools'):
        for path in (repo / directory).rglob('*'):
            if path.is_file() and path.suffix.lower() in ('.hc', '.hh', '.py', '.asm', '.inc'):
                paths.append(path)
    return {str(path.relative_to(repo)): sha(path) for path in sorted(paths)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', type=Path, required=True)
    parser.add_argument('--retained-build', type=Path, required=True)
    parser.add_argument('--stage-listing', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    parser.add_argument('--cpu', default='486', help='CPU model for all native build/install boots')
    parser.add_argument('--qmp-stdio', action='store_true')
    parser.add_argument('--build-command-timeout', type=int, default=3600,
                        help='Per-module native rebuild limit in seconds')
    args = parser.parse_args()
    if args.build_command_timeout <= 0:
        parser.error('Build command timeout must be positive')
    runtime = ['--accel', args.accel, '--cpu', args.cpu]
    if args.qmp_stdio:
        runtime.append('--qmp-stdio')
    repo, retained, listing, out = [p.resolve() for p in
        (args.repository, args.retained_build, args.stage_listing, args.out)]
    if out.exists():
        parser.error('Use a new output directory; existing evidence is preserved')
    ready = json.loads((retained / 'result.json').read_text())
    expected = {'Startup', 'MemoryRuntime', 'FileRuntime', 'ConsoleRuntime',
                'CompilerProbe', 'CompilerRuntime'}
    if ready.get('result') != 'pass' or set(ready.get('modules', {})) != expected:
        parser.error('Input must qualify all six retained modules')
    if not listing.is_file() or not (retained / 'source.img').is_file():
        parser.error('Missing stage listing or qualified source image')
    inputs = {str(p): sha(p) for p in
              (retained / 'result.json', retained / 'source.img', listing, Path(__file__).resolve())}
    sources = source_identity(repo)
    out.mkdir(parents=True)
    report = {'result': 'running', 'stage': 'preflight', 'repository': str(repo),
              'accel': args.accel, 'cpu': args.cpu, 'qmp_stdio': args.qmp_stdio,
              'build_command_timeout': args.build_command_timeout,
              'input_sha256': inputs,
              'source_sha256': sources, 'stages': {}}

    def save():
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')

    def unchanged():
        if source_identity(repo) != sources:
            raise ValueError('Candidate sources changed during qualification')
        if any(sha(Path(name)) != digest for name, digest in inputs.items()):
            raise ValueError('Qualification input changed during execution')

    def run(stage, tool, *arguments):
        unchanged()
        report['stage'] = stage
        save()
        with (out / (stage + '.log')).open('w') as log:
            subprocess.run([sys.executable, str(repo / 'tools' / tool),
                            *map(str, arguments)], cwd=repo, stdout=log,
                           stderr=subprocess.STDOUT, check=True)
        result_path = out / stage / 'result.json'
        result = json.loads(result_path.read_text())
        if result.get('result') != 'pass':
            raise ValueError(stage + ' did not pass')
        report['stages'][stage] = {'result_sha256': sha(result_path), 'result': result}
        unchanged()
        save()
        return result

    def generation(number, built):
        prefix = 'gen' + str(number)
        install = out / (prefix + '-install')
        run(install.name, 'test-i386-retained-install.py', '--source', built / 'source.img',
            '--out', install, *runtime)
        native = out / (prefix + '-selfhost')
        result = run(native.name, 'test-i386-selfhost-install.py', '--disk', install / 'candidate.img',
            '--out', native, '--retained-build-result', built / 'result.json',
            '--retained-install-result', install / 'result.json',
            '--command-timeout', args.build_command_timeout, *runtime)
        if result.get('retained_origin') != 'guest-built supplied inputs':
            raise ValueError('Native generation used unqualified retained providers')
        audit = out / (prefix + '-audit')
        run(audit.name, 'audit-i386-guest-image.py', '--source', native / 'target.img',
            '--installed', native / 'target.img', '--kernel-module-path', '/Modules/I386/Kernel.t32m',
            '--flat-path', '/Probe/GuestBoot.bin', '--guest-compiler-template',
            '--stage-listing', listing, '--out', audit)
        return native, audit

    try:
        save()
        first, audited = generation(1, retained)
        built = out / 'gen2-retained-build'
        run(built.name, 'test-i386-retained-build.py', '--disk', first / 'target.img',
            '--reference-exports', audited / 'exports', '--compare-installed', first / 'target.img',
            '--out', built, '--command-timeout', args.build_command_timeout, *runtime)
        second, _ = generation(2, built)
        run('generation-identity', 'audit-i386-generations.py', '--first', first / 'target.img',
            '--second', second / 'target.img', '--out', out / 'generation-identity')
        report.update(result='pass', stage='complete')
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        save()


if __name__ == '__main__':
    main()
