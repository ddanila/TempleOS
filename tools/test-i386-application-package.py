#!/usr/bin/env python3
"""Verify additive packaging preserves a real native image and rejects conflicts."""
import argparse
import hashlib
from pathlib import Path
import runpy
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    args = parser.parse_args()
    source = args.disk.resolve()
    original = source.read_bytes()
    module = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
    pack, snapshot = module['package'], module['snapshot']
    before = snapshot(original)
    with tempfile.TemporaryDirectory() as directory:
        base = Path(directory)
        output = base/'added.img'
        additions = {'/Apps/PackagingProbe/data.bin':bytes(range(256)),
                     '/Apps/PackagingProbe/empty.DD':b''}
        archive_payload=b'archive fixture'
        archive=struct.pack('<qqB',17+len(archive_payload),len(archive_payload),1)+archive_payload
        additions['/Apps/PackagingProbe/archive.Z']=archive
        attrs={'/Apps/PackagingProbe/archive.Z':0xC00}
        report = pack(source, output, additions=additions,addition_attributes=attrs)
        _, files, directories = snapshot(output.read_bytes())
        assert all(files[name] == value for name,value in before[1].items())
        assert all(directories[name] == value for name,value in before[2].items())
        assert all(files[name] == (attrs.get(name,0x800),0,value) for name,value in additions.items())
        assert output.read_bytes()[:2048*512] == original[:2048*512]
        assert report['added_files'] == {k:hashlib.sha256(v).hexdigest() for k,v in additions.items()}
        repacked = base/'repacked.img'
        pack(output, repacked)
        assert repacked.read_bytes() == output.read_bytes()
        existing = next(iter(before[1]))
        for index, bad in enumerate([{existing:b'replacement'},
                {'/Modules/I386/Startup.t32m/child.HC':b'bad'},
                {'/Apps/../escape.HC':b'bad'}, {'/Apps/bad\0.HC':b'bad'},
                {'/Apps/probe.HC':'not bytes'}]):
            target = base/f'rejected-{index}.img'
            try:
                pack(source,target,additions=bad)
            except ValueError:
                pass
            else:
                raise AssertionError('Unsafe additions accepted')
            assert not target.exists()
        for index,(bad,attributes) in enumerate([
                ({'/bad.Z':b'bad'},{'/bad.Z':0xC00}),
                ({'/bad':archive},{'/bad':0xC00}),
                ({'/bad':b'bad'},{'/missing':0x800}),
                ({'/bad':b'bad'},{'/bad':0x810})]):
            target=base/f'bad-attributes-{index}.img'
            try:
                pack(source,target,additions=bad,addition_attributes=attributes)
            except ValueError:
                pass
            else:
                raise AssertionError('Invalid compressed addition accepted')
            assert not target.exists()
        try:
            pack(source,source,additions=additions)
        except ValueError:
            pass
        else:
            raise AssertionError('Source overwrite accepted')
    assert source.read_bytes() == original
    print('PASS: additive byte/metadata/boot preservation, empty/binary payloads, compressed attributes, idempotence and ten rejection cases')


if __name__=='__main__':
    main()
