"""Independent byte oracle for legacy and E32B native boot publication."""
import struct

BOOT_AREA = 2048 * 512
PAYLOAD_OFFSET = 4608


def expected_boot_area(source, payload):
    if len(source) < BOOT_AREA or source[510:512] != b'\x55\xaa':
        raise ValueError('Incomplete source boot area')
    if len(payload) < 8 or payload[0] != 0xE9 or any(payload[5:8]):
        raise ValueError('Invalid flat entry header')
    entry = 5 + struct.unpack_from('<i', payload, 1)[0]
    if not 8 <= entry < len(payload):
        raise ValueError('Invalid flat entry target')
    extended = struct.unpack_from('<I', source, 528)[0] == 0x42323345
    capacity = 2039 * 512 if extended else 960 * 512 - 4096
    if len(payload) > capacity:
        raise ValueError('Payload exceeds selected boot format')
    result = bytearray(source[:BOOT_AREA])
    if extended:
        if struct.unpack_from('<I', source, 532)[0] != 1 or struct.unpack_from('<I', source, 540)[0] != 0x100000:
            raise ValueError('Unsupported extended source metadata')
        checksum = 2166136261
        for byte in payload:
            checksum = ((checksum ^ byte) * 16777619) & 0xFFFFFFFF
        struct.pack_into('<I', result, 536, len(payload))
        struct.pack_into('<I', result, 544, checksum)
    result[PAYLOAD_OFFSET:PAYLOAD_OFFSET + capacity] = payload + bytes(capacity - len(payload))
    return bytes(result)
