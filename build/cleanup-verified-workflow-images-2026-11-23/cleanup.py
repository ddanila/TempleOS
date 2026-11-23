import hashlib
import json
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def identity(stat):
    return stat.st_ino, stat.st_size, stat.st_mtime_ns, stat.st_ctime_ns


workflows = {
    'resident-opt-c5-generations128/gen1-desktop64': ('after-physical.bin', 'working.img'),
    'resident-opt-c5-generations128/gen2-desktop64-rerun': ('after-physical.bin', 'working.img'),
    'application-menu-mouse-observer-v1/candidate64': ('working.img',),
    'i386-graphics-registry-integration/timeclock-report64': ('working.img',),
}
manifest = Path(__file__).with_name('manifest.jsonl')
if manifest.exists():
    raise FileExistsError(manifest)
for directory, filenames in workflows.items():
    root = Path('build') / directory
    receipt = json.loads((root / 'result.json').read_text())
    if receipt['result'] != 'pass' or not receipt['inputs_unchanged']:
        raise ValueError(f'Unverified workflow: {root}')
    for name in filenames:
        path = root / name
        before = path.stat()
        if path.is_symlink() or before.st_nlink != 1:
            raise ValueError(f'Unexpected links: {path}')
        sha256 = digest(path)
        with TemporaryDirectory(dir=root) as scratch:
            sparse = Path(scratch) / name
            subprocess.run(['cp', '--preserve=all', '--sparse=always',
                            '--reflink=never', '--', path, sparse], check=True)
            after = sparse.stat()
            if digest(sparse) != sha256 or identity(path.stat()) != identity(before):
                raise ValueError(f'File verification failed: {path}')
            reclaimed = (before.st_blocks - after.st_blocks) * 512
            if reclaimed <= 0:
                continue
            os.replace(sparse, path)
            row = dict(path=str(path), sha256=sha256, size=after.st_size,
                       reclaimed_bytes=reclaimed)
            with manifest.open('a') as stream:
                stream.write(json.dumps(row) + '\n')
            print(json.dumps(row))
