"""Check the original and native free-space reports for their mounted volumes."""
import hashlib
import json
from pathlib import Path
import re
import struct

HERE = Path(__file__).resolve().parent
BATCH = HERE / 'comparison'
RECORD = re.compile(rb'([A-Z]):\s+([0-9]+\.[0-9]{3})% Free\n')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def report(data):
    if not data.endswith(b'\x05'):
        raise ValueError('Invalid DolDoc terminator')
    rows = RECORD.findall(data[:-1])
    if b''.join(match.group() for match in RECORD.finditer(data[:-1])) != data[:-1]:
        raise ValueError('Unexpected free-space report text')
    if len({drive for drive, _ in rows}) != len(rows):
        raise ValueError('Duplicate drive in free-space report')
    return {drive.decode(): percent.decode() for drive, percent in rows}


def main():
    raw = (BATCH / 'result.json').read_bytes()
    batch = json.loads(raw)
    if not batch['inputs_unchanged'] or 'error' in batch:
        raise ValueError('The native demo did not return to the prompt')
    entry = batch['entries']['Demo/Dsk/UnusedSpaceRep.HC']
    observations = {}
    for side in ('original', 'native'):
        data = (BATCH / side / entry['output_file']).read_bytes()
        if sha(data) != entry[side + '_sha256']:
            raise ValueError(f'The {side} document differs from the batch receipt')
        observations[side] = report(data)

    if observations['original'] != {'B': '99.975', 'T': '0.000'}:
        raise ValueError('Unexpected original RAM disk or CD report')
    disk = (BATCH / 'native.img').read_bytes()
    audit = json.loads((HERE / 'space-audit.json').read_bytes())
    if audit['result'] != 'pass' or sha(disk) != audit['disk_sha256']:
        raise ValueError('The native guest disk differs from the audited image')
    sectors, = struct.unpack_from('<q', disk, 2048 * 512 + 16)
    expected = f"{audit['free_bytes'] * 100 / (sectors * 512):.3f}"
    if observations['native'] != {'C': expected}:
        raise ValueError('Native percentage does not match the audited RedSea bitmap')
    print(json.dumps(dict(result='pass', candidate_sha256=batch['input_sha256'],
                          source_sha256=entry['source_sha256'], batch_receipt_sha256=sha(raw),
                          guest_disk_sha256=audit['disk_sha256'], drive_sectors=sectors,
                          redsea_free_bytes=audit['free_bytes'], reports=observations), indent=2))


if __name__ == '__main__':
    main()
