#!/usr/bin/env python3
"""Losslessly archive named kernel listings from completed, inactive builds."""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
from tempfile import NamedTemporaryFile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"


def fingerprint(info):
    return info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_ctime_ns


def recovered_hash(path):
    with subprocess.Popen(["zstd", "-qdc", path], stdout=subprocess.PIPE) as reader:
        digest = hashlib.file_digest(reader.stdout, "sha256").hexdigest()
        if reader.wait():
            raise ValueError(f"Cannot read archive: {path}")
        return digest


def archive(path, manifest):
    destination = path.with_suffix(".txt.zst")
    with path.open("rb") as source, NamedTemporaryFile(dir=path.parent) as temp:
        original = os.fstat(source.fileno())
        if not stat.S_ISREG(original.st_mode) or original.st_nlink != 1:
            raise ValueError(f"Expected a single-link regular file: {path}")
        digest = hashlib.file_digest(source, "sha256").hexdigest()
        source.seek(0)
        subprocess.run(["zstd", "-q", "-1", "-c"], stdin=source, stdout=temp, check=True)
        os.fsync(temp.fileno())
        if recovered_hash(temp.name) != digest:
            raise ValueError(f"Archive verification failed: {path}")
        if destination.exists() and not destination.is_symlink() and destination.is_file():
            if recovered_hash(destination) != digest:
                destination = path.with_name(f"{path.name}.{digest}.zst")
        if fingerprint(path.lstat()) != fingerprint(original):
            raise ValueError(f"Listing changed during compression: {path}")
        os.chmod(temp.name, stat.S_IMODE(original.st_mode))
        try:
            os.link(temp.name, destination)
            archive_blocks = destination.stat().st_blocks
        except FileExistsError:
            if (destination.is_symlink() or not destination.is_file()
                    or recovered_hash(destination) != digest):
                raise ValueError(f"Conflicting archive: {destination}")
            archive_blocks = 0
        entry = {"source": str(path.relative_to(ROOT)), "archive": str(destination.relative_to(ROOT)),
                 "sha256": digest, "source_bytes": original.st_size,
                 "saved_allocated_bytes": (original.st_blocks - archive_blocks) * 512}
        manifest.write(json.dumps(entry) + "\n")
        manifest.flush()
        os.fsync(manifest.fileno())
        if fingerprint(path.lstat()) != fingerprint(original):
            raise ValueError(f"Listing changed before removal: {path}")
        path.unlink()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("listings", nargs="+", type=Path)
    args = parser.parse_args()
    tracked = subprocess.check_output(["git", "ls-files", "-z", "--", "build"], cwd=ROOT)
    tracked = set(os.fsdecode(tracked).split("\0"))
    paths = []
    for path in args.listings:
        path = path.absolute()
        if (path != path.resolve() or not path.is_relative_to(BUILD)
                or path.name != "kernel-assembly.txt"
                or str(path.relative_to(ROOT)) in tracked
                or str(path.with_suffix(".txt.zst").relative_to(ROOT)) in tracked):
            parser.error(f"Expected an untracked build listing with no symlinks: {path}")
        paths.append(path)
    with NamedTemporaryFile(mode="w", prefix="cleanup-kernel-listings-", suffix=".jsonl",
                            dir=BUILD, delete=False) as manifest:
        print(f"Recovery manifest: {manifest.name}", flush=True)
        with (BUILD / ".archive-kernel-listings.lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            for path in paths:
                archive(path, manifest)


if __name__ == "__main__":
    main()
