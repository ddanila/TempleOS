#!/usr/bin/env python3
"""Qualify two native generations using an already qualified nine-provider build."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
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
    parser.add_argument('--retained-install', type=Path,
                        help='Reuse an already passing all-nine installation directory for generation one, after verifying its provenance')
    parser.add_argument('--stage-listing', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    parser.add_argument('--cpu', default='486', help='CPU model for all native build/install boots')
    parser.add_argument('--welcome', action='store_true',
                        help='Expect the original welcome document at each prompt')
    parser.add_argument('--qmp-stdio', action='store_true')
    parser.add_argument('--managed-pointer', action='store_true',
                        help='Use exact managed-pointer welcome checks with live WinMgr')
    parser.add_argument('--build-command-timeout', type=int, default=3600,
                        help='Per-module native rebuild limit in seconds')
    parser.add_argument('--retained-build-ram-mib', type=int, choices=(16, 64, 128), default=16,
                        help='Guest RAM for the generation-two retained build (default: 16 MiB)')
    parser.add_argument('--flat-build-ram-mib', type=int, choices=(16, 64, 128), default=16,
                        help='Guest RAM for both native flat-kernel rebuilds (default: 16 MiB)')
    parser.add_argument('--allow-kernel-build-date', action='store_true',
                        help='Declare only the exported eight-byte Kernel date nondeterministic in the generation comparison')
    args = parser.parse_args()
    if args.build_command_timeout <= 0:
        parser.error('Build command timeout must be positive')
    runtime = ['--accel', args.accel, '--cpu', args.cpu]
    if args.qmp_stdio:
        runtime.append('--qmp-stdio')
    if args.welcome:
        runtime.append('--welcome')
    if args.managed_pointer:
        runtime.append('--managed-pointer')
    repo, retained, listing, out = [p.resolve() for p in
        (args.repository, args.retained_build, args.stage_listing, args.out)]
    if out.exists():
        parser.error('Use a new output directory; existing evidence is preserved')
    ready = json.loads((retained / 'result.json').read_text())
    expected = {'Startup', 'MemoryRuntime', 'FileRuntime', 'ConsoleRuntime',
                'CompilerProbe', 'CompilerRuntime', 'BuildRuntime', 'DocDiagnosticRuntime', 'EditorRuntime'}
    if ready.get('result') != 'pass' or set(ready.get('modules', {})) != expected:
        parser.error('Input must qualify all retained modules')
    if not listing.is_file() or not (retained / 'source.img').is_file():
        parser.error('Missing stage listing or qualified source image')
    if sha(retained / 'source.img') != ready.get('source_disk_sha256'):
        parser.error('Retained build image differs from its passing build receipt')
    inputs = {str(p): sha(p) for p in
              (retained / 'result.json', retained / 'source.img', listing, Path(__file__).resolve())}
    reused_install = args.retained_install.resolve() if args.retained_install else None
    reused_result = None
    if reused_install:
        install_result = reused_install / 'result.json'
        candidate = reused_install / 'candidate.img'
        if not install_result.is_file() or not candidate.is_file():
            parser.error('Reused installation must contain result.json and candidate.img')
        reused_result = json.loads(install_result.read_text())
        files = runpy.run_path(str(repo / 'tools/build-i386-kernel.py'))['mutated_file_contents']
        payloads = files(candidate, {f'/Modules/I386/{name}.t32m' for name in expected})
        verify = runpy.run_path(str(repo / 'tools/test-i386-selfhost-install.py'))['verify_retained_provenance']
        verify(ready, reused_result, sha(candidate), payloads)
        inputs.update({str(p): sha(p) for p in (install_result, candidate)})
    sources = source_identity(repo)
    out.mkdir(parents=True)
    report = {'result': 'running', 'stage': 'preflight', 'repository': str(repo),
              'scope': 'Two native rebuild/install/boot generations and artifact audits only; full desktop/application compatibility suite and C1-C5 qualification are separate gates.',
              'accel': args.accel, 'cpu': args.cpu, 'qmp_stdio': args.qmp_stdio, 'welcome': args.welcome,
              'managed_pointer': args.managed_pointer,
              'build_command_timeout': args.build_command_timeout,
              'retained_build_ram_mib': args.retained_build_ram_mib,
              'flat_build_ram_mib': args.flat_build_ram_mib,
              'allow_kernel_build_date': args.allow_kernel_build_date,
              'reused_retained_install': str(reused_install) if reused_install else None,
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
        if number == 1 and reused_install:
            unchanged()
            install = reused_install
            report['stages']['gen1-install'] = {
                'reused': True, 'directory': str(install),
                'result_sha256': sha(install / 'result.json'), 'result': reused_result}
            save()
        else:
            install = out / (prefix + '-install')
            run(install.name, 'test-i386-retained-install.py', '--source', built / 'source.img',
                '--out', install, *runtime)
        native = out / (prefix + '-selfhost')
        result = run(native.name, 'test-i386-selfhost-install.py', '--disk', install / 'candidate.img',
            '--out', native, '--retained-build-result', built / 'result.json',
            '--retained-install-result', install / 'result.json',
            '--build-ram-mib', args.flat_build_ram_mib,
            '--command-timeout', args.build_command_timeout, *runtime)
        if result.get('retained_origin') != 'guest-built supplied inputs':
            raise ValueError('Native generation used unqualified retained providers')
        if (set(result.get('guest_built_retained_modules', [])) != expected or
                set(result.get('guest_built_flat_modules', [])) !=
                {'Kernel', 'SysTry', 'TaskContext', 'ExceptContext', 'IrqEntry', 'ExceptionEntry'} or
                result.get('guest_built_auxiliary_modules') != ['CompilerProgramRuntimeProbe']):
            raise ValueError('Native generation omitted a guest-built delivered module')
        audit = out / (prefix + '-audit')
        run(audit.name, 'audit-i386-guest-image.py', '--source', native / 'target.img',
            '--installed', native / 'target.img', '--kernel-module-path', '/Modules/I386/Kernel.t32m',
            '--flat-path', '/Probe/GuestBoot.bin', '--guest-compiler-template',
            '--stage-listing', listing, '--out', audit)
        source_audit = out / (prefix + '-source-audit')
        run(source_audit.name, 'audit-i386-delivered-source.py',
            '--disk', native / 'target.img', '--repository', repo,
            '--out', source_audit / 'result.json')
        return native, audit

    try:
        save()
        run('input-source-audit', 'audit-i386-delivered-source.py',
            '--disk', retained / 'source.img', '--repository', repo,
            '--out', out / 'input-source-audit' / 'result.json')
        first, audited = generation(1, retained)
        built = out / 'gen2-retained-build'
        run(built.name, 'test-i386-retained-build.py', '--disk', first / 'target.img',
            '--reference-exports', audited / 'exports', '--compare-installed', first / 'target.img',
            '--out', built, '--command-timeout', args.build_command_timeout,
            '--ram-mib', args.retained_build_ram_mib, *runtime)
        second, _ = generation(2, built)
        run('generation-identity', 'audit-i386-generations.py', '--first', first / 'target.img',
            '--second', second / 'target.img', '--out', out / 'generation-identity',
            *(['--allow-kernel-build-date'] if args.allow_kernel_build_date else []))
        report.update(result='pass', stage='complete')
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        save()


if __name__ == '__main__':
    main()
