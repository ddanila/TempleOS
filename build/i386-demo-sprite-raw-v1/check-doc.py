"""Verify SpriteRaw's saved DolDoc and the packed vector commands."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

VECTOR = (
    bytes((1, 2))
    + struct.pack('<B4i', 10, 0, 0, 100, 50)
    + struct.pack('<B4i', 10, 0, 0, 50, 100)
    + struct.pack('<B4i', 10, 100, 50, 50, 100)
    + struct.pack('<B2i', 21, 20, 20)
    + bytes((0,))
)
EXPECTED = b'$SP,"",BI=1$' + b'\n' * 13 + b'\x05\0' + struct.pack('<4I', 1, 0, len(VECTOR), 1) + VECTOR


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('document', type=Path)
    args = parser.parse_args()
    data = args.document.read_bytes()
    if data != EXPECTED:
        raise ValueError('SpriteRaw DolDoc differs from the expected binary records')
    print(json.dumps(dict(result='pass', document_sha256=hashlib.sha256(data).hexdigest(),
                          document_bytes=len(data), vector_bytes=len(VECTOR)), indent=2))


if __name__ == '__main__':
    main()
