import hashlib
import json
from pathlib import Path
import subprocess

manifest = Path(__file__).with_name('manifest.json')
rows = json.loads(manifest.read_text())['files'] if manifest.exists() else []
runs = [
    'native-strut-entry-v1/strut64', 'span-reference-persistence-v1/native64',
    'native-window-ode-v1/strut64', 'native-stretched-spring-v1/native64',
    'native-ode-task-birth-v1/candidate64', 'native-ode-task-birth-v1/base64',
    'strut-ode-task-ring-v1/native64', 'strut-ode-mass-core-v1/native64',
    'strut-simulation-update-trace-v1/native64', 'strut-simulation-tick-v1/native64',
    'strut-projected-drag-v1/native64', 'strut-drag-diagnostic-v1/native64',
    'strut-rk4-derivative-v1/native64', 'strut-edit-play-v1/native64',
    'strut-edit-play-v1/original', 'strut-drag-diagnostic-v1/original',
    'strut-drag-hold-v1/original', 'strut-mass-selection-v1/original',
    'strut-projected-drag-v1/original', 'span-reference-persistence-v1/ram-reference',
    'span-reference-interactive-v1/original',
    'span-native-cold-v1/native64',
    'span-native-interactive-v1/native64',
    'span-native-coordinate-locals-v1/native64-typed',
    'span-native-music-v1/native64',
    'span-file-interchange-v1/native64',
    'span-file-interchange-v1/native64-roundtrip',
    'span-file-interchange-v1/original',
    'span-soundtrack-v1/reference-original',
    'span-soundtrack-v1/native64',
    'filename-popup-differential-v1/native64',
    'filename-popup-differential-v1/native64-escape',
    'filename-popup-differential-v1/original',
    'filename-popup-differential-v1/original-escape',
    'span-main-units-v1/native64',
    'span-draw-spring-default-v1/native64',
    'span-draw-spring-minimal-v1/native64',
    'span-line-call-v1/native64',
    'span-line-backend-trace-v1/native64',
    'production-span-followup-load-v1/GrModels',
    'production-span-followup-load-v1/Titanium',
    'production-span-followup-load-v1/ToTheFront',
    'production-span-followup-load-v1/X-Caliber',
    'grmodels-ball-reference-v1/native64',
    'grmodels-native-records-v1/native64',
    'grmodels-native-matrix-v1/native64',
    'xcaliber-ode-load-v1/native64',
    'tothefront-line-load-v1/native64',
    'native-geometry-source-v1/ToTheFront',
    'native-geometry-source-v1/GrModels',
    'native-geometry-source-v1/ToTheFront-serial',
    'native-geometry-source-v1/ToTheFront-serial-absolute',
    'native-geometry-source-v1/ToTheFront-serial-sibling',
    'native-geometry-source-v1/ToTheFront-serial-explicit',
    'native-geometry-source-v1/ToTheFront-serial-inline',
    'native-geometry-source-v1/ToTheFront-serial-units',
    'native-geometry-source-v1/ToTheFront-serial-exact',
    'native-geometry-source-v1/ToTheFront-split-fire',
    'native-geometry-source-v1/ToTheFront-curves',
    'native-geometry-source-v1/ToTheFront-range',
    'native-geometry-source-v1/ToTheFront-visibility',
    'native-geometry-source-v1/ToTheFront-visibility-zeroed',
    'tothefront-original-v1/visibility',
    'tothefront-original-v1/visibility-zeroed',
    'tothefront-original-v1/seed',
    'tothefront-original-v1/player-choice',
    'tothefront-original-v1/human-match',
    'native-geometry-source-v1/ToTheFront-key-poll',
    'native-geometry-source-v1/ToTheFront-task-settings',
    'native-geometry-source-v1/ToTheFront-combined',
    'native-geometry-source-v1/ToTheFront-human-match',
    'tothefront-normal-entry-v1/match64',
    'tothefront-normal-entry-v1/user8',
    'native-geometry-source-v1/ToTheFront-indirect-head',
    'native-geometry-source-v1/ToTheFront-wrap',
    'native-geometry-source-v1/X-Caliber',
    'native-geometry-source-v1/GrModels-ball-mesh',
    'grmodels-ball-reference-v1/interactive-original',
    'grmodels-ball-reference-v1/math-original',
    'grmodels-ball-reference-v1/math-native',
    'grmodels-ball-reference-v1/cosine-native',
    'grmodels-ball-reference-v1/cosine-retained',
    'i386-wide-product-lowering-v1/conversion64',
    'i386-wide-product-lowering-v1/user8',
    'i386-wide-product-lowering-v1/shared-conversion64',
    'i386-wide-product-lowering-v1/shared-user8',
    'i386-wide-product-lowering-v1/primary-user8',
    'i386-wide-product-lowering-v1/heap-base',
    'i386-wide-product-lowering-v1/heap-shared',
    'i386-wide-product-lowering-v1/heap-primary-minimum',
    'i386-wide-product-lowering-v1/small-holes-user8',
    'i386-wide-product-lowering-v1/heap-small-holes',
    'span-production-v1/gen1-user8',
    'span-production-v1/gen1-span64',
    'span-production-v1/gen1-user8-heap',
    'span-production-v1/gen1-cross-console-heap',
    'grmodels-ball-reference-v1/math-retained',
    'grmodels-ball-reference-v1/trace-original-fixed',
    'grmodels-ball-reference-v1/product-original',
    'grmodels-ball-reference-v1/product-native',
    'grmodels-ball-reference-v1/wide-check-original',
    'grmodels-ball-reference-v1/wide-check-original-implicit',
    'grmodels-ball-reference-v1/wide-check-native',
    'native-geometry-source-v1/GrModels-ball-mesh-retained',
    'native-geometry-source-v1/GrModels-ball-trace-retained-fixed',
    'native-geometry-source-v1/GrModels-ball-wide-product',
    'native-geometry-bindings-v1/GrModels',
    'native-geometry-bindings-v1/user8',
    'native-geometry-table-v1/GrModels',
    'native-geometry-table-v1/probe64',
    'native-geometry-table-v1/probe64-named',
    'native-geometry-table-v1/user8',
    'tothefront-integer-prompt-v1/native64',
    'xcaliber-vector-load-v1/native64',
]


def digest(stream):
    return hashlib.file_digest(stream, 'sha256').hexdigest()


def open_in_guest(path):
    return str(path) in subprocess.check_output(['ps', '-eo', 'args'], text=True)


for run in runs:
    directory = Path('build') / run
    receipt = directory / 'result.json'
    if not receipt.is_file() or json.loads(receipt.read_text())['result'] not in ('pass', 'fail', 'observed'):
        continue
    for name in ('working.img', 'probe.img', 'original.iso'):
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
