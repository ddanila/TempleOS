"""Validate the block device classes emitted by the pinned original guest."""
import gzip
import hashlib
import json
from pathlib import Path
import re

FIELDS = ('lock_fwding locked_flags bd_signature type flags first_drv_let unit pad base0 base1 '
          'blk_size drv_offset init_root_dir_blks max_blk dev_id_record RAM_dsk file_dsk_name '
          'file_dsk owning_task last_time max_reads max_writes').split()
FIELD = re.compile(rb'^[0-9A-F]{8} (?:\$FG,2\$)?(\w+)\s*:(?:\$FG\$)?([^\n]*)', re.MULTILINE)
SIGNATURE = int.from_bytes(b'BDSV', 'little')
HERE = Path(__file__).resolve().parent


def main():
    document = gzip.decompress((HERE / 'comparison/original/demo-0.DD.gz').read_bytes())
    sections = document.split(b'Class:"CBlkDev"\n')
    if sections[0] or len(sections) != 3 or not document.endswith(b'\x05'):
        raise ValueError('Expected two complete CBlkDev reports')
    observations = {}
    for section, (drive, device_type, block_size) in zip(sections[1:], (('B', 1, 512), ('T', 5, 2048))):
        rows = FIELD.findall(section)
        labels = [key.decode('ascii') for key, _ in rows]
        if labels != FIELDS:
            raise ValueError('CBlkDev fields differ from the canonical record')
        values = dict(rows)
        if values[b'first_drv_let'].decode('ascii') != drive or int(values[b'bd_signature'], 16) != SIGNATURE:
            raise ValueError('Wrong drive letter or block device signature')
        if int(values[b'type'], 16) != device_type or int(values[b'blk_size'], 16) != block_size:
            raise ValueError('Device type and block size differ from the guest profile')
        observations[drive] = dict(type=device_type, block_size=block_size,
                                   flags=int(values[b'flags'], 16),
                                   blocks=int(values[b'max_blk'], 16))
        if not observations[drive]['flags'] & 2 or observations[drive]['blocks'] < 1:
            raise ValueError('The device is empty or uninitialized')
    print(json.dumps(dict(result='pass', document_sha256=hashlib.sha256(document).hexdigest(),
                          fields_per_device=len(FIELDS), devices=observations), indent=2))


if __name__ == '__main__':
    main()
