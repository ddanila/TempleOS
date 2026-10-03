#!/usr/bin/env python3
"""Round-trip a persisted native i386 styled DolDoc through original TempleOS."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FILES = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents']
INPUT = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
EXPECTED = (b'$FG,4$red$FG$ plain$BG,1$ blue$BG$ end'
            b'$IV,1$ inv$IV,0$$UL,1$ under$UL,0$ done\x05')


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def replace_style_on_copy(disk, original, replacement):
    image = bytearray(disk.read_bytes())
    volume_start, sectors, root, bitmap_blocks, version = struct.unpack_from(
        '<5q', image, 2048 * 512 + 8)
    if volume_start != 2048 or version != 1 or root < 2049 + bitmap_blocks:
        raise ValueError('Unexpected RedSea volume in import copy')
    if 2048 + sectors > len(image) // 512:
        raise ValueError('RedSea volume exceeds import copy')
    _, _, _, directory_size, _ = struct.unpack_from('<H38sqqQ', image, root * 512)
    for offset in range(root * 512 + 128, root * 512 + directory_size, 64):
        attr, raw_name, block, size, date = struct.unpack_from('<H38sqqQ', image, offset)
        if raw_name.split(b'\0', 1)[0] != b'NativeColor.DD':
            continue
        if (attr != 0x800 or date != 0 or size != len(original) or
                image[block * 512:block * 512 + size] != original or
                block < 2049 + bitmap_blocks or block >= 2048 + sectors or
                len(replacement) > 512):
            raise ValueError('Unexpected native style extent in import copy')
        image[block * 512:(block + 1) * 512] = replacement.ljust(512, b'\0')
        struct.pack_into('<q', image, offset + 48, len(replacement))
        disk.write_bytes(image)
        return
    raise ValueError('Native style record missing from import copy')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('session_disk', type=Path,
                        help='Completed three-boot native DolDoc session image')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--qmp-stdio', action='store_true')
    args = parser.parse_args()
    session = args.session_disk.resolve()
    before = sha256(session)
    source = FILES(session, {'/NativeColor.DD'}).get('/NativeColor.DD')
    if source != EXPECTED:
        raise ValueError('Persisted native styled document differs from fixture')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    overlay = out / 'overlay'
    overlay.mkdir(exist_ok=True)
    (overlay / 'NativeColor.DD').write_bytes(source)
    iso = out / 'original-reader.iso'
    subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                    'build/rebuild-test/overlay', '--overlay',
                    'tests/guest/i386-doc-style-compat', '--overlay', str(overlay),
                    '--output', str(iso)], cwd=ROOT, check=True)
    guest = [sys.executable, 'tools/guest-run.py', str(iso),
             '--out', str(out / 'original'), '--timeout', '90']
    if args.qmp_stdio:
        guest.append('--qmp-stdio')
    subprocess.run(guest, cwd=ROOT, check=True)
    round_trip = (out / 'original/OriginalStyleRoundTrip.DD').read_bytes()
    if round_trip != source:
        raise ValueError('Original DocRead/DocSave changed native style bytes')
    authored = (out / 'original/OriginalAuthoredStyle.DD').read_bytes()
    if authored != source[:-1] + b'!\x05':
        raise ValueError('Original TempleOS did not edit the styled document')
    imported_disk = out / 'native-import.img'
    shutil.copyfile(session, imported_disk)
    replace_style_on_copy(imported_disk, source, authored)
    if FILES(imported_disk, {'/NativeColor.DD'}).get('/NativeColor.DD') != authored:
        raise ValueError('Original-authored bytes missing from import copy')
    commands = [
        ('CDoc *imported_style=DocRead("C:/NativeColor.DD");imported_style!=0;', ['1']),
        ('I64 imported_size;U8 *imported_data=DocSave(imported_style,&imported_size);'
         'imported_size==%d;' % len(authored), ['1']),
        ("imported_data[imported_size-2]=='!'&&imported_data[imported_size-1]==5;", ['1']),
        ('DocWrite(imported_style);', ['1']),
        ('Free(imported_data);DocDel(imported_style);', []),
    ]
    native_run = INPUT(imported_disk, out / 'native-import',
                       startup_check={'status': 'ok', 'answers': [], 'commands': commands},
                       snapshot=False, cpu='486,-fpu', accel='tcg',
                       qmp_stdio=args.qmp_stdio)
    if FILES(imported_disk, {'/NativeColor.DD'}).get('/NativeColor.DD') != authored:
        raise ValueError('Native guest changed original-authored style bytes')
    if sha256(session) != before:
        raise ValueError('Compatibility test changed the session disk')
    result = {'result': 'pass', 'bytes': len(source),
              'sha256': hashlib.sha256(source).hexdigest(),
              'original_round_trip': 'byte exact',
              'original_authored_bytes': len(authored),
              'original_authored_sha256': hashlib.sha256(authored).hexdigest(),
              'native_import': native_run,
              'session_disk_sha256': before, 'session_disk_unchanged': True}
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print('PASS: original TempleOS and native i386 exchanged styled documents')


if __name__ == '__main__':
    main()
