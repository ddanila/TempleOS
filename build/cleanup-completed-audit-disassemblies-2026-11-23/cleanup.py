import hashlib
import json
from pathlib import Path
import subprocess

manifest = Path(__file__).with_name('manifest.json')
rows = json.loads(manifest.read_text())['files'] if manifest.exists() else []
runs = [
    'native-strut-entry-v1/combined',
    'native-window-ode-v1/combined',
    'native-ode-on-demand-v1/combined',
    'native-ode-on-demand-v1/console-only',
    'native-ode-task-birth-v1/cross',
    'strut-native-raster-bindings-v1/audit',
    'i386-graphics-registry-integration/generations128/gen1-audit',
    'i386-graphics-registry-integration/generations128/gen2-audit',
    'i386-graphics-registry-integration/native',
    'i386-graphics-registry-integration/native-v2',
    'on-demand-optimizer-v5/audit',
    'on-demand-optimizer-v4/audit',
    'on-demand-lexer-v9/audit',
    'on-demand-lexer-v8/audit',
    'on-demand-lexer-v6/audit',
    'resident-opt-original-user-v2/audit',
    'original-user-loop-prototype-v7/audit',
    'original-user-loop-prototype-v5/audit',
    'original-user-loop-input-batch-v1/audit',
    'original-user-loop-ownership-v3/audit',
    'original-user-loop-ownership-v1/audit',
    'original-user-loop-prototype-v1/audit',
    'native-geometry-bindings-v1/combined',
    'native-geometry-table-v1/combined',
    'native-geometry-table-v1/combined-named',
    'i386-wide-product-lowering-v1/candidate',
    'i386-wide-product-lowering-v1/shared-candidate',
    'i386-wide-product-lowering-v1/primary-candidate',
    'span-production-v1/generations128-resume-install/gen1-audit',
]


def digest(stream):
    return hashlib.file_digest(stream, 'sha256').hexdigest()


def open_in_guest(path):
    return str(path) in subprocess.check_output(['ps', '-eo', 'args'], text=True)


for run in runs:
    directory = Path('build') / run
    for name in ('kernel-assembly.txt',):
        original = directory / name
        archive = original.with_suffix(original.suffix + '.zst')
        if not original.is_file() or original.is_symlink() or archive.exists():
            continue
        if open_in_guest(original) or subprocess.check_output(
                ['git', 'ls-files', '--', str(original)], text=True):
            continue
        before = original.stat()
        with original.open('rb') as stream:
            sha256 = digest(stream)
        scratch = archive.with_suffix(archive.suffix + '.tmp')
        subprocess.run(['zstd', '-q', str(original), '-o', str(scratch)], check=True)
        with subprocess.Popen(['zstd', '-qdc', str(scratch)], stdout=subprocess.PIPE) as proc:
            verified = digest(proc.stdout)
            if proc.wait() != 0 or verified != sha256:
                raise ValueError(f'Archive verification failed for {original}')
        after = original.stat()
        if (before.st_ino, before.st_size, before.st_mtime_ns) != (
                after.st_ino, after.st_size, after.st_mtime_ns) or open_in_guest(original):
            raise ValueError(f'Image changed or reopened during archival: {original}')
        saved = (before.st_blocks - scratch.stat().st_blocks) * 512
        if saved <= 0:
            scratch.unlink()
            continue
        scratch.rename(archive)
        rows.append(dict(original=str(original), archive=str(archive), sha256=sha256,
                         size=before.st_size, reclaimed_bytes=saved,
                         restore=['zstd', '-d', str(archive), '-o', str(original)]))
        manifest_tmp = manifest.with_suffix('.tmp')
        manifest_tmp.write_text(json.dumps(
            {'files': rows, 'reclaimed_bytes': sum(row['reclaimed_bytes'] for row in rows)},
            indent=2) + '\n')
        manifest_tmp.replace(manifest)
        original.unlink()

print(len(rows), sum(row['reclaimed_bytes'] for row in rows), 'bytes archived')
