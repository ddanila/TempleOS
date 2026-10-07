#!/usr/bin/env python3
"""Verify an unpacked i386 release-candidate directory without the source tree."""

import argparse
import gzip
import hashlib
import json
from pathlib import Path
import runpy


def file_sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', nargs='?', type=Path,
                        default=Path(__file__).resolve().parent,
                        help='Directory containing manifest.json')
    args = parser.parse_args()
    package = args.package.resolve()
    manifest = json.loads((package / 'manifest.json').read_text())
    if manifest.get('format') not in (1, 2) or manifest.get('image') != 'TempleOS-i386-gen2.img':
        raise ValueError('Unexpected release manifest format or image')
    if manifest['format'] == 2 and 'loaded_firmware_evidence' not in manifest:
        raise ValueError('New release manifest requires loaded-firmware evidence')
    files = manifest['files_sha256']
    actual = {str(path.relative_to(package)) for path in package.rglob('*')
              if path.is_file() and path.relative_to(package) != Path('manifest.json')}
    if actual != set(files):
        raise ValueError(f'Bundle file set differs: missing={set(files)-actual}, extra={actual-set(files)}')
    for name, expected in files.items():
        if file_sha256(package / name) != expected:
            raise ValueError(f'Bundle file hash differs: {name}')
    disk = package / (manifest['image'] + '.gz')
    digest = hashlib.sha256()
    size = 0
    with gzip.open(disk, 'rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
            size += len(chunk)
    if (size, digest.hexdigest()) != (manifest['image_bytes'], manifest['image_sha256']):
        raise ValueError('Decompressed disk differs from manifest')
    if 'loaded_firmware_evidence' in manifest:
        if manifest['loaded_firmware_evidence'] != 'evidence/loaded-firmware':
            raise ValueError('Unexpected loaded-firmware evidence location')
        verify_firmware = runpy.run_path(
            str(package / 'evidence/loaded-firmware-checker.py'))['verify']
        firmware = verify_firmware(package / manifest['loaded_firmware_evidence'])
        if firmware['source_disk_sha256'] != manifest['image_sha256']:
            raise ValueError('Firmware evidence belongs to a different release image')
    if 'speaker_output_generations' in manifest:
        if manifest['speaker_output_generations'] != ['first', 'second']:
            raise ValueError('Expected audio evidence for both generations')
        assess = runpy.run_path(str(package / 'evidence/speaker-output-checker.py'))['assess_wav']
        for label, disk_hash in (('first', manifest['image_sha256']),
                                 ('second', manifest['second_generation_sha256'])):
            audio = json.loads((package / f'evidence/{label}-speaker-output.json').read_text())
            wav = package / f'evidence/{label}-speaker.wav'
            if audio.get('disk_sha256') != disk_hash or audio.get('wav_sha256') != file_sha256(wav):
                raise ValueError(f'{label}: audio evidence identity differs')
            measured = assess(wav, audio.get('console_result', {}).get('audio_emission', {}))
            if measured['result'] != 'pass' or any(audio.get(key) != value for key, value in measured.items()):
                raise ValueError(f'{label}: speaker output failed independent verification')
    print(json.dumps({'result': 'pass', 'files': len(files),
                      'image_sha256': digest.hexdigest(),
                      'packaging_revision': manifest['packaging_revision']}, indent=2))


if __name__ == '__main__':
    main()
