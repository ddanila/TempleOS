"""Validate the complete BlkDevRep rows against each guest's device profile."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import runpy


HERE = Path(__file__).resolve().parent
REFERENCE = runpy.run_path(str(HERE / 'check-original.py'))
HEADER = b'Class:"CBlkDev"\n'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def devices(document):
    sections = document.split(HEADER)
    if sections[0] or not document.endswith(b'\x05'):
        raise ValueError('Expected complete CBlkDev reports')
    rows = {}
    for section in sections[1:]:
        fields = REFERENCE['FIELD'].findall(section)
        if [key.decode('ascii') for key, _ in fields] != REFERENCE['FIELDS']:
            raise ValueError('CBlkDev fields differ from the canonical record')
        data = dict(fields)
        drive = data[b'first_drv_let'].decode('ascii')
        if drive in rows or int(data[b'bd_signature'], 16) != REFERENCE['SIGNATURE']:
            raise ValueError('Invalid or repeated device record')
        rows[drive] = dict(type=int(data[b'type'], 16),
                           block_size=int(data[b'blk_size'], 16),
                           flags=int(data[b'flags'], 16),
                           max_blk=int(data[b'max_blk'], 16))
        if not rows[drive]['flags'] & 2 or rows[drive]['max_blk'] < 1:
            raise ValueError('Uninitialized device')
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    parser.add_argument('image', type=Path)
    args = parser.parse_args()
    receipt = json.loads((args.run / 'result.json').read_bytes())
    entry = receipt['entries']['Demo/Dsk/BlkDevRep.HC']
    if ('error' in receipt or not receipt['inputs_unchanged'] or
            sha(args.image.read_bytes()) != receipt['input_sha256']):
        raise ValueError('Missing complete unchanged-source capture')
    observed = {}
    for side in ('original', 'native'):
        path = args.run / side / entry['output_file']
        if path.is_file():
            data = path.read_bytes()
        else:
            data = gzip.decompress(path.with_suffix('.DD.gz').read_bytes())
        if sha(data) != entry[f'{side}_sha256']:
            raise ValueError(f'{side} document changed')
        observed[side] = devices(data)
    expected = {'original': {'B': (1, 512), 'T': (5, 2048)}, 'native': {'C': (2, 512)}}
    for side, by_drive in observed.items():
        if {letter: (row['type'], row['block_size']) for letter, row in by_drive.items()} != expected[side]:
            raise ValueError(f'{side} device profile differs: {by_drive}')
    if observed['native']['C']['max_blk'] != args.image.stat().st_size // 512 - 1:
        raise ValueError('The report does not cover the native ATA disk extent')
    print(json.dumps(dict(result='pass', fields_per_device=len(REFERENCE['FIELDS']),
                          devices=observed, input_sha256=receipt['input_sha256'],
                          source_sha256=entry['source_sha256']), indent=2))


if __name__ == '__main__':
    main()
