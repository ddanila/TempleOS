"""Verify the four GlblVars memory dumps captured from the 386 guest."""
import hashlib
import json
from pathlib import Path
import re
import struct

HERE = Path(__file__).resolve().parent
document = (HERE/'guest/demo-0.DD').read_bytes()
lines = document.splitlines()
if len(lines) != 18 or lines[16:] != [b'', b'\x05']:
    raise ValueError('Expected four dumps and the DolDoc terminator')

cases = []
for index, prefix in enumerate((b'Name', b'Static', b'name', b'static'), 1):
    start = (index - 1) * 4
    dump = bytearray()
    for offset, width, line in zip((0, 16, 32), (16, 16, 4), lines[start:start+3]):
        if not line.startswith(f'{offset:08X} '.encode()):
            raise ValueError(f'Unexpected row offset in dump {index}')
        dump.extend(bytes.fromhex(line[9:9+3*width].decode()))
    records = list(struct.iter_unpack('<i8s', dump))
    match = re.fullmatch(fr'Time {index}:([0-9]+)'.encode(), lines[start+3])
    if not match or not 0 <= int(match[1]) < 1000:
        raise ValueError(f'Unexpected time in dump {index}')
    value = int(match[1])
    expected = [(time, (prefix + str(number).encode()).ljust(8, b'\0'))
                for number, time in enumerate((10, value, 30), 1)]
    if records != expected:
        raise ValueError(f'Unexpected records in dump {index}')
    cases.append(dict(prefix=prefix.decode(), time=value, bytes=len(dump)))

print(json.dumps(dict(result='pass', document_sha256=hashlib.sha256(document).hexdigest(),
                      cases=cases), indent=2))
