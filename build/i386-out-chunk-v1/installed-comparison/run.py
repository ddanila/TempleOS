"""Run the 8 MiB document resource fixture with one replacement compiler."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('compiler', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    args.out.mkdir(parents=True)
    base = sha(args.source)
    disk = args.out / 'installed.img'
    replacement = '/Probe/ChunkCompiler.t32m'
    retained = '/Modules/I386/CompilerRuntime.t32m'
    compiler = args.compiler.read_bytes()
    helpers = runpy.run_path('tools/build-i386-kernel.py')
    contents = helpers['mutated_file_contents']
    console = '/Modules/I386/ConsoleRuntime.t32m'
    original = contents(args.source, {retained, console})
    package = runpy.run_path('tools/package-i386-native-image.py')['package']
    package(args.source, disk, additions={replacement: compiler})
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = Guest(disk, args.out / 'replace', True, ram_mib=16)
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('if(!FileDel("C:' + retained + '") || !FileMove("C:' +
                      replacement + '","C:' + retained + '"))throw(\'Install\',TRUE);')
    finally:
        guest.close()
    after = contents(disk, {retained, console, replacement})
    assert after == {retained: compiler, console: original[console]}
    assert sha(args.source) == base
    frozen = sha(disk)
    resource = args.out / 'resource8'
    run = subprocess.run([sys.executable, 'tools/test-i386-resource-profile.py',
                          '--disk', str(disk), '--out', str(resource), '--accel', 'kvm',
                          '--qmp-stdio', '--managed-welcome', '--writable-copy'])
    assert sha(disk) == frozen
    log = (resource / 'debug.log').read_text()
    receipt = resource / 'resource-result.json'
    report = dict(result='pass' if run.returncode == 0 else 'fail', base_disk_sha256=base,
                  installed_disk_sha256=frozen, compiler_sha256=sha(args.compiler),
                  console_sha256=hashlib.sha256(original[console]).hexdigest(),
                  reached_prompt='DONE native kernel startup\n' in log,
                  emitter_chunk_space_rejected='EMITTER CHUNK SPACE REJECT' in log,
                  log_sha256=sha(resource / 'debug.log'))
    if run.returncode == 0:
        report['completed_document_sessions'] = json.loads(receipt.read_text())['document_development_cycles']
    else:
        report['tail'] = log.splitlines()[-12:]
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(report)


if __name__ == '__main__':
    main()
